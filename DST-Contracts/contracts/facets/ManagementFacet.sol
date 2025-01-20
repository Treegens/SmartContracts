// SPDX-License-Identifier: GPL
pragma solidity 0.8.17;

import { LibDiamond } from "../libraries/LibDiamond.sol";
import "../MGRO.sol";
import "../NFTMinter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// Make sure you have the Strings library imported if not already:
import "@openzeppelin/contracts/utils/Strings.sol";

contract ManagementFacet {
    /* ------------------------------------------------------------------------
       EVENTS
    --------------------------------------------------------------------------*/
    event LogImgNo(uint256 imgNo);
    event LogBaseURI(string baseURI);
    event LogValues(uint256 x, uint256 y); // for debugging percentages

    /* ------------------------------------------------------------------------
       MODIFIERS
    --------------------------------------------------------------------------*/
    modifier onlyOwner {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        if (msg.sender != ds.contractOwner) revert();
        _;
    }

    /* ------------------------------------------------------------------------
       FUNCTIONS
    --------------------------------------------------------------------------*/

    function initialize(
        address _minter, 
        address _token, 
        address _dao, 
        address _buyToken
    ) 
        external  
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(ds.count == 0, "Can only be run once");
        require(
            _minter != address(0) || 
            _token  != address(0) || 
            _dao    != address(0),
            "Invalid Addresses"
        );

        ds.mgro      = IMGro(_token);
        ds.minter    = IMinter(_minter);
        ds.buyToken  = IERC20(_buyToken);
        ds.dao       = _dao;
        ds.nftCount  = 0;
        ds.count++;
    }

    function setFeeCollector(address _address) external {
        require(_address != address(0), "Invalid Address");
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(msg.sender == ds.dao, "Fee collector can be changed only via DAO");
        ds.feeCollector = _address;
    }

    function setPurchaseToken(address _token) external {
        require(_token != address(0), "Invalid Token");
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(msg.sender == ds.dao, "Purchase token can be changed only via DAO");
        ds.buyToken = IERC20(_token);
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

        uint256 token = _tokens * 10**18;
        ds.mgro.mintTokens(_receiver, token);
        ds.minted[_receiver] += _tokens;
    }

    function burnTokens(uint256 _tokens) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 token = _tokens * 10**18;
        ds.mgro.burnTokens(msg.sender, token);
        ds.burnt[msg.sender] += _tokens;
    }

    function mintNFT() external onlyOwner {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 nftId = ++ds.nftCount;
        string memory _uri = string(abi.encodePacked(ds.baseURIs[0], "1"));
        ds.minter.safeMint(msg.sender, nftId);
        ds.minter.updateURI(nftId, _uri);
        ds.userNFTs[msg.sender].push(nftId);
    }

    function mintNFTasUser() external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint price = ds.nftPrice;
        require(ds.buyToken.balanceOf(msg.sender) > price, "Insufficient Balance");
        require(ds.buyToken.allowance(msg.sender, address(this)) >= price, "Insufficient Allowance");

        ds.buyToken.transferFrom(msg.sender, ds.feeCollector, price);

        uint256 nftId = ++ds.nftCount;
        string memory _uri = string(abi.encodePacked(ds.baseURIs[0], "1"));
        ds.minter.safeMint(msg.sender, nftId);
        ds.minter.updateURI(nftId, _uri);
        ds.userNFTs[msg.sender].push(nftId);
    }

    // Function to update NFTs based on user statistics
    function updateNFTs(address _address) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint[] memory tokens = ds.userNFTs[_address];
        (uint256 _minted, uint256 _burnt) = checkStats(_address);

        // Avoid division by zero if minted+burnt == 0
        uint256 total = _minted + _burnt;
        if (total == 0) {
            // If user has no minted or burnt history, simply skip or default to baseURIs[0]
            return;
        }

        uint256 percentageX = (_minted * 100) / total;
        uint256 percentageY = (_burnt * 100) / total;

        // Round percentages to the nearest 10%
        uint256 roundedX = roundToNearestTen(percentageX);
        uint256 roundedY = roundToNearestTen(percentageY);

        // Log the final (rounded) percentages
        emit LogValues(roundedX, roundedY);

        string storage _baseURI;

        if (roundedX == roundedY) {
            // If minted/burnt percentages match after rounding
            _baseURI = ds.baseURIs[0];
            string memory _URI;
            if(_minted > 0) {
                _URI = string(abi.encodePacked(_baseURI, Strings.toString(2)));
            } else {
                _URI = string(abi.encodePacked(_baseURI, Strings.toString(1)));
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

    /* ------------------------------------------------------------------------
       INTERNAL / PRIVATE HELPERS
    --------------------------------------------------------------------------*/

    // Function to set URIs for multiple tokens
    function _setURIs(uint[] memory _tokenIds, string memory uri) internal {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 len = _tokenIds.length;
        for (uint256 i = 0; i < len; i++) {
            uint256 _token = _tokenIds[i];
            ds.minter.updateURI(_token, uri);
        }
    }

    // Decide which image to pick from the baseURI
    function _setURI(
        string memory _baseURI, 
        uint256 x, 
        uint256 y, 
        uint[] memory tokens
    ) 
        internal 
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        // First, log the x and y we received for debugging:
        emit LogValues(x, y);

        uint256 imgNo;
        string memory _base;

        // Cases for minted:burnt ratio images
        if (x == 100 && y == 0) {
            _base = _baseURI;
            imgNo = 1;
        } 
        else if (x == 90 && y == 10) {
            _base = _baseURI;
            imgNo = 2;
        } 
        else if (x == 80 && y == 20) {
            _base = _baseURI;
            imgNo = 3;
        } 
        else if (x == 70 && y == 30) {
            _base = _baseURI;
            imgNo = 4;
        } 
        else if (x == 60 && y == 40) {
            _base = _baseURI;
            imgNo = 5;
        } 
        // 50/50 or any leftover rounding scenario
        else {
            _base = ds.baseURIs[0];
            imgNo = 2;
        }

        // Log the image number chosen
        emit LogImgNo(imgNo);
        // Log the base URI chosen
        emit LogBaseURI(_base);

        // Construct final URI and update tokens
        string memory props = Strings.toString(imgNo);
        string memory finalURI = string(abi.encodePacked(_base, props));
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
