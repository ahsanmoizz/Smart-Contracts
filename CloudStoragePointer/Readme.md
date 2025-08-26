
## Overview
Registry for off-chain content pointers (IPFS/Arweave/Filecoin CIDs). Publishers pay a small fee to add content, which prevents spam. The contract stores immutable CIDs and lightweight metadata and provides discovery by publisher.

## Features
- Add IPFS/Arweave CIDs with short metadata.
- Update metadata or deactivate by publisher (or admin).
- Registry fee to curb spam; owner withdraws fees.
- Indexed retrieval of records by publisher.

## Key functions
- `setRegistryFee(fee)` — owner sets registration fee.
- `addFile(cid, metadata)` — pay fee and register content.
- `updateFile(id, newMetadata)` — publisher updates meta.
- `deactivateFile(id)` — publisher or owner deactivates.
- `getFile(id)` — view file record.
- `getFilesByPublisher(address)` — list of file ids.

## Security & UX notes
- Keep metadata short; store large JSON off-chain (IPFS) and reference the CID here.
- Consider using ERC20 token fees if required (change payable => token transfer).
- Front-end should validate CID formats and gas estimates before sending txs.
