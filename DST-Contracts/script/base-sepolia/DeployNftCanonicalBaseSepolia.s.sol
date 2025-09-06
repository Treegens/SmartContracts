// SPDX-License-Identifier: GPL
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {TreegenNFT} from "../../src/onft/TreegenNFT_Canonical.sol";
import {ChainConfig} from "../../script/ChainConfig.s.sol";
import {CREATE3} from "../../lib/solady/src/utils/CREATE3.sol";

/**
 * @title DeployNftCanonicalBaseSepolia
 * @notice Script for deploying TreegenNFT canonical on Base Sepolia using CREATE3 for deterministic address
 */
contract DeployNftCanonicalBaseSepolia is Script {

    function run() external returns (address nft_) {
        vm.startBroadcast();

        console.log("=== Deploying TreegenNFT Canonical on Base Sepolia ===");

        // Verify we're on Base Sepolia (chainId 84532)
        require(block.chainid == 84532, "Must be deployed on Base Sepolia");

        // Get deployer address
        address deployer = msg.sender;
        console.log("Deployer:", deployer);

        // Use deterministic salt for CREATE3 - same salt will be used on OP Sepolia
        bytes32 salt = keccak256(abi.encode("Treegens_NFT_V1_CANONICAL"));
        console.log("CREATE3 Salt:", vm.toString(salt));

        // Use the default URI from ChainConfig
        string memory defaultURI = ChainConfig.BASE_URI_A;

        // Predict the deployment address
        address predictedAddress = CREATE3.predictDeterministicAddress(salt, address(this));
        console.log("Predicted NFT address:", predictedAddress);

        // Get LayerZero endpoint for Base Sepolia
        ChainConfig.LzInfo memory info = ChainConfig.getLzInfo(block.chainid);

        // Create initialization code with correct constructor parameters
        bytes memory initCode = abi.encodePacked(
            type(TreegenNFT).creationCode,
            abi.encode("Treegen", "TGN", defaultURI, info.endpoint, deployer)
        );

        // Deploy using CREATE3
        nft_ = CREATE3.deployDeterministic(initCode, salt);
        TreegenNFT nft = TreegenNFT(nft_);

        console.log("TreegenNFT deployed at:", nft_);
        console.log("Actual address matches prediction:", nft_ == predictedAddress);

        // Verify deployment
        require(nft.owner() == deployer, "Owner not set correctly");
        console.log("NFT owner verified:", nft.owner());
        console.log("NFT default URI:", defaultURI);

        console.log("=== TreegenNFT Canonical Deployment Complete ===");
        console.log("NFT address:", nft_);
        console.log("Chain ID:", block.chainid);
        console.log("Role: NFT_CANONICAL");

        vm.stopBroadcast();

        return nft_;
    }
}
