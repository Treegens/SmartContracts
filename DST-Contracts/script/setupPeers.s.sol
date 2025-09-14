// SPDX-License-Identifier: GPL
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {ChainConfig} from "./ChainConfig.s.sol";
import {BaseMgroOapp} from "../src/bridge/BaseMgroOapp.sol";
import {CeloMgroOapp} from "../src/bridge/CeloMgroOapp.sol";
import {TreegenNFT} from "../src/onft/TreegenNFT.sol";

contract SetupPeers is Script {
    
    function run() external {
        address base_messenger = vm.envAddress("MAINNET_BASE_MESSENGER");
        address celo_messenger = vm.envAddress("MAINNET_CELO_MESSENGER");
        address nft = vm.envAddress("MAINNET_NFT_ADDRESS");

        uint32 baseEid = uint32(ChainConfig.getLzInfo(8453).eid);
        uint32 celoEid = uint32(ChainConfig.getLzInfo(42220).eid);
        uint32 ethereumEid = uint32(ChainConfig.getLzInfo(1).eid);
        
        console.log("=== Setting up LayerZero Peers ===");
        console.log("Base EID:", baseEid);
        console.log("Celo EID:", celoEid);
        console.log("Ethereum EID:", ethereumEid);

        // Configure Base mainnet
        console.log("\n--- Configuring Base Mainnet ---");
        // vm.createSelectFork(vm.rpcUrl("base"));
        // vm.startBroadcast();

        // // BaseMgroOapp: Base -> Celo
        // console.log("Setting BaseMgroOapp peer (Base -> Celo)");
        // BaseMgroOapp(base_messenger).setPeer(celoEid, bytes32(uint256(uint160(celo_messenger))));
        // console.log("BaseMgroOapp peer set");

        // // TreegenNFT: Base -> Ethereum
        // console.log("Setting TreegenNFT peer (Base -> Ethereum)");
        // TreegenNFT(nft).setPeer(ethereumEid, bytes32(uint256(uint160(nft))));
        // console.log("TreegenNFT peer set");

        // vm.stopBroadcast();

        // Configure Celo mainnet
        console.log("\n--- Configuring Celo Mainnet ---");
        vm.createSelectFork(vm.rpcUrl("celo"));
        vm.startBroadcast();

        // CeloMgroOapp: Celo -> Base
        console.log("Setting CeloMgroOapp peer (Celo -> Base)");
        CeloMgroOapp(payable(celo_messenger)).setPeer(baseEid, bytes32(uint256(uint160(base_messenger))));
        console.log("CeloMgroOapp peer set");

        vm.stopBroadcast();

        // Configure Ethereum mainnet
        console.log("\n--- Configuring Ethereum Mainnet ---");
        vm.createSelectFork(vm.rpcUrl("ethereum"));
        vm.startBroadcast();

        // TreegenNFT: Ethereum -> Base
        console.log("Setting TreegenNFT peer (Ethereum -> Base)");
        TreegenNFT(nft).setPeer(baseEid, bytes32(uint256(uint160(nft))));
        console.log("TreegenNFT peer set");

        vm.stopBroadcast();

        console.log("\n=== All peers configured successfully! ===");
    }
}
