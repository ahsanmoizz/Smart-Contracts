# Identity & Reputation Contract

## Overview
A lightweight self-sovereign identity system where users create on-chain profiles and peers endorse them to build reputation. Reputation is a simple numeric sum of endorsements; when a profile crosses a configurable threshold, a badge event is emitted (can be extended to mint NFTs).

## Features
- Create or update a profile with a handle and metadata pointer (IPFS/Arweave/HTTP).
- Peer endorsements with positive integer scores.
- Reputation aggregated per profile and accessible on-chain.
- Badge issuance via events when thresholds are reached.
- Simple, gas-efficient data structures; easy to extend (NFT badges, signed attestations, staking for endorsements).

## Key functions
- `createOrUpdateProfile(handle, metadataURI)` — create or update caller's profile.
- `endorse(user, score)` — endorse another profile with a positive integer score.
- `getProfile(user)` — read profile fields and reputation.
- `setBadgeThreshold(t)` — owner-only; adjust threshold for badge emission.

## Security & design notes
- No anti-sybil protections included. In production, consider:
  - Requiring endorsers to stake tokens which can be slashed for spam/abuse.
  - Using off-chain identity verification for initial trusted endorsers.
  - Rate limits or cooldowns per endorser.
- Badge issuance currently emits an event. For on-chain proof, integrate an ERC-721 minter.
- Metadata is stored off-chain; contract only stores the pointer to keep gas costs reasonable.
- Add monitoring for reputation spikes and unusual activity.

## Testing & tooling
- Use Hardhat or Foundry for unit tests:
  - profile creation/update
  - endorse flow and reputation changes
  - badge threshold behavior
  - negative tests (self-endorse, non-existing profiles)
- Provide a minimal frontend to:
  - register profile (IPFS metadata upload)
  - view profile + endorsements
  - endorse other users
