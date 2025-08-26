#![cfg_attr(not(feature = "std"), no_std)]

use ink::prelude::{string::String, vec::Vec};
use ink::storage::Mapping;

#[ink::contract]
pub mod cloud_pointer {
    use super::*;

    #[derive(scale::Encode, scale::Decode, Clone, Debug, PartialEq, Eq)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo))]
    pub struct FileRecord {
        cid: String,
        metadata: String,
        publisher: AccountId,
        timestamp: u64,
        active: bool,
    }

    #[ink(storage)]
    pub struct CloudPointer {
        files: Vec<FileRecord>,
        files_by_publisher: Mapping<AccountId, Vec<u128>>,
        owner: AccountId,
        registry_fee: Balance,
    }

    #[ink(event)]
    pub struct FileAdded {
        #[ink(topic)]
        id: u128,
        #[ink(topic)]
        publisher: AccountId,
        cid: String,
    }

    #[ink(event)]
    pub struct FileUpdated {
        #[ink(topic)]
        id: u128,
        metadata: String,
    }

    impl CloudPointer {
        #[ink(constructor)]
        pub fn new(registry_fee: Balance) -> Self {
            Self {
                files: Vec::new(),
                files_by_publisher: Mapping::default(),
                owner: Self::env().caller(),
                registry_fee,
            }
        }

        #[ink(message, payable)]
        pub fn add_file(&mut self, cid: String, metadata: String) -> u128 {
            let paid = Self::env().transferred_value();
            assert!(paid >= self.registry_fee, "Insufficient fee");
            let publisher = Self::env().caller();
            let id = self.files.len() as u128;
            let rec = FileRecord {
                cid: cid.clone(),
                metadata: metadata.clone(),
                publisher,
                timestamp: Self::env().block_timestamp(),
                active: true,
            };
            self.files.push(rec);
            // index by publisher
            let mut list = self.files_by_publisher.get(publisher).unwrap_or_default();
            list.push(id);
            self.files_by_publisher.insert(publisher, &list);
            Self::env().emit_event(FileAdded { id, publisher, cid });
            id
        }

        #[ink(message)]
        pub fn update_file(&mut self, id: u128, new_metadata: String) {
            assert!((id as usize) < self.files.len(), "Bad id");
            let caller = Self::env().caller();
            let rec = self.files.get_mut(id as usize).unwrap();
            assert!(rec.publisher == caller || caller == self.owner, "Not authorized");
            rec.metadata = new_metadata.clone();
            Self::env().emit_event(FileUpdated { id, metadata: new_metadata });
        }

        #[ink(message)]
        pub fn deactivate_file(&mut self, id: u128) {
            assert!((id as usize) < self.files.len(), "Bad id");
            let caller = Self::env().caller();
            let rec = self.files.get_mut(id as usize).unwrap();
            assert!(rec.publisher == caller || caller == self.owner, "Not authorized");
            rec.active = false;
        }

        #[ink(message)]
        pub fn get_file(&self, id: u128) -> Option<FileRecord> {
            if (id as usize) >= self.files.len() { return None; }
            Some(self.files.get(id as usize).cloned().unwrap())
        }

        #[ink(message)]
        pub fn get_files_by_publisher(&self, publisher: AccountId) -> Vec<u128> {
            self.files_by_publisher.get(publisher).unwrap_or_default()
        }

        #[ink(message)]
        pub fn set_registry_fee(&mut self, fee: Balance) {
            assert_eq!(Self::env().caller(), self.owner, "Only owner");
            self.registry_fee = fee;
        }

        #[ink(message)]
        pub fn withdraw(&mut self, to: AccountId, amount: Balance) {
            assert_eq!(Self::env().caller(), self.owner, "Only owner");
            assert!(Self::env().balance() >= amount, "Insufficient balance");
            Self::env().transfer(to, amount).expect("Transfer failed");
        }

        #[ink(message)]
        pub fn files_count(&self) -> u128 {
            self.files.len() as u128
        }
    }
}
