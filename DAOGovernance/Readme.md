
* Overview

  * Token‑weighted governance with proposal creation, voting, and execution through a timelock/executor address.
* Features

  * Proposal creation gated by token balance threshold.
  * Voting period and quorum checks.
  * Simple execution model forwarding ABI‑encoded calls to a timelock/executor.
* Security Notes

  * For production, use a proper timelock contract (e.g., OpenZeppelin TimelockController).
  * Consider snapshot tokens (ERC20Snapshot) to avoid vote manipulation during voting period.

