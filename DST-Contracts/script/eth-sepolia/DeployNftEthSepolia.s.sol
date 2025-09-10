// SPDX-License-Identifier: GPL
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {TreegenNFT} from "../../src/onft/TreegenNFT.sol";
import {ChainConfig} from "../../script/ChainConfig.s.sol";
import {CREATE3} from "../../lib/solady/src/utils/CREATE3.sol";

/**
 * @title DeployNftEthSepolia
 * @notice Script for deploying TreegenNFT on Ethereum Sepolia using CREATE3 with same salt as canonical
 * @dev This will deploy to the same address as the canonical NFT on Base Sepolia
 */
contract DeployNftEthSepolia is Script {

    function run() external returns (address nft_) {
        address nftUpdater = address(0);
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        console.log("=== Deploying TreegenNFT on Ethereum Sepolia ===");

        // Verify we're on Ethereum Sepolia (chainId 11155111)
        require(block.chainid == 11155111, "Must be deployed on Ethereum Sepolia");

        // Get deployer address
        address deployer = msg.sender;
        console.log("Deployer:", deployer);

        // Use the SAME salt as canonical deployment for deterministic address
        string memory saltString = vm.envString("NFT_SALT");
        bytes32 salt = keccak256(abi.encode(saltString));
        console.log("CREATE3 Salt (same as canonical):", vm.toString(salt));

        // Use the default URI from ChainConfig
        string memory defaultURI = "https://nft.treegens.org/meta/";

        // Predict the deployment address (should be same as canonical)
        address predictedAddress = CREATE3.predictDeterministicAddress(salt, deployer);
        console.log("Predicted NFT address:", predictedAddress);
        console.log("Note: This should match the canonical NFT address on Base Sepolia");

        // Get LayerZero endpoint for Ethereum Sepolia
        ChainConfig.LzInfo memory info = ChainConfig.getLzInfo(block.chainid);

        // Create initialization code with correct constructor parameters
        bytes memory initCode = abi.encodePacked(
            type(TreegenNFT).creationCode,
            abi.encode("Treegen", "TGN", defaultURI, info.endpoint, deployer, nftUpdater)
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
        console.log("Role: NFT_ETH_SEPOLIA");
        console.log("Note: This NFT has the same address as the canonical on Base Sepolia");

        vm.stopBroadcast();

        return nft_;
    }
}
