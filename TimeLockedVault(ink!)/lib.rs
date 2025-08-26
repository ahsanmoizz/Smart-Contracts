#![cfg_attr(not(feature = "std"), no_std)]

use ink::prelude::vec::Vec;
use ink::storage::Mapping;

#[ink::contract]
pub mod vesting {
    use super::*;

    #[derive(scale::Encode, scale::Decode, Clone, Debug, PartialEq, Eq)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo))]
    pub struct Grant {
        beneficiary: AccountId,
        total: Balance,
        start: u64,
        cliff: u64,
        duration: u64,
        claimed: Balance,
        revocable: bool,
        revoked: bool,
    }

    #[ink(storage)]
    pub struct Vesting {
        grants: Mapping<AccountId, Grant>,
        owner: AccountId,
    }

    #[ink(event)]
    pub struct Granted {
        #[ink(topic)]
        beneficiary: AccountId,
        total: Balance,
    }

    #[ink(event)]
    pub struct Claimed {
        #[ink(topic)]
        beneficiary: AccountId,
        amount: Balance,
    }

    impl Vesting {
        #[ink(constructor)]
        pub fn new() -> Self {
            Self {
                grants: Mapping::default(),
                owner: Self::env().caller(),
            }
        }

        #[ink(message)]
        pub fn grant(
            &mut self,
            beneficiary: AccountId,
            total: Balance,
            start: u64,
            cliff_duration: u64,
            duration: u64,
            revocable: bool,
        ) {
            assert_eq!(Self::env().caller(), self.owner, "Only owner");
            assert!(duration > 0, "Zero duration");
            let g = Grant {
                beneficiary,
                total,
                start,
                cliff: start + cliff_duration,
                duration,
                claimed: 0,
                revocable,
                revoked: false,
            };
            self.grants.insert(beneficiary, &g);
            Self::env().emit_event(Granted { beneficiary, total });
        }

        #[ink(message)]
        pub fn claim(&mut self) {
            let caller = Self::env().caller();
            let mut g = self.grants.get(caller).expect("No grant");
            assert!(!g.revoked, "Revoked");
            let vested = Self::env().block_timestamp();
            let vested_amount = if vested < g.cliff {
                0
            } else if vested >= g.start + g.duration {
                g.total
            } else {
                let elapsed = vested - g.start;
                (g.total as u128 * (elapsed as u128) / (g.duration as u128)) as Balance
            };
            let claimable = vested_amount.saturating_sub(g.claimed);
            assert!(claimable > 0, "Nothing to claim");
            g.claimed += claimable;
            self.grants.insert(caller, &g);
            // Transfer tokens to caller (PSP22 transfer) — implement in production
            Self::env().emit_event(Claimed { beneficiary: caller, amount: claimable });
        }

        #[ink(message)]
        pub fn revoke(&mut self, beneficiary: AccountId) {
            assert_eq!(Self::env().caller(), self.owner, "Only owner");
            let mut g = self.grants.get(beneficiary).expect("No grant");
            assert!(g.revocable && !g.revoked, "Not revocable");
            g.revoked = true;
            self.grants.insert(beneficiary, &g);
            // Optionally transfer refund portion to owner
        }

        #[ink(message)]
        pub fn get_grant(&self, beneficiary: AccountId) -> Option<Grant> {
            self.grants.get(beneficiary)
        }
    }
}
