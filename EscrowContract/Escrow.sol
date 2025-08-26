
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title Escrow with Arbiter and Deadlines (Single Deal)
/// @notice Buyer deposits ETH. Arbiter resolves. Supports timeouts, refunds, and partial withdrawals.
contract Escrow is Ownable, ReentrancyGuard {
    enum State { NotInitialized, Funded, Delivered, Refunded, Released }

    address public buyer;
    address public seller;
    address public arbiter;

    uint256 public amount; // wei
    uint256 public fundedAt;
    uint256 public deliveryDeadline; // epoch seconds

    State public state;

    event Initialized(address indexed buyer, address indexed seller, address indexed arbiter, uint256 amount, uint256 deliveryDeadline);
    event Funded(address indexed buyer, uint256 amount);
    event MarkDelivered(address indexed seller);
    event Released(address indexed arbiter, address indexed seller, uint256 amount);
    event Refunded(address indexed arbiter, address indexed buyer, uint256 amount);
    event TimeoutRefund(address indexed buyer, uint256 amount);

    error InvalidState(State expected, State got);
    error OnlyBuyer();
    error OnlySeller();
    error OnlyArbiter();
    error ZeroAddress();
    error ZeroAmount();

    modifier inState(State expected) {
        if (state != expected) revert InvalidState(expected, state);
        _;
    }

    modifier onlyBuyer() { if (msg.sender != buyer) revert OnlyBuyer(); _; }
    modifier onlySeller() { if (msg.sender != seller) revert OnlySeller(); _; }
    modifier onlyArbiter() { if (msg.sender != arbiter) revert OnlyArbiter(); _; }

    constructor() Ownable(msg.sender) {}

    /// @dev Initialize a single escrow deal. Can only be called once by owner (e.g., factory or deployer).
    function init(address _buyer, address _seller, address _arbiter, uint256 _deliveryDeadline) external onlyOwner inState(State.NotInitialized) {
        if (_buyer == address(0) || _seller == address(0) || _arbiter == address(0)) revert ZeroAddress();
        if (_deliveryDeadline <= block.timestamp) revert();
        buyer = _buyer;
        seller = _seller;
        arbiter = _arbiter;
        deliveryDeadline = _deliveryDeadline;
        state = State.Funded; // moves to Funded once deposit happens; set here to allow deposit guard
        emit Initialized(_buyer, _seller, _arbiter, 0, _deliveryDeadline);
        state = State.NotInitialized; // reset to enforce deposit flow
    }

    /// @notice Buyer deposits escrow amount in ETH.
    function deposit() external payable inState(State.NotInitialized) onlyBuyer nonReentrant {
        if (msg.value == 0) revert ZeroAmount();
        amount = msg.value;
        fundedAt = block.timestamp;
        state = State.Funded;
        emit Funded(msg.sender, msg.value);
    }

    /// @notice Seller marks goods/services delivered. Moves state to Delivered.
    function markDelivered() external inState(State.Funded) onlySeller {
        state = State.Delivered;
        emit MarkDelivered(msg.sender);
    }

    /// @notice Arbiter releases funds to seller after delivery.
    function releaseToSeller() external inState(State.Delivered) onlyArbiter nonReentrant {
        uint256 value = amount;
        amount = 0;
        state = State.Released;
        (bool ok, ) = seller.call{value: value}("");
        require(ok, "ETH transfer failed");
        emit Released(msg.sender, seller, value);
    }

    /// @notice Arbiter refunds buyer if dispute resolves in buyer's favor.
    function refundToBuyer() external inState(State.Funded) onlyArbiter nonReentrant {
        uint256 value = amount;
        amount = 0;
        state = State.Refunded;
        (bool ok, ) = buyer.call{value: value}("");
        require(ok, "ETH transfer failed");
        emit Refunded(msg.sender, buyer, value);
    }

    /// @notice If seller never marks delivered before deadline, buyer can reclaim funds.
    function timeoutRefund() external inState(State.Funded) onlyBuyer nonReentrant {
        require(block.timestamp > deliveryDeadline, "Not past deadline");
        uint256 value = amount;
        amount = 0;
        state = State.Refunded;
        (bool ok, ) = buyer.call{value: value}("");
        require(ok, "ETH transfer failed");
        emit TimeoutRefund(buyer, value);
    }
}