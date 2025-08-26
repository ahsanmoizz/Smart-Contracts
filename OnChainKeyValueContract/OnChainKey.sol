
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

/// @title OnChainKeyValue - Permissioned key-value store
/// @notice Lightweight on-chain database for small config and metadata. Writes are permissioned; reads are public.
contract OnChainKeyValue is Ownable, Pausable {
    // Using string as key is permitted but remember it stores bytes on-chain.
    mapping(string => string) private store;
    mapping(address => bool) public writers;

    event Set(string indexed key, string value, address indexed writer);
    event Deleted(string indexed key, address indexed writer);
    event WriterToggled(address indexed account, bool allowed);

    error NotAllowed();

    modifier onlyWriter() {
        if (!writers[msg.sender] && msg.sender != owner()) revert NotAllowed();
        _;
    }

    constructor() {}

    /// @notice Toggle writer permission for an address.
    function toggleWriter(address account, bool allowed) external onlyOwner {
        writers[account] = allowed;
        emit WriterToggled(account, allowed);
    }

    /// @notice Set a single key -> value. Only writers or owner can call.
    function set(string calldata key, string calldata value) external whenNotPaused onlyWriter {
        store[key] = value;
        emit Set(key, value, msg.sender);
    }

    /// @notice Set multiple key/value pairs in one transaction.
    function batchSet(string[] calldata keys, string[] calldata values) external whenNotPaused onlyWriter {
        require(keys.length == values.length, "len mismatch");
        for (uint256 i = 0; i < keys.length; i++) {
            store[keys[i]] = values[i];
            emit Set(keys[i], values[i], msg.sender);
        }
    }

    /// @notice Fetch a stored value. Public and view-only.
    function get(string calldata key) external view returns (string memory) {
        return store[key];
    }

    /// @notice Delete a key. Only writers/owner can call.
    function remove(string calldata key) external whenNotPaused onlyWriter {
        delete store[key];
        emit Deleted(key, msg.sender);
    }

    /// @notice Pause writes in emergency.
    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }
}