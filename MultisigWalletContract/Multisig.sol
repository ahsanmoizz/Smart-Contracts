
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Gas‑efficient Multi‑Sig Wallet
contract MultiSigWallet is ReentrancyGuard {
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public required;

    struct Tx { address to; uint256 value; bytes data; bool executed; uint256 confirmations; }
    Tx[] public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmed;

    event Deposit(address indexed sender, uint256 amount);
    event SubmitTransaction(uint256 indexed txId, address indexed to, uint256 value, bytes data);
    event Confirm(address indexed owner, uint256 indexed txId);
    event Execute(uint256 indexed txId);

    modifier onlyOwner() { require(isOwner[msg.sender], "Not owner"); _; }

    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, "No owners");
        require(_required > 0 && _required <= _owners.length, "Bad required");
        for (uint i = 0; i < _owners.length; i++) {
            address o = _owners[i];
            require(o != address(0), "Zero");
            require(!isOwner[o], "Duplicate");
            isOwner[o] = true;
            owners.push(o);
        }
        required = _required;
    }

    receive() external payable { emit Deposit(msg.sender, msg.value); }

    function submitTransaction(address to, uint256 value, bytes calldata data) external onlyOwner returns (uint256) {
        transactions.push(Tx({to: to, value: value, data: data, executed: false, confirmations: 0}));
        uint256 txId = transactions.length - 1;
        emit SubmitTransaction(txId, to, value, data);
        return txId;
    }

    function confirmTransaction(uint256 txId) external onlyOwner {
        require(txId < transactions.length, "Tx nonexistent");
        require(!confirmed[txId][msg.sender], "Already");
        confirmed[txId][msg.sender] = true;
        transactions[txId].confirmations++;
        emit Confirm(msg.sender, txId);
    }

    function executeTransaction(uint256 txId) external nonReentrant onlyOwner {
        Tx storage txi = transactions[txId];
        require(!txi.executed, "Already");
        require(txi.confirmations >= required, "Not enough confirmations");
        txi.executed = true;
        (bool ok, ) = txi.to.call{value: txi.value}(txi.data);
        require(ok, "Execution failed");
        emit Execute(txId);
    }
}