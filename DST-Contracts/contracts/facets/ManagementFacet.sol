// SPDX-License-Identifier: GPL
pragma solidity ^0.8.20;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import "../MGRO.sol";
import "../NFTMinter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {LibXChain} from "../libraries/LibXChain.sol";
import {LibNftUpdate} from "../libraries/LibNftUpdate.sol";
import {IBaseMgroMessenger} from "../interfaces/IBaseMgroMessenger.sol";

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
        // default: enable automatic NFT updates
        LibNftUpdate.s().autoEnabled = true;
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

    function mintMgroTokens(address _receiver, uint256 _tokens) external payable {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(msg.sender == ds.mgroVerification, "Only the Verification Contract can mint MGRO tokens");
        LibXChain.XChainStorage storage xs = LibXChain.xchainStorage();
        require(xs.messenger != address(0) && xs.dstEid != 0, "XChain not configured");
        uint256 token = _tokens * 10 ** 18;
        // forward cross-chain to Celo; msg.value must match quote
        IBaseMgroMessenger(xs.messenger).sendMint{value: msg.value}(xs.dstEid, _receiver, token, xs.lzOptions, false);
        // optimistic local stats to preserve current UX; can be switched to ack-based later
        ds.minted[_receiver] += _tokens;
        if (LibNftUpdate.isAutoUpdateEnabled()) {
            _updateNFTsAuto(_receiver);
        }
    }

    function burnTokens(uint256 _tokens) external payable {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibXChain.XChainStorage storage xs = LibXChain.xchainStorage();
        require(xs.messenger != address(0) && xs.dstEid != 0, "XChain not configured");
        uint256 token = _tokens * 10 ** 18;
        IBaseMgroMessenger(xs.messenger).sendBurn{value: msg.value}(xs.dstEid, msg.sender, token, xs.lzOptions, false);
        ds.burnt[msg.sender] += _tokens;
        if (LibNftUpdate.isAutoUpdateEnabled()) {
            _updateNFTsAuto(msg.sender);
        }
    }

    // --- xchain config ---
    function xchainSetMessenger(address _messenger) external {
        LibXChain.setMessenger(_messenger);
    }

    function xchainSetDstEid(uint32 _eid) external {
        LibXChain.setDstEid(_eid);
    }

    function xchainSetOptions(bytes calldata _opts) external {
        LibXChain.setLzOptions(_opts);
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

    // --- automatic NFT updates based on minted vs burnt ---
    function _updateNFTsAuto(address _user) internal {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint[] memory tokens = ds.userNFTs[_user];
        if (tokens.length == 0) return;
        uint256 numBase = ds.baseURIs.length;
        if (numBase == 0) return;

        (string memory finalURI, uint8 tierCode) = _chooseURIWithTier(_user);
        if (bytes(finalURI).length == 0) return;

        // skip writes if unchanged tier
        if (LibNftUpdate.getLastTier(_user) == tierCode) return;

        _setURIs(tokens, finalURI);
        LibNftUpdate.setLastTier(_user, tierCode);
    }

    function _chooseURIWithTier(address _user) internal view returns (string memory uri, uint8 tierCode) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 minted = ds.minted[_user];
        uint256 burnt = ds.burnt[_user];

        // If baseURIs not fully configured, default to first available base
        if (ds.baseURIs.length < 3) {
            // Fallback to baseURIs[0] with image 1 or 2 depending on activity
            string memory base0 = ds.baseURIs[0];
            string memory suffix = minted > 0 ? "2" : "1";
            uri = string(abi.encodePacked(base0, suffix));
            tierCode = uint8(0 * 10 + (minted > 0 ? 2 : 1));
            return (uri, tierCode);
        }

        uint256 total = minted + burnt;
        if (total == 0) {
            // No activity, default to baseURIs[0] + "1"
            uri = string(abi.encodePacked(ds.baseURIs[0], "1"));
            tierCode = uint8(0 * 10 + 1);
            return (uri, tierCode);
        }

        // Percentages rounded to nearest 10
        uint256 pctMinted = (minted * 100) / total;
        uint256 pctBurnt = 100 - pctMinted;
        uint256 x = _roundToNearestTen(pctMinted);
        uint256 y = _roundToNearestTen(pctBurnt);

        // Equal case -> neutral base
        if (x == y) {
            string memory baseNeutral = ds.baseURIs[0];
            string memory suffixNeutral = minted > 0 ? "2" : "1";
            uri = string(abi.encodePacked(baseNeutral, suffixNeutral));
            tierCode = uint8(0 * 10 + (minted > 0 ? 2 : 1));
            return (uri, tierCode);
        }

        if (x > y) {
            // Mint-dominant → baseURIs[1]
            (uri, tierCode) = _composeFromTierWithCode(1, ds.baseURIs[1], x);
            return (uri, tierCode);
        } else {
            // Burn-dominant → baseURIs[2]
            (uri, tierCode) = _composeFromTierWithCode(2, ds.baseURIs[2], y);
            return (uri, tierCode);
        }
    }

    function _composeFromTierWithCode(uint8 baseIndex, string storage _base, uint256 dominantPct) internal pure returns (string memory uri, uint8 code) {
        // Map 100,90,80,70,60 to images 1..5, else fallback to neutral 2
        uint256 imgNo;
        if (dominantPct >= 100) imgNo = 1;
        else if (dominantPct == 90) imgNo = 2;
        else if (dominantPct == 80) imgNo = 3;
        else if (dominantPct == 70) imgNo = 4;
        else if (dominantPct == 60) imgNo = 5;
        else imgNo = 2;
        uri = string(abi.encodePacked(_base, Strings.toString(imgNo)));
        code = uint8(baseIndex * 10 + uint8(imgNo));
        return (uri, code);
    }

    function _roundToNearestTen(uint256 value) internal pure returns (uint256) {
        uint256 remainder = value % 10;
        if (remainder >= 5) {
            return value + (10 - remainder);
        } else {
            return value - remainder;
        }
    }
}
