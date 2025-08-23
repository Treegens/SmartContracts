// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {ChainConfig} from "./ChainConfig.s.sol";
import {ManagementFacet} from "../src/facets/ManagementFacet.sol";
import {MessagingFee} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {BaseMgroMessenger} from "../src/bridge/BaseMgroMessenger.sol";

contract MintMgro is Script {
    function run() external {
        vm.startBroadcast();
        address diamond = 0x956b2cE17260a22dA2eE5E48dB50f6CC35e0B1A0;
        
        ManagementFacet mgmt = ManagementFacet(diamond);

        // Read the stored cross-chain configuration from the diamond
        address messenger = mgmt.xchainGetMessenger();
        uint32 dstEid = mgmt.xchainGetDstEid();
        bytes memory lzOptions = mgmt.xchainGetOptions();
        console.logBytes(lzOptions);
        
        console.log("Stored Messenger:", messenger);
        console.log("Stored DstEid:", dstEid);
        console.log("Stored Options Length:", lzOptions.length);

        // Get quote for cross-chain mint operation using stored options
        MessagingFee memory fee = BaseMgroMessenger(messenger).quoteMint(
            dstEid, 
            msg.sender, 
            101, 
            lzOptions, // Use stored LayerZero options
            false
        );
        console.log("Quote:", fee.nativeFee);
        
        // Call mintMgroTokens which handles the cross-chain logic internally
        mgmt.mintMgroTokens{value: fee.nativeFee}(msg.sender, 101);

        vm.stopBroadcast();
    }
}
