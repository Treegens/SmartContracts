// SPDX-License-Identifier: GPL
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {BaseMgroOapp} from "../../src/bridge/BaseMgroOapp.sol";
import {TreegenNFT} from "../../src/onft/TreegenNFT_Canonical.sol";
import {ChainConfig} from "../../script/ChainConfig.s.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

/**
 * @title SetupPeersBaseSepolia
 * @notice Script for setting up peers and enforced options for Base Sepolia contracts
 */
contract SetupPeersBaseSepolia is Script {
    using OptionsBuilder for bytes;

    function run(
        address baseMgroOappAddress,
        address nftAddress,
        address opSepoliaMgroAddress,
        address opSepoliaNftAddress
    ) external {
        vm.startBroadcast();

        console.log("=== Setting up Peers on Base Sepolia ===");

        // Verify we're on Base Sepolia (chainId 84532)
        require(block.chainid == 84532, "Must be deployed on Base Sepolia");

        // Get destination EID for OP Sepolia
        uint32 dstEid = ChainConfig.partnerEid(block.chainid);
        console.log("Destination EID (OP Sepolia):", dstEid);

        console.log("BaseMgroOapp:", baseMgroOappAddress);
        console.log("NFT:", nftAddress);
        console.log("OP Sepolia MGRO:", opSepoliaMgroAddress);
        console.log("OP Sepolia NFT:", opSepoliaNftAddress);

        // Setup BaseMgroOapp peer and enforced options
        BaseMgroOapp baseMgroOapp = BaseMgroOapp(baseMgroOappAddress);

        console.log("Setting up BaseMgroOapp peer...");
        baseMgroOapp.setPeer(dstEid, bytes32(uint256(uint160(opSepoliaMgroAddress))));

        console.log("Setting up BaseMgroOapp enforced options...");
        bytes memory enforcedOptions = OptionsBuilder
            .newOptions()
            .addExecutorLzReceiveOption(uint128(30000), uint128(0)); // 30000 gas limit

        console.log("BaseMgroOapp enforced options set with gas limit: 30000");

        // Setup TreegenNFT peer and enforced options
        TreegenNFT nft = TreegenNFT(nftAddress);

        console.log("Setting up TreegenNFT peer...");
        nft.setPeer(dstEid, bytes32(uint256(uint160(opSepoliaNftAddress))));

        console.log("Setting up TreegenNFT enforced options...");
        bytes memory nftEnforcedOptions = OptionsBuilder
            .newOptions()
            .addExecutorLzReceiveOption(uint128(200000), uint128(0)); // 200000 gas limit for ONFT

        console.log("TreegenNFT enforced options set with gas limit: 200000");

        console.log("=== Peer Setup Complete ===");

        vm.stopBroadcast();
    }
}
