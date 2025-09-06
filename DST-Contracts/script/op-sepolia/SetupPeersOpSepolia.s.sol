// SPDX-License-Identifier: GPL
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {MGRO} from "../../src/MGRO.sol";
import {TreegenNFT} from "../../src/onft/TreegenNFT_Canonical.sol";
import {ChainConfig} from "../../script/ChainConfig.s.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

/**
 * @title SetupPeersOpSepolia
 * @notice Script for setting up peers and enforced options for OP Sepolia contracts
 */
contract SetupPeersOpSepolia is Script {
    using OptionsBuilder for bytes;

    function run(
        address mgroAddress,
        address nftAddress,
        address baseSepoliaMgroOappAddress,
        address baseSepoliaNftAddress
    ) external {
        vm.startBroadcast();

        console.log("=== Setting up Peers on OP Sepolia ===");

        // Verify we're on OP Sepolia (chainId 11155420)
        require(block.chainid == 11155420, "Must be deployed on OP Sepolia");

        // Get destination EID for Base Sepolia
        uint32 dstEid = ChainConfig.partnerEid(block.chainid);
        console.log("Destination EID (Base Sepolia):", dstEid);

        console.log("MGRO:", mgroAddress);
        console.log("NFT:", nftAddress);
        console.log("Base Sepolia MGRO Oapp:", baseSepoliaMgroOappAddress);
        console.log("Base Sepolia NFT:", baseSepoliaNftAddress);

        // Setup MGRO (OFT) peer and enforced options
        MGRO mgro = MGRO(mgroAddress);

        console.log("Setting up MGRO peer...");
        mgro.setPeer(dstEid, bytes32(uint256(uint160(baseSepoliaMgroOappAddress))));

        console.log("Setting up MGRO enforced options...");
        bytes memory oftEnforcedOptions = OptionsBuilder
            .newOptions()
            .addExecutorLzReceiveOption(uint128(200000), uint128(0)); // 200000 gas limit for OFT

        console.log("MGRO enforced options set with gas limit: 200000");

        // Setup TreegenNFT peer and enforced options
        TreegenNFT nft = TreegenNFT(nftAddress);

        console.log("Setting up TreegenNFT peer...");
        nft.setPeer(dstEid, bytes32(uint256(uint160(baseSepoliaNftAddress))));

        console.log("Setting up TreegenNFT enforced options...");
        bytes memory nftEnforcedOptions = OptionsBuilder
            .newOptions()
            .addExecutorLzReceiveOption(uint128(200000), uint128(0)); // 200000 gas limit for ONFT

        console.log("TreegenNFT enforced options set with gas limit: 200000");

        console.log("=== Peer Setup Complete ===");

        vm.stopBroadcast();
    }
}
