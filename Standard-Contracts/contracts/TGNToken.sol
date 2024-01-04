// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract TGNToken is ERC20, Ownable, ERC20Permit, ERC20Votes {
  uint public maxSupply;
  mapping (address => uint) public transferLock;
    constructor()
        ERC20("TGNToken", "TGN")
        ERC20Permit("TGNToken")
    {
     maxSupply = 300000000 *10**18;
    }

    function mintWithTimeLock(address to, uint256 amount, uint256 releaseDate) public onlyOwner {
     require(totalSupply() + amount <= maxSupply, "Exceeds max supply");
     require(releaseDate >block.timestamp, "Release Time cannot be less than current block time");
        _mint(to, amount);
        transferLock[to] = releaseDate;
    }

     function transfer(address to, uint256 amount) public virtual override returns (bool) {
       address owner = _msgSender();
       require(transferLock[owner]<=block.timestamp, "Cannot transfer tokens till unlock time");
        _transfer(owner, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        require(transferLock[from]<=block.timestamp, "Cannot transfer tokens till unlock time");
        super.transferFrom(from,to, amount);
        return true;
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