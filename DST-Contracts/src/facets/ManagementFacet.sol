// SPDX-License-Identifier: GPL
pragma solidity ^0.8.20;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import "../MGRO.sol";
import "../interfaces/IMinter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {LibXChain} from "../libraries/LibXChain.sol";
import {IBaseMgroOapp} from "../interfaces/IBaseMgroOapp.sol";

contract ManagementFacet {
    /* ------------------------------------------------------------------------
       EVENTS
    --------------------------------------------------------------------------*/
    event LogImgNo(uint256 imgNo);
    event LogBaseURI(string baseURI);
    event LogValues(uint256 x, uint256 y);
    event NFTPurchased(address, uint, uint);
    event MintConfirmed(address user, uint256 amountWei);
    event BurnConfirmed(address user, uint256 amountWei);

    /* ------------------------------------------------------------------------
       FUNCTIONS
    --------------------------------------------------------------------------*/

    function initialize(
        address _minter,
        address _token,
        address _dao,
        address _buyToken
    ) external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(ds.count == 0, "Can only be run once");
        require(_minter != address(0), "Invalid minter Address");
        require(_dao != address(0), "Invalid DAO Address");
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
        require(
            msg.sender == ds.dao,
            "Fee collector can be changed only via DAO"
        );
        ds.feeCollector = _address;
    }

    function setPurchaseToken(address _token, uint256 _price) external {
        require(_token != address(0), "Invalid Token");
        require(_price != 0, "Set a valid Price");
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(
            msg.sender == ds.dao,
            "Purchase token can be changed only via DAO"
        );
        ds.buyToken = IERC20(_token);
        ds.nftPrice = _price;
    }
    function setVerificationContract(address _address) external {
        require(_address != address(0), "Invalid Address");
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.mgroVerification = _address;
    }

    function setMgroToken(address _mgro) external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(_mgro != address(0), "Invalid MGRO address");
        ds.mgro = IMGro(_mgro);
    }

    // Function to add base URI
    function addBaseURI(string memory _URI) external {
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
    function checkStats(
        address _address
    ) public view returns (uint256 _minted, uint256 _burnt) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        _minted = ds.minted[_address];
        _burnt = ds.burnt[_address];
        return (_minted, _burnt);
    }

    function mintMgroTokens(
        address _receiver,
        uint256 _tokens
    ) external payable {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(
            msg.sender == ds.mgroVerification,
            "Only the Verification Contract can mint MGRO tokens"
        );
        LibXChain.XChainStorage storage xs = LibXChain.xchainStorage();
        require(
            xs.messenger != address(0) && xs.dstEid != 0,
            "XChain not configured"
        );
        uint256 token = _tokens * 10 ** 18;
        // forward cross-chain to Celo; msg.value must match quote
        IBaseMgroOapp(xs.messenger).sendMint{value: msg.value}(
            xs.dstEid,
            _receiver,
            token,
            false
        );
        // ack-based flow: final stats updated on confirmMint
    }

    function burnTokens(uint256 _tokens) external payable {
        LibXChain.XChainStorage storage xs = LibXChain.xchainStorage();
        require(
            xs.messenger != address(0) && xs.dstEid != 0,
            "XChain not configured"
        );
        uint256 token = _tokens * 10 ** 18;
        IBaseMgroOapp(xs.messenger).sendBurn{value: msg.value}(
            xs.dstEid,
            msg.sender,
            token,
            false
        );
        // ack-based flow: final stats updated on confirmBurn
    }

    // -------- ack handlers from messenger --------
    modifier onlyMessenger() {
        require(msg.sender == LibXChain.getMessenger(), "Unauthorized");
        _;
    }

    function confirmMint(
        address _receiver,
        uint256 _amountWei
    ) external onlyMessenger {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 tokens = _amountWei / 1e18;
        if (tokens == 0) return;
        ds.minted[_receiver] += tokens;
        emit MintConfirmed(_receiver, _amountWei);
    }

    function confirmBurn(
        address _user,
        uint256 _amountWei
    ) external onlyMessenger {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 tokens = _amountWei / 1e18;
        if (tokens == 0) return;
        ds.burnt[_user] += tokens;
        emit BurnConfirmed(_user, _amountWei);
    }

    // --- xchain config ---
    function xchainSetMessenger(address _messenger) external {
        LibXChain.setMessenger(_messenger);
    }

    function xchainSetDstEid(uint32 _eid) external {
        LibXChain.setDstEid(_eid);
    }

    // --- xchain getters ---
    function xchainGetMessenger() external view returns (address) {
        return LibXChain.getMessenger();
    }

    function xchainGetDstEid() external view returns (uint32) {
        return LibXChain.getDstEid();
    }

    function mintNFT(address _address) external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(ds.baseURIs.length > 0, "No URIs active");
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

        require(
            ds.buyToken.balanceOf(msg.sender) >= price,
            "Insufficient balance"
        );
        require(
            ds.buyToken.allowance(msg.sender, address(this)) >= price,
            "Insufficient allowance"
        );

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

}
