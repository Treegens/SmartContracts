// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20;

import { LibDiamond } from "../libraries/LibDiamond.sol";
import "../MGRO.sol";
import "../NFTMinter.sol";

contract ManagementFacet {
    IMGrow private mgrow;
    IMinter private minter;

   function initialize(address _minter, address _token, address _dao) external {
        require(_minter != address(0) || _token != address(0) || _dao != address(0), "Invalid Addresses");
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        mgrow = IMGrow(_token);
        minter = IMinter(_minter);
        ds.dao = _dao;
        ds.nftCount = 0;
    }
    // Function to add base URI
    function addBaseURI(string memory _URI) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(ds.baseURIs.length < 3, "Cannot have more than 3 URIs");
        ds.baseURIs.push(_URI);
    }

    // Function to check the number of NFTs owned by a user
    function checkUserNFTs(address _user) public view returns (uint) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.userNFTs[_user].length;
    }
     // Function to check the number of base URIs
    function checklength() public view returns (uint) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.baseURIs.length;
    }

    // Function to check minted and burnt tokens for an address
    function checkStats(address _address) public view returns (uint _minted, uint _burnt) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        _minted = ds.minted[_address];
        _burnt = ds.burnt[_address];
        return (_minted, _burnt);
    }


    function mintTokens(address _receiver, uint _tokens) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        mgrow.mintTokens(_receiver, _tokens);
        ds.minted[_receiver] += _tokens;
    }

    function burnTokens(uint _tokens) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        mgrow.burnTokens(msg.sender, _tokens);
        ds.burnt[msg.sender] += _tokens;
    }

    function mintNFTs() external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint nftId = ++ds.nftCount;
        string memory _uri = ds.baseURIs[0];
        minter.safeMint(msg.sender, nftId);
        minter.updateURI(nftId, _uri);
        ds.userNFTs[msg.sender].push(nftId);
    }

    // Function to update NFTs based on user statistics
    function updateNFTs(address _address) public {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint[] memory tokens = ds.userNFTs[_address];
        (uint _minted, uint _burnt) = checkStats(_address);
        string storage _baseURI;

        if (_minted == _burnt) {
            _baseURI = ds.baseURIs[0];
            setURIs(tokens, _baseURI);
        } else if (_minted > _burnt) {
            _baseURI = ds.baseURIs[1];
            _setURI(_baseURI, _minted, _burnt, tokens);
        } else {
            _baseURI = ds.baseURIs[2];
            _setURI(_baseURI, _burnt, _minted, tokens);
        }
    }

// Function to set URIs for multiple tokens
    function setURIs(uint[] memory _tokenIds, string memory uri) internal {
        uint len = _tokenIds.length;
        for (uint i = 0; i < len; i++) {
            uint _token = _tokenIds[i];
            minter.updateURI(_token, uri);
        }
    }

    // Function to set URI based on user statistics
    function _setURI(string memory _baseURI, uint x, uint y, uint[] memory tokens) internal {
        uint imageID = getImageId(x);
        uint z = x % y;
        uint prop = (x - z) / y;

        if (prop > 5) {
            prop = 5;
        }
        string memory props = Strings.toString(prop);
        string memory finalURI;

        finalURI = string(abi.encodePacked(_baseURI, props, '/', Strings.toString(imageID)));
        setURIs(tokens, finalURI);
    }

    // Function to determine the image ID based on a value
    function getImageId(uint x) internal pure returns (uint imageID) {
        uint _x = x / 1 ether;
        if (_x <= 50) {
            imageID = 1;
        } else if (_x <= 100) {
            imageID = 2;
        } else if (_x <= 150) {
            imageID = 3;
        } else if (_x <= 200) {
            imageID = 4;
        } else {
            imageID = 5;
        } 
    }
}