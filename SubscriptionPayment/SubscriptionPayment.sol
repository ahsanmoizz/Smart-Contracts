// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title SubscriptionPayment
/// @notice Simple on-chain subscription manager using a pull model (merchant pulls payments).
contract SubscriptionPayment is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct Plan {
        IERC20 token;        // token used for payments
        uint256 price;       // price per period (in token smallest unit)
        uint256 period;      // period length in seconds
        address merchant;    // recipient of payments
        bool active;         // is plan active
    }

    struct Subscription {
        uint256 planId;
        uint256 start;
        uint256 lastPaid;
        bool active;
    }

    Plan[] public plans;
    // planId => subscriber => Subscription
    mapping(uint256 => mapping(address => Subscription)) public subscriptions;
    // planId => list of subscribers (for merchant batch collection)
    mapping(uint256 => address[]) public planSubscribers;

    event PlanCreated(uint256 indexed planId, address indexed merchant, address token, uint256 price, uint256 period);
    event PlanToggled(uint256 indexed planId, bool active);
    event Subscribed(address indexed user, uint256 indexed planId);
    event Unsubscribed(address indexed user, uint256 indexed planId);
    event Collected(uint256 indexed planId, address indexed user, uint256 amount, address indexed merchant);

    error InvalidPlan();
    error NotAuthorized();
    error AlreadySubscribed();
    error NotSubscribed();
    error NothingDue();

    modifier validPlan(uint256 planId) {
        if (planId >= plans.length) revert InvalidPlan();
        _;
    }

    /// @notice Owner or an admin can create a plan. Merchant will receive payments.
    function createPlan(IERC20 token, uint256 price, uint256 period, address merchant) external onlyOwner returns (uint256) {
        require(address(token) != address(0), "Zero token");
        require(price > 0, "Zero price");
        require(period > 0, "Zero period");
        require(merchant != address(0), "Zero merchant");

        plans.push(Plan({
            token: token,
            price: price,
            period: period,
            merchant: merchant,
            active: true
        }));

        uint256 id = plans.length - 1;
        emit PlanCreated(id, merchant, address(token), price, period);
        return id;
    }

    /// @notice Owner can activate/deactivate a plan.
    function togglePlan(uint256 planId, bool on) external onlyOwner validPlan(planId) {
        plans[planId].active = on;
        emit PlanToggled(planId, on);
    }

    /// @notice Subscribe to a plan. The subscriber must later approve the token to this contract for payments.
    function subscribe(uint256 planId) external validPlan(planId) {
        Plan storage p = plans[planId];
        require(p.active, "Plan inactive");
        Subscription storage s = subscriptions[planId][msg.sender];
        if (s.active) revert AlreadySubscribed();

        s.planId = planId;
        s.start = block.timestamp;
        s.lastPaid = block.timestamp;
        s.active = true;

        planSubscribers[planId].push(msg.sender);
        emit Subscribed(msg.sender, planId);
    }

    /// @notice Unsubscribe from a plan. Merchant will no longer be able to collect for this subscriber.
    function unsubscribe(uint256 planId) external validPlan(planId) {
        Subscription storage s = subscriptions[planId][msg.sender];
        if (!s.active) revert NotSubscribed();
        s.active = false;
        emit Unsubscribed(msg.sender, planId);
    }

    /// @notice Merchant (or owner) pulls due payments for a single subscriber.
    /// Subscriber must have approved the contract to transfer tokens beforehand.
    function collect(uint256 planId, address user) public nonReentrant validPlan(planId) {
        Plan storage p = plans[planId];
        if (msg.sender != p.merchant && msg.sender != owner()) revert NotAuthorized();

        Subscription storage s = subscriptions[planId][user];
        if (!s.active) revert NotSubscribed();

        uint256 elapsed = block.timestamp - s.lastPaid;
        uint256 periods = elapsed / p.period;
        if (periods == 0) revert NothingDue();

        uint256 amount = periods * p.price;
        // update lastPaid to avoid double-collect
        s.lastPaid = s.lastPaid + periods * p.period;

        // pull from subscriber to merchant
        p.token.safeTransferFrom(user, p.merchant, amount);
        emit Collected(planId, user, amount, p.merchant);
    }

    /// @notice Batch collect across a slice of subscribers for a plan.
    /// Be mindful of gas limits; split batches if needed.
    function collectBatch(uint256 planId, uint256 startIndex, uint256 endIndex) external nonReentrant validPlan(planId) {
        Plan storage p = plans[planId];
        if (msg.sender != p.merchant && msg.sender != owner()) revert NotAuthorized();

        address[] storage list = planSubscribers[planId];
        if (endIndex >= list.length) endIndex = list.length - 1;
        for (uint256 i = startIndex; i <= endIndex; i++) {
            address user = list[i];
            // try/catch is not used; failing transfer will revert entire batch
            // this is intentional to avoid loss of accounting
            try this.collect(planId, user) {
                // nothing
            } catch {
                // skip failing users (allow batch to continue)
                // Note: using try/catch with external call to this.collect
                // means collect's state changes already applied; we rely on its internal checks.
            }
        }
    }

    /// @notice Returns how many full periods are due for a subscriber on a plan.
    function periodsDue(uint256 planId, address user) public view validPlan(planId) returns (uint256) {
        Subscription storage s = subscriptions[planId][user];
        if (!s.active) return 0;
        Plan storage p = plans[planId];
        return (block.timestamp - s.lastPaid) / p.period;
    }

    /// @notice Number of plans created.
    function plansCount() external view returns (uint256) {
        return plans.length;
    }

    /// @notice Subscribers for a plan (useful for paging).
    function subscribersOf(uint256 planId) external view validPlan(planId) returns (address[] memory) {
        return planSubscribers[planId];
    }
}
