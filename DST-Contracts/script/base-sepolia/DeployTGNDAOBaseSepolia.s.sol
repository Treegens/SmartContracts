// SPDX-License-Identifier: GPL
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {TGNDAO} from "../../src/TGNDAO.sol";
import {IVotes} from "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";

/**
 * @title DeployTGNDAOBaseSepolia
 * @notice Script for deploying TGNDAO on Base Sepolia
 */
contract DeployTGNDAOBaseSepolia is Script {

    function run() external returns (address dao_) {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        console.log("=== Deploying TGNDAO on Base Sepolia ===");

        // Verify we're on Base Sepolia (chainId 84532)
        require(block.chainid == 84532, "Must be deployed on Base Sepolia");

        // Get deployer address
        address deployer = vm.addr(privateKey);
        console.log("Deployer:", deployer);

        // Deploy TGNDAO
        TGNDAO dao = new TGNDAO(
            IVotes(deployer),  // _token (must be IVotes compatible)
            4,                // _quorumPercentage (4%)
            1,                // _votingDelay (1 block)
            45818             // _votingPeriod (~1 week in blocks)
        );
        dao_ = address(dao);

        console.log("TGNDAO deployed at:", dao_);

        // Verify deployment
        // TGNDAO doesn't have an owner() function as it's a governance contract
        // Verification is done by checking the voting token and parameters instead
        require(address(dao.token()) == deployer, "Voting token not set correctly");
        console.log("TGNDAO voting token verified:", address(dao.token()));

        console.log("=== TGNDAO Deployment Complete ===");
        console.log("TGNDAO address:", dao_);
        console.log("Chain ID:", block.chainid);

        vm.stopBroadcast();

        return dao_;
    }
}
