// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {ManagementFacet} from "../src/facets/ManagementFacet.sol";

contract MintNFT is Script {
    function run() external {

        address diamondAddress = vm.envAddress("DIAMOND_ADDRESS");
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);
        vm.startBroadcast(privateKey);

        ManagementFacet mgmt = ManagementFacet(diamondAddress);

        mgmt.mintNFT(deployer);
        vm.stopBroadcast();
    }
}