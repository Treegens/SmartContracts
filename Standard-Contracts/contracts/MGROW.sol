// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MGROW is ERC20, Ownable {

    address public management;
    constructor()ERC20("MGROW", "MGROW") Ownable(msg.sender){
        
            }

    modifier onlyManagement {
        require(msg.sender == management, "Unauthorized");
        _;  
    }

   
    function setManagementContract(address _address) public onlyOwner{
        require(_address != address(0));
        management = _address;
    }

    function mintTokens(address _receiver, uint _tokens) external  onlyManagement{
        require(_tokens > 0, "Invalid Token Number");
        _mint(_receiver, _tokens);

    }

    function burnTokens(address _address, uint tokenAmt) external onlyManagement {
        require(balanceOf(_address)>tokenAmt, "Not Enough tokens to burn");
        _burn(_address, tokenAmt);
    }
}

interface IMGrow {

     function mintTokens(address _receiver, uint _tokens) external;
    function burnTokens(address _address, uint tokenAmt) external;
}