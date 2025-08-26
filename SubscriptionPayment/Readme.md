Overview

Pull-model subscription manager for ERC20 tokens.

Merchants create plans and pull payments for subscribers after they approve the token allowance.

Features

Multiple plans with arbitrary ERC20 token, price and period.

Merchant or owner can collect payments.

Batch collection for merchant to process subscribers in slices.

Per-subscriber subscription record with lastPaid tracking.

Key functions

createPlan(token, price, period, merchant) — owner creates a plan.

subscribe(planId) — user subscribes (no token transfer at subscribe time).

unsubscribe(planId) — user unsubscribes.

collect(planId, user) — merchant pulls owed payments; user must have approved tokens.

collectBatch(planId, start, end) — batch collection.

periodsDue(planId, user) — view how many billing periods are owed.

Security & UX notes

Collector must be the plan merchant or contract owner.

Subscriber must approve the contract for the amount required before collect.

Batch collection can fail if a subscriber lacks allowance or funds; front-end should validate allowance and balance before attempting collect.

For automation, use an off-chain scheduler (cron, Chainlink Keepers) to call collectBatch.

Consider adding slashing or grace periods in production if you want to avoid immediate cancellations on missed payment.

Deployment

Deploy with OpenZeppelin contracts installed (@openzeppelin/contracts).

Provide a front-end that asks subscribers to approve a generous allowance (or exactly required per period).

For local testing use Hardhat and a simple ERC20 test token.