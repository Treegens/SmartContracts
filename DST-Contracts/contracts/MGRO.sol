// SPDX-License-Identifier: GPL
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MGRO is ERC20, Ownable {

    address public management;
    constructor()ERC20("MGRO", "MGRO"){
        
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
        require(balanceOf(_address)>=tokenAmt, "Not Enough tokens to burn");
        _burn(_address, tokenAmt);
    }
}

interface IMGro {

     function mintTokens(address _receiver, uint _tokens) external;
    function burnTokens(address _address, uint tokenAmt) external;
}