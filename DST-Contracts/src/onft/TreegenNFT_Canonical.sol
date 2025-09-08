// SPDX-License-Identifier: GPL
pragma solidity ^0.8.20;

import { ONFT721 } from "@layerzerolabs/onft-evm/contracts/onft721/ONFT721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC4906.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TreegenNFT is ONFT721, IERC4906 {
    string private _defaultURI;
    address public management;
    address public nftUpdater;
    
    // Optional mapping for token URIs
    mapping(uint256 tokenId => string) private _tokenURIs;
    
    // Mapping from owner address to list of owned token IDs
    mapping(address => uint256[]) private _ownedTokens;
    
    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    modifier onlyManagement() {
        require(msg.sender == management, "Unauthorized");
        _;
    }

    modifier onlyNFTUpdater() {
        require(msg.sender == nftUpdater, "Unauthorized");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory defaultURI_,
        address _lzEndpoint,
        address _delegate
    ) ONFT721(_name, _symbol, _lzEndpoint, _delegate){
        _defaultURI = defaultURI_;
    }

    function setNFTUpdater(address _address) public onlyOwner {
        require(_address != address(0), "Invalid address");
        nftUpdater = _address;
    }

    function setManagementContract(address _address) public onlyOwner {
        require(_address != address(0), "Invalid address");
        management = _address;
    }

    function setDefaultURI(string memory _newDefaultURI) public onlyOwner {
        _defaultURI = _newDefaultURI;
    }

    function safeMint(address to, uint256 tokenId) public onlyManagement {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked(_defaultURI, Strings.toString(tokenId))));
        _addTokenToOwnerEnumeration(to, tokenId);
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

    function metadataUpdate(uint256 tokenId) external onlyNFTUpdater {
        emit MetadataUpdate(tokenId);
    }

    function batchMetadataUpdate(uint256[] memory tokenIds) external onlyNFTUpdater {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            emit MetadataUpdate(tokenIds[i]);
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
    
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        _tokenURIs[tokenId] = _tokenURI;
        emit MetadataUpdate(tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) {
        _removeTokenFromOwnerEnumeration(from, tokenId);
        super.transferFrom(from, to, tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) {
        _removeTokenFromOwnerEnumeration(from, tokenId);
        super.safeTransferFrom(from, to, tokenId, data);
        _addTokenToOwnerEnumeration(to, tokenId);
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

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, IERC165)
        returns (bool)
    {
        return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Override _update to handle token enumeration
     */
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = super._update(to, tokenId, auth);
        
        // Skip enumeration updates for transfers handled by transferFrom/safeTransferFrom
        // as they already handle enumeration manually
        if (from == address(0)) {
            // Minting - only add to enumeration if not already added by safeMint
            if (_ownedTokensIndex[tokenId] == 0 && (_ownedTokens[to].length == 0 || _ownedTokens[to][0] != tokenId)) {
                _addTokenToOwnerEnumeration(to, tokenId);
            }
        } else if (to == address(0)) {
            // Burning - remove from enumeration
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        // For regular transfers, enumeration is handled in transferFrom/safeTransferFrom
        
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