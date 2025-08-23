// SPDX-License-Identifier: GPL
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {ChainConfig} from "script/ChainConfig.s.sol";
import {console} from "forge-std/console.sol";
import {CeloMgroReceiver} from "../src/bridge/CeloMgroReceiver.sol";
import {BaseMgroMessenger} from "../src/bridge/BaseMgroMessenger.sol";

contract LayerZeroSetup is Script {
    
    function run() external {

        uint256 privateKey = vm.envUint("TESTNET_PRIVATE_KEY");

        address celoMgroReceiver = 0x2F7c2CEAdf6BCda06232FC4b76806a63C5A903E9; // OP Sepolia
        address baseMgroMessenger = 0xA84eC7CF3F5797A615d2518d65333E66001E496E; // Base Sepolia
        
        console.log("=== EID Configuration ===");
        console.log("OP Sepolia (11155420) EID:", ChainConfig.partnerEid(11155420));
        console.log("Base Sepolia (84532) EID:", ChainConfig.partnerEid(84532));
        
        // Setup OP Sepolia fork - CeloMgroReceiver sets peer to Base Sepolia (source of messages)
        vm.createSelectFork(vm.rpcUrl("op_sepolia"));
        vm.startBroadcast(privateKey);
        vm.chainId(11155420);
        console.log("=== Setting up CeloMgroReceiver on OP Sepolia ===");
        console.log("Chain ID:", block.chainid);
        console.log("Setting peer to Base Sepolia EID:", ChainConfig.partnerEid(block.chainid));
        // CeloMgroReceiver on OP Sepolia should accept messages from Base Sepolia (EID 40245)
        CeloMgroReceiver(celoMgroReceiver).setPeer(40245, bytes32(uint256(uint160(baseMgroMessenger))));
        vm.stopBroadcast();

        // Setup Base Sepolia fork - BaseMgroMessenger sets peer to OP Sepolia (source of messages)
        vm.createSelectFork(vm.rpcUrl("base_sepolia"));
        vm.startBroadcast(privateKey);
        vm.chainId(84532);
        console.log("=== Setting up BaseMgroMessenger on Base Sepolia ===");
        console.log("Chain ID:", block.chainid);
        console.log("Setting peer to OP Sepolia EID:", ChainConfig.partnerEid(block.chainid));
        // BaseMgroMessenger on Base Sepolia should accept messages from OP Sepolia (EID 40232)
        BaseMgroMessenger(baseMgroMessenger).setPeer(40232, bytes32(uint256(uint160(celoMgroReceiver)));
        vm.stopBroadcast();
        
        console.log("=== Peer Setup Complete ===");
        console.log("CeloMgroReceiver (OP Sepolia) now accepts messages from Base Sepolia (EID 40245)");
        console.log("BaseMgroMessenger (Base Sepolia) now accepts messages from OP Sepolia (EID 40232)");
    }
}