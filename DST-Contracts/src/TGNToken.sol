// SPDX-License-Identifier: GPL
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TGNToken is Ownable, ERC20, ERC20Permit, ERC20Votes {
  error InvalidInput();
  uint256 public constant MAX_SUPPLY= 300000000 *10**18;

  mapping(address=>bool) public isTimelocked;
  mapping (address => uint) public transferLock;
    constructor()
        ERC20("TGNToken", "TGN")
        ERC20Permit("TGNToken")
        Ownable(msg.sender)
    {    }


    function mintWithTimelock(address to, uint256 amount, uint256 releaseDate) public onlyOwner {
     if(to==address(0)|| amount == 0) revert InvalidInput();
     require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds max supply");
     require(releaseDate >block.timestamp, "Release Time cannot be less than current block time");
        _mint(to, amount);
        isTimelocked[to]=true;
        transferLock[to] = releaseDate;
    }

    //the addresses minted to can transfer tokens immediately
    function mint(address to, uint256 amount) public onlyOwner {
    require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds max supply");
    require(to != address(0), "Invalid Address"); // Check for a valid address
    require(amount != 0, "Invalid Amount"); // Check for a non-zero amount

    _mint(to, amount);
    // isTimelocked[to] = false;
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
         if(isTimelocked[from]==true){
       require(transferLock[from]<=block.timestamp, "Cannot transfer tokens till unlock time");
       }
        // _transfer(from, to, amount);
        super.transferFrom(from, to, amount);
        return true;
    }

    // OpenZeppelin v5: override the unified _update hook for ERC20Votes
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    // OZ v5: disambiguate Nonces.nonces vs ERC20Permit nonces via override
    function nonces(address owner)
        public
        view
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(owner);
    }


  //OWNER OVERRIDE OF TIMELOCK
  function overrideTimelock(address _address) external onlyOwner {
    require(isTimelocked[_address], "The address is already not on timelock");
    isTimelocked[_address] = false;
  }

}