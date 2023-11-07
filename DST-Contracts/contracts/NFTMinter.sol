
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TreegenNFT is ERC721, ERC721URIStorage, Ownable {

    address public management;
    constructor()
        ERC721("Treegen", "Treegen")
        Ownable(msg.sender)
    {}


    function setManagementContract(address _address) public onlyOwner{
        require(_address != address(0));
        management = _address;
    }



    function _baseURI() internal pure override returns (string memory) {
        return "";
    }

    function safeMint(address to, uint256 tokenId)
        public
       
    {
         require(msg.sender == management, "Unauthorized");
        _safeMint(to, tokenId);
       

    }

    function updateURI(uint tokenId, string memory uri) external {
        require(msg.sender == management, "Unauthorized");

        _setTokenURI(tokenId, uri);
   
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(IERC721, ERC721) {
        //require(from == address(0)|| from == owner, "This is a soulbound NFT: Cannot be transferred");
        super.transferFrom(from, to, tokenId);
        _setTokenURI(tokenId, '1.json');
    }
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(IERC721, ERC721) {
        super.safeTransferFrom(from, to, tokenId, data);
         _setTokenURI(tokenId, '1.json');

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
}

interface IMinter {

    function safeMint(address to, uint256 tokenId) external;
        
    function updateURI(uint tokenId, string memory uri) external;
}   
