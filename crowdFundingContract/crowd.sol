// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract crowd {
    address public immutable owner;
    uint public immutable goalAmount;
    uint public endTime;
    uint public totalFunds;
    address[] public contributors;
    mapping(address => uint) public balances;

    enum CampaignState { Freeze, Active }
    CampaignState public state;

    event FundsAdded(address indexed contributor, uint amount);
    event FundsWithdrawn(address indexed owner, uint amount);
    event RefundIssued(address indexed contributor, uint amount);

    constructor(uint _goalAmount, uint _duration) {
        owner = msg.sender;
        goalAmount = _goalAmount;
        endTime = block.timestamp + _duration;
        state = CampaignState.Active;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Only the contract owner can perform this action");
        _;
    }

    modifier isActive() {
        require(state == CampaignState.Active, "Campaign is not active");
        require(block.timestamp <= endTime, "Campaign has ended");
        _;
    }

    function addFunds() public payable isActive {
        require(msg.value > 0, "Amount must be greater than 0");
        
        balances[msg.sender] += msg.value;
        contributors.push(msg.sender);
        totalFunds += msg.value;

        if (totalFunds >= goalAmount) {
            state = CampaignState.Freeze;
        }
        
        emit FundsAdded(msg.sender, msg.value);
    }

    function withdrawFunds() public onlyOwner {
        require(state == CampaignState.Freeze, "Campaign goal not reached yet");
        require(totalFunds >= goalAmount, "Insufficient funds");
        
        
        uint amount = totalFunds;
        totalFunds = 0;
        payable(owner).transfer(amount);
        
        emit FundsWithdrawn(owner, amount);
    }

    function refundContributors() public {
        require(state == CampaignState.Active, "Refunds only while the campaign is active");
        require(block.timestamp > endTime, "Campaign is still ongoing");
        require(totalFunds < goalAmount, "Goal met; no refunds");

        uint amountToRefund = balances[msg.sender];
        require(amountToRefund > 0, "No balance to refund");

        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amountToRefund);
        
        emit RefundIssued(msg.sender, amountToRefund);
    }
}
