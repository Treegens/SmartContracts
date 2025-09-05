
// SPDX-License-Identifier: GPL
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TreegenNFT is Ownable, ERC721, ERC721URIStorage {

    address public management;
    string private _defaultURI;
    
    // Mapping from owner address to list of owned token IDs
    mapping(address => uint256[]) private _ownedTokens;
    
    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;
    constructor(string memory defaultURI_)
        ERC721("Treegen", "Treegen")
        Ownable(msg.sender)
    {
        _defaultURI = defaultURI_;
    }


    function setManagementContract(address _address) public onlyOwner{
        require(_address != address(0));
        management = _address;
    }



    function _baseURI() internal view override returns (string memory) {
        return "";
    }

    function safeMint(address to, uint256 tokenId)
        public
       
    {
         require(msg.sender == management, "Unauthorized");
        _safeMint(to, tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);

    }
    

    function updateURI(uint tokenId, string memory uri) external {
        require(msg.sender == management, "Unauthorized");

        _setTokenURI(tokenId, uri);
   
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(IERC721, ERC721) {
        //require(from == address(0)|| from == owner, "This is a soulbound NFT: Cannot be transferred");
        _removeTokenFromOwnerEnumeration(from, tokenId);
        super.transferFrom(from, to, tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);
        string memory _uri = string(abi.encodePacked(_defaultURI, '1'));
        _setTokenURI(tokenId, _uri);
    }
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(IERC721, ERC721) {
        _removeTokenFromOwnerEnumeration(from, tokenId);
        super.safeTransferFrom(from, to, tokenId, data);
        _addTokenToOwnerEnumeration(to, tokenId);
        string memory _uri = string(abi.encodePacked(_defaultURI, '1'));
        _setTokenURI(tokenId, _uri);

    }

    // The following functions are overrides required by Solidity.

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
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
    function updateURIsByAddress(address owner, string memory uri) external {
        require(msg.sender == management, "Unauthorized");
        uint256[] memory tokens = _ownedTokens[owner];
        
        for (uint256 i = 0; i < tokens.length; i++) {
            _setTokenURI(tokens[i], uri);
        }
    }

    /**
     * @dev Updates URI for a specific token owned by an address
     */
    function updateURIByAddressAndIndex(address owner, uint256 index, string memory uri) external {
        require(msg.sender == management, "Unauthorized");
        uint256[] memory tokens = _ownedTokens[owner];
        require(index < tokens.length, "Index out of bounds");
        
        _setTokenURI(tokens[index], uri);
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

