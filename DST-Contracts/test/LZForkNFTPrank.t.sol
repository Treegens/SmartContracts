// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {TreegenNFT} from "../src/onft/TreegenNFT.sol";
import {ILayerZeroEndpointV2, Origin} from "../lib/layerzero-v2/packages/layerzero-v2/evm/protocol/contracts/interfaces/ILayerZeroEndpointV2.sol";

contract LZForkNFTPrankTest is Test {
	// Mainnet addresses
	address constant LZ_ENDPOINT_MAINNET = 0x1a44076050125825900e736c501f859c50fE728c;
	address constant NFT_ADDR = 0xef8B62026895A09D6A631181008969677b7A5ABB; // same address on Base/Ethereum per env
	uint32  constant BASE_EID = 30184;
	uint32  constant ETH_EID  = 30101;

	function test_base_receive_nft_from_eth_prankEndpoint() external {
		// Fork Base and select
		uint256 baseFork = vm.createFork(vm.rpcUrl("base"));
		vm.selectFork(baseFork);

		TreegenNFT nftBase = TreegenNFT(NFT_ADDR);

		// Ensure peer for ETH_EID is set to NFT_ADDR (Ethereum side)
		address ownerBase = nftBase.owner();
		vm.prank(ownerBase);
		nftBase.setPeer(ETH_EID, bytes32(uint256(uint160(NFT_ADDR))));

		address user = address(0xaaaAbbBBCccCDDddEeEEFFfF1111222233334444);
		uint256 tokenId = 987654321; // choose an unused token id

		// Expect no owner yet (if it reverts, it's fine; we'll just proceed to mint on receive)
		// Build ONFT message payload: abi.encodePacked(sendTo, tokenId)
		bytes memory payload = abi.encodePacked(bytes32(uint256(uint160(user))), tokenId);

		Origin memory origin = Origin({
			srcEid: ETH_EID,
			sender: bytes32(uint256(uint160(NFT_ADDR))),
			nonce: 1
		});
		bytes32 guid = keccak256(abi.encodePacked(blockhash(block.number - 1), address(this), user, tokenId));

		// Prank as endpoint and deliver to Base NFT
		vm.prank(LZ_ENDPOINT_MAINNET);
		nftBase.lzReceive(origin, guid, payload, address(0), "");

		assertEq(nftBase.ownerOf(tokenId), user, "Base receive did not mint to user");
	}

	function test_eth_receive_nft_from_base_prankEndpoint() external {
		// Fork Ethereum and select
		uint256 ethFork = vm.createFork(vm.rpcUrl("ethereum"));
		vm.selectFork(ethFork);

		TreegenNFT nftEth = TreegenNFT(NFT_ADDR);

		// Ensure peer for BASE_EID is set to NFT_ADDR (Base side)
		address ownerEth = nftEth.owner();
		vm.prank(ownerEth);
		nftEth.setPeer(BASE_EID, bytes32(uint256(uint160(NFT_ADDR))));

		address user = address(0x9999888877776666555544443333222211110000);
		uint256 tokenId = 123456789; // choose an unused token id

		bytes memory payload = abi.encodePacked(bytes32(uint256(uint160(user))), tokenId);

		Origin memory origin = Origin({
			srcEid: BASE_EID,
			sender: bytes32(uint256(uint160(NFT_ADDR))),
			nonce: 1
		});
		bytes32 guid = keccak256(abi.encodePacked(blockhash(block.number - 1), address(this), user, tokenId));

		vm.prank(LZ_ENDPOINT_MAINNET);
		nftEth.lzReceive(origin, guid, payload, address(0), "");

		assertEq(nftEth.ownerOf(tokenId), user, "Ethereum receive did not mint to user");
	}
}
