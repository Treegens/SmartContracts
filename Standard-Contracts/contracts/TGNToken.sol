// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract TGNToken is ERC20, Ownable, ERC20Permit, ERC20Votes {
  uint public maxSupply;
    constructor(address initialOwner)
        ERC20("TGNToken", "TGN")
        Ownable(initialOwner)
        ERC20Permit("TGNToken")
    {
     maxSupply = 300000000 *10**18;
    }

    function mint(address to, uint256 amount) public onlyOwner {
     require(totalSupply() + amount <= maxSupply, "Exceeds max supply");
        _mint(to, amount);
    }

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Votes)
    {
        super._update(from, to, value);
    }

    function nonces(address owner)
        public
        view
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(owner);
    }
}