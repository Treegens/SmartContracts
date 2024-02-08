// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import "./TGNVault.sol";

contract TGNDAO is
  Governor,
  GovernorSettings,
  GovernorCountingSimple,
  GovernorVotes,
  GovernorVotesQuorumFraction
{
  address private MGROVerification;
  ITGNVault private staking;
  mapping (uint => bool) private requiresStaking;
  mapping (uint => address []) private noVotes;
  mapping (uint => address []) private yesVotes;

  error RequiresStaking();


  constructor(
    IVotes _token,
    uint256 _quorumPercentage,
    uint256 _votingPeriod,
    uint256 _votingDelay,
    address _MGROContract, 
    address _stakingContract
  )
    Governor("GovernorContract")
    GovernorSettings(
      _votingDelay, 
      _votingPeriod, // 45818, /* 1 week */ // voting period
      0 // proposal threshold
    )
    GovernorVotes(_token)
    GovernorVotesQuorumFraction(_quorumPercentage)

  {
    staking = ITGNVault(_stakingContract);
    MGROVerification = _MGROContract;
  }

  function votingDelay()
    public
    view
    override(IGovernor, GovernorSettings)
    returns (uint256)
  {
    return super.votingDelay();
  }

  function votingPeriod()
    public
    view
    override(IGovernor, GovernorSettings)
    returns (uint256)
  {
    return super.votingPeriod();
  }

  // The following functions are overrides required by Solidity.

  function quorum(uint256 blockNumber)
    public
    view
    override(IGovernor, GovernorVotesQuorumFraction)
    returns (uint256)
  {
    return super.quorum(blockNumber);
  }

  function getVotes(address account, uint256 blockNumber)
    public
    view
    override(Governor)
    returns (uint256)
  {
    return super.getVotes(account, blockNumber);
  }

  function state(uint256 proposalId)
    public
    view
    override(Governor)
    returns (ProposalState)
  {
    return super.state(proposalId);
  }

  function propose(
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    string memory description
  ) public override(Governor) returns (uint256) {
    
    uint256 id =  super.propose(targets, values, calldatas, description);
    
    for(uint i; i<targets.length; i++ ){
      if(targets[i] == MGROVerification){
        requiresStaking[id] = true;
        staking.setUnstakeLock(true);
      } else {
        requiresStaking[id] = false;
      }
    
    }
    return id;
  }

  function proposalThreshold()
    public
    view
    override(Governor, GovernorSettings)
    returns (uint256)
  {
    return super.proposalThreshold();
  }

  function _execute(
    uint256 proposalId,
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes32 descriptionHash
  ) internal override(Governor) {
    super._execute(proposalId, targets, values, calldatas, descriptionHash);
    // //the slashStaked function called after voting
    // slashStaked(proposalId);
  }

  function _castVote(uint256 proposalId,
        address account,
        uint8 support,
        string memory reason,
        bytes memory params)
        internal virtual override(Governor) returns (uint256){
          uint256 userBal = staking.getStakedBalance(account);
          if(requiresStaking[proposalId]==true){
          if(userBal == 0) revert RequiresStaking();
          }
           if(support == 0){
            noVotes[proposalId].push(account);
          }else if(support == 1){
            yesVotes[proposalId].push(account);
          }
          return super._castVote(proposalId,account, support,reason, params);

         


        }

  function _cancel(
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes32 descriptionHash
  ) internal override(Governor) returns (uint256) {
    return super._cancel(targets, values, calldatas, descriptionHash);
  }

  function _executor()
    internal
    view
    override(Governor )
    returns (address)
  {
    return super._executor();
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(Governor )
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function slashStaked(uint256 proposalId) external  {
    ProposalState current = state(proposalId);
    address[] memory accounts;
    if (current ==ProposalState.Defeated){
    accounts = getYesVotes(proposalId);
    }else if(current == ProposalState.Succeeded) {
    accounts = getNoVotes(proposalId);
    }

    for (uint i = 0; i < accounts.length; i++) {
      staking.slash(accounts[i]);
    }
    staking.setUnstakeLock(false);
    
  }


  function getNoVotes(uint256 proposalId) internal view returns (address[] memory) {
    return noVotes[proposalId];
    
  }
  function getYesVotes(uint256 proposalId) internal view returns (address[] memory) {
    return yesVotes[proposalId];
    
  }
}