// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentralizedFileStorage {
    struct File {
        string fileHash; // IPFS hash or similar identifier
        string fileName; // Name of the file
        string fileType; // File type (e.g., .png, .txt)
        uint256 timestamp; // When the file was uploaded
        address owner; // Owner of the file
    }

    mapping(uint256 => File) public files; // Map file IDs to File structs
    mapping(string => bool) public fileExists; // Track file hashes to prevent duplicates
    address public owner; // Contract owner
    uint256 public fileCount; // Counter for file IDs
    uint256[] public folder; // Dynamic array to store file IDs

    event FileUploaded(
        uint256 indexed fileId,
        string fileHash,
        string fileName,
        string fileType,
        uint256 timestamp,
        address indexed owner
    );

    constructor() {
        owner = msg.sender; // Set contract deployer as the owner
    }

    /**
     * @dev Upload a file to the decentralized storage system.
     * @param _fileHash The unique hash of the file (from IPFS or similar).
     * @param _fileName The name of the file.
     * @param _fileType The type of the file (e.g., .png, .txt).
     */
    function uploadFile(
        string memory _fileHash,
        string memory _fileName,
        string memory _fileType
    ) public {
        require(bytes(_fileHash).length > 0, "File hash is required");
        require(bytes(_fileName).length > 0, "File name is required");
        require(bytes(_fileType).length > 0, "File type is required");
        require(msg.sender != address(0), "Uploader address cannot be zero");
        require(!fileExists[_fileHash], "Duplicate file hash");

        fileCount++;
        folder.push(fileCount);
        files[fileCount] = File({
            fileHash: _fileHash,
            fileName: _fileName,
            fileType: _fileType,
            timestamp: block.timestamp,
            owner: msg.sender
        });

        fileExists[_fileHash] = true;

        emit FileUploaded(
            fileCount,
            _fileHash,
            _fileName,
            _fileType,
            block.timestamp,
            msg.sender
        );
    }

    /**
     * @dev Retrieve file metadata by file ID.
     * @param _fileId The ID of the file.
     * @return File metadata.
     */
    function getFile(uint256 _fileId) public view returns (File memory) {
        require(_fileId > 0 && _fileId <= fileCount, "File does not exist");
        return files[_fileId];
    }

    /**
     * @dev Restrict certain operations to the file owner.
     * @param _fileId The ID of the file.
     */
    modifier onlyFileOwner(uint256 _fileId) {
        require(files[_fileId].owner == msg.sender, "Not the file owner");
        _;
    }

    /**
     * @dev Delete a file's metadata (only for file owner).
     * @param _fileId The ID of the file to delete.
     */
    function deleteFile(uint256 _fileId) public onlyFileOwner(_fileId) {
        delete fileExists[files[_fileId].fileHash];
        delete files[_fileId];
    }

    /**
     * @dev Get the list of all file IDs uploaded.
     * @return An array of file IDs.
     */
    function getFileIds() public view returns (uint256[] memory) {
        return folder;
    }
}
