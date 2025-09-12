// SPDX-License-Identifier: GPL
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Diamond} from "../../src/Diamond.sol";
import {DiamondCutFacet} from "../../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../../src/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../../src/facets/OwnershipFacet.sol";
import {ManagementFacet} from "../../src/facets/ManagementFacet.sol";
import {IDiamondCut} from "../../src/interfaces/IDiamondCut.sol";
import {DiamondInit} from "../../src/upgradeInitializers/DiamondInit.sol";
import {ChainConfig} from "../../script/ChainConfig.s.sol";

/**
 * @title DeployDiamondBaseSepolia
 * @notice Script for deploying Diamond contract with all facets on Base Sepolia
 */
contract DeployDiamondBaseSepolia is Script {

    function run() external returns (address diamond_) {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        console.log("=== Deploying Diamond on Base Sepolia ===");

        // Verify we're on Base Sepolia (chainId 84532)
        require(block.chainid == 84532, "Must be deployed on Base Sepolia");

        // Get deployer address
        address deployer = vm.addr(privateKey);
        console.log("Deployer:", deployer);

        // Deploy DiamondCutFacet first
        DiamondCutFacet cutFacet = new DiamondCutFacet();
        console.log("DiamondCutFacet deployed at:", address(cutFacet));

        // Deploy Diamond with DiamondCutFacet
        Diamond diamond = new Diamond(deployer, address(cutFacet));
        diamond_ = address(diamond);
        console.log("Diamond deployed at:", diamond_);

        // Deploy all other facets
        DiamondInit init = new DiamondInit();
        DiamondLoupeFacet loupe = new DiamondLoupeFacet();
        OwnershipFacet own = new OwnershipFacet();
        ManagementFacet management = new ManagementFacet();

        console.log("Facets deployed:");
        console.log("- DiamondInit:", address(init));
        console.log("- DiamondLoupeFacet:", address(loupe));
        console.log("- OwnershipFacet:", address(own));
        console.log("- ManagementFacet:", address(management));

        // Prepare facet cuts
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](3);

        // 1. DiamondLoupeFacet
        {
            bytes4[] memory selectors = new bytes4[](4);
            selectors[0] = loupe.facets.selector;
            selectors[1] = loupe.facetFunctionSelectors.selector;
            selectors[2] = loupe.facetAddresses.selector;
            selectors[3] = loupe.facetAddress.selector;
            cuts[0] = IDiamondCut.FacetCut({
                facetAddress: address(loupe),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectors
            });
        }

        // 2. OwnershipFacet
        {
            bytes4[] memory selectors = new bytes4[](2);
            selectors[0] = own.transferOwnership.selector;
            selectors[1] = own.owner.selector;
            cuts[1] = IDiamondCut.FacetCut({
                facetAddress: address(own),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectors
            });
        }

        // 3. ManagementFacet
        {
            bytes4[] memory selectors = new bytes4[](19);
            uint256 i;
            selectors[i++] = ManagementFacet.initialize.selector;
            selectors[i++] = ManagementFacet.setFeeCollector.selector;
            selectors[i++] = ManagementFacet.setPurchaseToken.selector;
            selectors[i++] = ManagementFacet.setVerificationContract.selector;
            selectors[i++] = ManagementFacet.setMgroToken.selector;
            selectors[i++] = ManagementFacet.checkUserNFTs.selector;
            selectors[i++] = ManagementFacet.checkStats.selector;
            selectors[i++] = ManagementFacet.mintMgroTokens.selector;
            selectors[i++] = ManagementFacet.burnTokens.selector;
            selectors[i++] = ManagementFacet.confirmMint.selector;
            selectors[i++] = ManagementFacet.confirmBurn.selector;
            selectors[i++] = ManagementFacet.xchainSetMessenger.selector;
            selectors[i++] = ManagementFacet.xchainSetDstEid.selector;
            selectors[i++] = ManagementFacet.xchainGetMessenger.selector;
            selectors[i++] = ManagementFacet.xchainGetDstEid.selector;
            selectors[i++] = ManagementFacet.mintNFT.selector;
            selectors[i++] = ManagementFacet.mintNFTasUser.selector;

            cuts[2] = IDiamondCut.FacetCut({
                facetAddress: address(management),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectors
            });
        }

        // Execute diamond cut
        IDiamondCut(diamond_).diamondCut(cuts, address(init), abi.encodeWithSelector(DiamondInit.init.selector));

        console.log("Diamond cut executed successfully");
        console.log("=== Diamond Deployment Complete ===");
        console.log("Diamond address:", diamond_);
        console.log("Chain ID:", block.chainid);
        console.log("Role: DIAMOND_CHAIN");

        vm.stopBroadcast();

        return diamond_;
    }
}
