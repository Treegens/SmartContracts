// SPDX-License-Identifier: GPL
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {MGRO} from "../../src/MGRO.sol";
import {ChainConfig} from "../../script/ChainConfig.s.sol";
import {CREATE3} from "../../lib/solady/src/utils/CREATE3.sol";

/**
 * @title DeployMgroOpSepolia
 * @notice Script for deploying MGRO token on OP Sepolia using CREATE3 for deterministic address
 */
contract DeployMgroOpSepolia is Script {

    function run() external returns (address mgro_) {
        vm.startBroadcast();

        console.log("=== Deploying MGRO on OP Sepolia ===");

        // Verify we're on OP Sepolia (chainId 11155420)
        require(block.chainid == 11155420, "Must be deployed on OP Sepolia");

        // Get LayerZero endpoint info
        ChainConfig.LzInfo memory info = ChainConfig.getLzInfo(block.chainid);
        require(info.endpoint != address(0), "Unsupported chain for MGRO");

        console.log("Chain ID:", block.chainid);
        console.log("LZ Endpoint:", info.endpoint);
        console.log("LZ EID:", info.eid);

        // Get deployer address
        address deployer = msg.sender;
        console.log("Deployer:", deployer);

        // Use deterministic salt for CREATE3
        string memory saltString = vm.envString("MGRO_SALT");
        bytes32 salt = keccak256(abi.encode(saltString));
        console.log("CREATE3 Salt:", vm.toString(salt));

        // Predict the deployment address
        address predictedAddress = CREATE3.predictDeterministicAddress(salt, deployer);
        console.log("Predicted MGRO address:", predictedAddress);

        // Create initialization code
        bytes memory initCode = abi.encodePacked(
            type(MGRO).creationCode,
            abi.encode(info.endpoint, deployer)
        );

        // Deploy using CREATE3
        mgro_ = CREATE3.deployDeterministic(initCode, salt);
        MGRO mgro = MGRO(mgro_);

        console.log("MGRO deployed at:", mgro_);
        console.log("Actual address matches prediction:", mgro_ == predictedAddress);

        // Verify deployment
        require(mgro.owner() == deployer, "Owner not set correctly");
        console.log("MGRO owner verified:", mgro.owner());

        console.log("=== MGRO Deployment Complete ===");
        console.log("MGRO address:", mgro_);
        console.log("Chain ID:", block.chainid);
        console.log("Role: MGRO_CHAIN");

        vm.stopBroadcast();

        return mgro_;
    }
}
