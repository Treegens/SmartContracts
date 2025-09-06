// SPDX-License-Identifier: GPL
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {TreegenNFT} from "../../src/onft/TreegenNFT_Canonical.sol";
import {ChainConfig} from "../../script/ChainConfig.s.sol";
import {CREATE3} from "../../lib/solady/src/utils/CREATE3.sol";

/**
 * @title DeployNftOpSepolia
 * @notice Script for deploying TreegenNFT on OP Sepolia using CREATE3 with same salt as canonical
 * @dev This will deploy to the same address as the canonical NFT on Base Sepolia
 */
contract DeployNftOpSepolia is Script {

    function run() external returns (address nft_) {
        vm.startBroadcast();

        console.log("=== Deploying TreegenNFT on OP Sepolia ===");

        // Verify we're on OP Sepolia (chainId 11155420)
        require(block.chainid == 11155420, "Must be deployed on OP Sepolia");

        // Get deployer address
        address deployer = msg.sender;
        console.log("Deployer:", deployer);

        // Use the SAME salt as canonical deployment for deterministic address
        bytes32 salt = keccak256(abi.encode("Treegens_NFT_V1_CANONICAL"));
        console.log("CREATE3 Salt (same as canonical):", vm.toString(salt));

        // Use the default URI from ChainConfig
        string memory defaultURI = ChainConfig.BASE_URI_A;

        // Predict the deployment address (should be same as canonical)
        address predictedAddress = CREATE3.predictDeterministicAddress(salt, address(this));
        console.log("Predicted NFT address:", predictedAddress);
        console.log("Note: This should match the canonical NFT address on Base Sepolia");

        // Get LayerZero endpoint for OP Sepolia
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
        console.log("Address matches prediction:", nft_ == predictedAddress);

        // Verify deployment
        require(nft.owner() == deployer, "Owner not set correctly");
        console.log("NFT owner verified:", nft.owner());
        console.log("NFT default URI:", defaultURI);

        console.log("=== TreegenNFT Deployment Complete ===");
        console.log("NFT address:", nft_);
        console.log("Chain ID:", block.chainid);
        console.log("Role: NFT_OP_SEPOLIA");
        console.log("Note: This NFT has the same address as the canonical on Base Sepolia");

        vm.stopBroadcast();

        return nft_;
    }
}
