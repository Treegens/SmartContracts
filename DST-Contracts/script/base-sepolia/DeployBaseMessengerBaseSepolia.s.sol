// SPDX-License-Identifier: GPL
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {BaseMgroOapp} from "../../src/bridge/BaseMgroOapp.sol";
import {ChainConfig} from "../../script/ChainConfig.s.sol";
import {ManagementFacet} from "../../src/facets/ManagementFacet.sol";

/**
 * @title DeployBaseMessengerBaseSepolia
 * @notice Script for deploying BaseMgroOapp (messenger) on Base Sepolia
 */
contract DeployBaseMessengerBaseSepolia is Script {

    function run() external returns (address messenger_) {

        address diamondAddress = vm.envAddress("DIAMOND_ADDRESS");
        ManagementFacet mgmt = ManagementFacet(diamondAddress);
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);
        vm.startBroadcast(privateKey);

        console.log("=== Deploying BaseMgroOapp on Base Sepolia ===");

        // Verify we're on Base Sepolia (chainId 84532)
        require(block.chainid == 84532, "Must be deployed on Base Sepolia");

        // Get LayerZero endpoint info
        ChainConfig.LzInfo memory info = ChainConfig.getLzInfo(block.chainid);
        require(info.endpoint != address(0), "Unsupported chain for BaseMgroOapp");

        console.log("Chain ID:", block.chainid);
        console.log("LZ Endpoint:", info.endpoint);
        console.log("LZ EID:", info.eid);
        console.log("Diamond address:", diamondAddress);

        // Get deployer address
        console.log("Deployer:", deployer);

        // Deploy BaseMgroOapp
        BaseMgroOapp messenger = new BaseMgroOapp(
            info.endpoint,
            deployer,
            diamondAddress
        );
        messenger_ = address(messenger);

        console.log("BaseMgroOapp deployed at:", messenger_);

        // Verify deployment
        require(messenger.management() == diamondAddress, "Management not set correctly");
        require(messenger.owner() == deployer, "Owner not set correctly");
        console.log("BaseMgroOapp management verified:", messenger.management());
        console.log("BaseMgroOapp owner verified:", messenger.owner());

        // Get destination EID for OP Sepolia
        uint32 dstEid = ChainConfig.partnerEid(block.chainid);
        console.log("Destination EID (OP Sepolia):", dstEid);

        console.log("=== BaseMgroOapp Deployment Complete ===");
        console.log("BaseMgroOapp address:", messenger_);
        console.log("Chain ID:", block.chainid);
        console.log("Role: BASE_MESSENGER");

        mgmt.xchainSetMessenger(address(messenger));
        mgmt.xchainSetDstEid(dstEid);

        vm.stopBroadcast();

        return messenger_;
    }
}
