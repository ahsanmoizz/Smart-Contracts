
## Overview
A permissioned, lightweight on-chain key-value store designed for small configuration values, DNS-like resolution, and metadata references. Reads are public and free; writes are restricted to owner and whitelisted writer addresses to control gas costs and prevent spam.

## Features
- Permissioned writers to limit who can write values.
- Batch writes to save gas when updating multiple keys.
- Public read access via `get(key)`.
- Pausable write operations for emergency response.

## Key functions
- `toggleWriter(address, bool)` — owner toggles writer access.
- `set(key, value)` — write single key-value pair.
- `batchSet(keys, values)` — write multiple pairs in one tx.
- `get(key)` — read stored value.
- `remove(key)` — delete key.

## Security & gas considerations
- Storing large strings on-chain is expensive. Keep values small (CID, small JSON, config strings).
- Use off-chain compression or IPFS for big data; store pointers here.
- Carefully control writer list to avoid spam and unexpected gas costs.

## Deployment & Testing
- Requires OpenZeppelin contracts (`Ownable`, `Pausable`).
- Add unit tests for permissioning, batch writes, pause behavior, and gas profiling.
