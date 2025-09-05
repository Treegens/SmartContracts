// SPDX-License-Identifier: GPL
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
import {ManagementFacet} from "../src/facets/ManagementFacet.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../src/interfaces/IDiamondLoupe.sol";

contract AddMissingSelectors is Script {
    
    function run() external {
        uint256 privateKey = vm.envUint("TESTNET_PRIVATE_KEY");
        
        // Address of your existing diamond
        address diamond = 0x0f6fd7483C9ED740e6bc0a203059001c2907D0Db; // base sepolia
        
        vm.startBroadcast(privateKey);
        // Get the DiamondCutFacet and DiamondLoupeFacet from the diamond
        DiamondCutFacet diamondCut = DiamondCutFacet(diamond);
        DiamondLoupeFacet diamondLoupe = DiamondLoupeFacet(diamond);
        
        // Find the existing ManagementFacet
        IDiamondLoupe.Facet[] memory facets = diamondLoupe.facets();
        address currentManagementFacet = address(0);
        
        for (uint i = 0; i < facets.length; i++) {
            // Check if this facet has ManagementFacet functions
            bytes4[] memory selectors = diamondLoupe.facetFunctionSelectors(facets[i].facetAddress);
            for (uint j = 0; j < selectors.length; j++) {
                if (selectors[j] == ManagementFacet.initialize.selector) {
                    currentManagementFacet = facets[i].facetAddress;
                    console.log("Found ManagementFacet at:", currentManagementFacet);
                    break;
                }
            }
            if (currentManagementFacet != address(0)) break;
        }
        
        require(currentManagementFacet != address(0), "ManagementFacet not found in diamond");
        
        // Get current function selectors for the ManagementFacet
        bytes4[] memory currentSelectors = diamondLoupe.facetFunctionSelectors(currentManagementFacet);
        console.log("Current ManagementFacet selectors count:", currentSelectors.length);
        
        // Define the 8 missing function selectors
        bytes4[] memory missingSelectors = new bytes4[](5);
        missingSelectors[0] = ManagementFacet.confirmMint.selector;
        missingSelectors[1] = ManagementFacet.confirmBurn.selector;
        missingSelectors[2] = ManagementFacet.xchainGetMessenger.selector;
        missingSelectors[3] = ManagementFacet.xchainGetDstEid.selector;
     
        console.log("Adding 8 missing function selectors...");
        console.log("confirmMint selector:", vm.toString(ManagementFacet.confirmMint.selector));
        console.log("confirmBurn selector:", vm.toString(ManagementFacet.confirmBurn.selector));
        console.log("xchainGetMessenger selector:", vm.toString(ManagementFacet.xchainGetMessenger.selector));
        console.log("xchainGetDstEid selector:", vm.toString(ManagementFacet.xchainGetDstEid.selector));
        
        // Check if any of these selectors already exist
        for (uint i = 0; i < missingSelectors.length; i++) {
            address existingFacet = diamondLoupe.facetAddress(missingSelectors[i]);
            if (existingFacet != address(0)) {
                console.log("Selector", vm.toString(missingSelectors[i]), "already exists in facet:", existingFacet);
            }
        }

        for(uint i=0; i < missingSelectors.length; i++) {
        }

        for (uint i = 0; i < missingSelectors.length; i++) {
            address existingFacet = diamondLoupe.facetAddress(missingSelectors[i]);
            console.log("Facet address:", existingFacet);
        }
        
        // Create diamond cut to add missing selectors to existing ManagementFacet
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: currentManagementFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: missingSelectors
        });
        
        // Execute the diamond cut
        diamondCut.diamondCut(cuts, address(0), "");
        
        console.log("Successfully added 5 missing function selectors to diamond!");
        console.log("ManagementFacet address:", currentManagementFacet);
        
        // Verify the addition
        bytes4[] memory newSelectors = diamondLoupe.facetFunctionSelectors(currentManagementFacet);
        console.log("New ManagementFacet selectors count:", newSelectors.length);
        console.log("Added selectors:", newSelectors.length - currentSelectors.length);
        
        vm.stopBroadcast();
    }
}
