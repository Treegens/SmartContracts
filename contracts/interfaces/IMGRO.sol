// SPDX-License-Identifier: GPL
pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IMGRO
 * @notice External interface for the MGRO ERC20 token.
 * @dev Combines standard ERC20 transfers with role-gated mint and burn.
 *
 * Access is managed through {IAccessControl}. The MGRO implementation defines:
 * - `MINTER_ROLE` — required to call {mint}
 * - `BURNER_ROLE` — required to call {burn}
 * - `DEFAULT_ADMIN_ROLE` — grants and revokes the roles above
 */
interface IMGRO is IERC20, IAccessControl {
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
     */
    function mint(address to, uint256 amount) external;

    /**
     * @notice Burns MGRO tokens from `from` without spending an allowance.
     * @dev Emits a {IERC20-Transfer} event with `to` set to the zero address.
     * @param from Account whose balance is reduced.
     * @param amount Number of tokens to burn, in the token's smallest unit (wei).
     *
     * Requirements:
     * - Caller must have `BURNER_ROLE`.
     * - `from` must not be the zero address.
     * - `amount` must be greater than zero.
     * - `from` must have a balance of at least `amount`.
     */
    function burn(address from, uint256 amount) external;
}
