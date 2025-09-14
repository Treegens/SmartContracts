// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {CeloMgroOapp} from "../src/bridge/CeloMgroOapp.sol";
import {MGRO} from "../src/MGRO.sol";
import {ILayerZeroEndpointV2, Origin} from "../lib/layerzero-v2/packages/layerzero-v2/evm/protocol/contracts/interfaces/ILayerZeroEndpointV2.sol";

contract LZForkPrankTest is Test {
	// Mainnet addresses (from env.example / ChainConfig)
	address constant LZ_ENDPOINT_MAINNET = 0x1a44076050125825900e736c501f859c50fE728c;
	address constant CELO_MESSENGER = 0x43576228672F058dE4131A1C0996A920E3B68028;
	address constant BASE_MESSENGER = 0x735976BD7F55c3bB1ae101F7B4b6b7208504296E;
	uint32  constant BASE_EID = 30184; // Base mainnet EID

	function test_celo_receive_mint_prankEndpoint() external {
		// Use the celo RPC endpoint from foundry.toml [rpc_endpoints]
		uint256 celoFork = vm.createFork(vm.rpcUrl("celo"));
		vm.selectFork(celoFork);

		CeloMgroOapp oapp = CeloMgroOapp(payable(CELO_MESSENGER));
		address mgroAddr = address(oapp.mgro());
		MGRO mgro = MGRO(mgroAddr);

		// Pick a test user and amount
		address testUser = address(0x1111222233334444555566667777888899990001);
		uint256 amount = 1e9; // 1,000,000,000 units (adjust as needed)

		uint256 beforeBal = mgro.balanceOf(testUser);

		// Build the same payload CeloMgroOapp expects from BaseMgroOapp
		// enum Operation { Mint, Burn } => Mint = 0
		bytes memory payload = abi.encode(uint8(0), testUser, amount);

		Origin memory origin = Origin({
			srcEid: BASE_EID,
			sender: bytes32(uint256(uint160(BASE_MESSENGER))),
			nonce: 1
		});

		bytes32 guid = keccak256(abi.encodePacked(blockhash(block.number - 1), address(this), testUser, amount));

		// Prank as the LayerZero Endpoint and directly call lzReceive on the OApp
		vm.prank(LZ_ENDPOINT_MAINNET);
		oapp.lzReceive(origin, guid, payload, address(0), "");

		uint256 afterBal = mgro.balanceOf(testUser);
		assertEq(afterBal, beforeBal + amount, "MGRO mint not reflected after lzReceive");
	}
}
