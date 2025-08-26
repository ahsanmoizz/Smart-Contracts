# On-Chain Key-Value Store (ink!)

## Overview
A lightweight permissioned key-value database on chain. Useful for storing small configuration values, CIDs, or DNS-like mapping where tamper-resistance is required. Reads are public; writes are restricted to owner/whitelisted writers.

## Features
- `set(key, value)` — permissioned write
- `batch_set(keys, values)` — batch writes to save gas
- `get(key)` — public read
- `remove(key)` — delete entry
- `toggle_writer(account, allowed)` — owner toggles writer
- `pause()` / `unpause()` — owner emergency pause for writes

## Notes
- Keep stored values small (CIDs, short JSON). Storing large strings on chain is expensive.
- Use the contract as a pointer store (store IPFS CIDs) rather than raw large data.
- Test permissioning and pause behavior locally before mainnet deploy.
