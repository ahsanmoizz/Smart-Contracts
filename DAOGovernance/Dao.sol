
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title Simple Governor with Token‑weighted Voting and Timelock Execution
/// @notice Off‑chain proposals can be submitted; this contract handles proposal lifecycle, voting, and execution via a timelock address.
contract DAOGovernance is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable govToken; // voting token
    address public timelock; // executor (could be a timelock contract)

    uint256 public proposalCount;
    uint256 public minQuorum; // number of votes required
    uint256 public votingPeriod; // seconds
    uint256 public proposalThreshold; // minimum tokens to create proposal

    enum ProposalState { Pending, Active, Defeated, Succeeded, Queued, Executed }

    struct Proposal {
        address proposer;
        string description;
        bytes[] calls; // encoded function calls to timelock/executor
        uint256 start; // voting start
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    mapping(uint256 => Proposal) internal proposals;

    event ProposalCreated(uint256 indexed id, address indexed proposer, string description);
    event VoteCast(uint256 indexed id, address indexed voter, bool support, uint256 weight);
    event ProposalQueued(uint256 indexed id);
    event ProposalExecuted(uint256 indexed id);

    constructor(IERC20 _govToken, address _timelock, uint256 _minQuorum, uint256 _votingPeriod, uint256 _threshold) Ownable(msg.sender) {
        govToken = _govToken;
        timelock = _timelock;
        minQuorum = _minQuorum;
        votingPeriod = _votingPeriod;
        proposalThreshold = _threshold;
    }

    modifier validProposal(uint256 id) {
        require(id > 0 && id <= proposalCount, "Invalid");
        _;
    }

    function setTimelock(address _timelock) external onlyOwner { timelock = _timelock; }
    function setParams(uint256 _minQuorum, uint256 _votingPeriod, uint256 _threshold) external onlyOwner {
        minQuorum = _minQuorum; votingPeriod = _votingPeriod; proposalThreshold = _threshold;
    }

    /// @notice Create a proposal. `calls` are ABI-encoded calls to the `timelock` executor.
    function propose(bytes[] calldata calls, string calldata description) external returns (uint256) {
        require(govToken.balanceOf(msg.sender) >= proposalThreshold, "Below threshold");
        proposalCount++;
        Proposal storage p = proposals[proposalCount];
        p.proposer = msg.sender;
        p.description = description;
        p.start = block.timestamp;
        for (uint i = 0; i < calls.length; i++) p.calls.push(calls[i]);
        emit ProposalCreated(proposalCount, msg.sender, description);
        return proposalCount;
    }

    function state(uint256 id) public view validProposal(id) returns (ProposalState) {
        Proposal storage p = proposals[id];
        if (block.timestamp < p.start + votingPeriod) return ProposalState.Active;
        if (p.forVotes + p.againstVotes < minQuorum) return ProposalState.Defeated;
        if (p.forVotes <= p.againstVotes) return ProposalState.Defeated;
        if (!p.executed) return ProposalState.Succeeded;
        return ProposalState.Executed;
    }

    function castVote(uint256 id, bool support) external validProposal(id) {
        Proposal storage p = proposals[id];
        require(!p.hasVoted[msg.sender], "Already");
        require(block.timestamp <= p.start + votingPeriod, "Voting closed");
        uint256 weight = govToken.balanceOf(msg.sender);
        require(weight > 0, "No weight");
        p.hasVoted[msg.sender] = true;
        if (support) p.forVotes += weight; else p.againstVotes += weight;
        emit VoteCast(id, msg.sender, support, weight);
    }

    /// @notice Queue and execute by sending calls to the timelock/executor address.
    function execute(uint256 id) external validProposal(id) {
        Proposal storage p = proposals[id];
        require(state(id) == ProposalState.Succeeded, "Not succeeded");
        // Naive execution: call timelock with each encoded call (timelock expected to be a contract owned by DAO)
        for (uint i = 0; i < p.calls.length; i++) {
            (bool ok, ) = timelock.call(p.calls[i]);
            require(ok, "Call failed");
        }
        p.executed = true;
        emit ProposalExecuted(id);
    }
}