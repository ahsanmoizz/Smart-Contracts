#![cfg_attr(not(feature = "std"), no_std)]

use ink::prelude::{string::String, vec::Vec};
use ink::storage::Mapping;

#[ink::contract]
pub mod identity_reputation {
    use super::*;

    #[derive(scale::Encode, scale::Decode, Clone, Debug, PartialEq, Eq)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo))]
    pub struct Profile {
        id: u128,
        handle: String,
        metadata: String,
        created_at: u64,
        reputation: u128,
        exists: bool,
    }

    #[ink(storage)]
    pub struct IdentityReputation {
        profiles: Mapping<AccountId, Profile>,
        id_counter: u128,
        endorsements: Mapping<(u128, AccountId), u128>, // (profile_id, endorser) -> score
        owner: AccountId,
        badge_threshold: u128,
    }

    #[ink(event)]
    pub struct ProfileCreated {
        #[ink(topic)]
        id: u128,
        #[ink(topic)]
        account: AccountId,
        handle: String,
    }

    #[ink(event)]
    pub struct Endorsed {
        #[ink(topic)]
        profile_id: u128,
        #[ink(topic)]
        endorser: AccountId,
        score: u128,
    }

    #[ink(event)]
    pub struct BadgeIssued {
        #[ink(topic)]
        profile_id: u128,
        badge: String,
    }

    impl IdentityReputation {
        #[ink(constructor)]
        pub fn new(badge_threshold: u128) -> Self {
            Self {
                profiles: Mapping::default(),
                id_counter: 0,
                endorsements: Mapping::default(),
                owner: Self::env().caller(),
                badge_threshold,
            }
        }

        #[ink(message)]
        pub fn create_or_update_profile(&mut self, handle: String, metadata: String) {
            let caller = Self::env().caller();
            let mut p = self.profiles.get(caller).unwrap_or(Profile {
                id: 0,
                handle: String::new(),
                metadata: String::new(),
                created_at: 0,
                reputation: 0,
                exists: false,
            });

            if !p.exists {
                self.id_counter += 1;
                p.id = self.id_counter;
                p.created_at = Self::env().block_timestamp();
                p.exists = true;
            }

            p.handle = handle.clone();
            p.metadata = metadata.clone();
            self.profiles.insert(caller, &p);

            if p.id == self.id_counter {
                Self::env().emit_event(ProfileCreated { id: p.id, account: caller, handle });
            }
        }

        #[ink(message)]
        pub fn endorse(&mut self, account: AccountId, score: u128) {
            assert!(score > 0, "Zero score");
            let caller = Self::env().caller();
            assert!(caller != account, "Cannot self-endorse");
            let mut p = self.profiles.get(account).expect("Profile not found");
            let key = (p.id, caller);
            let prev = self.endorsements.get(&key).unwrap_or(0);
            let new_score = prev + score;
            self.endorsements.insert(&key, &new_score);
            p.reputation += score;
            self.profiles.insert(account, &p);
            Self::env().emit_event(Endorsed { profile_id: p.id, endorser: caller, score });
            if p.reputation >= self.badge_threshold {
                Self::env().emit_event(BadgeIssued { profile_id: p.id, badge: String::from("TrustedContributor") });
            }
        }

        #[ink(message)]
        pub fn get_profile(&self, account: AccountId) -> Option<Profile> {
            self.profiles.get(account)
        }

        #[ink(message)]
        pub fn set_badge_threshold(&mut self, t: u128) {
            assert_eq!(Self::env().caller(), self.owner, "Only owner");
            self.badge_threshold = t;
        }

        #[ink(message)]
        pub fn profile_count(&self) -> u128 {
            self.id_counter
        }
    }
}
