# Token Vesting Contract

## Overview
This contract releases ERC20 tokens to beneficiaries over a vesting period. Team or investors receive tokens gradually instead of all at once.

## Features
- Owner sets token allocations.
- Linear vesting over a duration.
- Users can claim vested tokens anytime after the start.

## Usage
1. Deploy with token address and vesting duration.
2. Owner sets allocations for each address.
3. Users call `claim()` to receive vested tokens.
