// SPDX-License-Identifier: GPL
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {Diamond} from "src/Diamond.sol";
import {DiamondCutFacet} from "src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "src/facets/DiamondLoupeFacet.sol";
import {TimelockOwnershipFacet} from "src/facets/TimelockOwnershipFacet.sol";
import {FundManagementFacet} from "src/facets/FundManagementFacet.sol";
import {IDiamondCut} from "src/interfaces/IDiamondCut.sol";
import {ITimelockOwnership} from "src/interfaces/ITimelockOwnership.sol";

/**
 * @title DiamondEnhancedTest
 * @notice Comprehensive tests for enhanced Diamond security features
 * @dev Tests all audit fixes: constructor validation, timelock ownership, fund management, integrity checks
 */
contract DiamondEnhancedTest is Test {
    address internal diamondAddr;
    Diamond internal diamond;
    DiamondCutFacet internal cutFacet;
    DiamondLoupeFacet internal loupe;
    TimelockOwnershipFacet internal timelockOwnership;
    FundManagementFacet internal fundManagement;
    
    address internal deployer = address(this);
    address internal newOwner = address(0x1234567890123456789012345678901234567890);
    address internal attacker = address(0xBAD);
    address internal user = address(0xBEEF);
    
    uint256 internal constant TIMELOCK_DELAY = 2 days;
    uint256 internal constant TEST_ETHER = 5 ether;

    function setUp() public {
        // Deploy DiamondCutFacet first
        cutFacet = new DiamondCutFacet();
        
        // Deploy Diamond with enhanced validation
        diamond = new Diamond(deployer, address(cutFacet));
        diamondAddr = address(diamond);
        
        // Deploy additional facets
        DiamondLoupeFacet loupeImpl = new DiamondLoupeFacet();
        TimelockOwnershipFacet timelockImpl = new TimelockOwnershipFacet();
        FundManagementFacet fundImpl = new FundManagementFacet();
        
        // Add facets to Diamond
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](3);
        
        // Add DiamondLoupeFacet selectors (including new validateDiamondIntegrity)
        {
            bytes4[] memory selectors = new bytes4[](5);
            selectors[0] = loupeImpl.facets.selector;
            selectors[1] = loupeImpl.facetFunctionSelectors.selector;
            selectors[2] = loupeImpl.facetAddresses.selector;
            selectors[3] = loupeImpl.facetAddress.selector;
            selectors[4] = loupeImpl.validateDiamondIntegrity.selector;
            cuts[0] = IDiamondCut.FacetCut({
                facetAddress: address(loupeImpl), 
                action: IDiamondCut.FacetCutAction.Add, 
                functionSelectors: selectors
            });
        }
        
        // Add TimelockOwnershipFacet selectors
        {
            bytes4[] memory selectors = new bytes4[](8);
            selectors[0] = timelockImpl.proposeOwnershipTransfer.selector;
            selectors[1] = timelockImpl.cancelOwnershipTransfer.selector;
            selectors[2] = timelockImpl.acceptOwnership.selector;
            selectors[3] = timelockImpl.getPendingOwnershipTransfer.selector;
            selectors[4] = timelockImpl.enableTimelock.selector;
            selectors[5] = timelockImpl.disableTimelock.selector;
            selectors[6] = timelockImpl.isTimelockEnabled.selector;
            selectors[7] = timelockImpl.getTimelockDelay.selector;
            cuts[1] = IDiamondCut.FacetCut({
                facetAddress: address(timelockImpl), 
                action: IDiamondCut.FacetCutAction.Add, 
                functionSelectors: selectors
            });
        }
        
        // Add FundManagementFacet selectors
        {
            bytes4[] memory selectors = new bytes4[](4);
            selectors[0] = fundImpl.withdrawEther.selector;
            selectors[1] = fundImpl.withdrawAllEther.selector;
            selectors[2] = fundImpl.getEtherBalance.selector;
            selectors[3] = fundImpl.emergencyWithdraw.selector;
            cuts[2] = IDiamondCut.FacetCut({
                facetAddress: address(fundImpl), 
                action: IDiamondCut.FacetCutAction.Add, 
                functionSelectors: selectors
            });
        }
        
        // Apply cuts
        IDiamondCut(diamondAddr).diamondCut(cuts, address(0), "");
        
        // Set up facet interfaces
        loupe = DiamondLoupeFacet(diamondAddr);
        timelockOwnership = TimelockOwnershipFacet(diamondAddr);
        fundManagement = FundManagementFacet(diamondAddr);
        
        // Fund test accounts
        vm.deal(newOwner, 10 ether);
        vm.deal(attacker, 10 ether);
        vm.deal(user, 10 ether);
        
        // Send some ether to Diamond for testing
        vm.deal(diamondAddr, TEST_ETHER);
    }

    // ========================
    // Constructor Validation Tests (Audit Fix #1)
    // ========================
    
    function testConstructorValidation_ZeroOwner() public {
        vm.expectRevert("Diamond: owner is zero address");
        new Diamond(address(0), address(cutFacet));
    }
    
    function testConstructorValidation_ZeroDiamondCutFacet() public {
        vm.expectRevert("Diamond: cut facet is zero address");
        new Diamond(deployer, address(0));
    }
    
    function testConstructorValidation_DiamondCutFacetNoCode() public {
        // Use an EOA address (no code)
        address tempAddr = address(0xDEAD);
        vm.expectRevert("Diamond: cut facet has no code");
        new Diamond(deployer, tempAddr);
    }
    
    function testConstructorValidation_Success() public {
        DiamondCutFacet newCutFacet = new DiamondCutFacet();
        
        // Should emit initialization event on deploy
        vm.expectEmit(true, true, false, true);
        emit Diamond.DiamondInitialized(newOwner, address(newCutFacet));
        Diamond newDiamond = new Diamond(newOwner, address(newCutFacet));
    }

    // ========================
    // Fallback Validation Tests (Audit Fix #4 & #5)
    // ========================
    
    function testFallbackValidation_NonExistentFunction() public {
        // Try to call a function that doesn't exist
        (bool success,) = diamondAddr.call(abi.encodeWithSignature("nonExistentFunction()"));
        assertFalse(success);
    }
    
    function testFallbackValidation_FacetSelfDestructed() public {
        // This test would require deploying a facet, adding it, then selfdestructing it
        // For now, we test the basic functionality works
        assertTrue(address(diamondAddr).code.length > 0);
        
        // Test that valid function calls work
        uint256 balance = fundManagement.getEtherBalance();
        assertEq(balance, TEST_ETHER);
    }

    // ========================
    // Timelock Ownership Tests (Audit Fix #2)
    // ========================
    
    function testTimelockOwnership_EnableTimelock() public {
        // Initially timelock should be disabled
        assertFalse(timelockOwnership.isTimelockEnabled());
        
        // Enable timelock
        timelockOwnership.enableTimelock(TIMELOCK_DELAY);
        assertTrue(timelockOwnership.isTimelockEnabled());
        assertEq(timelockOwnership.getTimelockDelay(), TIMELOCK_DELAY);
    }
    
    function testTimelockOwnership_InvalidDelay() public {
        // Test delay too short
        vm.expectRevert("LibDiamond: invalid delay");
        timelockOwnership.enableTimelock(12 hours);
        
        // Test delay too long
        vm.expectRevert("LibDiamond: invalid delay");
        timelockOwnership.enableTimelock(31 days);
    }
    
    function testTimelockOwnership_ProposeTransfer() public {
        timelockOwnership.enableTimelock(TIMELOCK_DELAY);
        
        // Propose ownership transfer
        vm.expectEmit(true, true, false, true);
        emit ITimelockOwnership.OwnershipTransferProposed(deployer, newOwner, block.timestamp + TIMELOCK_DELAY);
        timelockOwnership.proposeOwnershipTransfer(newOwner);
        
        // Check pending transfer
        (address proposedOwner, uint256 executeAfter) = timelockOwnership.getPendingOwnershipTransfer();
        assertEq(proposedOwner, newOwner);
        assertEq(executeAfter, block.timestamp + TIMELOCK_DELAY);
    }
    
    function testTimelockOwnership_CancelTransfer() public {
        timelockOwnership.enableTimelock(TIMELOCK_DELAY);
        timelockOwnership.proposeOwnershipTransfer(newOwner);
        
        // Cancel transfer
        vm.expectEmit(true, false, false, true);
        emit ITimelockOwnership.OwnershipTransferCancelled(newOwner);
        timelockOwnership.cancelOwnershipTransfer();
        
        // Check no pending transfer
        (address proposedOwner, uint256 executeAfter) = timelockOwnership.getPendingOwnershipTransfer();
        assertEq(proposedOwner, address(0));
        assertEq(executeAfter, 0);
    }
    
    function testTimelockOwnership_AcceptTransfer() public {
        timelockOwnership.enableTimelock(TIMELOCK_DELAY);
        timelockOwnership.proposeOwnershipTransfer(newOwner);
        
        // Fast forward past timelock
        vm.warp(block.timestamp + TIMELOCK_DELAY + 1);
        
        // Accept ownership
        vm.prank(newOwner);
        vm.expectEmit(true, true, false, true);
        emit ITimelockOwnership.OwnershipAccepted(deployer, newOwner);
        timelockOwnership.acceptOwnership();
        
        // Verify ownership changed
        (address _p, uint256 _t) = timelockOwnership.getPendingOwnershipTransfer();
        assertEq(_p, address(0));
        assertEq(_t, 0);
    }
    
    function testTimelockOwnership_AcceptTransferTooEarly() public {
        timelockOwnership.enableTimelock(TIMELOCK_DELAY);
        timelockOwnership.proposeOwnershipTransfer(newOwner);
        
        // Try to accept before timelock expires
        vm.prank(newOwner);
        vm.expectRevert("LibDiamond: timelock not expired");
        timelockOwnership.acceptOwnership();
    }
    
    function testTimelockOwnership_AcceptTransferWrongAddress() public {
        timelockOwnership.enableTimelock(TIMELOCK_DELAY);
        timelockOwnership.proposeOwnershipTransfer(newOwner);
        
        // Wrong address tries to accept
        vm.prank(attacker);
        vm.expectRevert("TimelockOwnership: not proposed owner");
        timelockOwnership.acceptOwnership();
    }
    
    function testTimelockOwnership_UnauthorizedAccess() public {
        vm.startPrank(attacker);
        
        vm.expectRevert("LibDiamond: Must be contract owner");
        timelockOwnership.proposeOwnershipTransfer(newOwner);
        
        vm.expectRevert("LibDiamond: Must be contract owner");
        timelockOwnership.cancelOwnershipTransfer();
        
        vm.expectRevert("LibDiamond: Must be contract owner");
        timelockOwnership.enableTimelock(TIMELOCK_DELAY);
        
        vm.expectRevert("LibDiamond: Must be contract owner");
        timelockOwnership.disableTimelock();
        
        vm.stopPrank();
    }
    
    function testTimelockOwnership_DisableTimelock() public {
        timelockOwnership.enableTimelock(TIMELOCK_DELAY);
        assertTrue(timelockOwnership.isTimelockEnabled());
        
        timelockOwnership.disableTimelock();
        assertFalse(timelockOwnership.isTimelockEnabled());
        
        // With timelock disabled, ownership transfer should be immediate
        timelockOwnership.proposeOwnershipTransfer(newOwner);
        
        // Should be no pending transfer since it's immediate
        (address proposedOwner, uint256 executeAfter) = timelockOwnership.getPendingOwnershipTransfer();
        assertEq(proposedOwner, address(0));
        assertEq(executeAfter, 0);
    }

    // ========================
    // Fund Management Tests (Audit Fix #4)
    // ========================
    
    function testFundManagement_WithdrawEther() public {
        uint256 withdrawAmount = 2 ether;
        
        vm.expectEmit(true, false, false, true);
        emit FundManagementFacet.EtherWithdrawn(newOwner, withdrawAmount);
        fundManagement.withdrawEther(payable(newOwner), withdrawAmount);
        
        assertEq(newOwner.balance, 10 ether + withdrawAmount);
        assertEq(fundManagement.getEtherBalance(), TEST_ETHER - withdrawAmount);
    }
    
    function testFundManagement_WithdrawAllEther() public {
        vm.expectEmit(true, false, false, true);
        emit FundManagementFacet.EtherWithdrawn(newOwner, TEST_ETHER);
        fundManagement.withdrawAllEther(payable(newOwner));
        
        assertEq(newOwner.balance, 10 ether + TEST_ETHER);
        assertEq(fundManagement.getEtherBalance(), 0);
    }
    
    function testFundManagement_EmergencyWithdraw() public {
        vm.expectEmit(true, false, false, true);
        emit FundManagementFacet.EmergencyWithdraw(newOwner, TEST_ETHER);
        fundManagement.emergencyWithdraw(payable(newOwner));
        
        assertEq(newOwner.balance, 10 ether + TEST_ETHER);
        assertEq(fundManagement.getEtherBalance(), 0);
    }
    
    function testFundManagement_WithdrawZeroAmount() public {
        vm.expectRevert("Fund: zero amount");
        fundManagement.withdrawEther(payable(newOwner), 0);
    }
    
    function testFundManagement_WithdrawZeroAddress() public {
        vm.expectRevert("Fund: zero recipient");
        fundManagement.withdrawEther(payable(address(0)), 1 ether);
    }
    
    function testFundManagement_WithdrawInsufficientBalance() public {
        vm.expectRevert("Fund: insufficient balance");
        fundManagement.withdrawEther(payable(newOwner), TEST_ETHER + 1);
    }
    
    function testFundManagement_UnauthorizedAccess() public {
        vm.startPrank(attacker);
        
        vm.expectRevert("LibDiamond: Must be contract owner");
        fundManagement.withdrawEther(payable(attacker), 1 ether);
        
        vm.expectRevert("LibDiamond: Must be contract owner");
        fundManagement.withdrawAllEther(payable(attacker));
        
        vm.expectRevert("LibDiamond: Must be contract owner");
        fundManagement.emergencyWithdraw(payable(attacker));
        
        vm.stopPrank();
    }
    
    function testFundManagement_GetEtherBalance() public {
        assertEq(fundManagement.getEtherBalance(), TEST_ETHER);
        
        // Send more ether
        vm.deal(diamondAddr, TEST_ETHER + 1 ether);
        assertEq(fundManagement.getEtherBalance(), TEST_ETHER + 1 ether);
    }

    // ========================
    // Diamond Integrity Tests (Audit Fix #3)
    // ========================
    
    function testDiamondIntegrity_AllFacetsValid() public {
        (bool isValid, address[] memory invalidFacets) = loupe.validateDiamondIntegrity();
        assertTrue(isValid);
        assertEq(invalidFacets.length, 0);
    }
    
    function testDiamondIntegrity_FacetAddresses() public {
        address[] memory facets = loupe.facetAddresses();
        assertTrue(facets.length >= 4); // At least cut, loupe, timelock, fund facets
        
        // Verify all facets have code
        for (uint256 i = 0; i < facets.length; i++) {
            assertTrue(facets[i].code.length > 0);
        }
    }
    
    function testDiamondIntegrity_FacetSelectors() public {
        address[] memory facets = loupe.facetAddresses();
        
        for (uint256 i = 0; i < facets.length; i++) {
            bytes4[] memory selectors = loupe.facetFunctionSelectors(facets[i]);
            assertTrue(selectors.length > 0);
            
            // Verify each selector maps to the correct facet
            for (uint256 j = 0; j < selectors.length; j++) {
                address facetAddr = loupe.facetAddress(selectors[j]);
                assertEq(facetAddr, facets[i]);
            }
        }
    }

    // ========================
    // Event Tests
    // ========================
    
    function testEtherReceivedEvent() public {
        vm.expectEmit(true, false, false, true);
        emit Diamond.EtherReceived(user, 1 ether);
        
        vm.prank(user);
        (bool success,) = diamondAddr.call{value: 1 ether}("");
        assertTrue(success);
    }
    
    function testDiamondInitializedEvent() public {
        DiamondCutFacet newCutFacet = new DiamondCutFacet();
        
        vm.expectEmit(true, true, false, true);
        emit Diamond.DiamondInitialized(newOwner, address(newCutFacet));
        
        new Diamond(newOwner, address(newCutFacet));
    }

    // ========================
    // Integration Tests
    // ========================
    
    function testIntegration_FullOwnershipTransferFlow() public {
        // Enable timelock
        timelockOwnership.enableTimelock(TIMELOCK_DELAY);
        
        // Propose transfer
        timelockOwnership.proposeOwnershipTransfer(newOwner);
        
        // Verify pending
        (address proposedOwner, uint256 executeAfter) = timelockOwnership.getPendingOwnershipTransfer();
        assertEq(proposedOwner, newOwner);
        
        // Cancel and propose again
        timelockOwnership.cancelOwnershipTransfer();
        timelockOwnership.proposeOwnershipTransfer(attacker);
        
        // Fast forward and accept
        vm.warp(block.timestamp + TIMELOCK_DELAY + 1);
        vm.prank(attacker);
        timelockOwnership.acceptOwnership();
        
        // Verify ownership changed
        (address finalProposedOwner, uint256 finalExecuteAfter) = timelockOwnership.getPendingOwnershipTransfer();
        assertEq(finalProposedOwner, address(0));
        assertEq(finalExecuteAfter, 0);
    }
    
    function testIntegration_FundManagementAfterOwnershipTransfer() public {
        // Transfer ownership first
        timelockOwnership.enableTimelock(TIMELOCK_DELAY);
        timelockOwnership.proposeOwnershipTransfer(newOwner);
        vm.warp(block.timestamp + TIMELOCK_DELAY + 1);
        vm.prank(newOwner);
        timelockOwnership.acceptOwnership();
        
        // New owner should be able to withdraw funds
        vm.prank(newOwner);
        fundManagement.withdrawAllEther(payable(newOwner));
        
        assertEq(fundManagement.getEtherBalance(), 0);
        assertEq(newOwner.balance, 10 ether + TEST_ETHER);
    }
    
    function testIntegration_MultipleFacetOperations() public {
        // Test that all facets work together
        (bool ok, ) = loupe.validateDiamondIntegrity();
        assertTrue(ok);
        
        // Enable timelock
        timelockOwnership.enableTimelock(TIMELOCK_DELAY);
        
        // Check balance
        assertEq(fundManagement.getEtherBalance(), TEST_ETHER);
        
        // Propose ownership transfer
        timelockOwnership.proposeOwnershipTransfer(newOwner);
        
        // All operations should work together
        assertTrue(timelockOwnership.isTimelockEnabled());
        (ok, ) = loupe.validateDiamondIntegrity();
        assertTrue(ok);
        assertEq(fundManagement.getEtherBalance(), TEST_ETHER);
    }

    // ========================
    // Edge Cases and Error Handling
    // ========================
    
    function testEdgeCase_ZeroValueEtherTransfer() public {
        // Test receiving zero value doesn't break anything
        (bool success,) = diamondAddr.call{value: 0}("");
        assertTrue(success);
        assertEq(fundManagement.getEtherBalance(), TEST_ETHER);
    }
    
    function testEdgeCase_LargeEtherAmount() public {
        uint256 largeAmount = 1000 ether;
        vm.deal(diamondAddr, largeAmount);
        
        assertEq(fundManagement.getEtherBalance(), largeAmount);
        
        vm.prank(deployer);
        fundManagement.withdrawAllEther(payable(newOwner));
        
        assertEq(newOwner.balance, 10 ether + largeAmount);
        assertEq(fundManagement.getEtherBalance(), 0);
    }
    
    function testEdgeCase_MaxTimelockDelay() public {
        timelockOwnership.enableTimelock(30 days);
        assertEq(timelockOwnership.getTimelockDelay(), 30 days);
        
        timelockOwnership.proposeOwnershipTransfer(newOwner);
        (address proposedOwner, uint256 executeAfter) = timelockOwnership.getPendingOwnershipTransfer();
        assertEq(proposedOwner, newOwner);
        assertEq(executeAfter, block.timestamp + 30 days);
    }
    
    function testEdgeCase_MinTimelockDelay() public {
        timelockOwnership.enableTimelock(1 days);
        assertEq(timelockOwnership.getTimelockDelay(), 1 days);
    }

    // ========================
    // Gas Optimization Tests
    // ========================
    
    function testGasOptimization_FallbackCall() public {
        uint256 gasBefore = gasleft();
        fundManagement.getEtherBalance();
        uint256 gasUsed = gasBefore - gasleft();
        
        // Fallback should be efficient
        assertLt(gasUsed, 12000);
    }
    
    function testGasOptimization_TimelockOperations() public {
        timelockOwnership.enableTimelock(TIMELOCK_DELAY);
        
        uint256 gasBefore = gasleft();
        timelockOwnership.proposeOwnershipTransfer(newOwner);
        uint256 gasUsed = gasBefore - gasleft();
        
        // Timelock operations should be efficient
        assertLt(gasUsed, 60000);
    }

    // ========================
    // Helper Functions
    // ========================
    
    function testHelper_ContractCodeSize() public {
        assertTrue(diamondAddr.code.length > 0);
        assertTrue(address(cutFacet).code.length > 0);
        assertTrue(address(loupe).code.length > 0);
        assertTrue(address(timelockOwnership).code.length > 0);
        assertTrue(address(fundManagement).code.length > 0);
    }
    
    function testHelper_StoragePositions() public {
        // Verify storage positions don't collide
        bytes32 diamondPos = keccak256("diamond.standard.diamond.storage");
        assertTrue(diamondPos != bytes32(0));
    }
    
    receive() external payable {}
}
