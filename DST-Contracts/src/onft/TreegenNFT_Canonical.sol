// SPDX-License-Identifier: GPL
pragma solidity ^0.8.20;

import { ONFT721Enumerable } from "../../lib/devtools/packages/onft-evm/contracts/onft721/ONFT721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC4906.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TreegenNFT is ONFT721Enumerable, IERC4906 {
    string private _defaultURI;
    address public management;
    address public nftUpdater;
    
    // Optional mapping for token URIs
    mapping(uint256 tokenId => string) private _tokenURIs;

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
        address _delegate,
        address _management,
        address _nftUpdater
    ) ONFT721Enumerable(_name, _symbol, _lzEndpoint, _delegate){
        _defaultURI = defaultURI_;
        management = _management;
        nftUpdater = _nftUpdater;
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
    }

    function updateURI(uint256 tokenId) external onlyNFTUpdater {
        string memory _uri = string(abi.encodePacked(_defaultURI, Strings.toString(tokenId)));
        _setTokenURI(tokenId, _uri);
    }

    /**
     * @dev Returns the list of token IDs owned by an address
     */
    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokens = new uint256[](tokenCount);
        
        for (uint256 i = 0; i < tokenCount; i++) {
            tokens[i] = tokenOfOwnerByIndex(owner, i);
        }
        
        return tokens;
    }

    /**
     * @dev Updates URIs for all tokens owned by a specific address
     */
    function updateURIsByAddress(address owner, string[] memory uris) external onlyNFTUpdater {
        uint256 tokenCount = balanceOf(owner);
        require(tokenCount == uris.length, "Array length mismatch");
        
        for (uint256 i = 0; i < tokenCount; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(owner, i);
            _setTokenURI(tokenId, uris[i]);
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
        uint256 tokenCount = balanceOf(owner);
        require(index < tokenCount, "Index out of bounds");
        
        uint256 tokenId = tokenOfOwnerByIndex(owner, index);
        _setTokenURI(tokenId, uri);
    }
    
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        _tokenURIs[tokenId] = _tokenURI;
        emit MetadataUpdate(tokenId);
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
        override(ERC721Enumerable, IERC165)
        returns (bool)
    {
        return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns the maximum total supply of tokens
     * @return The maximum supply of tokens
     */
    function totalSupply() public view override returns (uint256) {
        return 1000; // MAX_SUPPLY from ManagementFacet
    }

}