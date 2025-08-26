
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title Fair Lottery using Commit-Reveal to mitigate miner bias
contract Lottery is ReentrancyGuard {
    enum Phase { Commit, Reveal, Finished }

    struct Player { bytes32 commitHash; uint256 stake; bool revealed; uint256 secret; }

    uint256 public ticketPrice; // wei
    uint256 public commitEnd;
    uint256 public revealEnd;
    Phase public phase;

    address[] public players;
    mapping(address => Player) public info;

    address public winner;

    event Committed(address indexed player, bytes32 commitHash, uint256 stake);
    event Revealed(address indexed player, uint256 secret);
    event WinnerSelected(address indexed winner, uint256 prize);

    error WrongPhase(Phase expected, Phase got);
    error AlreadyCommitted();
    error NotCommitted();

    modifier inPhase(Phase p) { if (phase != p) revert WrongPhase(p, phase); _; }

    constructor(uint256 _ticketPrice, uint256 _commitDuration, uint256 _revealDuration) payable {
        ticketPrice = _ticketPrice;
        commitEnd = block.timestamp + _commitDuration;
        revealEnd = commitEnd + _revealDuration;
        phase = Phase.Commit;
    }

    /// @notice Commit with hash = keccak256(abi.encodePacked(secret, msg.sender)).
    function commit(bytes32 commitHash) external payable inPhase(Phase.Commit) nonReentrant {
        require(block.timestamp < commitEnd, "Commit period over");
        require(msg.value == ticketPrice, "Pay exact ticket price");
        if (info[msg.sender].commitHash != bytes32(0)) revert AlreadyCommitted();
        info[msg.sender] = Player({commitHash: commitHash, stake: msg.value, revealed: false, secret: 0});
        players.push(msg.sender);
        emit Committed(msg.sender, commitHash, msg.value);
    }

    function startReveal() external inPhase(Phase.Commit) {
        require(block.timestamp >= commitEnd, "Commit ongoing");
        phase = Phase.Reveal;
    }

    function reveal(uint256 secret) external inPhase(Phase.Reveal) {
        require(block.timestamp < revealEnd, "Reveal period over");
        Player storage p = info[msg.sender];
        if (p.commitHash == bytes32(0)) revert NotCommitted();
        require(!p.revealed, "Already revealed");
        require(keccak256(abi.encodePacked(secret, msg.sender)) == p.commitHash, "Bad secret");
        p.revealed = true;
        p.secret = secret;
        emit Revealed(msg.sender, secret);
    }

    function finish() external inPhase(Phase.Reveal) nonReentrant {
        require(block.timestamp >= revealEnd, "Reveal ongoing");
        // Build entropy from all revealed secrets and block data
        bytes32 entropy = keccak256(abi.encodePacked(blockhash(block.number - 1), address(this)));
        uint256 revealedCount;
        for (uint256 i = 0; i < players.length; i++) {
            Player storage p = info[players[i]];
            if (p.revealed) {
                revealedCount++;
                entropy = keccak256(abi.encodePacked(entropy, p.secret, players[i]));
            }
        }
        require(revealedCount > 0, "No reveals");
        uint256 idx = uint256(entropy) % revealedCount;
        // Map idx to the idx-th revealed player
        uint256 seen;
        address win;
        for (uint256 i = 0; i < players.length; i++) {
            Player storage p = info[players[i]];
            if (p.revealed) {
                if (seen == idx) { win = players[i]; break; }
                seen++;
            }
        }
        winner = win;
        phase = Phase.Finished;
        uint256 prize = address(this).balance;
        (bool ok, ) = win.call{value: prize}("");
        require(ok, "Payout failed");
        emit WinnerSelected(win, prize);
    }
}