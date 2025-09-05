// SPDX-License-Identifier: GPL
pragma solidity ^0.8.17;

// import "forge-std/Script.sol";
// import {console} from "forge-std/console.sol";
// import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
// import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
// import {ManagementFacet} from "../src/facets/ManagementFacet.sol";
// import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
// import {IDiamondLoupe} from "../src/interfaces/IDiamondLoupe.sol";

// contract UpgradeManagementFacet is Script {
    
//     function run() external {
//         uint256 privateKey = vm.envUint("TESTNET_PRIVATE_KEY");
        
//         // Address of your existing diamond
//         address diamond = 0x0f6fd7483C9ED740e6bc0a203059001c2907D0Db; // base sepolia
        
//         vm.startBroadcast(privateKey);
        
//         // Deploy the new ManagementFacet
//         ManagementFacet newManagementFacet = new ManagementFacet();
//         console.log("New ManagementFacet deployed at:", address(newManagementFacet));
        
//         // Get the DiamondCutFacet and DiamondLoupeFacet from the diamond
//         DiamondCutFacet diamondCut = DiamondCutFacet(diamond);
//         DiamondLoupeFacet diamondLoupe = DiamondLoupeFacet(diamond);
        
//         // First, let's see what facets currently exist
//         IDiamondLoupe.Facet[] memory facets = diamondLoupe.facets();
//         console.log("Current facets count:", facets.length);
        
//         // Find the current ManagementFacet
//         address currentManagementFacet = address(0);
//         for (uint i = 0; i < facets.length; i++) {
//             console.log("Facet", i, ":", facets[i].facetAddress);
//             // Check if this facet has ManagementFacet functions
//             bytes4[] memory selectors = diamondLoupe.facetFunctionSelectors(facets[i].facetAddress);
//             for (uint j = 0; j < selectors.length; j++) {
//                 if (selectors[j] == ManagementFacet.initialize.selector) {
//                     currentManagementFacet = facets[i].facetAddress;
//                     console.log("Found ManagementFacet at:", currentManagementFacet);
//                     break;
//                 }
//             }
//             if (currentManagementFacet != address(0)) break;
//         }
//         if (currentManagementFacet == address(0)) {
//             console.log("No existing ManagementFacet found, adding new one");
            
//             // Add new ManagementFacet
//             IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);
            
//             // Get all the function selectors from the new ManagementFacet
//             bytes4[] memory selectors = new bytes4[](22);
//             uint256 selectorIndex = 0;
            
//             // Core functions
//             selectors[selectorIndex++] = ManagementFacet.initialize.selector;
//             selectors[selectorIndex++] = ManagementFacet.setFeeCollector.selector;
//             selectors[selectorIndex++] = ManagementFacet.setPurchaseToken.selector;
//             selectors[selectorIndex++] = ManagementFacet.setVerificationContract.selector;
//             selectors[selectorIndex++] = ManagementFacet.setMgroToken.selector;
//             selectors[selectorIndex++] = ManagementFacet.addBaseURI.selector;
//             selectors[selectorIndex++] = ManagementFacet.checkUserNFTs.selector;
//             selectors[selectorIndex++] = ManagementFacet.checklength.selector;
//             selectors[selectorIndex++] = ManagementFacet.checkStats.selector;
//             selectors[selectorIndex++] = ManagementFacet.mintMgroTokens.selector;
//             selectors[selectorIndex++] = ManagementFacet.burnTokens.selector;
//             selectors[selectorIndex++] = ManagementFacet.mintNFT.selector;
//             selectors[selectorIndex++] = ManagementFacet.mintNFTasUser.selector;
//             selectors[selectorIndex++] = ManagementFacet.updateNFTs.selector;
            
//             // Confirm functions for cross-chain acknowledgments
//             selectors[selectorIndex++] = ManagementFacet.confirmMint.selector;
//             selectors[selectorIndex++] = ManagementFacet.confirmBurn.selector;
            
//             // XChain configuration functions
//             selectors[selectorIndex++] = ManagementFacet.xchainSetMessenger.selector;
//             selectors[selectorIndex++] = ManagementFacet.xchainSetDstEid.selector;
//             selectors[selectorIndex++] = ManagementFacet.xchainSetOptions.selector;
            
//             // XChain getter functions
//             selectors[selectorIndex++] = ManagementFacet.xchainGetMessenger.selector;
//             selectors[selectorIndex++] = ManagementFacet.xchainGetDstEid.selector;
//             selectors[selectorIndex++] = ManagementFacet.xchainGetOptions.selector;
            
//             cuts[0] = IDiamondCut.FacetCut({
//                 facetAddress: address(newManagementFacet),
//                 action: IDiamondCut.FacetCutAction.Add,
//                 functionSelectors: selectors
//             });
            
//             diamondCut.diamondCut(cuts, address(0), "");
//             console.log("New ManagementFacet added successfully!");
            
//         } else {
//             console.log("Replacing existing ManagementFacet from:", currentManagementFacet);
            
//             // Get the current function selectors
//             bytes4[] memory currentSelectors = diamondLoupe.facetFunctionSelectors(currentManagementFacet);
//             console.log("Current selectors count:", currentSelectors.length);
            
//             // Define new function selectors (including confirm functions and getter functions)
//             bytes4[] memory newSelectors = new bytes4[](5);
//             newSelectors[0] = ManagementFacet.confirmMint.selector;
//             newSelectors[1] = ManagementFacet.confirmBurn.selector;
//             newSelectors[2] = ManagementFacet.xchainGetMessenger.selector;
//             newSelectors[3] = ManagementFacet.xchainGetDstEid.selector;
//             newSelectors[4] = ManagementFacet.xchainGetOptions.selector;
            
//             // We need two operations: Replace existing functions and Add new functions
//             IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](2);
            
//             // 1. Replace existing functions with the new facet
//             cuts[0] = IDiamondCut.FacetCut({
//                 facetAddress: address(newManagementFacet),
//                 action: IDiamondCut.FacetCutAction.Replace,
//                 functionSelectors: currentSelectors
//             });
            
//             // 2. Add new functions (confirm functions and getters)
//             cuts[1] = IDiamondCut.FacetCut({
//                 facetAddress: address(newManagementFacet),
//                 action: IDiamondCut.FacetCutAction.Add,
//                 functionSelectors: newSelectors
//             });
            
//             diamondCut.diamondCut(cuts, address(0), "");
//             console.log("ManagementFacet replaced and new functions added successfully!");
//         }
        
//         console.log("New facet address:", address(newManagementFacet));
        
//         vm.stopBroadcast();
//     }
// }
