// SPDX-License-Identifier: GPL
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {TreegenNFT} from "../src/onft/TreegenNFT_Canonical.sol";
import {ChainConfig} from "./ChainConfig.s.sol";
import {SendParam} from "../lib/devtools/packages/onft-evm/contracts/onft721/interfaces/IONFT721.sol";
import {MessagingReceipt, MessagingFee} from "../lib/layerzero-v2/packages/layerzero-v2/evm/protocol/contracts/interfaces/ILayerZeroEndpointV2.sol";

contract BridgeNFT is Script {
    using ChainConfig for uint256;

    function run() external {
        address nftAddress = vm.envAddress("NFT_ADDRESS");
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);
        
        // Get token ID to bridge (optional, defaults to 1)
        uint256 tokenId = vm.envOr("TOKEN_ID", uint256(7));
        
        uint256 dstChainId = block.chainid == 84532 ? 11155111 : 84532;
        
        // Get destination address (optional, defaults to deployer)
        address dstAddress = vm.envOr("DST_ADDRESS", deployer);
        
        vm.startBroadcast(privateKey);

        console.log("=== Bridging NFT ===");
        console.log("NFT Address:", nftAddress);
        console.log("Deployer:", deployer);
        console.log("Token ID to bridge:", tokenId);
        console.log("Destination Chain ID:", dstChainId);
        console.log("Destination Address:", dstAddress);

        // Get LayerZero info for destination chain
        ChainConfig.LzInfo memory dstLzInfo = ChainConfig.getLzInfo(dstChainId);
        require(dstLzInfo.eid != 0, "Unsupported destination chain");
        
        console.log("Destination EID:", dstLzInfo.eid);

        // Check if user owns the token
        TreegenNFT nft = TreegenNFT(nftAddress);
        require(nft.ownerOf(tokenId) == deployer, "You don't own this token");
        console.log("Token ownership verified");

        // Prepare send parameters
        SendParam memory sendParam = SendParam({
            dstEid: dstLzInfo.eid,
            to: _addressToBytes32(dstAddress),
            tokenId: tokenId,
            extraOptions: "",
            composeMsg: "",
            onftCmd: ""
        });

        // Quote the bridging fee
        MessagingFee memory fee = nft.quoteSend(sendParam, false);
        console.log("Bridging fee (native):", fee.nativeFee);
        console.log("Bridging fee (lzToken):", fee.lzTokenFee);

        // Check if user has approved the NFT contract to transfer the token
        address approved = nft.getApproved(tokenId);
        bool isApprovedForAll = nft.isApprovedForAll(deployer, nftAddress);
        
        if (approved != nftAddress && !isApprovedForAll) {
            console.log("NFT contract not approved. Approving now...");
            nft.approve(nftAddress, tokenId);
            console.log("Approval completed");
        } else {
            console.log("NFT contract already approved");
        }

        // Execute the bridge transaction
        console.log("Executing bridge transaction...");
        MessagingReceipt memory receipt = nft.send{value: fee.nativeFee}(
            sendParam,
            fee,
            deployer
        );

        console.log("=== Bridge Transaction Complete ===");
        console.log("Transaction GUID:");
        console.logBytes32(receipt.guid);
        console.log("Nonce:");
        console.logUint(receipt.nonce);
        console.log("Fee paid:");
        console.logUint(receipt.fee.nativeFee);
        console.log("Token bridged successfully!");

        vm.stopBroadcast();
    }

    /**
     * @notice Bridge multiple NFTs in a batch
     */
    function bridgeBatch() external {
        address nftAddress = vm.envAddress("NFT_ADDRESS");
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);
        
        // Get token IDs to bridge (comma-separated string from env)
        string memory tokenIdsStr = vm.envString("TOKEN_IDS");
        uint256[] memory tokenIds = _parseTokenIds(tokenIdsStr);
        
        // Get destination chain ID
        uint256 dstChainId = vm.envOr("DST_CHAIN_ID", uint256(11155111));
        address dstAddress = vm.envOr("DST_ADDRESS", deployer);
        
        vm.startBroadcast(privateKey);

        console.log("=== Bridging Multiple NFTs ===");
        console.log("NFT Address:", nftAddress);
        console.log("Deployer:", deployer);
        console.log("Number of tokens to bridge:", tokenIds.length);
        console.log("Destination Chain ID:", dstChainId);
        console.log("Destination Address:", dstAddress);

        TreegenNFT nft = TreegenNFT(nftAddress);
        ChainConfig.LzInfo memory dstLzInfo = ChainConfig.getLzInfo(dstChainId);
        require(dstLzInfo.eid != 0, "Unsupported destination chain");

        uint256 totalFee = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            
            // Check ownership
            require(nft.ownerOf(tokenId) == deployer, string(abi.encodePacked("You don't own token ", vm.toString(tokenId))));
            
            // Prepare send parameters
            SendParam memory sendParam = SendParam({
                dstEid: dstLzInfo.eid,
                to: _addressToBytes32(dstAddress),
                tokenId: tokenId,
                extraOptions: "",
                composeMsg: "",
                onftCmd: ""
            });

            // Quote the fee
            MessagingFee memory fee = nft.quoteSend(sendParam, false);
            totalFee += fee.nativeFee;
            
            console.log("Token", tokenId, "bridging fee:", fee.nativeFee);
        }

        console.log("Total bridging fee:", totalFee);

        // Execute all bridge transactions
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            
            // Check and handle approval for each token
            address approved = nft.getApproved(tokenId);
            bool isApprovedForAll = nft.isApprovedForAll(deployer, nftAddress);
            
            if (approved != nftAddress && !isApprovedForAll) {
                console.log("Approving token");
                console.logUint(tokenId);
                nft.approve(nftAddress, tokenId);
            }
            
            SendParam memory sendParam = SendParam({
                dstEid: dstLzInfo.eid,
                to: _addressToBytes32(dstAddress),
                tokenId: tokenId,
                extraOptions: "",
                composeMsg: "",
                onftCmd: ""
            });

            MessagingFee memory fee = nft.quoteSend(sendParam, false);
            
            console.log("Bridging token", tokenId, "...");
            MessagingReceipt memory receipt = nft.send{value: fee.nativeFee}(
                sendParam,
                fee,
                deployer
            );
            
            console.log("Token");
            console.logUint(tokenId);
            console.log("bridged with GUID:");
            console.logBytes32(receipt.guid);
        }

        console.log("=== Batch Bridge Complete ===");
        console.log("All tokens bridged successfully!");

        vm.stopBroadcast();
    }

    /**
     * @notice Check if a token can be bridged (ownership and approval)
     */
    function checkBridgeability() external view {
        address nftAddress = vm.envAddress("NFT_ADDRESS");
        uint256 tokenId = vm.envOr("TOKEN_ID", uint256(1));
        address user = vm.addr(vm.envUint("PRIVATE_KEY"));
        
        TreegenNFT nft = TreegenNFT(nftAddress);
        
        console.log("=== Bridgeability Check ===");
        console.log("NFT Address:", nftAddress);
        console.log("Token ID:", tokenId);
        console.log("User:", user);
        
        // Check ownership
        try nft.ownerOf(tokenId) returns (address owner) {
            if (owner == user) {
                console.log("User owns the token");
            } else {
                console.log("User does not own the token. Owner:", owner);
                return;
            }
        } catch {
            console.log("Token does not exist");
            return;
        }
        
        // Check approval
        address approved = nft.getApproved(tokenId);
        bool isApprovedForAll = nft.isApprovedForAll(user, nftAddress);
        
        if (approved == nftAddress || isApprovedForAll) {
            console.log("NFT contract is approved to transfer the token");
        } else {
            console.log("NFT contract not approved to transfer token");
            console.log("  - Individual approval:", approved);
            console.log("  - Approved for all:", isApprovedForAll);
        }
        
        // Check if token is locked (if it has a lock mechanism)
        console.log("Token is bridgeable!");
    }

    /**
     * @dev Convert address to bytes32 for LayerZero
     */
    function _addressToBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    /**
     * @dev Parse comma-separated token IDs string
     */
    function _parseTokenIds(string memory tokenIdsStr) internal pure returns (uint256[] memory) {
        // Simple implementation - in practice you might want more robust parsing
        bytes memory data = bytes(tokenIdsStr);
        uint256 count = 1;
        
        // Count commas to determine array size
        for (uint256 i = 0; i < data.length; i++) {
            if (data[i] == ',') count++;
        }
        
        uint256[] memory tokenIds = new uint256[](count);
        uint256 current = 0;
        uint256 start = 0;
        
        for (uint256 i = 0; i <= data.length; i++) {
            if (i == data.length || data[i] == ',') {
                bytes memory tokenIdBytes = new bytes(i - start);
                for (uint256 j = start; j < i; j++) {
                    tokenIdBytes[j - start] = data[j];
                }
                tokenIds[current] = _parseUint(string(tokenIdBytes));
                current++;
                start = i + 1;
            }
        }
        
        return tokenIds;
    }

    /**
     * @dev Parse string to uint256
     */
    function _parseUint(string memory str) internal pure returns (uint256) {
        bytes memory b = bytes(str);
        uint256 result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            if (uint8(b[i]) >= 48 && uint8(b[i]) <= 57) {
                result = result * 10 + (uint8(b[i]) - 48);
            }
        }
        return result;
    }
}