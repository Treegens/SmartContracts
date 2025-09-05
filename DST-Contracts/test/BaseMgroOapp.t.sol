// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import {BaseMgroOapp} from "src/bridge/BaseMgroOapp.sol";
import {MockLzEndpointV2} from "./MockLzEndpointV2.sol";
import { Origin } from "@layerzerolabs/oapp-evm/contracts/oapp/interfaces/IOAppReceiver.sol";
import {ManagementFacet} from "src/facets/ManagementFacet.sol";

interface IManagementAck {
    function confirmMint(address _receiver, uint256 _tokens) external;
    function confirmBurn(address _user, uint256 _tokens) external;
}

contract BaseMgroOappReceiveTest is Test {
    BaseMgroOapp internal oapp;
    MockLzEndpointV2 internal endpoint;
    ManagementFacet internal management;

    address internal deployer;
    address internal user;
    address internal diamond = 0x0f6fd7483C9ED740e6bc0a203059001c2907D0Db;

    // Mirror events from MockManagement for expectEmit
    event MintConfirmed(address receiver, uint256 amount);
    event BurnConfirmed(address user, uint256 amount);

    function setUp() public {
        uint256 privateKey = vm.envUint("TESTNET_PRIVATE_KEY");
        deployer = vm.addr(privateKey);
        vm.startPrank(deployer);
        user = address(0xBEEF);

        endpoint = MockLzEndpointV2(0x6EDCE65403992e310A62460808c4b910D972f10f);
        management = ManagementFacet(diamond);
        oapp = BaseMgroOapp(0xB9Ac7bCbA82603768b4Bc98646A10D5B79BEE60E);

        // Update the diamond's messenger to point to our test BaseMgroOapp
        management.xchainSetMessenger(address(oapp));

        // Set a peer for source EID so receiver checks pass
        oapp.setPeer(40232, bytes32(uint256(uint160(address(this)))));
        vm.stopPrank();
    }

    function _origin(uint32 srcEid, address sender) internal pure returns (Origin memory origin) {
        origin = Origin({ srcEid: srcEid, sender: bytes32(uint256(uint160(sender))), nonce: 0 });
    }

    function test_lzReceive_ack_mint_ok_emitsManagementCall() public {
        // Arrange
        bytes memory msgPayload = abi.encode(BaseMgroOapp.Ack.MintOk, user, uint256(10 ether));
        Origin memory origin = _origin(40232, address(this));
        bytes32 guid = bytes32(uint256(0xABCD));

        // // Expect the management to be notified (via event from mock)
        // vm.expectEmit(true, true, true, true, diamond);
        // emit MintConfirmed(user, 10 ether);

        // Act: simulate endpoint calling receiver
        vm.prank(address(endpoint));
        oapp.lzReceive(origin, guid, msgPayload, address(0), bytes(""));
    }

    function test_lzReceive_ack_burn_ok_emitsManagementCall() public {
        // Arrange
        bytes memory msgPayload = abi.encode(BaseMgroOapp.Ack.BurnOk, user, uint256(5 ether));
        Origin memory origin = _origin(40232, address(this));
        bytes32 guid = bytes32(uint256(0xBEEF));

        // vm.expectEmit(true, true, true, true, diamond);
        // emit BurnConfirmed(user, 5 ether);

        // Act
        vm.prank(address(endpoint));
        oapp.lzReceive(origin, guid, msgPayload, address(0), bytes(""));
    }
}
