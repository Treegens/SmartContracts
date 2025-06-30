// SPDX-License-Identifier: GPL
pragma solidity 0.8.17;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import "../MGRO.sol";
import "../NFTMinter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ManagementFacet {
    /* ------------------------------------------------------------------------
       EVENTS
    --------------------------------------------------------------------------*/
    event LogImgNo(uint256 imgNo);
    event LogBaseURI(string baseURI);
    event LogValues(uint256 x, uint256 y);
    event NFTPurchased(address, uint, uint);


    /* ------------------------------------------------------------------------
       FUNCTIONS
    --------------------------------------------------------------------------*/

    function initialize(address _minter, address _token, address _dao, address _buyToken) external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(ds.count == 0, "Can only be run once");
        require(_minter != address(0) , "Invalid minter Address");
        require(_dao != address(0), "Invalid DAO Address");
        require(_token != address(0), "Invalid MGRO token Address");
        require(_buyToken != address(0), "Invalid Purchasing token Address");

        ds.mgro = IMGro(_token);
        ds.minter = IMinter(_minter);
        ds.buyToken = IERC20(_buyToken);
        ds.dao = _dao;
        ds.nftCount = 0;
        ds.count++;
    }

    function setFeeCollector(address _address) external {
        require(_address != address(0), "Invalid Address");
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(msg.sender == ds.dao, "Fee collector can be changed only via DAO");
        ds.feeCollector = _address;
    }


    function setPurchaseToken(address _token, uint256 _price) external {
        require(_token != address(0), "Invalid Token");
        require(_price != 0, "Set a valid Price");
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(msg.sender == ds.dao, "Purchase token can be changed only via DAO");
        ds.buyToken = IERC20(_token);
        ds.nftPrice = _price;
    }
     function setVerificationContract(address _address) external {
        require(_address != address(0), "Invalid Address");
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.mgroVerification = _address;
    }

    // Function to add base URI
    function addBaseURI(string memory _URI) external  {
        LibDiamond.enforceIsContractOwner();
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

    function mintMgroTokens(address _receiver, uint256 _tokens) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(msg.sender == ds.mgroVerification, "Only the Verification Contract can mint MGRO tokens");
        uint256 token = _tokens * 10 ** 18;
        ds.mgro.mintTokens(_receiver, token);
        ds.minted[_receiver] += _tokens;
    }

    function burnTokens(uint256 _tokens) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 token = _tokens * 10 ** 18;
        ds.mgro.burnTokens(msg.sender, token);
        ds.burnt[msg.sender] += _tokens;
    }

    function mintNFT(address _address) external  {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(ds.baseURIs.length >0, "No URIs active");
        uint256 nftId = ++ds.nftCount;
        string memory _uri = string(abi.encodePacked(ds.baseURIs[0], "1"));
        ds.userNFTs[_address].push(nftId);
        ds.minter.safeMint(_address, nftId);
        ds.minter.updateURI(nftId, _uri);
    }

function mintNFTasUser() external {
    LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

    uint256 price = ds.nftPrice;
    if (price == 0) revert("Not yet active");
    require(ds.baseURIs.length > 0, "No baseURI");
    require(ds.feeCollector != address(0), "Fee collector not set");

    require(ds.buyToken.balanceOf(msg.sender) >= price, "Insufficient balance");
    require(ds.buyToken.allowance(msg.sender, address(this)) >= price, "Insufficient allowance");

    // --- effects ---
    uint256 nftId = ++ds.nftCount;
    ds.userNFTs[msg.sender].push(nftId);

    // --- interactions ---
    bool ok = ds.buyToken.transferFrom(msg.sender, ds.feeCollector, price);
    require(ok, "Token transfer failed");

    string memory uri = string(abi.encodePacked(ds.baseURIs[0], "1"));
    ds.minter.safeMint(msg.sender, nftId);
    ds.minter.updateURI(nftId, uri);

    emit NFTPurchased(msg.sender, nftId, price);
}


    // Function to update NFTs based on user statistics
    function updateNFTs(address _address, string memory uri) external  {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
         LibDiamond.enforceIsContractOwner();
        uint[] memory tokens = ds.userNFTs[_address];
        _setURIs(tokens, uri);
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
}
