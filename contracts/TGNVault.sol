// SPDX-License-Identifier: GPL
pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ITGNVault.sol";

/**
 * @title TGNVault
 * @author Treegens Foundation
 * @notice Staking vault for TGN with role-gated slashing.
 */
contract TGNVault is AccessControl, ITGNVault {
    bytes32 public constant SLASHER_ROLE = keccak256("SLASHER_ROLE");

    IERC20 private immutable tgn;
    uint8 public immutable slashingPercentage;
    address public treasury;

    mapping(address => uint256) public stakedBalance;
    mapping(address => uint256) public lastStakedTime;

    event Staked(address indexed staker, uint256 amount);
    event Unstaked(address indexed staker, uint256 amount);
    event Slashed(address indexed staker, uint256 amount);
    event TreasurySet(address indexed oldTreasury, address indexed newTreasury);

    error TGNVault__InvalidInput();
    error TGNVault__ApproveOrIncreaseAllowance();
    error TGNVault__InvalidSlashingAmount();
    error TGNVault__NotEnoughStake();
    error TGNVault__TokenTransferFailed();

    constructor(address _admin, address _tgn, address _slasher, uint8 _slashingPercent, address _treasury) {
        if (_admin == address(0) || _tgn == address(0) || _slasher == address(0) || _treasury == address(0)) {
            revert TGNVault__InvalidInput();
        }
        if (_slashingPercent > 100) revert TGNVault__InvalidInput();

        tgn = IERC20(_tgn);
        treasury = _treasury;
        slashingPercentage = _slashingPercent;

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(SLASHER_ROLE, _slasher);
    }

    /// @inheritdoc ITGNVault
    function setTreasury(address _treasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_treasury == address(0)) revert TGNVault__InvalidInput();
        address oldTreasury = treasury;
        treasury = _treasury;
        emit TreasurySet(oldTreasury, _treasury);
    }

    /// @inheritdoc ITGNVault
    function stake(uint256 amount) external {
        if (amount == 0) revert TGNVault__InvalidInput();
        if (tgn.allowance(msg.sender, address(this)) < amount) {
            revert TGNVault__ApproveOrIncreaseAllowance();
        }
        if (!tgn.transferFrom(msg.sender, address(this), amount)) {
            revert TGNVault__TokenTransferFailed();
        }

        stakedBalance[msg.sender] += amount;
        lastStakedTime[msg.sender] = block.timestamp;

        emit Staked(msg.sender, amount);
    }

    /// @inheritdoc ITGNVault
    function unstake(uint256 amount) external {
        if (amount == 0) revert TGNVault__InvalidInput();
        if (stakedBalance[msg.sender] < amount) revert TGNVault__NotEnoughStake();

        stakedBalance[msg.sender] -= amount;

        if (!tgn.transfer(msg.sender, amount)) revert TGNVault__TokenTransferFailed();

        emit Unstaked(msg.sender, amount);
    }

    /// @inheritdoc ITGNVault
    function slash(address staker) external onlyRole(SLASHER_ROLE) {
        uint256 bal = stakedBalance[staker];
        if (bal == 0) revert TGNVault__InvalidSlashingAmount();

        uint256 slashAmt = (uint256(slashingPercentage) * bal) / 100;
        stakedBalance[staker] = bal - slashAmt;

        if (!tgn.transfer(treasury, slashAmt)) revert TGNVault__TokenTransferFailed();

        emit Slashed(staker, slashAmt);
    }

    /// @inheritdoc ITGNVault
    function getStakedBalance(address staker) external view returns (uint256) {
        return stakedBalance[staker];
    }

    /// @inheritdoc ITGNVault
    function getLastStakedTime(address staker) external view returns (uint256) {
        return lastStakedTime[staker];
    }
}
