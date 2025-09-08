// SPDX-License-Identifier: GPL
pragma solidity ^0.8.20;

interface IMGro {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}