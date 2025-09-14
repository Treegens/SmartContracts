// SPDX-License-Identifier: GPL
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {ManagementFacet} from "../../src/facets/ManagementFacet.sol";
import {ChainConfig} from "../../script/ChainConfig.s.sol";

/**
 * @title InitializeManagementFacetBaseSepolia
 * @notice Script for initializing ManagementFacet with proper parameters on Base Sepolia
 */
contract InitializeManagementFacetBaseSepolia is Script {

    function run(
    ) external {
        uint256 privateKey = vm.envUint("MAINNET_PRIVATE_KEY");
        address deployer = vm.addr(privateKey);
        address diamondAddress = vm.envAddress("MAINNET_DIAMOND_ADDRESS");
        address nftAddress = vm.envAddress("MAINNET_NFT_ADDRESS");
        address tgnAddress = vm.envAddress("MAINNET_TGN_ADDRESS");
        address daoAddress = deployer;

        vm.startBroadcast(privateKey);

        console.log("=== Initializing ManagementFacet on Base Sepolia ===");

        console.log("Diamond Address:", diamondAddress);
        console.log("NFT Address:", nftAddress);
        console.log("DAO Address:", daoAddress);
        console.log("TGN Address:", tgnAddress);



        // Initialize ManagementFacet
        ManagementFacet management = ManagementFacet(diamondAddress);

        // Parameters for initialization:
        // _minter = nftAddress (TreegenNFT_Canonical)
        // _token = address(0) (MGRO - to be set later)
        // _dao = daoAddress (TGNDAO)
        // _buyToken = tgnAddress (TGN on Base Sepolia)

        console.log("Initializing ManagementFacet...");
        management.initialize(
            nftAddress,     // _minter (TreegenNFT_Canonical)
            address(0),     // _token (MGRO - address(0) for now)
            daoAddress,     // _dao (TGNDAO)
            tgnAddress    // _buyToken (TGN)
        );

        console.log("ManagementFacet initialized successfully");

        // Verify initialization
        console.log("ManagementFacet verification:");
        console.log("- NFT Minter:", management.checkUserNFTs(diamondAddress)); // Should be 0 initially

        console.log("=== ManagementFacet Initialization Complete ===");

        vm.stopBroadcast();
    }
}
