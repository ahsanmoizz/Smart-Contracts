# Cloud Storage Pointer Registry (ink!)

## Overview
Register and discover off-chain content pointers (IPFS/Arweave/Filecoin). Publishers pay a small on-chain fee to register content, preventing spam. The contract saves CIDs and short metadata and allows publishers to update or deactivate their records.

## Features
- `add_file(cid, metadata)` payable — register pointer with fee
- `update_file(id, metadata)` — publisher or owner can update metadata
- `deactivate_file(id)` — publisher or owner can deactivate
- `get_file(id)` — retrieve file record
- `get_files_by_publisher(pub)` — list of file ids by publisher
- `withdraw(to, amount)` — owner withdraws collected fees

## Notes
- Keep `metadata` short (CID and small JSON). Use IPFS for large assets.
- You can switch to ERC20 fee collection by replacing payable logic with token transfers.
- Front-end should validate CID format and visualize IPFS content.
