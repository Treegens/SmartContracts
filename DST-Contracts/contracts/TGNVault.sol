// SPDX-License-Identifier: GPL
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TGNVault {
    address private daoContract;
    address private mgroVerification; // Address of the DAO contract
    bool private slashingEnabled;

    IERC20 private tgn;
    uint8 private slashingPercentage;

    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public lastStakedTime;
    mapping(address => bool) public stakeLocked;

    event Staked(address indexed staker, uint256 amount);
    event Unstaked(address indexed staker, uint256 amount);
    event Slashed(address indexed staker, uint256 amount);

    error InvalidInput();
    error OnlyDAOAuthorized();
    error EnableSlashing();
    error ApproveOrIncreaseAllowance();
    error InvalidSlashingAmount();
    error ZeroPercentSlashing();
    error Unauthorized();

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

    constructor(address _tgn, address _DAO) {
        if (_tgn == address(0) || _DAO == address(0)) revert InvalidInput();
        daoContract = _DAO; // Set the DAO contract during deployment
        slashingEnabled = false;
        tgn = IERC20(_tgn);
    }

    function setVerificationAddress(address _address) external onlyDAO {
        if (_address == address(0)) revert InvalidInput();
        mgroVerification = _address;
    }

    function setSlashingParams(uint8 _percent) external onlyDAO {
        //limit to a max of 30% slash
        if (_percent == 0 || _percent > 30) revert InvalidInput();
        slashingPercentage = _percent;
        slashingEnabled = true;
    }

    // Function to stake tokens
    function stake(uint256 amount) external {
        if (amount == 0) revert InvalidInput();
        if (tgn.allowance(msg.sender, address(this)) < amount) revert ApproveOrIncreaseAllowance();
        bool success = tgn.transferFrom(msg.sender, address(this), amount);
        require(success, " TGN Transfer failed");
        stakedBalance[msg.sender] += amount;
        lastStakedTime[msg.sender] = block.timestamp;

        emit Staked(msg.sender, amount);
    }

    // Function to unstake tokens
    function unstake(uint256 amount) external {
        if (amount == 0) revert InvalidInput();
        require(stakedBalance[msg.sender] >= amount, "Not enough staked balance");
       require(!stakeLocked[msg.sender], "Active votes: unstake disabled");

        bool success = tgn.transfer(msg.sender, amount);
        require(success, " TGN Transfer failed");

        stakedBalance[msg.sender] -= amount;

        emit Unstaked(msg.sender, amount);
    }

    // Function to slash a staker's balance (can only be called by the DAO)
    function slash(address staker) external onlyMGROVerification slashingAllowed {
        uint256 amount = stakedBalance[staker];
        if (amount == 0) revert InvalidSlashingAmount();

        if (slashingPercentage == 0) revert ZeroPercentSlashing();

        uint256 slashAmount = (slashingPercentage * amount) / 100;
        if (slashAmount > amount) revert InvalidSlashingAmount();

        stakedBalance[staker] -= slashAmount;

        emit Slashed(staker, slashAmount);
    }

    // —— NEW functions, only callable by MGROVerification ——
    function lockStake(address staker) external onlyMGROVerification {
        stakeLocked[staker] = true;
    }

    function unlockStake(address staker) external onlyMGROVerification {
        stakeLocked[staker] = false;
    }

    // Function to enable/disable slashing (can only be called by the DAO)
    function setSlashingEnabled(bool enabled) external onlyDAO {
        slashingEnabled = enabled;
    }

    // Function to get the current staking balance of an address
    function getStakedBalance(address staker) external view returns (uint256) {
        return stakedBalance[staker];
    }

    // Function to get the last staking time of an address
    function getLastStakedTime(address staker) external view returns (uint256) {
        return lastStakedTime[staker];
    }

    // Public getter for DAO contract address
    function getDAOContract() external view returns (address) {
        return daoContract;
    }

    // Public getter for slashing enabled flag
    function isSlashingEnabled() external view returns (bool) {
        return slashingEnabled;
    }

}

interface ITGNVault {
    function slash(address) external;
    function getStakedBalance(address) external view returns (uint256);
    function lockStake(address) external;
    function unlockStake(address) external;
}
