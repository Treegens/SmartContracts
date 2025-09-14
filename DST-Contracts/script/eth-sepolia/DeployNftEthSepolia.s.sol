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
        uint256 privateKey = vm.envUint("MAINNET_PRIVATE_KEY");
        address deployer = vm.addr(privateKey);

        // Record initial gas and ETH balance
        uint256 gasAtStart = gasleft();
        uint256 ethAtStart = deployer.balance;

        vm.startBroadcast(privateKey);

        console.log("=== Deploying TreegenNFT on Ethereum Sepolia ===");

        // Get deployer address
        console.log("Deployer:", deployer);

        // Use the SAME salt as canonical deployment for deterministic address
        string memory saltString = vm.envString("MAINNET_NFT_SALT");
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
            abi.encode("Treegens Dynamic NFT Agent", "TREEGEN", defaultURI, info.endpoint, deployer, nftUpdater)
        );

        // Deploy using CREATE3
        nft_ = CREATE3.deployDeterministic(initCode, salt);
        TreegenNFT nft = TreegenNFT(nft_);

        // Record gas and ETH after deployment
        uint256 gasAtEnd = gasleft();
        uint256 ethAtEnd = deployer.balance;

        uint256 gasUsed = gasAtStart - gasAtEnd;
        uint256 ethUsed = ethAtStart > ethAtEnd ? ethAtStart - ethAtEnd : 0;

        console.log("TreegenNFT deployed at:", nft_);
        console.log("Address matches prediction:", nft_ == predictedAddress);

        // Verify deployment
        require(nft.owner() == deployer, "Owner not set correctly");
        console.log("NFT owner verified:", nft.owner());
        console.log("NFT default URI:", defaultURI);

        // Log gas and ETH usage
        console.log("=== Deployment Gas and ETH Usage ===");
        console.log("Gas used:", gasUsed);
        console.log("ETH used (wei):", ethUsed);

        console.log("=== TreegenNFT Deployment Complete ===");
        console.log("NFT address:", nft_);
        console.log("Chain ID:", block.chainid);
        console.log("Role: NFT_ETH_SEPOLIA");
        console.log("Note: This NFT has the same address as the canonical on Base Sepolia");

        vm.stopBroadcast();

        return nft_;
    }
}
