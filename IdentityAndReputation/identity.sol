// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";

/// @title IdentityReputation - On-chain profiles and reputation with endorsements
/// @notice Lightweight self-sovereign identity with peer endorsements and simple badge issuance when thresholds met.
contract IdentityReputation is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _profileIds;

    struct Profile {
        uint256 id;
        address addr;
        string handle;
        string metadataURI; // IPFS/metadata pointer
        uint256 createdAt;
        uint256 reputation;
        bool exists;
    }

    // profile id => Profile
    mapping(uint256 => Profile) public profiles;
    // address => profile id
    mapping(address => uint256) public addressToProfileId;

    // endorsements[profileId][endorser] = score
    mapping(uint256 => mapping(address => uint256)) public endorsements;

    event ProfileCreated(uint256 indexed id, address indexed addr, string handle);
    event ProfileUpdated(uint256 indexed id, address indexed addr, string handle);
    event Endorsed(uint256 indexed profileId, address indexed endorser, uint256 score);
    event BadgeIssued(uint256 indexed profileId, string badge);

    uint256 public badgeThreshold = 100; // example threshold for badge

    error AlreadyExists();
    error NotFound();
    error SelfEndorse();
    error ZeroScore();

    /// @notice Create a new profile or update existing profile for msg.sender
    /// @param handle short handle (no uniqueness enforced here)
    /// @param metadataURI pointer to off-chain metadata (IPFS/Arweave CID or HTTPS)
    function createOrUpdateProfile(string calldata handle, string calldata metadataURI) external {
        uint256 pid = addressToProfileId[msg.sender];
        if (pid == 0) {
            // create new profile
            _profileIds.increment();
            uint256 newId = _profileIds.current();
            profiles[newId] = Profile({
                id: newId,
                addr: msg.sender,
                handle: handle,
                metadataURI: metadataURI,
                createdAt: block.timestamp,
                reputation: 0,
                exists: true
            });
            addressToProfileId[msg.sender] = newId;
            emit ProfileCreated(newId, msg.sender, handle);
        } else {
            // update existing
            Profile storage p = profiles[pid];
            p.handle = handle;
            p.metadataURI = metadataURI;
            emit ProfileUpdated(pid, msg.sender, handle);
        }
    }

    /// @notice Endorse a profile with a positive integer score. Endorsers cannot endorse themselves.
    /// Multiple endorsements from same endorser increase their recorded score (and overall reputation).
    /// @param user address of profile owner
    /// @param score positive integer endorsement value
    function endorse(address user, uint256 score) external {
        if (score == 0) revert ZeroScore();
        uint256 pid = addressToProfileId[user];
        if (pid == 0) revert NotFound();
        if (user == msg.sender) revert SelfEndorse();

        uint256 prev = endorsements[pid][msg.sender];
        endorsements[pid][msg.sender] = prev + score;
        profiles[pid].reputation += score;

        emit Endorsed(pid, msg.sender, score);

        if (profiles[pid].reputation >= badgeThreshold) {
            emit BadgeIssued(pid, "TrustedContributor");
        }
    }

    /// @notice Get profile data for a user address
    /// @param user address to query
    /// @return id profile id
    /// @return handle profile handle
    /// @return metadataURI pointer to off-chain metadata
    /// @return reputation aggregated reputation
    /// @return createdAt timestamp
    function getProfile(address user) external view returns (
        uint256 id,
        string memory handle,
        string memory metadataURI,
        uint256 reputation,
        uint256 createdAt
    ) {
        uint256 pid = addressToProfileId[user];
        if (pid == 0) revert NotFound();
        Profile storage p = profiles[pid];
        return (p.id, p.handle, p.metadataURI, p.reputation, p.createdAt);
    }

    /// @notice Admin: update badge threshold
    /// @param t new threshold
    function setBadgeThreshold(uint256 t) external onlyOwner {
        badgeThreshold = t;
    }
}
