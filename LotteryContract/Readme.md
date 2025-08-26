
* Overview

  * Lottery using commit‑reveal to reduce manipulation.
* Flow

  * Commit phase → players submit hash with ticket price.
  * Reveal phase → players reveal secret.
  * Finish → contract selects winner from revealed players and pays the pot.
* Key Functions

  * `commit(commitHash)`
  * `startReveal()`
  * `reveal(secret)`
  * `finish()`
* Notes

  * Use off‑chain helper to compute `commitHash = keccak256(secret, player)`.
  * For mainnet, consider Chainlink VRF for stronger randomness.
