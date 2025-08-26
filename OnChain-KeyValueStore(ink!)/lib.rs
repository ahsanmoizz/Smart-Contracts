#![cfg_attr(not(feature = "std"), no_std)]

use ink::prelude::{string::String, vec::Vec};
use ink::storage::Mapping;

#[ink::contract]
pub mod key_value {
    use super::*;

    #[ink(storage)]
    pub struct KeyValue {
        store: Mapping<String, String>,
        writers: Mapping<AccountId, bool>,
        owner: AccountId,
        paused: bool,
    }

    #[ink(event)]
    pub struct Set {
        #[ink(topic)]
        key: String,
        value: String,
        #[ink(topic)]
        writer: AccountId,
    }

    #[ink(event)]
    pub struct Deleted {
        #[ink(topic)]
        key: String,
        #[ink(topic)]
        writer: AccountId,
    }

    #[ink(event)]
    pub struct WriterToggled {
        #[ink(topic)]
        account: AccountId,
        allowed: bool,
    }

    impl KeyValue {
        #[ink(constructor)]
        pub fn new() -> Self {
            let caller = Self::env().caller();
            Self {
                store: Mapping::default(),
                writers: Mapping::default(),
                owner: caller,
                paused: false,
            }
        }

        /// Toggle writer permission (owner only)
        #[ink(message)]
        pub fn toggle_writer(&mut self, account: AccountId, allowed: bool) {
            self.ensure_owner();
            self.writers.insert(account, &allowed);
            Self::env().emit_event(WriterToggled { account, allowed });
        }

        /// Set a key => value (writer or owner)
        #[ink(message)]
        pub fn set(&mut self, key: String, value: String) {
            self.ensure_not_paused();
            let caller = Self::env().caller();
            let is_writer = self.writers.get(caller).unwrap_or(false);
            assert!(is_writer || caller == self.owner, "Not allowed to write");
            self.store.insert(key.clone(), &value);
            Self::env().emit_event(Set { key, value, writer: caller });
        }

        /// Batch set multiple keys (writer or owner)
        #[ink(message)]
        pub fn batch_set(&mut self, keys: Vec<String>, values: Vec<String>) {
            self.ensure_not_paused();
            assert!(keys.len() == values.len(), "Length mismatch");
            let caller = Self::env().caller();
            let is_writer = self.writers.get(caller).unwrap_or(false);
            assert!(is_writer || caller == self.owner, "Not allowed to write");
            for i in 0..keys.len() {
                let k = keys.get(i).cloned().unwrap();
                let v = values.get(i).cloned().unwrap();
                self.store.insert(k.clone(), &v);
                Self::env().emit_event(Set { key: k, value: v, writer: caller });
            }
        }

        /// Get value by key (public)
        #[ink(message)]
        pub fn get(&self, key: String) -> Option<String> {
            self.store.get(key)
        }

        /// Remove a key (writer or owner)
        #[ink(message)]
        pub fn remove(&mut self, key: String) {
            self.ensure_not_paused();
            let caller = Self::env().caller();
            let is_writer = self.writers.get(caller).unwrap_or(false);
            assert!(is_writer || caller == self.owner, "Not allowed to remove");
            self.store.remove(key.clone());
            Self::env().emit_event(Deleted { key, writer: caller });
        }

        /// Pause writes (owner)
        #[ink(message)]
        pub fn pause(&mut self) {
            self.ensure_owner();
            self.paused = true;
        }

        /// Unpause writes (owner)
        #[ink(message)]
        pub fn unpause(&mut self) {
            self.ensure_owner();
            self.paused = false;
        }

        /// Helpers
        fn ensure_owner(&self) {
            assert_eq!(Self::env().caller(), self.owner, "Only owner");
        }
        fn ensure_not_paused(&self) {
            assert!(!self.paused, "Paused");
        }
    }
}
