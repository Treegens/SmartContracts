// SPDX-License-Identifier: GPL
pragma solidity ^0.8.17;

// Import required contracts and libraries
import "forge-std/Script.sol"; // Foundry script utilities
import {MGRO} from "../src/MGRO.sol"; // Main MGRO token contract
import {ChainConfig} from "../script/ChainConfig.s.sol"; // Chain configuration helper
import {CeloMgroOapp} from "../src/bridge/CeloMgroOapp.sol"; // Bridge receiver contract
import { OptionsBuilder } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
import {CREATE3} from "../lib/solady/src/utils/CREATE3.sol"; // Deterministic deployment library

/**
 * @title DeployMgroCelo
 * @notice Script for deploying MGRO token and its receiver contract on Celo chain
 * @dev Uses CREATE3 for deterministic deployment addresses
 */
contract DeployMgroCelo is Script {
    using OptionsBuilder for bytes;
    /**
     * @notice Main deployment function
     * @return mgro_ Address of deployed MGRO contract
     * @dev Steps:
     * 1. Get chain configuration
     * 2. Deploy MGRO deterministically
     * 3. Deploy receiver contract
     * 4. Set receiver as MGRO management
     * 5. Save deployment details
     */
    function run() external returns (address mgro_) {
        vm.startBroadcast();

        // Get LayerZero endpoint info for current chain
        ChainConfig.LzInfo memory info = ChainConfig.getLzInfo(block.chainid);
        require(info.endpoint != address(0), "Unsupported chain for MGRO");

        // Get delegate from env or use caller as fallback
        address delegate = msg.sender;

        // Deterministic MGRO deployment with fixed salt
        bytes32 salt = keccak256(abi.encode("Treegens_MGRO_V1"));
        bytes memory initCode = abi.encodePacked(
            type(MGRO).creationCode, 
            abi.encode(info.endpoint, delegate)
        );
        mgro_ = CREATE3.deployDeterministic(initCode, salt);
        MGRO mgro = MGRO(mgro_);
        console.log("[DeployMgroCelo] MGRO:", mgro_);

        // Deploy receiver contract for bridge functionality
        CeloMgroOapp receiver = new CeloMgroOapp(
            info.endpoint,
            delegate,
            mgro_
        );
        address receiverAddr = address(receiver);
        console.log("[DeployMgroCelo] CeloMgroOapp:", receiverAddr);

        // Configure MGRO with receiver as management contract
        mgro.setManagementContract(receiverAddr);
        console.log("[DeployMgroCelo] MGRO management set to receiver");

        // Note: ack options are now enforced by the endpoint, no need to set them
        console.log("[DeployMgroCelo] Using enforced ack options from endpoint");

        				// Log deployment details
		console.log("[DeployMgroCelo] chainId:", block.chainid);
		console.log("[DeployMgroCelo] eid:", info.eid);
		console.log("[DeployMgroCelo] role: MGRO_CHAIN");

        console.log("[DeployMgroCelo] endpoint:", info.endpoint, "eid:", info.eid);

        vm.stopBroadcast();
    }

}
