// SPDX-License-Identifier: GPL
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IMGRO.sol";

/**
 * @title MGRO
 * @author Treegens Foundation
 * @notice ERC20 reward token with a 1B supply cap, EIP-2612 permit, role-gated mint, and permissionless burn.
 */
contract MGRO is ERC20Capped, ERC20Burnable, ERC20Permit, AccessControl, IMGRO {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 1 ether;

    error MGRO__InvalidInput();

    constructor(address _admin) ERC20("MGRO", "MGRO") ERC20Capped(MAX_SUPPLY) ERC20Permit("MGRO") {
        if (_admin == address(0)) revert MGRO__InvalidInput();
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /// @inheritdoc IMGRO
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        if (to == address(0) || amount == 0) revert MGRO__InvalidInput();
        _mint(to, amount);
    }

    /// @inheritdoc IMGRO
    function burn(uint256 amount) public override(ERC20Burnable, IMGRO) {
        super.burn(amount);
    }

    /// @inheritdoc IMGRO
    function burnFrom(address account, uint256 amount) public override(ERC20Burnable, IMGRO) {
        super.burnFrom(account, amount);
    }

    /// @inheritdoc IMGRO
    function cap() public view override(ERC20Capped, IMGRO) returns (uint256) {
        return super.cap();
    }

    /// @inheritdoc IERC20Permit
    function nonces(address owner) public view override(ERC20Permit, IERC20Permit) returns (uint256) {
        return super.nonces(owner);
    }

    function _update(address from, address to, uint256 value) internal virtual override(ERC20, ERC20Capped) {
        super._update(from, to, value);
    }
}
