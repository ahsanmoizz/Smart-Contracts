
* Overview

  * Single‑deal ETH escrow with buyer, seller, and arbiter.
  * Supports deadlines, refunds, and release on delivery confirmation.
* Features

  * Time‑boxed delivery with buyer timeout refund.
  * Arbiter‑mediated release/refund.
  * Reentrancy protections.
* Key Functions

  * `init(buyer, seller, arbiter, deadline)`
  * `deposit()`
  * `markDelivered()`
  * `releaseToSeller()` / `refundToBuyer()`
  * `timeoutRefund()`
* Setup

  * Requires OpenZeppelin `Ownable` and `ReentrancyGuard`.
* Security Notes

  * ETH only. If using ERC20, add SafeERC20.
  * Consider factories for multi‑deal deployments.
