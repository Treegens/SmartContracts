// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {ChainConfig} from "./ChainConfig.s.sol";
import {ManagementFacet} from "../src/facets/ManagementFacet.sol";
import {MessagingFee} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {BaseMgroOapp} from "../src/bridge/BaseMgroOapp.sol";

contract MintMgro is Script {
    function run() external {
        vm.startBroadcast();
        address diamond = vm.envAddress("DIAMOND_ADDRESS");
        
        ManagementFacet mgmt = ManagementFacet(diamond);

        // Read the stored cross-chain configuration from the diamond
        address messenger = mgmt.xchainGetMessenger();
        uint32 dstEid = mgmt.xchainGetDstEid();
        
        console.log("Stored Messenger:", messenger);
        console.log("Stored DstEid:", dstEid);

        // Get quote for cross-chain mint operation using stored options
        MessagingFee memory fee = BaseMgroOapp(messenger).quoteMint(
            dstEid, 
            msg.sender, 
            1012,
            false
        );
        console.log("Quote:", fee.nativeFee);
        
        // Call mintMgroTokens which handles the cross-chain logic internally
        mgmt.mintMgroTokens{value: fee.nativeFee}(msg.sender, 101);

        vm.stopBroadcast();
    }
}