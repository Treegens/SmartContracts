// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {MGRO} from "src/MGRO.sol";
import {CeloMgroOapp} from "src/bridge/CeloMgroOapp.sol";
import {MockLzEndpointV2} from "./MockLzEndpointV2.sol";
import {MessagingFee} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";

import { Origin } from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppReceiver.sol";

contract CeloMgroOappReceiveTest is Test {
    MGRO internal mgro;
    CeloMgroOapp internal oapp;
    MockLzEndpointV2 internal endpoint;

    address internal deployer;
    address internal user;

    function setUp() public {
        deployer = address(this);
        user = address(0xBEEF);

        // Deploy mock endpoint and contracts
        endpoint = new MockLzEndpointV2();
        mgro = new MGRO(address(endpoint), deployer);

        // OApp delegate/owner is deployer in tests
        oapp = new CeloMgroOapp(address(endpoint), deployer, address(mgro));

        // Allow the receiver to control MGRO supply as management
        mgro.setManagementContract(address(oapp));
    }

    function _origin(uint32 srcEid, address sender) internal pure returns (Origin memory origin) {
        // Construct a minimal Origin; the structure comes from IOAppReceiver
        origin = Origin({ srcEid: srcEid, sender: bytes32(uint256(uint160(sender))), nonce: 0 });
    }

    function test_lzReceive_mint_mintsMGROAndAttemptsAck() public {
        // vm.createSelectFork({urlOrAlias: "op_sepolia"});
        // vm.startBroadcast(vm.envUint("TESTNET_PRIVATE_KEY"));
        uint256 amount = 10 ether;

        // Build the exact payload used for minting on the receiver side
        bytes memory payload = abi.encode(CeloMgroOapp.Operation.Mint, user, amount);

        // Simulate LayerZero endpoint calling into the OApp receiver
        Origin memory origin = _origin(40245, address(this)); // arbitrary srcEid and sender
        bytes32 guid = bytes32(uint256(0xDEADBEEF));
        address executor = address(0);
        bytes memory extraData = bytes("");

        // Set up a peer for EID 200 to avoid NoPeer error
        oapp.setPeer(40245, bytes32(uint256(uint160(address(this)))));

        vm.prank(address(endpoint));
        oapp.lzReceive{value: 0.001 ether}(origin, guid, payload, executor, extraData);

        // MGRO should be minted to user by the receiver
        assertEq(mgro.balanceOf(user), amount, "mint should credit user");
    }
}


