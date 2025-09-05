// SPDX-License-Identifier: GPL
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import {Diamond} from "src/Diamond.sol";
import {DiamondCutFacet} from "src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "src/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "src/facets/OwnershipFacet.sol";
import {ManagementFacet} from "src/facets/ManagementFacet.sol";
import {IDiamondCut} from "src/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "src/interfaces/IDiamondLoupe.sol";
import {DiamondInit} from "src/upgradeInitializers/DiamondInit.sol";

import {MGRO} from "src/MGRO.sol";
import {TreegenNFT} from "src/NFTMinter.sol";
import {MockLzEndpointV2} from "./MockLzEndpointV2.sol";
import {MockMessenger} from "./MockMessenger.sol";

contract DiamondTest is Test, IERC721Receiver {
    address internal diamondAddr;
    DiamondLoupeFacet internal loupe;
    OwnershipFacet internal own;
    ManagementFacet internal mgmt;

    MGRO internal mgro;
    TreegenNFT internal nft;

    address internal deployer;

    function setUp() public {
        deployer = address(this);

        // external contracts
        MockLzEndpointV2 lzEndpoint = new MockLzEndpointV2();
        mgro = new MGRO(address(lzEndpoint), deployer);
        nft = new TreegenNFT("example://uri");

        // diamond base
        DiamondCutFacet cut = new DiamondCutFacet();
        Diamond diamond = new Diamond(deployer, address(cut));

        // init + facets
        DiamondInit init = new DiamondInit();
        DiamondLoupeFacet loupeImpl = new DiamondLoupeFacet();
        OwnershipFacet ownImpl = new OwnershipFacet();
        ManagementFacet mgmtImpl = new ManagementFacet();

        // compose cut
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](3);
        {
            bytes4[] memory selectors = new bytes4[](4);
            selectors[0] = loupeImpl.facets.selector;
            selectors[1] = loupeImpl.facetFunctionSelectors.selector;
            selectors[2] = loupeImpl.facetAddresses.selector;
            selectors[3] = loupeImpl.facetAddress.selector;
            cuts[0] = IDiamondCut.FacetCut({facetAddress: address(loupeImpl), action: IDiamondCut.FacetCutAction.Add, functionSelectors: selectors});
        }
        {
            bytes4[] memory selectors = new bytes4[](2);
            selectors[0] = ownImpl.transferOwnership.selector;
            selectors[1] = ownImpl.owner.selector;
            cuts[1] = IDiamondCut.FacetCut({facetAddress: address(ownImpl), action: IDiamondCut.FacetCutAction.Add, functionSelectors: selectors});
        }
        {
            bytes4[] memory selectors = new bytes4[](16);
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
            cuts[2] = IDiamondCut.FacetCut({facetAddress: address(mgmtImpl), action: IDiamondCut.FacetCutAction.Add, functionSelectors: selectors});
        }

        IDiamondCut(address(diamond)).diamondCut(cuts, address(init), abi.encodeWithSelector(DiamondInit.init.selector));

        diamondAddr = address(diamond);
        loupe = DiamondLoupeFacet(diamondAddr);
        own = OwnershipFacet(diamondAddr);
        mgmt = ManagementFacet(diamondAddr);

        // wire mgro and nft to trust management (diamond)
        mgro.setManagementContract(diamondAddr);
        nft.setManagementContract(diamondAddr);

        // initialize management state
        mgmt.initialize(address(nft), address(mgro), deployer, address(mgro));
        
        // Set this test contract as the verification contract to allow minting
        mgmt.setVerificationContract(address(this));
        
        // Configure XChain for minting to work (mock messenger and destination endpoint ID)
        MockMessenger mockMessenger = new MockMessenger();
        mgmt.xchainSetMessenger(address(mockMessenger));
        mgmt.xchainSetDstEid(1); // mock destination endpoint ID

        // add URIs
        mgmt.addBaseURI("ipfs://A/");
        mgmt.addBaseURI("ipfs://B/");
        mgmt.addBaseURI("ipfs://C/");
    }

    function testLoupeFacetCount() public {
        address[] memory addrs = loupe.facetAddresses();
        assertEq(addrs.length, 4, "should have 4 facets including cut");
    }

    function testBaseURIsAdded() public {
        assertEq(mgmt.checklength(), 3);
    }

    function testMintAndBurnMGROUpdatesStats() public {
        // mint 10 "units" => 10e18 tokens
        mgmt.mintMgroTokens(deployer, 10);
        assertEq(mgro.balanceOf(deployer), 10 ether);
        (uint256 minted, uint256 burnt) = mgmt.checkStats(deployer);
        assertEq(minted, 10);
        assertEq(burnt, 0);

        // burn 5 units
        mgmt.burnTokens(5);
        (minted, burnt) = mgmt.checkStats(deployer);
        assertEq(minted, 10);
        assertEq(burnt, 5);
        assertEq(mgro.balanceOf(deployer), 5 ether);
    }

    function testMintNFTAndUpdateURI() public {
        mgmt.mintNFT(deployer);
        // token 1 should exist; initial URI is baseURIs[0] + "1"
        assertEq(nft.tokenURI(1), string(abi.encodePacked("ipfs://A/", "1")));
    }

    function testPurchaseFlow_mintNFTasUser() public {
        // prepare price and fee collector
        uint256 price = 3 ether;
        mgmt.setFeeCollector(address(0xFEE));
        mgmt.setPurchaseToken(address(mgro), price);

        // fund user with mgro
        mgmt.mintMgroTokens(deployer, 100);
        // approve diamond to pull price
        mgro.approve(diamondAddr, price);

        // user purchase
        mgmt.mintNFTasUser();

        // verify
        assertEq(mgmt.checkUserNFTs(deployer), 1);
        assertEq(mgro.balanceOf(address(0xFEE)), price);
    }

    // ERC721Receiver implementation
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}


