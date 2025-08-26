// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title InsurancePool (parametric insurance prototype)
/// @notice Simple pool where users buy policies and owner/oracle triggers payouts.
contract InsurancePool is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable stable;      // stable token for premiums and payouts
    // premiumRate is scaled by 1e18. premium = coverage * premiumRate * duration / 1e18
    // duration is in seconds.
    uint256 public premiumRate;

    struct Policy {
        address holder;
        uint256 coverage;   // requested coverage amount (token units)
        uint256 premium;    // premium paid
        uint256 start;
        uint256 duration;   // seconds
        bool active;
        bool paidOut;
    }

    Policy[] public policies;
    uint256 public totalCoveredActive;   // sum of coverage for active, unpaid policies
    uint256 public totalPremiumsCollected;

    event PremiumRateSet(uint256 rate);
    event Funded(address indexed from, uint256 amount);
    event PolicyBought(uint256 indexed id, address indexed holder, uint256 coverage, uint256 premium, uint256 duration);
    event EventTriggered(uint256 indexed id, address indexed triggeredBy);
    event Payout(uint256 indexed id, address indexed holder, uint256 amount);
    event SurplusWithdrawn(address indexed owner, uint256 amount);

    error BadParams();
    error InsufficientFunds();
    error InvalidPolicy();
    error NotOwnerOrOracle();

    constructor(IERC20 _stable, uint256 _initialPremiumRate) {
        require(address(_stable) != address(0), "Zero token");
        stable = _stable;
        premiumRate = _initialPremiumRate;
    }

    /// @notice Owner sets premium rate. Rate scaled by 1e18.
    function setPremiumRate(uint256 rate) external onlyOwner {
        premiumRate = rate;
        emit PremiumRateSet(rate);
    }

    /// @notice Owner or allocator can fund the pool with stable tokens.
    function fund(uint256 amount) external {
        require(amount > 0, "Zero");
        stable.safeTransferFrom(msg.sender, address(this), amount);
        emit Funded(msg.sender, amount);
    }

    /// @notice Buy a policy. Premium is computed by formula and pulled from buyer.
    /// coverage: desired payout amount; duration: seconds the policy is active.
    function buyPolicy(uint256 coverage, uint256 duration) external returns (uint256) {
        if (coverage == 0 || duration == 0) revert BadParams();
        // precise premium calculation: premium = coverage * premiumRate * duration / 1e18
        uint256 premium = (coverage * premiumRate * duration) / 1e18;
        require(premium > 0, "Zero premium");

        // collect premium from buyer
        stable.safeTransferFrom(msg.sender, address(this), premium);

        Policy memory p = Policy({
            holder: msg.sender,
            coverage: coverage,
            premium: premium,
            start: block.timestamp,
            duration: duration,
            active: true,
            paidOut: false
        });

        policies.push(p);
        uint256 id = policies.length - 1;

        totalCoveredActive += coverage;
        totalPremiumsCollected += premium;

        emit PolicyBought(id, msg.sender, coverage, premium, duration);
        return id;
    }

    /// @notice Owner (oracle) triggers payout for a specific policy id.
    /// In a real system an oracle would authorize this action.
    function triggerPayout(uint256 id) external onlyOwner {
        if (id >= policies.length) revert InvalidPolicy();
        Policy storage p = policies[id];
        require(p.active && !p.paidOut, "Not eligible");

        uint256 available = stable.balanceOf(address(this));
        uint256 payout = p.coverage;
        if (payout > available) payout = available; // pay what we have

        // bookkeeping
        p.paidOut = true;
        p.active = false;
        totalCoveredActive -= p.coverage;

        if (payout > 0) {
            stable.safeTransfer(p.holder, payout);
        }

        emit EventTriggered(id, msg.sender);
        emit Payout(id, p.holder, payout);
    }

    /// @notice Batch trigger for multiple policy ids (useful for oracle batches).
    function triggerBatch(uint256[] calldata ids) external onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            if (id >= policies.length) continue;
            Policy storage p = policies[id];
            if (!p.active || p.paidOut) continue;

            uint256 available = stable.balanceOf(address(this));
            uint256 payout = p.coverage > available ? available : p.coverage;

            p.paidOut = true;
            p.active = false;
            totalCoveredActive -= p.coverage;

            if (payout > 0) stable.safeTransfer(p.holder, payout);
            emit EventTriggered(id, msg.sender);
            emit Payout(id, p.holder, payout);
        }
    }

    /// @notice Owner withdraws surplus funds that are not reserved to cover active policies.
    function withdrawSurplus(uint256 amount) external onlyOwner {
        uint256 balance = stable.balanceOf(address(this));
        uint256 reserved = totalCoveredActive;
        if (balance <= reserved) revert InsufficientFunds();
        uint256 withdrawable = balance - reserved;
        require(amount <= withdrawable, "Amount > withdrawable");
        stable.safeTransfer(msg.sender, amount);
        emit SurplusWithdrawn(msg.sender, amount);
    }

    /// @notice View helpers
    function policiesCount() external view returns (uint256) {
        return policies.length;
    }

    function getPolicy(uint256 id) external view returns (
        address holder,
        uint256 coverage,
        uint256 premium,
        uint256 start,
        uint256 duration,
        bool active,
        bool paidOut
    ) {
        Policy storage p = policies[id];
        return (p.holder, p.coverage, p.premium, p.start, p.duration, p.active, p.paidOut);
    }
}
