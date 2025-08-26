> Smart Contracts Collection

Welcome to my Smart Contracts Collection.
This repo is a mix of Solidity (Ethereum) and Rust (Substrate/CosmWasm) contracts that explore different concepts in blockchain development.

The goal is to build a cross-chain identity, finance, and utility toolkit, while also showcasing my skills in both ecosystems.

> Contracts Overview
🔹 Solidity Contracts

ERC20 Token

A standard fungible token implementation.

Includes minting, burning, and ownership logic.

Staking & Rewards

Users can stake tokens to earn rewards.

Flexible and locked staking models supported.

Escrow Contract

Ensures safe transactions between buyer and seller.

Funds are released only when conditions are met.

Referral Contract

Tracks referrals and distributes bonuses.

Useful for community-driven dApps.

🔹 Rust Contracts

Voting DAO (CosmWasm)

A governance system where users can create proposals and vote.

Weighted voting based on staked tokens.

Cross-Chain Identity (Substrate)

A decentralized identity contract.

Allows reputation and identity management across chains.

NFT Marketplace

Buy, sell, and auction NFTs.

Written in Rust for chain efficiency.

Lending & Borrowing

Peer-to-peer lending system.

Secured with collateral and interest logic.

 > Why This Matters ?

Solidity covers the most widely used ecosystem (Ethereum, EVM chains).

Rust covers newer, high-performance blockchains (Polkadot, Cosmos, NEAR).

Together, they demonstrate multi-chain development expertise.

> How to Use ?

Clone the repo:

git clone https://github.com/your-username/Smart-Contracts.git


For Solidity (EVM):

cd solidity-contracts
truffle migrate --network development


For Rust (CosmWasm):

cd rust-contracts
cargo wasm
cargo test

📜 License

MIT License – Free to use, modify, and share.
