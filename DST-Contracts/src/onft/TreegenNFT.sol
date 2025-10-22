// SPDX-License-Identifier: GPL
pragma solidity 0.8.24;

import {ONFT721Enumerable} from "../../lib/devtools/packages/onft-evm/contracts/onft721/ONFT721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC4906.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title TreegenNFT
 * @notice ERC721 NFT with LayerZero cross-chain capabilities for the Treegen ecosystem
 * @dev Extends ONFT721Enumerable for omnichain NFT functionality with ERC4906 metadata updates
 */
contract TreegenNFT is ONFT721Enumerable, IERC4906 {
    // Custom errors for gas efficiency
    error Unauthorized();
    error InvalidAddress();
    error InvalidURI();
    error ArrayLengthMismatch();
    error IndexOutOfBounds();
    error EmptyArray();

    /// @dev ERC4906 interface ID
    bytes4 private constant ERC4906_INTERFACE_ID = 0x49064906;

    address public nftUpdater;
    string private _defaultURI;
    
    /// @notice Mapping from token ID to custom URI
    mapping(uint256 tokenId => string) private _tokenURIs;

    // Events with indexed parameters for efficient filtering
    event NFTUpdaterChanged(address indexed oldUpdater, address indexed newUpdater);
    event DefaultURIChanged(string indexed oldURI, string indexed newURI);

    modifier onlyNFTUpdater() {
        if (msg.sender != nftUpdater) revert Unauthorized();
        _;
    }

    /**
     * @notice Initializes the TreegenNFT contract
     * @param _name The name of the NFT collection
     * @param _symbol The symbol of the NFT collection
     * @param defaultURI_ The default base URI for token metadata
     * @param _lzEndpoint The LayerZero endpoint address for cross-chain functionality
     * @param _delegate The delegate address for LayerZero operations
     * @param _nftUpdater The address authorized to update NFT metadata
     */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory defaultURI_,
        address _lzEndpoint,
        address _delegate,
        address _nftUpdater
    ) ONFT721Enumerable(_name, _symbol, _lzEndpoint, _delegate) {
        if (_lzEndpoint == address(0)) revert InvalidAddress();
        if (_delegate == address(0)) revert InvalidAddress();
        if (_nftUpdater == address(0)) revert InvalidAddress();
        if (bytes(defaultURI_).length == 0) revert InvalidURI();
        
        _defaultURI = defaultURI_;
        nftUpdater = _nftUpdater;
    }

    /**
     * @notice Updates the NFT updater address
     * @param _address The new NFT updater address
     * @dev Only callable by the contract owner
     */
    function setNFTUpdater(address _address) public onlyOwner {
        if (_address == address(0)) revert InvalidAddress();
        address oldUpdater = nftUpdater;
        nftUpdater = _address;
        emit NFTUpdaterChanged(oldUpdater, _address);
    }

    /**
     * @notice Updates the default base URI for all tokens
     * @param _newDefaultURI The new default URI
     * @dev Only callable by the contract owner
     */
    function setDefaultURI(string memory _newDefaultURI) public onlyOwner {
        if (bytes(_newDefaultURI).length == 0) revert InvalidURI();
        string memory oldURI = _defaultURI;
        _defaultURI = _newDefaultURI;
        emit DefaultURIChanged(oldURI, _newDefaultURI);
    }

    /**
     * @notice Updates the URI for a specific token with a custom URI
     * @param tokenId The ID of the token to update
     * @param uri The custom URI to set
     * @dev Only callable by the NFT updater
     */
    function updateURI(
        uint256 tokenId,
        string memory uri
    ) external onlyNFTUpdater {
        _setTokenURI(tokenId, uri);
    }

    /**
     * @notice Updates the URI for a specific token to the default pattern
     * @param tokenId The ID of the token to update
     * @dev Only callable by the NFT updater
     */
    function updateURI(uint256 tokenId) external onlyNFTUpdater {
        string memory _uri = string.concat(_defaultURI, Strings.toString(tokenId));
        _setTokenURI(tokenId, _uri);
    }

    /**
     * @notice Returns the list of token IDs owned by an address
     * @param owner The address to query tokens for
     * @return An array of token IDs owned by the address
     */
    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokens = new uint256[](tokenCount);
        
        // Gas optimization: cache length and use unchecked increment
        uint256 length = tokenCount;
        for (uint256 i; i < length; ) {
            tokens[i] = tokenOfOwnerByIndex(owner, i);
            unchecked { ++i; }
        }
        
        return tokens;
    }

    /**
     * @notice Updates URIs for all tokens owned by a specific address
     * @param owner The address whose tokens will be updated
     * @param uris Array of new URIs for each token
     * @dev Only callable by the NFT updater. Array length must match token count
     */
    function updateURIsByAddress(address owner, string[] memory uris) external onlyNFTUpdater {
        uint256 tokenCount = balanceOf(owner);
        uint256 urisLength = uris.length;
        
        // Explicit array bounds checking
        if (urisLength == 0) revert EmptyArray();
        if (tokenCount != urisLength) revert ArrayLengthMismatch();
        
        // Gas optimization: cache length and use unchecked increment
        for (uint256 i; i < tokenCount; ) {
            if (i >= urisLength) revert IndexOutOfBounds(); // Explicit bounds check
            uint256 tokenId = tokenOfOwnerByIndex(owner, i);
            _setTokenURI(tokenId, uris[i]);
            unchecked { ++i; }
        }
    }

    /**
     * @notice Updates URI for a specific token owned by an address using index
     * @param owner The address that owns the token
     * @param index The index of the token in the owner's token list
     * @param uri The new URI for the token
     * @dev Only callable by the NFT updater
     */
    function updateURIByAddressAndIndex(address owner, uint256 index, string memory uri) external onlyNFTUpdater {
        uint256 tokenCount = balanceOf(owner);
        if (index >= tokenCount) revert IndexOutOfBounds();
        
        uint256 tokenId = tokenOfOwnerByIndex(owner, index);
        _setTokenURI(tokenId, uri);
    }

    /**
     * @notice Emits a metadata update event for a single token
     * @param tokenId The ID of the token to emit update for
     * @dev Only callable by the NFT updater
     */
    function metadataUpdate(uint256 tokenId) external onlyNFTUpdater {
        emit MetadataUpdate(tokenId);
    }

    /**
     * @notice Emits metadata update events for multiple tokens
     * @param tokenIds Array of token IDs to emit updates for
     * @dev Only callable by the NFT updater. Uses gas-optimized loop
     */
    function batchMetadataUpdate(uint256[] memory tokenIds) external onlyNFTUpdater {
        uint256 length = tokenIds.length;
        if (length == 0) revert EmptyArray();
        
        for (uint256 i; i < length; ) {
            emit MetadataUpdate(tokenIds[i]);
            unchecked { ++i; }
        }
    }
    
    /**
     * @dev Internal function to set token URI and emit metadata update event
     * @param tokenId The ID of the token
     * @param _tokenURI The URI to set
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        _tokenURIs[tokenId] = _tokenURI;
        emit MetadataUpdate(tokenId);
    }

    /**
     * @notice Checks if the contract supports a given interface
     * @param interfaceId The interface identifier to check
     * @return True if the interface is supported, false otherwise
     * @dev Includes try-catch to prevent reverts and ensure ERC165 compliance
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721Enumerable, IERC165) returns (bool) {
        // Check for ERC4906 interface
        if (interfaceId == ERC4906_INTERFACE_ID) return true;
        
        // Try parent supportsInterface to prevent reverts
        try this.supportsInterface(interfaceId) returns (bool result) {
            return result;
        } catch {
            // Fallback to parent implementation without try-catch
            return super.supportsInterface(interfaceId);
        }
    }

    /**
     * @notice Returns the URI for a given token ID
     * @param tokenId The ID of the token
     * @return The token's metadata URI
     * @dev Returns custom URI if set, otherwise returns default URI + tokenId
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireOwned(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        
        // If there is a custom token URI, return it
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }
        
        // Otherwise, return defaultURI + tokenId (using string.concat to prevent hash collisions)
        return string.concat(_defaultURI, Strings.toString(tokenId));
    }
}
