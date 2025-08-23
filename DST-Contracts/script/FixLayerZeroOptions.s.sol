// SPDX-License-Identifier: GPL
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {ManagementFacet} from "../src/facets/ManagementFacet.sol";

contract FixLayerZeroOptions is Script {
    
    function run() external {
        uint256 privateKey = vm.envUint("TESTNET_PRIVATE_KEY");
        
        // Address of your diamond
        address diamond = 0x956b2cE17260a22dA2eE5E48dB50f6CC35e0B1A0; // base sepolia
        
        vm.startBroadcast(privateKey);
        
        ManagementFacet mgmt = ManagementFacet(diamond);
        
        // Check current options
        bytes memory currentOptions = mgmt.xchainGetOptions();
        console.log("Current options:");
        console.logBytes(currentOptions);
        console.log("Current options length:", currentOptions.length);
        
        // Let's try the legacy Type 1 format instead of Type 3
        // Type 1 format: [uint16 type][uint256 gasLimit]  
        uint32 gasLimit = 200000;
        
        bytes memory legacyOptions = abi.encodePacked(
            uint16(1),           // Type 1 (legacy)
            uint256(gasLimit)    // Gas limit as uint256
        );
        
        console.log("Using legacy Type 1 options:");
        console.logBytes(legacyOptions);
        console.log("Legacy options length:", legacyOptions.length);
        
        // Also try a simpler Type 3 approach
        bytes memory simpleType3 = abi.encodePacked(
            uint16(3),      // Type 3 options
            uint8(1),       // Worker ID = 1 (Executor)
            uint16(17),     // Option size = 17 bytes  
            uint8(1),       // Option type = 1 (LzReceive)
            uint128(gasLimit)  // Gas limit
        );
        
        console.log("Simple Type 3 options:");
        console.logBytes(simpleType3);
        
        // Let's try the legacy Type 1 format first (it's simpler and more reliable)
        console.log("Setting legacy Type 1 options:");
        mgmt.xchainSetOptions(legacyOptions);
        
        // Verify the options were set correctly
        bytes memory verifyOptions = mgmt.xchainGetOptions();
        console.log("Verified options:");
        console.logBytes(verifyOptions);
        
        console.log("LayerZero options fixed successfully!");
        
        vm.stopBroadcast();
    }
}
