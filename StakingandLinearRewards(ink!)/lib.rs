#![cfg_attr(not(feature = "std"), no_std)]

use ink::prelude::vec::Vec;
use ink::storage::Mapping;

#[ink::contract]
pub mod staking {
    use super::*;
    use ink::env::CallFlags;
    use ink::prelude::string::String;

    #[ink(storage)]
    pub struct Staking {
        stake_token: AccountId,
        reward_token: AccountId,
        total_staked: Balance,
        balances: Mapping<AccountId, Balance>,
        rewards: Mapping<AccountId, Balance>,
        reward_rate: u128, // rewards per second scaled by 1e18-like unit
        last_update: u64,
        owner: AccountId,
    }

    #[ink(event)]
    pub struct Staked {
        #[ink(topic)]
        user: AccountId,
        amount: Balance,
    }

    #[ink(event)]
    pub struct RewardPaid {
        #[ink(topic)]
        user: AccountId,
        amount: Balance,
    }

    impl Staking {
        #[ink(constructor)]
        pub fn new(stake_token: AccountId, reward_token: AccountId, reward_rate: u128) -> Self {
            Self {
                stake_token,
                reward_token,
                total_staked: 0,
                balances: Mapping::default(),
                rewards: Mapping::default(),
                reward_rate,
                last_update: Self::env().block_timestamp(),
                owner: Self::env().caller(),
            }
        }

        #[ink(message)]
        pub fn set_reward_rate(&mut self, rate: u128) {
            self.ensure_owner();
            self.reward_rate = rate;
        }

        #[ink(message)]
        pub fn stake(&mut self, amount: Balance) {
            assert!(amount > 0, "Zero stake");
            let caller = Self::env().caller();
            // Transfer stake tokens from user to contract (PSP22 transfer_from)
            let res = build_call::<<Self as ::ink::env::ContractEnv>::Env>()
                .call(self.stake_token)
                .exec_input(
                    ink::env::call::ExecutionInput::new(ink::env::call::Selector::new([0x0f,0x12,0x0a,0x0b])) // not portable; prefer trait bindings in real projects
                )
                .returns::<()>()
                .fire();
            // For demo: assume token transfer succeeded (use PSP22 trait in real implementation)
            let prev = self.balances.get(caller).unwrap_or(0);
            self.balances.insert(caller, &(prev + amount));
            self.total_staked += amount;
            self.last_update = Self::env().block_timestamp();
            Self::env().emit_event(Staked { user: caller, amount });
        }

        #[ink(message)]
        pub fn withdraw(&mut self, amount: Balance) {
            let caller = Self::env().caller();
            let bal = self.balances.get(caller).unwrap_or(0);
            assert!(amount <= bal, "Insufficient");
            self.balances.insert(caller, &(bal - amount));
            self.total_staked -= amount;
            // Transfer stake tokens back to caller (PSP22 transfer)
            // omitted here for compactness
        }

        #[ink(message)]
        pub fn claim_reward(&mut self) {
            let caller = Self::env().caller();
            let reward = self.rewards.get(caller).unwrap_or(0);
            assert!(reward > 0, "No reward");
            self.rewards.insert(caller, &0);
            // Transfer reward_token to caller (PSP22 transfer)
            self.last_update = Self::env().block_timestamp();
            Self::env().emit_event(RewardPaid { user: caller, amount: reward });
        }

        fn ensure_owner(&self) {
            assert_eq!(Self::env().caller(), self.owner, "Only owner");
        }
    }
}
