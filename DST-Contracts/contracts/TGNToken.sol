// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract TGNToken is ERC20, Ownable, ERC20Permit, ERC20Votes {
  uint256 public maxSupply;
  mapping(address=>bool) public isTimelocked;
  mapping (address => uint) public transferLock;
    constructor()
        ERC20("TGNToken", "TGN")
        ERC20Permit("TGNToken")
    {
     maxSupply = 300000000 *10**18;
    }


    function mintWithTimelock(address to, uint256 amount, uint256 releaseDate) public onlyOwner {
     require(totalSupply() + amount <= maxSupply, "Exceeds max supply");
     require(releaseDate >block.timestamp, "Release Time cannot be less than current block time");
        _mint(to, amount);
        isTimelocked[to]=true;
        transferLock[to] = releaseDate;
    }

    //the addresses minted to can transfer tokens immediately
    function mint(address to, uint256 amount) public onlyOwner {
    require(totalSupply() + amount <= maxSupply, "Exceeds max supply");
    require(to != address(0), "Invalid Address"); // Check for a valid address
    require(amount != 0, "Invalid Amount"); // Check for a non-zero amount

    _mint(to, amount);
    isTimelocked[to] = false;
}


     function transfer(address to, uint256 amount) public virtual override returns (bool) {
       address owner = _msgSender();
       if(isTimelocked[owner] == true){
       require(transferLock[owner]<=block.timestamp, "Cannot transfer tokens till unlock time");
       }
        _transfer(owner, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
         if(isTimelocked[from]){
       require(transferLock[from]<=block.timestamp, "Cannot transfer tokens till unlock time");
       }
        _transfer(from, to, amount);
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


  //OWNER OVERRIDE OF TIMELOCK
  function overrideTimelock(address _address) external onlyOwner {
    require(isTimelocked[_address], "The address is already not on timelock");
    isTimelocked[_address] = false;
  }

}