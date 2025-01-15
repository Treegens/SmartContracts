// SPDX-License-Identifier: GPL
pragma solidity 0.8.17;

import "./TGNVault.sol";
import "./facets/ManagementFacet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MGROVerification is ReentrancyGuard {
    event VerificationProposalCreated(uint256 indexed proposalId, address indexed proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool vote);
    event VerificationProposalExecuted(uint256 indexed proposalId, bool succeeded);

    error InvalidInput();
    // Struct to represent a verification proposal
    struct VerificationProposal {
        address proposer;
        uint256 proposalId;
        uint256 amount;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 endTime;
        bool executed;
        bool isActive;
        mapping(address => bool) hasVoted;
        address[] yesVoters;
        address[] noVoters;
    }

    // Mapping to store all verification proposals
    mapping(uint256 => VerificationProposal) public verificationProposals;

    // Counter for proposal IDs
    uint256 public proposalCounter;
    uint256 public votingPeriod;

    // Address of the vault contract where members stake tokens
    ITGNVault private tgnVault;

    ManagementFacet private mgmt;

    // Modifier to check if the sender is a member with staked tokens
    modifier onlyStakedMember() {
        require(tgnVault.getStakedBalance(msg.sender) > 0, "Not a staked member");
        _;
    }

    constructor(address _vaultContract, address _diamond, uint256 _votingPeriod) {
        if(_vaultContract == address(0) ||_diamond == address(0) || _votingPeriod == 0) revert InvalidInput();
        tgnVault = ITGNVault(_vaultContract);
        mgmt = ManagementFacet(_diamond);
        votingPeriod = _votingPeriod;
    }

    // Function to create a new verification proposal
    function proposeVerification(uint256 _amount) external onlyStakedMember {
        uint256 newProposalId = ++proposalCounter;
        VerificationProposal storage newProposal = verificationProposals[newProposalId];
        newProposal.proposalId = newProposalId;
        newProposal.proposer = msg.sender;
        newProposal.amount = _amount;
        newProposal.endTime = block.timestamp + votingPeriod;

        newProposal.isActive = true;

        emit VerificationProposalCreated(newProposalId, msg.sender);
    }

    // Function to cast a vote on a verification proposal
    function vote(uint256 _proposalId, bool _vote) external onlyStakedMember nonReentrant {
        VerificationProposal storage proposal = verificationProposals[_proposalId];
        require(block.timestamp <= proposal.endTime, "Voting period has ended");
        require(proposal.isActive == true, "Proposal is not Active");
        require(!proposal.executed, "Proposal has already been executed");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        _updateProposalStatus(_proposalId);
        proposal.hasVoted[msg.sender] = true;
        if (_vote) {
            proposal.yesVotes++;
            proposal.yesVoters.push(msg.sender);
        } else {
            proposal.noVotes++;
            proposal.noVoters.push(msg.sender);
        }

        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    // Function to execute a verification proposal and slash tokens
    function executeVerification(uint256 _proposalId) external onlyStakedMember nonReentrant {
        VerificationProposal storage proposal = verificationProposals[_proposalId];
        // If the end time has passed but isActive is still true, auto-update
        if (block.timestamp > proposal.endTime && proposal.isActive) {
            proposal.isActive = false;
        }
        require(!proposal.executed, "Proposal has already been executed");
        require(!proposal.isActive, "Proposal still active");

        bool proposalSucceeded = proposal.yesVotes > proposal.noVotes;

        // Execute the verification logic based on the proposal result
        if (proposalSucceeded) {
            address recepient = proposal.proposer;
            uint256 amount = proposal.amount;

            mgmt.mintTokens(recepient, amount);
            address[] memory noVoters = proposal.noVoters;
            _tokenSlash(noVoters);
        } else {
            address[] memory yesVoters = proposal.yesVoters;
            _tokenSlash(yesVoters);
        }

        proposal.executed = true;

        emit VerificationProposalExecuted(_proposalId, proposalSucceeded);
    }

    function hasVoted(uint256 proposalId, address voter) external view returns (bool) {
        return verificationProposals[proposalId].hasVoted[voter];
    }

    function _tokenSlash(address[] memory voters) internal {
        uint256 length = voters.length;

        for (uint i = 0; i < length; i++) {
            tgnVault.slash(voters[i]);
        }
    }

    function _updateProposalStatus(uint256 _proposalId) internal {
        VerificationProposal storage proposal = verificationProposals[_proposalId];
        if (block.timestamp > proposal.endTime) {
            proposal.isActive = false;
        }
    }
}
