// SPDX-License-Identifier: GPL
pragma solidity ^0.8.20;

interface IMinter {
    function safeMint(address to, uint256 tokenId) external;
    function updateURI(uint256 tokenId, string memory uri) external;
}