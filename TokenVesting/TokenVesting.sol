// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract TokenVesting {
    address public owner;
    IERC20 public token;
    mapping(address => uint256) public allocations;
    mapping(address => uint256) public claimed;

    uint256 public start;
    uint256 public duration;

    constructor(address _token, uint256 _duration) {
        owner = msg.sender;
        token = IERC20(_token);
        start = block.timestamp;
        duration = _duration;
    }

    function setAllocation(address user, uint256 amount) external {
        require(msg.sender == owner, "Not owner");
        allocations[user] = amount;
    }

    function claim() external {
        require(block.timestamp > start, "Vesting not started");
        uint256 vested = (allocations[msg.sender] * (block.timestamp - start)) / duration;
        if (vested > allocations[msg.sender]) {
            vested = allocations[msg.sender];
        }
        uint256 claimable = vested - claimed[msg.sender];
        require(claimable > 0, "Nothing to claim");

        claimed[msg.sender] += claimable;
        token.transfer(msg.sender, claimable);
    }
}
