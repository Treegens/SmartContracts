// SPDX-License-Identifier: GPL
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {Diamond} from "src/Diamond.sol";
import {DiamondCutFacet} from "src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "src/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "src/facets/OwnershipFacet.sol";
import {ManagementFacet} from "src/facets/ManagementFacet.sol";
import {IDiamondCut} from "src/interfaces/IDiamondCut.sol";
import {DiamondInit} from "src/upgradeInitializers/DiamondInit.sol";

import {MGRO} from "src/MGRO.sol";
import {TreegenNFT} from "src/NFTMinter.sol";
import {BaseMgroOapp} from "src/bridge/BaseMgroOapp.sol";
import {MockLzEndpointV2} from "./MockLzEndpointV2.sol";
import {MockMessenger} from "./MockMessenger.sol";

/**
 * @title SecurityAudit
 * @notice Security-focused tests for the last two commits' changes
 * @dev Tests H-1, H-2, M-1, M-2 findings from the audit
 */
contract SecurityAuditTest is Test {
    address internal diamondAddr;
    ManagementFacet internal mgmt;
    MGRO internal mgro;
    TreegenNFT internal nft;
    BaseMgroOapp internal messenger;
    MockLzEndpointV2 internal lzEndpoint;
    
    address internal deployer = address(this);
    address internal attacker = address(0xBAD);
    address internal user = address(0x1234567890123456789012345678901234567890);

    function setUp() public {
        // Deploy infrastructure
        lzEndpoint = new MockLzEndpointV2();
        mgro = new MGRO(address(lzEndpoint), deployer);
        nft = new TreegenNFT("ipfs://base/");
        
        // Deploy Diamond
        DiamondCutFacet cut = new DiamondCutFacet();
        Diamond diamond = new Diamond(deployer, address(cut));
        
        // Setup Diamond facets
        DiamondInit init = new DiamondInit();
        DiamondLoupeFacet loupeImpl = new DiamondLoupeFacet();
        OwnershipFacet ownImpl = new OwnershipFacet();
        ManagementFacet mgmtImpl = new ManagementFacet();
        
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](3);
        
        // Loupe facet
        {
            bytes4[] memory selectors = new bytes4[](4);
            selectors[0] = loupeImpl.facets.selector;
            selectors[1] = loupeImpl.facetFunctionSelectors.selector;
            selectors[2] = loupeImpl.facetAddresses.selector;
            selectors[3] = loupeImpl.facetAddress.selector;
            cuts[0] = IDiamondCut.FacetCut({
                facetAddress: address(loupeImpl), 
                action: IDiamondCut.FacetCutAction.Add, 
                functionSelectors: selectors
            });
        }
        
        // Ownership facet
        {
            bytes4[] memory selectors = new bytes4[](2);
            selectors[0] = ownImpl.transferOwnership.selector;
            selectors[1] = ownImpl.owner.selector;
            cuts[1] = IDiamondCut.FacetCut({
                facetAddress: address(ownImpl), 
                action: IDiamondCut.FacetCutAction.Add, 
                functionSelectors: selectors
            });
        }
        
        // Management facet
        {
            bytes4[] memory selectors = new bytes4[](19);
            uint256 i;
            selectors[i++] = ManagementFacet.initialize.selector;
            selectors[i++] = ManagementFacet.setFeeCollector.selector;
            selectors[i++] = ManagementFacet.setPurchaseToken.selector;
            selectors[i++] = ManagementFacet.setVerificationContract.selector;
            selectors[i++] = ManagementFacet.addBaseURI.selector;
            selectors[i++] = ManagementFacet.checkUserNFTs.selector;
            selectors[i++] = ManagementFacet.checklength.selector;
            selectors[i++] = ManagementFacet.checkStats.selector;
            selectors[i++] = ManagementFacet.mintMgroTokens.selector;
            selectors[i++] = ManagementFacet.burnTokens.selector;
            selectors[i++] = ManagementFacet.mintNFT.selector;
            selectors[i++] = ManagementFacet.mintNFTasUser.selector;
            selectors[i++] = ManagementFacet.xchainSetMessenger.selector;
            selectors[i++] = ManagementFacet.xchainSetDstEid.selector;
            selectors[i++] = ManagementFacet.xchainGetMessenger.selector;
            selectors[i++] = ManagementFacet.xchainGetDstEid.selector;
            cuts[2] = IDiamondCut.FacetCut({
                facetAddress: address(mgmtImpl), 
                action: IDiamondCut.FacetCutAction.Add, 
                functionSelectors: selectors
            });
        }
        
        IDiamondCut(address(diamond)).diamondCut(cuts, address(init), abi.encodeWithSelector(DiamondInit.init.selector));
        
        diamondAddr = address(diamond);
        mgmt = ManagementFacet(diamondAddr);
        
        // Wire contracts
        mgro.setManagementContract(diamondAddr);
        nft.setManagementContract(diamondAddr);
        
        // Initialize management
        mgmt.initialize(address(nft), address(mgro), deployer, address(mgro));
        mgmt.setVerificationContract(address(this));
        
        // Setup cross-chain (but keep messenger unset for some tests)
        messenger = new BaseMgroOapp(address(lzEndpoint), deployer, diamondAddr);
        mgmt.addBaseURI("ipfs://base/");
        
        // Fund test accounts
        vm.deal(attacker, 10 ether);
        vm.deal(user, 10 ether);
    }

    // ========================
    // H-1: Cross-Chain Message Relay Validation Tests
    // ========================
    
    function testH1_CrossChainMessengerValidatesAmounts() public {
        // Setup cross-chain
        mgmt.xchainSetMessenger(address(messenger));
        mgmt.xchainSetDstEid(1); // Celo
        
        // H-1a: Test zero amount mint should revert
        vm.expectRevert();
        mgmt.mintMgroTokens{value: 0}(user, 0);
        
        // H-1b: Test extremely large amount (potential overflow)
        vm.expectRevert();
        mgmt.mintMgroTokens{value: 0}(user, type(uint256).max / 10**18);
        
        // H-1c: Test zero address recipient
        vm.expectRevert();
        mgmt.mintMgroTokens{value: 0}(address(0), 100);
    }
    
    function testH1_CrossChainMessengerUnauthorizedAccess() public {
        mgmt.xchainSetMessenger(address(messenger));
        mgmt.xchainSetDstEid(1);
        
        // H-1d: Attacker tries to call messenger directly
        vm.startPrank(attacker);
        vm.expectRevert(); // Should revert due to onlyManagement modifier
        messenger.sendMint{value: 0}(1, attacker, 1000 ether, false);
        vm.stopPrank();
    }

    // ========================
    // H-2: Optimistic State Update Tests
    // ========================
    
    function testH2_OptimisticStateDesynchronization() public {
        mgmt.xchainSetMessenger(address(messenger));
        mgmt.xchainSetDstEid(1);
        
        // H-2a: Mint tokens and check optimistic state
        mgmt.mintMgroTokens{value: 0}(user, 100);
        (uint256 minted, uint256 burnt) = mgmt.checkStats(user);
        assertEq(minted, 100, "Optimistic state should be updated");
        
        // H-2b: Verify actual MGRO balance might be 0 (since cross-chain mint is mocked)
        // This demonstrates the desynchronization risk
        uint256 actualBalance = mgro.balanceOf(user);
        console.log("Optimistic minted:", minted);
        console.log("Actual MGRO balance:", actualBalance);
        
        // In a real scenario, if cross-chain fails, minted != actualBalance
    }
    
    function testH2_BurnWithoutSufficientBalance() public {
        mgmt.xchainSetMessenger(address(messenger));
        mgmt.xchainSetDstEid(1);
        
        // H-2c: Try to burn tokens user doesn't have
        vm.startPrank(user);
        mgmt.burnTokens{value: 0}(100); // User has 0 MGRO but tries to burn 100
        
        (uint256 minted, uint256 burnt) = mgmt.checkStats(user);
        assertEq(burnt, 100, "Optimistic burn state updated");
        assertEq(mgro.balanceOf(user), 0, "User still has 0 MGRO");
        vm.stopPrank();
    }

    // ========================
    // M-1: Missing Balance Checks
    // ========================
    
    function testM1_BurnFunctionLacksBalanceValidation() public {
        mgmt.xchainSetMessenger(address(messenger));
        mgmt.xchainSetDstEid(1);
        
        // M-1: ManagementFacet.burnTokens() doesn't check user's actual MGRO balance
        vm.startPrank(user);
        
        // This should ideally revert but doesn't due to missing validation
        mgmt.burnTokens{value: 0}(1000 ether);
        
        (uint256 minted, uint256 burnt) = mgmt.checkStats(user);
        assertEq(burnt, 1000 ether, "Burn was recorded despite insufficient balance");
        vm.stopPrank();
    }

    // ========================
    // M-2: Access Control Tests
    // ========================
    
    function testM2_CrossChainConfigurationAccess() public {
        // M-2a: Non-owner cannot set cross-chain config
        vm.startPrank(attacker);
        vm.expectRevert();
        mgmt.xchainSetMessenger(address(messenger));
        
        vm.expectRevert();
        mgmt.xchainSetDstEid(1);
        vm.stopPrank();
        
        // M-2b: Owner can set config
        mgmt.xchainSetMessenger(address(messenger));
        mgmt.xchainSetDstEid(1);
        
        assertEq(mgmt.xchainGetMessenger(), address(messenger));
        assertEq(mgmt.xchainGetDstEid(), 1);
    }
    
    function testM2_NoEmergencyPauseMechanism() public {
        mgmt.xchainSetMessenger(address(messenger));
        mgmt.xchainSetDstEid(1);
        
        // M-2c: No way to pause cross-chain operations in emergency
        // If messenger gets compromised, there's no emergency stop
        
        // Demonstrate: even if we wanted to "pause", we'd have to set messenger to address(0)
        // But this would break existing functionality rather than pause it
        mgmt.xchainSetMessenger(address(0));
        
        vm.expectRevert("XChain not configured");
        mgmt.mintMgroTokens{value: 0}(user, 100);
    }

    // ========================
    // Integration & Edge Case Tests
    // ========================
    
    function testNFTUpdateAfterMint() public {
        mgmt.xchainSetMessenger(address(messenger));
        mgmt.xchainSetDstEid(1);
        
        // User starts with no NFTs
        assertEq(mgmt.checkUserNFTs(user), 0);
        
        // Mint NFT first
        mgmt.mintNFT(user);
        assertEq(mgmt.checkUserNFTs(user), 1);
        
        // Mint MGRO tokens - should trigger NFT update due to auto-update
        mgmt.mintMgroTokens{value: 0}(user, 100);
        
        // Verify stats updated
        (uint256 minted, uint256 burnt) = mgmt.checkStats(user);
        assertEq(minted, 100);
        assertEq(burnt, 0);
    }
    
    function testDivisionByZeroInTierCalculation() public {
        // Edge case: user with 0 total activity
        (uint256 minted, uint256 burnt) = mgmt.checkStats(user);
        assertEq(minted + burnt, 0, "No activity yet");
        
        // This should not revert due to division by zero
        // The _chooseURIWithTier function should handle total == 0 case
        mgmt.mintNFT(user);
        
        // If auto-update is enabled, _updateNFTsAuto gets called
        // which calls _chooseURIWithTier with total = 0
    }

    // ========================
    // Helper Functions
    // ========================
    
    function testStorageCollisionDetection() public {
        // Verify storage positions don't collide
        bytes32 diamondPos = keccak256("diamond.standard.diamond.storage");
        bytes32 xchainPos = keccak256("treegen.management.xchain.storage");
        bytes32 nftPos = keccak256("treegen.management.nft.update.storage");
        
        assertTrue(diamondPos != xchainPos, "Diamond and XChain storage collision");
        assertTrue(diamondPos != nftPos, "Diamond and NFT storage collision");
        assertTrue(xchainPos != nftPos, "XChain and NFT storage collision");
    }
    
    receive() external payable {}
}
