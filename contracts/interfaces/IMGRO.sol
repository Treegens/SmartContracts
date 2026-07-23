// SPDX-License-Identifier: GPL
pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

/**
 * @title IMGRO
 * @notice External interface for the MGRO ERC20 token.
 * @dev Combines standard ERC20 transfers with EIP-2612 permit, role-gated mint, and permissionless burn.
 *
 * Access is managed through {IAccessControl}. The MGRO implementation defines:
 * - `MINTER_ROLE` — required to call {mint}
 * - `DEFAULT_ADMIN_ROLE` — grants and revokes `MINTER_ROLE`
 */
interface IMGRO is IERC20, IERC20Permit, IAccessControl {
    /**
     * @notice Maximum outstanding MGRO supply (1 billion tokens, 18 decimals).
     */
    function MAX_SUPPLY() external view returns (uint256);

    /**
     * @notice Returns the cap on the token's total supply.
     */
    function cap() external view returns (uint256);

    /**
     * @notice Mints new MGRO tokens to `to`.
     * @dev Emits a {IERC20-Transfer} event with `from` set to the zero address.
     * @param to Recipient of the newly minted tokens.
     * @param amount Number of tokens to mint, in the token's smallest unit (wei).
     *
     * Requirements:
     * - Caller must have `MINTER_ROLE`.
     * - `to` must not be the zero address.
     * - `amount` must be greater than zero.
     * - `totalSupply() + amount` must not exceed {cap}.
     */
    function mint(address to, uint256 amount) external;

    /**
     * @notice Burns MGRO tokens from the caller's balance.
     * @dev Emits a {IERC20-Transfer} event with `to` set to the zero address.
     * @param amount Number of tokens to burn, in the token's smallest unit (wei).
     *
     * Requirements:
     * - Caller must have a balance of at least `amount`.
     */
    function burn(uint256 amount) external;

    /**
     * @notice Burns MGRO tokens from `account`, spending the caller's allowance.
     * @dev Emits a {IERC20-Transfer} event with `to` set to the zero address.
     * @param account Account whose balance is reduced.
     * @param amount Number of tokens to burn, in the token's smallest unit (wei).
     *
     * Requirements:
     * - Caller must have allowance for `account` of at least `amount`.
     * - `account` must have a balance of at least `amount`.
     */
    function burnFrom(address account, uint256 amount) external;
}
