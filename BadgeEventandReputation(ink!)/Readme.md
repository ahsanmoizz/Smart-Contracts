# Identity & Reputation (ink!)

## Overview
On-chain profile registry with peer endorsements. Profiles accumulate numeric reputation; when threshold is met, a badge event is emitted. Good base for reputation systems in DAOs, marketplaces, hiring platforms.

## Features
- `create_or_update_profile(handle, metadata)` — register or edit profile
- `endorse(account, score)` — peer endorses with positive integer score
- `get_profile(account)` — fetch profile struct
- `set_badge_threshold(t)` — owner updates badge threshold
- Badge issuance via events; easy to hook to an off-chain indexer to mint NFTs

## Notes
- No sybil protection built-in. Consider staking, attestation or KYC for production.
- Off-chain indexer can mint NFT badges when BadgeIssued event occurs.
- Use metadata pointers (IPFS) to store resumes, portfolio links, or DID docs.
