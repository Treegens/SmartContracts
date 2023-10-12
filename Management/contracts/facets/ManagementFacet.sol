// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import { LibDiamond } from "../libraries/LibDiamond.sol";

contract ManagementFacet {
    
    function updateMinted(address _person ,uint256 _amountMinted) external {
        
        LibDiamond.DiamondStorage storage ds  = LibDiamond.diamondStorage();
        ds.totalMinted[_person]+=_amountMinted;


    }
    function updateBurnt(address _person, uint256 _amountBurnt) external {
         LibDiamond.DiamondStorage storage ds  = LibDiamond.diamondStorage();
         ds.totalBurnt[_person]+=_amountBurnt;
    }

    function updateURI() external {


    }
    function getTreeStats (address _address) public view returns (uint, uint) {
               LibDiamond.DiamondStorage  storage ds  = LibDiamond.diamondStorage();
               return (ds.totalMinted[_address], ds.totalBurnt[_address]);
        
    }


}