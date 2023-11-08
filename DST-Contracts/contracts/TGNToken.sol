// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract TGNToken is ERC20, Ownable, ERC20Permit, ERC20Votes {
  uint public maxSupply;
    constructor()
        ERC20("TGNToken", "TGN")
        ERC20Permit("TGNToken")
    {
     maxSupply = 300000000 *10**18;
    }

    function mint(address to, uint256 amount) public onlyOwner {
     require(totalSupply() + amount <= maxSupply, "Exceeds max supply");
        _mint(to, amount);
    }

    // The following functions are overrides required by Solidity.

   function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(ERC20, ERC20Votes) {
    super._afterTokenTransfer(from, to, amount);
  }
  
   function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
    super._mint(to, amount);
  }

  function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
    super._burn(account, amount);
  }

}