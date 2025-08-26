

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title CloudStoragePointer - Register and discover off-chain content pointers (IPFS/Arweave/Filecoin)
/// @notice Stores immutable pointers (CIDs) and lightweight metadata. Registry fee prevents spam.
contract CloudStoragePointer is Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    struct FileRecord {
        string cid; // IPFS/Arweave CID or other pointer
        string metadata; // short JSON or text
        address publisher;
        uint256 timestamp;
        bool active;
    }

    uint256 public registryFee; // fee to register a file (wei) or token units
    FileRecord[] public files;
    mapping(address => EnumerableSet.UintSet) private filesByPublisher;

    event FileAdded(uint256 indexed id, address indexed publisher, string cid);
    event FileUpdated(uint256 indexed id, string newMeta);
    event FileDeactivated(uint256 indexed id);
    event RegistryFeeSet(uint256 fee);

    error InsufficientFee();
    error NotOwnerOrPublisher();

    constructor(uint256 _registryFee) {
        registryFee = _registryFee;
    }

    /// @notice Set the fee to register files. Owner only.
    function setRegistryFee(uint256 fee) external onlyOwner {
        registryFee = fee;
        emit RegistryFeeSet(fee);
    }

    /// @notice Add a file pointer. Must send exact fee.
    function addFile(string calldata cid, string calldata metadata) external payable returns (uint256) {
        if (msg.value < registryFee) revert InsufficientFee();
        FileRecord memory r = FileRecord({cid: cid, metadata: metadata, publisher: msg.sender, timestamp: block.timestamp, active: true});
        files.push(r);
        uint256 id = files.length - 1;
        filesByPublisher[msg.sender].add(id);
        emit FileAdded(id, msg.sender, cid);
        return id;
    }

    /// @notice Update metadata for your file.
    function updateFile(uint256 id, string calldata newMetadata) external {
        require(id < files.length, "Bad id");
        FileRecord storage r = files[id];
        require(r.publisher == msg.sender || msg.sender == owner(), "Not authorized");
        r.metadata = newMetadata;
        emit FileUpdated(id, newMetadata);
    }

    /// @notice Deactivate a file (publisher or owner).
    function deactivateFile(uint256 id) external {
        require(id < files.length, "Bad id");
        FileRecord storage r = files[id];
        require(r.publisher == msg.sender || msg.sender == owner(), "Not authorized");
        r.active = false;
        emit FileDeactivated(id);
    }

    /// @notice View a file record.
    function getFile(uint256 id) external view returns (string memory cid, string memory metadata, address publisher, uint256 timestamp, bool active) {
        require(id < files.length, "Bad id");
        FileRecord storage r = files[id];
        return (r.cid, r.metadata, r.publisher, r.timestamp, r.active);
    }

    /// @notice Get list of file ids published by an address (paged).
    function getFilesByPublisher(address publisher) external view returns (uint256[] memory) {
        uint256 len = filesByPublisher[publisher].length();
        uint256[] memory out = new uint256[](len);
        for (uint256 i = 0; i < len; i++) out[i] = filesByPublisher[publisher].at(i);
        return out;
    }

    /// @notice Owner withdraws collected fees.
    function withdraw(address payable to) external onlyOwner {
        to.transfer(address(this).balance);
    }
}