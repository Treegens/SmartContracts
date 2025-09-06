// SPDX-License-Identifier: GPL
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {TGNDAO} from "../../src/TGNDAO.sol";

/**
 * @title DeployTGNDAOBaseSepolia
 * @notice Script for deploying TGNDAO on Base Sepolia
 */
contract DeployTGNDAOBaseSepolia is Script {

    function run() external returns (address dao_) {
        vm.startBroadcast();

        console.log("=== Deploying TGNDAO on Base Sepolia ===");

        // Verify we're on Base Sepolia (chainId 84532)
        require(block.chainid == 84532, "Must be deployed on Base Sepolia");

        // Get deployer address
        address deployer = msg.sender;
        console.log("Deployer:", deployer);

        // Deploy TGNDAO
        TGNDAO dao = new TGNDAO();
        dao_ = address(dao);

        console.log("TGNDAO deployed at:", dao_);

        // Verify deployment
        require(dao.owner() == deployer, "Owner not set correctly");
        console.log("TGNDAO owner verified:", dao.owner());

        console.log("=== TGNDAO Deployment Complete ===");
        console.log("TGNDAO address:", dao_);
        console.log("Chain ID:", block.chainid);

        vm.stopBroadcast();

        return dao_;
    }
}
