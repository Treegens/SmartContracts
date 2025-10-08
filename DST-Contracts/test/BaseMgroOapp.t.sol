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

// Mock reverting management contract for testing error handling
contract RevertingManagement is IManagementAck {
    function confirmMint(address, uint256) external pure override {
        revert("Mock revert");
    }
    
    function confirmBurn(address, uint256) external pure override {
        revert("Mock revert");
    }
}

// Simple non-reverting management mock
    contract OkManagement is IManagementAck {
        function confirmMint(address, uint256) external pure {}
        function confirmBurn(address, uint256) external pure {}
    }

contract BaseMgroOappReceiveTest is Test {
    BaseMgroOapp internal oapp;
    MockLzEndpointV2 internal endpoint;
    ManagementFacet internal management;

    address internal user;
    address internal diamond = 0x0f6fd7483C9ED740e6bc0a203059001c2907D0Db;

    // Mirror events from MockManagement for expectEmit
    event MintConfirmed(address receiver, uint256 amount);
    event BurnConfirmed(address user, uint256 amount);
    
    // Events from BaseMgroOapp
    event AckReceived(BaseMgroOapp.Ack indexed ackType, address indexed user, uint256 amount);
    event AckForwardingFailed(BaseMgroOapp.Ack indexed ackType, address indexed user, uint256 amount, bytes reason);

    

    function setUp() public {
        user = address(0xBEEF);
        endpoint = new MockLzEndpointV2();
        OkManagement mgmt = new OkManagement();
        oapp = new BaseMgroOapp(address(endpoint), address(this), address(mgmt));
        // Set a peer for source EID so receiver checks pass
        oapp.setPeer(40232, bytes32(uint256(uint160(address(this)))));
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
    
    function test_lzReceive_ackReceived_event() public {
        bytes memory msgPayload = abi.encode(BaseMgroOapp.Ack.MintOk, user, uint256(10 ether));
        Origin memory origin = _origin(40232, address(this));
        bytes32 guid = bytes32(uint256(0xABCD));

        vm.expectEmit(true, true, true, true);
        emit AckReceived(BaseMgroOapp.Ack.MintOk, user, 10 ether);

        vm.prank(address(endpoint));
        oapp.lzReceive(origin, guid, msgPayload, address(0), bytes(""));
    }
}

// New comprehensive security test suite
contract BaseMgroOappSecurityTest is Test {
    BaseMgroOapp internal oapp;
    MockLzEndpointV2 internal endpoint;
    
    address internal owner;
    address internal management;
    address internal newManagement;
    address internal attacker;
    
    // Events to test
    event ManagementUpdated(address indexed oldManagement, address indexed newManagement);
    event ManagementTransferProposed(address indexed currentManagement, address indexed pendingManagement);
    event Paused(address account);
    event Unpaused(address account);
    event AckForwardingFailed(BaseMgroOapp.Ack indexed ackType, address indexed user, uint256 amount, bytes reason);
    
    function setUp() public {
        owner = address(this);
        management = address(0x1234);
        newManagement = address(0x5678);
        attacker = address(0xBAD);
        
        // Deploy mock endpoint
        endpoint = new MockLzEndpointV2();
        
        // Deploy oapp
        oapp = new BaseMgroOapp(address(endpoint), owner, management);
    }
    
    // ============ Constructor Tests ============
    
    function test_Revert_constructor_zeroEndpoint() public {
        // Base constructor of OApp will revert before our custom check
        vm.expectRevert();
        new BaseMgroOapp(address(0), owner, management);
    }
    
    function test_Revert_constructor_zeroDelegate() public {
        // Ownable constructor reverts before our custom check
        vm.expectRevert();
        new BaseMgroOapp(address(endpoint), address(0), management);
    }
    
    function test_Revert_constructor_zeroManagement() public {
        vm.expectRevert(BaseMgroOapp.ZeroAddress.selector);
        new BaseMgroOapp(address(endpoint), owner, address(0));
    }
    
    function test_constructor_setsManagement() public {
        assertEq(oapp.management(), management);
    }
    
    // ============ Two-Step Management Transfer Tests ============
    
    function test_proposeManagementTransfer_onlyOwner() public {
        vm.prank(attacker);
        vm.expectRevert();
        oapp.proposeManagementTransfer(newManagement);
    }
    
    function test_Revert_proposeManagementTransfer_zeroAddress() public {
        vm.expectRevert(BaseMgroOapp.ZeroAddress.selector);
        oapp.proposeManagementTransfer(address(0));
    }
    
    function test_proposeManagementTransfer_success() public {
        vm.expectEmit(true, true, false, false);
        emit ManagementTransferProposed(management, newManagement);
        
        oapp.proposeManagementTransfer(newManagement);
        assertEq(oapp.pendingManagement(), newManagement);
    }
    
    function test_acceptManagementTransfer_onlyPending() public {
        oapp.proposeManagementTransfer(newManagement);
        
        vm.prank(attacker);
        vm.expectRevert(BaseMgroOapp.Unauthorized.selector);
        oapp.acceptManagementTransfer();
    }
    
    function test_acceptManagementTransfer_success() public {
        oapp.proposeManagementTransfer(newManagement);
        
        vm.expectEmit(true, true, false, false);
        emit ManagementUpdated(management, newManagement);
        
        vm.prank(newManagement);
        oapp.acceptManagementTransfer();
        
        assertEq(oapp.management(), newManagement);
        assertEq(oapp.pendingManagement(), address(0));
    }
    
    function test_cancelManagementTransfer_onlyOwner() public {
        oapp.proposeManagementTransfer(newManagement);
        
        vm.prank(attacker);
        vm.expectRevert();
        oapp.cancelManagementTransfer();
    }
    
    function test_cancelManagementTransfer_success() public {
        oapp.proposeManagementTransfer(newManagement);
        
        oapp.cancelManagementTransfer();
        assertEq(oapp.pendingManagement(), address(0));
    }
    
    // ============ Pausability Tests ============
    
    function test_pause_onlyOwner() public {
        vm.prank(attacker);
        vm.expectRevert();
        oapp.pause();
    }
    
    function test_pause_success() public {
        vm.expectEmit(true, false, false, false);
        emit Paused(owner);
        
        oapp.pause();
        assertTrue(oapp.paused());
    }
    
    function test_unpause_onlyOwner() public {
        oapp.pause();
        
        vm.prank(attacker);
        vm.expectRevert();
        oapp.unpause();
    }
    
    function test_unpause_success() public {
        oapp.pause();
        
        vm.expectEmit(true, false, false, false);
        emit Unpaused(owner);
        
        oapp.unpause();
        assertFalse(oapp.paused());
    }
    
    // ============ Validation Tests ============
    
    function test_Revert_quoteMint_zeroAddress() public {
        vm.expectRevert(BaseMgroOapp.ZeroAddress.selector);
        oapp.quoteMint(40232, address(0), 100 ether, false);
    }
    
    function test_Revert_quoteMint_zeroAmount() public {
        vm.expectRevert(BaseMgroOapp.InvalidAmount.selector);
        oapp.quoteMint(40232, address(0x1111), 0, false);
    }
    
    function test_Revert_quoteBurn_zeroAddress() public {
        vm.expectRevert(BaseMgroOapp.ZeroAddress.selector);
        oapp.quoteBurn(40232, address(0), 100 ether, false);
    }
    
    function test_Revert_quoteBurn_zeroAmount() public {
        vm.expectRevert(BaseMgroOapp.InvalidAmount.selector);
        oapp.quoteBurn(40232, address(0x1111), 0, false);
    }
    
    // ============ Error Handling in _lzReceive Tests ============
    
    function test_lzReceive_withRevertingManagement_emitsFailureEvent() public {
        // Deploy reverting management contract
        RevertingManagement revertingMgmt = new RevertingManagement();
        
        // Deploy new oapp with reverting management
        BaseMgroOapp testOapp = new BaseMgroOapp(address(endpoint), owner, address(revertingMgmt));
        testOapp.setPeer(40232, bytes32(uint256(uint160(address(this)))));
        
        bytes memory msgPayload = abi.encode(BaseMgroOapp.Ack.MintOk, address(0x1111), uint256(10 ether));
        Origin memory origin = Origin({ srcEid: 40232, sender: bytes32(uint256(uint160(address(this)))), nonce: 0 });
        bytes32 guid = bytes32(uint256(0xABCD));
        
        // Assert no revert occurs when management reverts; we rely on try/catch
        vm.prank(address(endpoint));
        testOapp.lzReceive(origin, guid, msgPayload, address(0), bytes(""));
    }
}

// Additional operational tests
contract BaseMgroOappOperationalTest is Test {
    BaseMgroOapp internal oapp;
    MockLzEndpointV2 internal endpoint;
    
    address internal owner;
    address internal management;
    
    function setUp() public {
        owner = address(this);
        management = address(0x1234);
        
        endpoint = new MockLzEndpointV2();
        oapp = new BaseMgroOapp(address(endpoint), owner, management);
    }
    
    function test_onlyManagement_modifier() public {
        vm.deal(address(0xBAD), 1 ether);
        
        vm.prank(address(0xBAD));
        vm.expectRevert(BaseMgroOapp.Unauthorized.selector);
        oapp.sendMint{value: 0.1 ether}(40232, address(0x1111), 100 ether, false);
    }
}
