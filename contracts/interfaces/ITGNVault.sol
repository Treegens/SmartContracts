// SPDX-License-Identifier: GPL
pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/IAccessControl.sol";

/**
 * @title ITGNVault
 * @notice External interface for the TGN staking vault.
 * @dev Staking is permissionless; slashing and treasury configuration are role-gated.
 *
 * Access is managed through {IAccessControl}. The TGNVault implementation defines:
 * - `SLASHER_ROLE` — required to call {slash}
 * - `DEFAULT_ADMIN_ROLE` — grants and revokes `SLASHER_ROLE` and may call {setTreasury}
 */
interface ITGNVault is IAccessControl {
    /**
     * @notice Stakes `amount` of TGN from the caller into the vault.
     * @param amount Number of TGN tokens to stake, in the token's smallest unit (wei).
     *
     * Requirements:
     * - `amount` must be greater than zero.
     * - Caller must have approved the vault for at least `amount`.
     */
    function stake(uint256 amount) external;

    /**
     * @notice Unstakes `amount` of TGN back to the caller.
     * @param amount Number of TGN tokens to withdraw, in the token's smallest unit (wei).
     *
     * Requirements:
     * - `amount` must be greater than zero.
     * - Caller must have at least `amount` staked.
     */
    function unstake(uint256 amount) external;

    /**
     * @notice Slashes a percentage of a staker's balance and sends it to the treasury.
     * @param staker Account whose stake is reduced.
     *
     * Requirements:
     * - Caller must have `SLASHER_ROLE`.
     * - `staker` must have a non-zero staked balance.
     */
    function slash(address staker) external;

    /**
     * @notice Updates the treasury address that receives slashed TGN.
     * @param treasury New treasury recipient.
     *
     * Requirements:
     * - Caller must have `DEFAULT_ADMIN_ROLE`.
     * - `treasury` must not be the zero address.
     */
    function setTreasury(address treasury) external;

    /**
     * @notice Returns the amount of TGN a staker currently has in the vault.
     * @param staker Account to query.
     */
    function getStakedBalance(address staker) external view returns (uint256);

    /**
     * @notice Returns the timestamp of a staker's most recent stake deposit.
     * @param staker Account to query.
     */
    function getLastStakedTime(address staker) external view returns (uint256);
}
