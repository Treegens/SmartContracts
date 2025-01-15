// SPDX-License-Identifier: GPL
pragma solidity 0.8.17;

import { LibDiamond } from "../libraries/LibDiamond.sol";
import "../MGRO.sol";
import "../NFTMinter.sol";

contract ManagementFacet {
    // event LogImgNo(uint256);
    // event LogBaseURI(string);
    

    modifier onlyOwner {
         LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        if(msg.sender != ds.contractOwner) revert();
        _;
    }

   function initialize(address _minter, address _token  , address _dao) external  {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(ds.count == 0, " Can only be run once");
        require(_minter != address(0) || _token != address(0)  || _dao != address(0), "Invalid Addresses");
        
    
       // owner = msg.sender;
        ds.mgro = IMGro(_token);
        ds.minter = IMinter(_minter);
        ds.dao = _dao;
        ds.nftCount = 0;
        ds.count++;
    }
    // Function to add base URI
    function addBaseURI(string memory _URI) external onlyOwner {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(ds.baseURIs.length < 3, "Cannot have more than 3 URIs");
        ds.baseURIs.push(_URI);
    }

    // Function to check the number of NFTs owned by a user
    function checkUserNFTs(address _user) external view returns (uint) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.userNFTs[_user].length;
    }
     // Function to check the number of base URIs
    function checklength() external view returns (uint) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.baseURIs.length;
    }

    // Function to check minted and burnt tokens for an address
    function checkStats(address _address) public view returns (uint256 _minted, uint256 _burnt) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        _minted = ds.minted[_address];
        _burnt = ds.burnt[_address];
        return (_minted, _burnt);
    }


    function mintTokens(address _receiver, uint256 _tokens) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(msg.sender == ds.dao, "Only the DAO can mint MGRO tokens");
        uint256 token = _tokens * 10 **18;
        ds.mgro.mintTokens(_receiver, token);
        ds.minted[_receiver] += _tokens;
    }

    function burnTokens(uint256 _tokens) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 token = _tokens *10 **18;
        ds.mgro.burnTokens(msg.sender, token);
        ds.burnt[msg.sender] += _tokens;
    }

    function mintNFTs() external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(msg.sender == ds.dao, "Only the DAO can mint NFTs");
        uint256 nftId = ++ds.nftCount;
        string memory _uri = string(abi.encodePacked(ds.baseURIs[0],'1'));
        ds.minter.safeMint(msg.sender, nftId);
        ds.minter.updateURI(nftId, _uri);
        ds.userNFTs[msg.sender].push(nftId);
    }

    // Function to update NFTs based on user statistics
    function updateNFTs(address _address) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint[] memory tokens = ds.userNFTs[_address];
        (uint256 _minted, uint256 _burnt) = checkStats(_address);
        string storage _baseURI;

    uint256 total = _minted + _burnt;
    uint256 percentageX = ( _minted * 100) / total;
    uint256 percentageY = ( _burnt * 100) / total;

    // Round percentages to the nearest 10%
    uint256 roundedX = roundToNearestTen(percentageX);
    uint256 roundedY = roundToNearestTen(percentageY);


        if (roundedX == roundedY) {
            string memory _URI;
            _baseURI = ds.baseURIs[0];
           if(_minted > 0 ){
            _URI = string(abi.encodePacked(_baseURI, Strings.toString(2)));
           }else {
            _URI = string(abi.encodePacked(_baseURI,Strings.toString(1)));
           }

            _setURIs(tokens, _URI);

        } else if (roundedX > roundedY) {
            _baseURI = ds.baseURIs[1];
            _setURI(_baseURI, roundedX, roundedY, tokens);
        } else {
            _baseURI = ds.baseURIs[2];
            _setURI(_baseURI, roundedY, roundedX, tokens);
        }
    }

// Function to set URIs for multiple tokens
    function _setURIs(uint[] memory _tokenIds, string memory uri) internal {
           LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 len = _tokenIds.length;
        for (uint256 i = 0; i < len; i++) {
            uint256 _token = _tokenIds[i];
            ds.minter.updateURI(_token, uri);
        }
    }

    //Get the Percentages from the closest 10%
    function _setURI(string memory _baseURI, uint256 x, uint256 y, uint[] memory tokens) internal {
    LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

    uint256 imgNo;
    string memory _base; 

  

    // Log values for debugging
   // emit LogValues(roundedX, roundedY); // Add an event LogValues(uint256 x, uint256 y) to your contract

    //img 1
    if (x == 100 && y == 0) {
        _base = _baseURI;
        imgNo = 1;
    }
    //img2 
    else if (x == 90 && y == 10) {
        _base = _baseURI;
        imgNo = 2;
    }
    //img3
    else if (x == 80 && y == 20) {
        _base = _baseURI;
        imgNo = 3;
    }
    //img4
    else if (x == 70 && y == 30) {
        _base = _baseURI;
        imgNo = 4;
    }
    //img5
    else if (x == 60 && y == 40) {
        _base = _baseURI;
        imgNo = 5;
    }
    // 50/50  case (Rounded)
    else {
        _base = ds.baseURIs[0];
        imgNo = 2;

    }

    // Log imgNo for debugging
   // emit LogImgNo(imgNo); // Add an event LogImgNo(uint256 imgNo) to your contract

    string memory props = Strings.toString(imgNo);
    string memory finalURI;

    // Log values for debugging
   

    finalURI = string(abi.encodePacked(_base, props));
   // emit LogBaseURI(_baseURI); // Add an event LogBaseURI(string _baseURI) to your contract
    _setURIs(tokens, finalURI);

}

    function roundToNearestTen(uint256 value) internal pure returns (uint256) {
        uint256 remainder = value % 10;
        if (remainder >= 5) {
            // Round up to the nearest 10%
            return value + (10 - remainder);
        } else {
            // Round down to the nearest 10%
            return value - remainder;
        }
    }
}

    // Function to set URI based on user statistics
    // function _setURI(string memory _baseURI, uint256 x, uint256 y, uint[] memory tokens) internal {
    //     uint256 imageID = getImageId(x);

    //     uint256 prop = 1; 

    //     if (x > 0 && y > 0){
    //     uint256 z = x % y;
    //     prop = (x - z) / y;
    //     }

    //     if (prop > 5) {
    //         prop = 5;
    //     }
        
        
    //     string memory props = Strings.toString(prop);
    //     string memory finalURI;
    //     if(x!=y){
    //     finalURI = string(abi.encodePacked(_baseURI,props, '/', Strings.toString(imageID)));
    //     }else if(x == y) {
    //          finalURI = string(abi.encodePacked(_baseURI,Strings.toString(imageID)));
    //     }
    //     _setURIs(tokens, finalURI);
    // }

    // // Function to determine the image ID based on a value
    // function getImageId(uint256 x) internal pure returns (uint256 imageID) {
    //     uint256 _x = x / 1 ether;
    //     if (_x <= 50) {
    //         imageID = 1;
    //     } else if (_x <= 100) {
    //         imageID = 2;
    //     } else if (_x <= 150) {
    //         imageID = 3;
    //     } else if (_x <= 200) {
    //         imageID = 4;
    //     } else {
    //         imageID = 5;
    //     } 
    // }
