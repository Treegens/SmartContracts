// SPDX-License-Identifier: GPL
pragma solidity 0.8.24;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IMGro} from "../interfaces/IMgro.sol";
import {IMinter} from "../interfaces/IMinter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {LibXChain} from "../libraries/LibXChain.sol";
import {IBaseMgroOapp} from "../interfaces/IBaseMgroOapp.sol";

/**
 * @title ManagementFacet
 * @notice Core management functionality for the Treegen Diamond contract
 * @dev Handles NFT minting, token operations, and cross-chain messaging with reentrancy protection
 */
contract ManagementFacet is ReentrancyGuard {
    /* ------------------------------------------------------------------------
       CONSTANTS
    --------------------------------------------------------------------------*/
    uint256 public constant MAX_NFT_SUPPLY = 1000;

    /* ------------------------------------------------------------------------
       EVENTS
    --------------------------------------------------------------------------*/
    event LogImgNo(uint256 indexed imgNo);
    event LogBaseURI(string indexed baseURI);
    event LogValues(uint256 indexed x, uint256 indexed y);
    event NFTPurchased(address indexed buyer, uint256 indexed tokenId, uint256 price);
    event MintConfirmed(address indexed user, uint256 amountWei);
    event BurnConfirmed(address indexed user, uint256 amountWei);
    event Initialized(address indexed minter, address indexed token, address indexed dao);
    event NFTPriceUpdated(uint256 oldPrice, uint256 newPrice);
    event FeeCollectorUpdated(address indexed oldCollector, address indexed newCollector);
    event PurchaseTokenUpdated(address indexed oldToken, address indexed newToken, uint256 newPrice);
    event VerificationContractUpdated(address indexed oldContract, address indexed newContract);
    event DaoUpdated(address indexed oldDao, address indexed newDao);
    event MgroTokenUpdated(address indexed oldToken, address indexed newToken);
    event MinterUpdated(address indexed oldMinter, address indexed newMinter);

    /* ------------------------------------------------------------------------
       FUNCTIONS
    --------------------------------------------------------------------------*/

    /**
     * @notice Initializes the management facet with core contracts
     * @param _minter The NFT minter contract address
     * @param _token The MGRO token address
     * @param _dao The DAO contract address
     * @param _buyToken The token used for NFT purchases
     * @dev Can only be called once by the contract owner
     */
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
        
        emit Initialized(_minter, _token, _dao);
    }

    /**
     * @notice Sets the fee collector address
     * @param _address The new fee collector address
     * @dev Only callable by the DAO
     */
    function setFeeCollector(address _address) external {
        require(_address != address(0), "Invalid Address");
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(
            msg.sender == ds.dao,
            "Fee collector can be changed only via DAO"
        );
        
        address oldCollector = ds.feeCollector;
        ds.feeCollector = _address;
        
        emit FeeCollectorUpdated(oldCollector, _address);
    }

    /**
     * @notice Sets the purchase token and price for NFTs
     * @param _token The new purchase token address
     * @param _price The new NFT price
     * @dev Only callable by the DAO
     */
    function setPurchaseToken(address _token, uint256 _price) external {
        require(_token != address(0), "Invalid Token");
        require(_price != 0, "Set a valid Price");
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(
            msg.sender == ds.dao,
            "Purchase token can be changed only via DAO"
        );
        
        address oldToken = address(ds.buyToken);
        uint256 oldPrice = ds.nftPrice;
        
        ds.buyToken = IERC20(_token);
        ds.nftPrice = _price;
        
        emit PurchaseTokenUpdated(oldToken, _token, _price);
        emit NFTPriceUpdated(oldPrice, _price);
    }
    /**
     * @notice Sets the verification contract address
     * @param _address The new verification contract address
     * @dev Only callable by the contract owner
     */
    function setVerificationContract(address _address) external {
        require(_address != address(0), "Invalid Address");
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        
        address oldContract = ds.mgroVerification;
        ds.mgroVerification = _address;
        
        emit VerificationContractUpdated(oldContract, _address);
    }

    /**
     * @notice Sets the DAO contract address
     * @param _address The new DAO contract address
     * @dev Only callable by the contract owner
     */
    function setDao(address _address) external {
        require(_address != address(0), "Invalid Address");
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        
        address oldDao = ds.dao;
        ds.dao = _address;
        
        emit DaoUpdated(oldDao, _address);
    }

    /**
     * @notice Sets the MGRO token contract address
     * @param _mgro The new MGRO token address
     * @dev Only callable by the contract owner
     */
    function setMgroToken(address _mgro) external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(_mgro != address(0), "Invalid MGRO address");
        
        address oldToken = address(ds.mgro);
        ds.mgro = IMGro(_mgro);
        
        emit MgroTokenUpdated(oldToken, _mgro);
    }

    /**
     * @notice Sets the NFT minter contract address
     * @param _address The new minter contract address
     * @dev Only callable by the contract owner
     */
    function setMinter(address _address) external {
        require(_address != address(0), "Invalid Address");
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        
        address oldMinter = address(ds.minter);
        ds.minter = IMinter(_address);
        
        emit MinterUpdated(oldMinter, _address);
    }

    /* ------------------------------------------------------------------------
       GETTER FUNCTIONS
    --------------------------------------------------------------------------*/

    /**
     * @notice Returns the number of NFTs owned by a user
     * @param _user The address to query
     * @return The count of NFTs owned by the user
     */
    function checkUserNFTs(address _user) external view returns (uint) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.userNFTs[_user].length;
    }

    /**
     * @notice Returns the list of NFT token IDs owned by a user
     * @param _user The address to query
     * @return Array of token IDs owned by the user
     */
    function getUserNFTIds(address _user) external view returns (uint256[] memory) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.userNFTs[_user];
    }

    /**
     * @notice Returns minted and burnt token statistics for an address
     * @param _address The address to query
     * @return _minted The number of tokens minted for this address
     * @return _burnt The number of tokens burnt by this address
     */
    function checkStats(
        address _address
    ) public view returns (uint256 _minted, uint256 _burnt) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        _minted = ds.minted[_address];
        _burnt = ds.burnt[_address];
        return (_minted, _burnt);
    }

    /**
     * @notice Returns the current NFT price
     * @return The price in buy tokens required to mint an NFT
     */
    function getNFTPrice() external view returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.nftPrice;
    }

    /**
     * @notice Returns the fee collector address
     * @return The address that receives NFT purchase fees
     */
    function getFeeCollector() external view returns (address) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.feeCollector;
    }

    /**
     * @notice Returns the DAO contract address
     * @return The DAO contract address
     */
    function getDao() external view returns (address) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.dao;
    }

    /**
     * @notice Returns the verification contract address
     * @return The MGRO verification contract address
     */
    function getVerificationContract() external view returns (address) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.mgroVerification;
    }

    /**
     * @notice Returns the buy token address
     * @return The ERC20 token address used for NFT purchases
     */
    function getBuyToken() external view returns (address) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return address(ds.buyToken);
    }

    /**
     * @notice Returns the minter contract address
     * @return The NFT minter contract address
     * @dev This is the address of the TreegenNFT contract
     */
    function getMinter() external view returns (address) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return address(ds.minter);
    }

    /**
     * @notice Returns the MGRO token contract address
     * @return The MGRO token contract address
     */
    function getMgroToken() external view returns (address) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return address(ds.mgro);
    }

    /**
     * @notice Returns whether the contract has been initialized
     * @return True if initialized, false otherwise
     */
    function isInitialized() external view returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.count > 0;
    }

    /**
     * @notice Returns the paused state of the contract
     * @return True if paused, false otherwise
     */
    function isPaused() external view returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.paused;
    }

    /**
     * @notice Returns all contract configuration addresses
     * @return dao The DAO contract address
     * @return verification The verification contract address
     * @return minter The minter contract address
     * @return mgro The MGRO token address
     * @return buyToken The buy token address
     * @return feeCollector The fee collector address
     */
    function getContractAddresses() external view returns (
        address dao,
        address verification,
        address minter,
        address mgro,
        address buyToken,
        address feeCollector
    ) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return (
            ds.dao,
            ds.mgroVerification,
            address(ds.minter),
            address(ds.mgro),
            address(ds.buyToken),
            ds.feeCollector
        );
    }

    /**
     * @notice Returns comprehensive NFT statistics
     * @return currentSupply The current number of NFTs minted
     * @return maxSupply The maximum NFT supply
     * @return price The current NFT price
     * @return initialized Whether the contract is initialized
     */
    function getNFTInfo() external view returns (
        uint256 currentSupply,
        uint256 maxSupply,
        uint256 price,
        bool initialized
    ) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return (
            ds.nftCount,
            MAX_NFT_SUPPLY,
            ds.nftPrice,
            ds.count > 0
        );
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

    /**
     * @dev Returns the total number of NFTs minted
     * @return The total supply of NFTs
     */
    function totalSupply() external view returns (uint256) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.nftCount;
    }

    /**
     * @notice Mints a new NFT to a specified address (owner only)
     * @param _address The address to receive the NFT
     * @dev Uses reentrancy protection and follows Checks-Effects-Interactions pattern
     */
    function mintNFT(address _address) external nonReentrant {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        
        // Checks
        require(_address != address(0), "Invalid address");
        require(ds.nftCount < MAX_NFT_SUPPLY, "Max NFT supply reached");
        
        // Effects: Update state before external calls
        uint256 nftId = ++ds.nftCount;
        ds.userNFTs[_address].push(nftId);
        
        // Interactions: External call last (safeMint has its own reentrancy guard)
        ds.minter.safeMint(_address, nftId);
    }

    /**
     * @notice Allows users to purchase and mint an NFT
     * @dev Uses reentrancy protection and follows Checks-Effects-Interactions pattern
     * Requires payment in the designated buyToken
     */
    function mintNFTasUser() external nonReentrant {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        
        // Checks
        require(ds.nftCount < MAX_NFT_SUPPLY, "Max NFT supply reached");
        uint256 price = ds.nftPrice;
        if (price == 0) revert("Not yet active");
        require(ds.feeCollector != address(0), "Fee collector not set");

        require(
            ds.buyToken.balanceOf(msg.sender) >= price,
            "Insufficient balance"
        );
        require(
            ds.buyToken.allowance(msg.sender, address(this)) >= price,
            "Insufficient allowance"
        );

        // Effects: Update state before external calls
        uint256 nftId = ++ds.nftCount;
        ds.userNFTs[msg.sender].push(nftId);

        // Interactions: External calls last
        bool ok = ds.buyToken.transferFrom(msg.sender, ds.feeCollector, price);
        require(ok, "Token transfer failed");

        ds.minter.safeMint(msg.sender, nftId);

        emit NFTPurchased(msg.sender, nftId, price);
    }

}
