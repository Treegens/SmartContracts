// SPDX-License-Identifier: GPL
pragma solidity 0.8.17;

import "./TGNVault.sol";
import "./facets/ManagementFacet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MGROVerification is ReentrancyGuard, Ownable {
    event VerificationProposalCreated(uint256 indexed proposalId, address indexed proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool vote);
    event VerificationProposalExecuted(uint256 indexed proposalId, bool succeeded);

    error InvalidInput();
    error Unauthorized();
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
    mapping(address => uint256) public strikeCount;
    mapping(address => uint8) public maxOpenVotes;
    mapping (address => bool) public blacklisted;
    uint8 public constant MAX_PARALLEL_VOTES = 3;

    // Counter for proposal IDs
    uint256 public proposalCounter;
    uint256 public votingPeriod;
    address private daoAddress;
   

    // Address of the vault contract where members stake tokens
    ITGNVault private tgnVault;

    ManagementFacet private mgmt;

    modifier votingQuota() {
        require(maxOpenVotes[msg.sender] < MAX_PARALLEL_VOTES, "Too many open Votes");
        _;
    }

    // Modifier to check if the sender is a member with staked tokens
    modifier onlyStakedMember() {
        require(tgnVault.getStakedBalance(msg.sender) > 0, "Not a staked member");
        _;
    }

    constructor(address _vaultContract, address _diamond, uint256 _votingPeriod, address _dao) {
        if (_vaultContract == address(0) || _diamond == address(0) || _votingPeriod == 0 || _dao == address(0)) revert InvalidInput();
        tgnVault = ITGNVault(_vaultContract);
        mgmt = ManagementFacet(_diamond);
        votingPeriod = _votingPeriod;
        daoAddress= _dao;
    }

    // Function to create a new verification proposal
    function proposeVerification(uint256 _amount) external onlyStakedMember {
        require(_amount > 0, "Zero amount");
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
    function vote(uint256 _proposalId, bool _vote) external onlyStakedMember votingQuota nonReentrant {
        VerificationProposal storage proposal = verificationProposals[_proposalId];
        require(block.timestamp <= proposal.endTime, "Voting period has ended");
        require(proposal.isActive == true, "Proposal is not Active");
        require(!proposal.executed, "Proposal has already been executed");
        require(!blacklisted[msg.sender], "User Blacklisted: Too many wrong verifications");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        if (maxOpenVotes[msg.sender] == 0) {
            tgnVault.lockStake(msg.sender);
        }
        proposal.hasVoted[msg.sender] = true;
        if (_vote) {
            proposal.yesVotes++;
            proposal.yesVoters.push(msg.sender);
        } else {
            proposal.noVotes++;
            proposal.noVoters.push(msg.sender);
        }
        maxOpenVotes[msg.sender] += uint8(1);
        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    // Function to execute a verification proposal and slash tokens
    function executeVerification(uint256 _proposalId) external onlyStakedMember nonReentrant {
        VerificationProposal storage proposal = verificationProposals[_proposalId];
        // If the end time has passed but isActive is still true, auto-update
        if (block.timestamp > proposal.endTime && proposal.isActive) {
            proposal.isActive = false;
        }
        require(tgnVault.isSlashingEnabled(), "Error: Slashing not enabled");
        require(!proposal.executed, "Proposal has already been executed");
        require(!proposal.isActive, "Proposal still active");

        bool proposalSucceeded = proposal.yesVotes > proposal.noVotes;

        // Execute the verification logic based on the proposal result
        if (proposalSucceeded) {
            address recepient = proposal.proposer;
            uint256 amount = proposal.amount;

            mgmt.mintMgroTokens(recepient, amount);
            address[] memory noVoters = proposal.noVoters;
            _countErrorVote(noVoters);
        } else {
            address[] memory yesVoters = proposal.yesVoters;
            _countErrorVote(yesVoters);
        }
        _clearOpenVoteCounters(proposal);
        proposal.executed = true;

        emit VerificationProposalExecuted(_proposalId, proposalSucceeded);
    }

    function hasVoted(uint256 proposalId, address voter) external view returns (bool) {
        return verificationProposals[proposalId].hasVoted[voter];
    }

    function resetBlacklist(address _address) external {
        if (msg.sender != daoAddress) revert Unauthorized();
        if (_address == address(0)) revert InvalidInput();
        strikeCount[_address] = 0;
        blacklisted[_address]=false;
    }

    function setDAOAddress(address _address) external onlyOwner {
        if (_address == address(0)) revert InvalidInput();
        daoAddress = _address;
    }

 
    function _countErrorVote(address[] memory voters) internal {
         uint256 length = voters.length;

        for (uint i = 0; i < length; i++) {
          
            strikeCount[voters[i]] += 1;
            if(strikeCount[voters[i]]>2) {
                blacklisted[voters[i]]=true;
                tgnVault.slash(voters[i]);
            }
        }
    }

    function _updateProposalStatus(uint256 _proposalId) internal {
        VerificationProposal storage proposal = verificationProposals[_proposalId];
        if (block.timestamp > proposal.endTime) {
            proposal.isActive = false;
        }
    }

    function _clearOpenVoteCounters(VerificationProposal storage p) internal {
        for (uint i; i < p.yesVoters.length; ++i) {
            uint8 cnt = maxOpenVotes[p.yesVoters[i]];
            if (cnt > 0) maxOpenVotes[p.yesVoters[i]] = cnt - uint8(1);
            if (maxOpenVotes[p.yesVoters[i]] == 0) {
                tgnVault.unlockStake(p.yesVoters[i]);
            }
        }
        for (uint i; i < p.noVoters.length; ++i) {
            uint8 cnt = maxOpenVotes[p.noVoters[i]];
            if (cnt > 0) maxOpenVotes[p.noVoters[i]] = cnt - uint8(1);
            if (maxOpenVotes[p.noVoters[i]] == 0) {
                tgnVault.unlockStake(p.noVoters[i]);
            }
        }
    }
}
