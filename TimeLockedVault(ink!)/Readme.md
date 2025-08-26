# Token Vesting / Time-Locked Vault (ink!)

## Overview
Linear token vesting with cliff and optional revocation. Beneficiaries can claim vested amounts after cliff and over duration. Stores grant metadata; integrates with PSP22 transfers for real token movement.

## Features
- `grant(beneficiary, total, start, cliff_duration, duration, revocable)` — owner sets grants
- `claim()` — beneficiary claims vested tokens
- `revoke(beneficiary)` — owner revokes revocable grants
- `get_grant(beneficiary)` — view grant details

## Notes
- This stores vesting schedules; you must transfer PSP22 tokens into a vault or integrate PSP22 `transfer` calls when claiming.
- Test edge cases: cliff, exact end, revocation mid-vesting.
- Add safety checks around total committed vs actual pool to avoid insolvency.
