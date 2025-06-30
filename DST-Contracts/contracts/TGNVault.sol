// SPDX-License-Identifier: GPL
pragma solidity ^0.8.17;
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TGNVault  is Ownable{
    // —— State —— 
    address private daoContract;
    address private mgroVerification;
    bool private slashingEnabled;

    IERC20 private immutable tgn;
    uint8 private slashingPercentage;

    /// user deposits
    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public lastStakedTime;

    /// per‐proposal locks: how many live proposals this user has voted in
    mapping(address => uint256) public activeVoteCount;

    /// global “emergency” lock for all unstaking
    bool public globalUnstakeLocked;

    // —— Events —— 
    event Staked(address indexed staker, uint256 amount);
    event Unstaked(address indexed staker, uint256 amount);
    event Slashed(address indexed staker, uint256 amount);
    event GlobalUnstakeLockSet(bool locked);

    // —— Errors —— 
    error InvalidInput();
    error OnlyDAOAuthorized();
    error EnableSlashing();
    error ApproveOrIncreaseAllowance();
    error InvalidSlashingAmount();
    error ZeroPercentSlashing();
    error Unauthorized();
    error NotEnoughStake();
    error UnstakeDisabled();
    error UnstakeGloballyDisabled();

    // —— Modifiers —— 
    modifier onlyDAO() {
        if (msg.sender != daoContract) revert OnlyDAOAuthorized();
        _;
    }



    modifier slashingAllowed() {
        if (!slashingEnabled) revert EnableSlashing();
        _;
    }

    modifier onlyMGROVerification() {
        if (msg.sender != mgroVerification) revert Unauthorized();
        _;
    }

    // —— Constructor —— 
    constructor(address _tgn, address _DAO)  {
        if (_tgn == address(0) || _DAO == address(0)) revert InvalidInput();
        tgn = IERC20(_tgn);
        daoContract = _DAO;
        slashingEnabled = true;
        globalUnstakeLocked = false;
    }

    // —— DAO‐only configuration —— 
    function setVerificationAddress(address _address) external onlyOwner {
        if (_address == address(0)) revert InvalidInput();
        mgroVerification = _address;
    }

    function setSlashingParams(uint8 _percent) external onlyDAO {
        if (_percent == 0 || _percent > 30) revert InvalidInput();
        slashingPercentage = _percent;
        slashingEnabled = true;
    }

    function setSlashingEnabled(bool enabled) external onlyDAO {
        slashingEnabled = enabled;
    }

    /// C08 fix: allow the DAO to globally lock or unlock unstaking
    function setUnstakeLock(bool locked) external onlyDAO {
        globalUnstakeLocked = locked;
        emit GlobalUnstakeLockSet(locked);
    }

    // —— Staking interface —— 
    function stake(uint256 amount) external {
        if (amount == 0) revert InvalidInput();
        if (tgn.allowance(msg.sender, address(this)) < amount) revert ApproveOrIncreaseAllowance();
        bool ok = tgn.transferFrom(msg.sender, address(this), amount);
        require(ok, "TGN transfer failed");

        stakedBalance[msg.sender] += amount;
        lastStakedTime[msg.sender] = block.timestamp;

        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external {
        if (amount == 0) revert InvalidInput();
        if (stakedBalance[msg.sender] < amount) revert NotEnoughStake();

        // 1) global DAO lock  
        if (globalUnstakeLocked) revert UnstakeGloballyDisabled();
        // 2) per‐proposal vote‐lock  
        if (activeVoteCount[msg.sender] > 0) revert UnstakeDisabled();

        bool ok = tgn.transfer(msg.sender, amount);
        require(ok, "TGN transfer failed");

        stakedBalance[msg.sender] -= amount;
        emit Unstaked(msg.sender, amount);
    }

    // —— Slashing —— 
    function slash(address staker) external onlyMGROVerification slashingAllowed {
        uint256 bal = stakedBalance[staker];
        if (bal == 0) revert InvalidSlashingAmount();
        if (slashingPercentage == 0) revert ZeroPercentSlashing();

        uint256 slashAmt = (uint256(slashingPercentage) * bal) / 100;
        if (slashAmt > bal) revert InvalidSlashingAmount();

        stakedBalance[staker] = bal - slashAmt;
        emit Slashed(staker, slashAmt);
    }

    // —— Vote‐lock integration —— 
    /// Called by MGROVerification (or DAO) when a user casts a vote on an active proposal
    function lockStake(address staker) external onlyMGROVerification {
        activeVoteCount[staker] += 1;
    }

    /// Called once a proposal is finalized or canceled
    function unlockStake(address staker) external onlyMGROVerification {
        uint256 count = activeVoteCount[staker];
        require(count > 0, "No active vote locks");
        activeVoteCount[staker] = count - 1;
    }

    // —— Views —— 
    function getStakedBalance(address staker) external view returns (uint256) {
        return stakedBalance[staker];
    }

    function getLastStakedTime(address staker) external view returns (uint256) {
        return lastStakedTime[staker];
    }

    function getDAOContract() external view returns (address) {
        return daoContract;
    }

    function isSlashingEnabled() external view returns (bool) {
        return slashingEnabled;
    }
}

interface ITGNVault {
    function slash(address) external;
    function getStakedBalance(address) external view returns (uint256);
    function lockStake(address) external;
    function unlockStake(address) external;
    function setUnstakeLock(bool) external;
    function isSlashingEnabled() external view returns (bool);
}
