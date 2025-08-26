Overview

Parametric insurance pool prototype. Users buy policies by paying an on-chain premium.

Owner (which represents a trusted oracle in this prototype) triggers payouts when off-chain conditions are met.

Premium model

Premium is calculated as premium = coverage * premiumRate * duration / 1e18.

premiumRate is set by the owner and is scaled by 1e18 for precision.

duration is in seconds.

Flow

Pool must be funded by actors (owner or others) to ensure liquidity.

User calls buyPolicy(coverage, duration); premium is transferred from user to contract.

Owner triggers a payout via triggerPayout(policyId) or triggerBatch(ids) after verifying an off-chain event.

Payout is the policy coverage amount, limited to available pool balance.

Key functions

setPremiumRate(rate) — set precision-scaled rate (owner).

fund(amount) — transfer stable tokens into pool.

buyPolicy(coverage, duration) — user buys a policy; returns policy id.

triggerPayout(id) / triggerBatch(ids) — owner triggers on-chain payout.

withdrawSurplus(amount) — owner can withdraw funds not reserved for active cover.

Security & production notes

In production, replace owner-triggered payouts with a decentralized oracle (Chainlink, custom multisig of oracles).

Premium pricing should be set by actuarial models off-chain. This contract uses a simple linear model for demo.

Avoid concentration risk: keep reserve ratios and capital adequacy checks on payouts.

Add event verification and replay protections if integrating multiple oracles.

Deployment

Deploy with a stablecoin address and initial premiumRate.

Use tests to simulate premium calculation and payout flows.

For front-end testing, use a local ERC20 test token and seed the pool using fund.