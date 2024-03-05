// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TGNVault.sol";
import "./facets/ManagementFacet.sol";

contract MGROVerification {

    // Struct to represent a verification proposal
    struct VerificationProposal {
        uint256 proposalId;
        address proposer;
        uint256 amount;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        mapping(address => bool) hasVoted;
        address [] yesVoters;
        address [] noVoters;
    }

    // Mapping to store all verification proposals
    mapping(uint256 => VerificationProposal) public verificationProposals;

    // Counter for proposal IDs
    uint256 public proposalCounter;

    // Address of the vault contract where members stake tokens
    ITGNVault private tgnVault;

    ManagementFacet private mgmt;


    // Modifier to check if the sender is a member with staked tokens
    modifier onlyStakedMember() {
        
        require(tgnVault.getStakedBalance(msg.sender)> 0, "Not a staked member");
        _;
    }

    // Event emitted when a new verification proposal is created
    event VerificationProposalCreated(uint256 proposalId, address proposer);

    // Event emitted when a vote is cast on a verification proposal
    event VoteCast(uint256 proposalId, address voter, bool vote);

    // Event emitted when a verification proposal is executed
    event VerificationProposalExecuted(uint256 proposalId, bool succeeded);

    constructor(address _vaultContract, address _diamond) {
        tgnVault = ITGNVault(_vaultContract);
        mgmt = ManagementFacet(_diamond);
    }

    // Function to create a new verification proposal
    function proposeVerification() external onlyStakedMember {
        uint256 newProposalId = proposalCounter++;
        VerificationProposal storage newProposal = verificationProposals[newProposalId];
        newProposal.proposalId = newProposalId;
        newProposal.proposer = msg.sender;

        emit VerificationProposalCreated(newProposalId, msg.sender);
    }

    // Function to cast a vote on a verification proposal
    function vote(uint256 _proposalId, bool _vote) external onlyStakedMember {
        VerificationProposal storage proposal = verificationProposals[_proposalId];
        require(!proposal.executed, "Proposal has already been executed");
        require(!proposal.hasVoted[msg.sender], "Already voted");

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
    function executeVerification(uint256 _proposalId) external onlyStakedMember {
        VerificationProposal storage proposal = verificationProposals[_proposalId];
        require(!proposal.executed, "Proposal has already been executed");

        bool proposalSucceeded = proposal.yesVotes > proposal.noVotes;

        // Execute the verification logic based on the proposal result
        if (proposalSucceeded) {
            address recepient = proposal.proposer;
            uint256 amount = proposal.amount;

            mgmt.mintTokens(recepient, amount);
            address [] memory noVoters = proposal.noVoters;
            _tokenSlash(noVoters);
            

            

        } else {
           address [] memory yesVoters = proposal.yesVoters;
           _tokenSlash(yesVoters);
        }

        proposal.executed = true;

        emit VerificationProposalExecuted(_proposalId, proposalSucceeded);
    }

    function _tokenSlash(address [] memory voters) internal {
        uint256 length = voters.length;

        for(uint i = 0; i<length; i++){
            tgnVault.slash(voters[i]);
        }
    }
}
