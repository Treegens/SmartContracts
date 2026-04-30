// SPDX-License-Identifier: GPL
pragma solidity 0.8.28;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TGNVault is Ownable {
    // —— State ——
    address public slasher;
    address public treasury;

    IERC20 private immutable tgn;
    uint8 public immutable slashingPercentage;

    /// user deposits
    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public lastStakedTime;

    // —— Events ——
    event Staked(address indexed staker, uint256 amount);
    event Unstaked(address indexed staker, uint256 amount);
    event Slashed(address indexed staker, uint256 amount);
    event SlasherSet(address indexed oldSlasher, address indexed newSlasher);
    event TreasurySet(address indexed oldTreasury, address indexed newTreasury);

    // —— Errors ——
    error InvalidInput();
    error ApproveOrIncreaseAllowance();
    error InvalidSlashingAmount();
    error Unauthorized();
    error NotEnoughStake();
    error TokenTransferFailed();

    // —— Modifiers ——
    modifier onlySlasher() {
        if (msg.sender != slasher) revert Unauthorized();
        _;
    }

    // —— Constructor ——
    constructor(address _tgn, address _slasher, uint8 _slashingPercent, address _treasury) Ownable(msg.sender) {
        tgn = IERC20(_tgn);
        slasher = _slasher;
        treasury = _treasury;
        slashingPercentage = _slashingPercent;
    }

    // —— Owner configuration ——
    function setSlasher(address _address) external onlyOwner {
        if (_address == address(0)) revert InvalidInput();
        address oldSlasher = slasher;
        slasher = _address;
        emit SlasherSet(oldSlasher, _address);
    }

    function setTreasury(address _address) external onlyOwner {
        if (_address == address(0)) revert InvalidInput();
        address oldTreasury = treasury;
        treasury = _address;
        emit TreasurySet(oldTreasury, _address);
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

        stakedBalance[msg.sender] -= amount;

        bool ok = tgn.transfer(msg.sender, amount);
        if (!ok) revert TokenTransferFailed();

        emit Unstaked(msg.sender, amount);
    }

    // —— Slashing ——
    function slash(address staker) external onlySlasher {
        uint256 bal = stakedBalance[staker];
        if (bal == 0) revert InvalidSlashingAmount();

        uint256 slashAmt = (uint256(slashingPercentage) * bal) / 100;
        if (slashAmt > bal) revert InvalidSlashingAmount();

        stakedBalance[staker] = bal - slashAmt;

        bool ok = tgn.transfer(treasury, slashAmt);
        if (!ok) revert TokenTransferFailed();
        emit Slashed(staker, slashAmt);
    }

    // —— Views ——
    function getStakedBalance(address staker) external view returns (uint256) {
        return stakedBalance[staker];
    }

    function getLastStakedTime(address staker) external view returns (uint256) {
        return lastStakedTime[staker];
    }
}

interface ITGNVault {
    function slash(address) external;

    function getStakedBalance(address) external view returns (uint256);
}
