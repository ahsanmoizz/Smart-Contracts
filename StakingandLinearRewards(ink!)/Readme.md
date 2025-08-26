# Staking & Linear Rewards (ink!)

## Overview
A staking contract blueprint to stake PSP22 tokens and receive linear rewards. This contract stores balances and rewards, and provides stake/withdraw/claim functions. For production, integrate PSP22 trait calls (OpenBrush or generated trait interfaces).

## Features
- `stake(amount)` — deposit stake tokens
- `withdraw(amount)` — withdraw staked tokens
- `claim_reward()` — claim accumulated rewards
- `set_reward_rate(rate)` — owner sets reward rate

## Notes
- Use OpenBrush PSP22 traits for safe token calls.
- Implement reward-per-token accounting for accurate distribution (example simplified here).
- Test staking/claiming under different time deltas and edge cases.
