// SPDX-License-Identifier: GPL
pragma solidity ^0.8.20;

import {ONFT721} from "@layerzerolabs/onft-evm/contracts/onft721/ONFT721.sol";
import "@openzeppelin/contracts/interfaces/IERC4906.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TreegenNFT is ONFT721, IERC4906 {
    address public nftUpdater;

    string private _defaultURI;
    
    // Optional mapping for token URIs
    mapping(uint256 tokenId => string) private _tokenURIs;
    
    // Mapping from owner address to list of owned token IDs
    mapping(address => uint256[]) private _ownedTokens;
    
    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    modifier onlyNFTUpdater() {
        require(msg.sender == nftUpdater, "Unauthorized");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory defaultURI_,
        address _lzEndpoint,
        address _delegate,
        address _nftUpdater
    ) ONFT721(_name, _symbol, _lzEndpoint, _delegate) {
        _defaultURI = defaultURI_;
        nftUpdater = _nftUpdater;
    }

    function setNFTUpdater(address _address) public onlyOwner {
        require(_address != address(0), "Invalid address");
        nftUpdater = _address;
    }

    function setDefaultURI(string memory _newDefaultURI) public onlyOwner {
        _defaultURI = _newDefaultURI;
    }

    function updateURI(
        uint256 tokenId,
        string memory uri
    ) external onlyNFTUpdater {
        _setTokenURI(tokenId, uri);
    }

    function updateURI(uint256 tokenId) external onlyNFTUpdater {
        string memory _uri = string(abi.encodePacked(_defaultURI, Strings.toString(tokenId)));
        _setTokenURI(tokenId, _uri);
    }

    /**
     * @dev Returns the list of token IDs owned by an address
     */
    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        return _ownedTokens[owner];
    }

    /**
     * @dev Updates URIs for all tokens owned by a specific address
     */
    function updateURIsByAddress(address owner, string[] memory uris) external onlyNFTUpdater {
        uint256[] memory tokens = _ownedTokens[owner];
        require(tokens.length == uris.length, "Array length mismatch");
        
        for (uint256 i = 0; i < tokens.length; i++) {
            _setTokenURI(tokens[i], uris[i]);
        }
    }

    /**
     * @dev Updates URI for a specific token owned by an address
     */
    function updateURIByAddressAndIndex(address owner, uint256 index, string memory uri) external onlyNFTUpdater {
        uint256[] memory tokens = _ownedTokens[owner];
        require(index < tokens.length, "Index out of bounds");
        
        _setTokenURI(tokens[index], uri);
    }

    function metadataUpdate(uint256 tokenId) external onlyNFTUpdater {
        emit MetadataUpdate(tokenId);
    }

    function batchMetadataUpdate(uint256[] memory tokenIds) external onlyNFTUpdater {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            emit MetadataUpdate(tokenIds[i]);
        }
    }
    
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        _tokenURIs[tokenId] = _tokenURI;
        emit MetadataUpdate(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, IERC165) returns (bool) {
        return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns the maximum total supply of tokens
     * @return The maximum supply of tokens
     */
    function totalSupply() public pure returns (uint256) {
        return 1000; // MAX_SUPPLY from ManagementFacet
    }
    
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
        
        // Otherwise, return defaultURI + tokenId
        return string(abi.encodePacked(_defaultURI, Strings.toString(tokenId)));
    }

    /**
     * @dev Override _update to handle token enumeration
     */
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = super._update(to, tokenId, auth);
        
        if (from != address(0)) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        
        if (to != address(0)) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
        
        return from;
    }

    /**
     * @dev Private function to add a token to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to remove a token from the owner's token list
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _ownedTokens[from].length - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        _ownedTokens[from].pop();
    }
}
