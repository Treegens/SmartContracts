// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SimpleStaking {
    address private daoContract;  // Address of the DAO contract
    bool private slashingEnabled; 

    IERC20 private tgn;
    uint8 private slashingPercentage;

    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public lastStakedTime;

    event Staked(address indexed staker, uint256 amount);
    event Unstaked(address indexed staker, uint256 amount);
    event Slashed(address indexed staker, uint256 amount);

    modifier onlyDAO() {
        require(msg.sender == daoContract, "Caller is not the DAO contract");
        _;
    }

    modifier slashingAllowed() {
        require(slashingEnabled, "Slashing is currently disabled");
        _;
    }

    constructor(address _tgn, address _DAO) {
        require(_tgn != address(0), "Invalid token Address");
        daoContract = _DAO;  // Set the DAO contract during deployment
        slashingEnabled = true; 
        tgn = IERC20(_tgn);
    }

    function setSlashingParams (uint8 _percent) external  onlyDAO  {
        require(_percent!=0, "Invalid Input");
        slashingPercentage = _percent;

    }

    // Function to stake tokens
    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(tgn.allowance(msg.sender, address(this)) >= amount, "Please increase the allowance for this contract");
        tgn.transferFrom(msg.sender, address(this), amount);

        stakedBalance[msg.sender] += amount;
        lastStakedTime[msg.sender] = block.timestamp;

        emit Staked(msg.sender, amount);
    }

    // Function to unstake tokens
    function unstake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(stakedBalance[msg.sender] >= amount, "Not enough staked balance");

        tgn.transfer(msg.sender, amount);

        stakedBalance[msg.sender] -= amount;

        emit Unstaked(msg.sender, amount);
    }

    // Function to slash a staker's balance (can only be called by the DAO)
  function slash(address staker) external  onlyDAO  slashingAllowed {
    uint256 amount = stakedBalance[staker];
    require(amount > 0, "Cannot slash zero balance");
    
    require(slashingPercentage > 0, "Slashing percentage must be greater than 0");

    uint256 slashAmount = (slashingPercentage * amount) / 100;
    require(slashAmount <= amount, "Slash amount exceeds staked balance");

    stakedBalance[staker] -= slashAmount;

    emit Slashed(staker, slashAmount);
}


    // Function to enable/disable slashing (can only be called by the DAO)
    function setSlashingEnabled(bool enabled) external  onlyDAO   {
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

interface ISimpleStaking{
    function slash(address staker) external;
    function getStakedBalance(address staker) external view returns (uint256); 
    function setSlashingParams (uint8 _percent) external;

}
