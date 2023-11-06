// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import { LibDiamond } from "../libraries/LibDiamond.sol";
import {MyToken}  from '../NFTMinter.sol';



contract ManagementFacet {
    
    function updateMinted(address _person ,uint256 _amountMinted) external {
        
        LibDiamond.DiamondStorage storage ds  = LibDiamond.diamondStorage();
        ds.totalMinted[_person]+=_amountMinted;


    }
    function updateBurnt(address _person, uint256 _amountBurnt) external {
         LibDiamond.DiamondStorage storage ds  = LibDiamond.diamondStorage();
         ds.totalBurnt[_person]+=_amountBurnt;
    }


    function updateURI(uint _tokenId) external {
         LibDiamond.DiamondStorage  storage ds  = LibDiamond.diamondStorage();
        address _owner = ds.token.ownerOf(_tokenId);
        (uint minted, uint burnt) = getTreeStats(_owner);

        //check which is greater between the 2 
        if(minted >burnt){
            setBrighterMind(minted, burnt);
        } else if(burnt > minted) {
            setBrighterHeart(minted, burnt);
        } else {
            setEquals(minted, burnt);
        }

        
        


    }
    function getTreeStats (address _address) public view returns (uint, uint) {
               LibDiamond.DiamondStorage  storage ds  = LibDiamond.diamondStorage();
               return (ds.totalMinted[_address], ds.totalBurnt[_address]);
        
    }

function setBrighterMind (uint minted, uint burnt) internal {

    //Set the baseURI to the one with brighter Mind than the heart
    
    //...

//calculate the proportionality, to see how much brighter the light is {2:1, 3:1, 4:1 & 5:1}
    uint proportion = calculateProportionality(minted, burnt);
    
    if(proportion == 2){
        //setImage to 2xBrighter mind
    }else if(proportion == 3){

    }else if (proportion == 4){

    }else {
        //if greater than 5, set to 5:1 
    }
   


}
function setBrighterHeart(uint minted, uint burnt) internal {
    uint proportion = calculateProportionality(burnt, minted);
    
    if(proportion == 2){
        //setImage to 2xBrighter mind
    }else if(proportion == 3){

    }else if (proportion == 4){

    }else {
        //if greater than 5, set to 5:1 
    }
}
function setEquals (uint minted, uint burnt) internal {
    if(minted == 0 && burnt==0  ){
        //NFT.updateURI(default URI With no Brightness)
    } else {
            
    }
    
}


// view function
function calculateProportionality(uint x, uint y) internal pure returns(uint) {

    uint z = x%y;
    uint proportionality = (x-z)/y;
    return proportionality;
}

function setMinterAddress (address _minter) external {
     LibDiamond.DiamondStorage  storage ds  = LibDiamond.diamondStorage();
     ds.token = MyToken(_minter);
}

}