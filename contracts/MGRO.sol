// SPDX-License-Identifier: GPL
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IMGRO.sol";

/**
 * @title MGRO
 * @author Treegens Foundation
 * @notice This contract is the main entry point for MGRO token.
 *          It allows for minting and burning of the token.
 */
contract MGRO is ERC20, AccessControl, IMGRO {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    error MGRO__InvalidInput();

    constructor() ERC20("MGRO", "MGRO") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @inheritdoc IMGRO
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _validateInput(to, amount);
        _mint(to, amount);
    }

    /// @inheritdoc IMGRO
    function burn(address from, uint256 amount) external onlyRole(BURNER_ROLE) {
        _validateInput(from, amount);
        _burn(from, amount);
    }

    function _validateInput(address to, uint256 amount) internal pure {
        if (to == address(0) || amount == 0) revert MGRO__InvalidInput();
    }
}
