// SPDX-License-Identifier: GPL
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import {TreegenNFT as TreegenNFT_Eth} from "../src/onft/TreegenNFT.sol";
import {TreegenNFT as TreegenNFT_Canonical_Base} from "../src/onft/TreegenNFT_Canonical.sol";
import {MockLzEndpointV2} from "./MockLzEndpointV2.sol";

// Test-only subclass to raise batch limits for benchmarking without changing prod code
contract TreegenNFT_Eth_Test is TreegenNFT_Eth {
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _defaultURI,
        address _lzEndpoint,
        address _delegate,
        address _nftUpdater
    ) TreegenNFT_Eth(_name, _symbol, _defaultURI, _lzEndpoint, _delegate, _nftUpdater) {
    }
}

contract TreegenNFT_Canonical_Base_Test is TreegenNFT_Canonical_Base {
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _defaultURI,
        address _lzEndpoint,
        address _delegate,
        address _management,
        address _nftUpdater
    ) TreegenNFT_Canonical_Base(_name, _symbol, _defaultURI, _lzEndpoint, _delegate, _management, _nftUpdater) {
        // Increase inherited batch limit for benchmarking
    }
}

contract TreegenNFTBatchTest is Test {
    MockLzEndpointV2 internal endpoint;
    address internal constant DUMMY_DELEGATE = address(0x2222);

    // Deployed per-test where needed
    TreegenNFT_Eth ethNft;
    TreegenNFT_Eth_Test ethNftMax;
    TreegenNFT_Canonical_Base baseNft;
    TreegenNFT_Canonical_Base_Test baseNftMax;

    address internal updater = address(this);
    address internal management = address(this);
    address internal user = address(0xBEEF);

    function setUp() public {
        // Deploy mock LayerZero endpoint
        endpoint = new MockLzEndpointV2();

        // Ethereum version (no mint in contract) - just for event batch benchmark
        ethNft = new TreegenNFT_Eth(
            "TreegenETH",
            "TGNETH",
            "ipfs://base/",
            address(endpoint),
            updater,
            updater
        );
        ethNftMax = new TreegenNFT_Eth_Test(
            "TreegenETHTest",
            "TGNETH_T",
            "ipfs://base/",
            address(endpoint),
            updater,
            updater
        );

        // No batch limit enforced in production contracts anymore

        // Base Canonical version (has mint)
        baseNft = new TreegenNFT_Canonical_Base(
            "TreegenBASE",
            "TGNBASE",
            "ipfs://base/",
            address(endpoint),
            updater,
            management,
            updater
        );
        baseNftMax = new TreegenNFT_Canonical_Base_Test(
            "TreegenBASETest",
            "TGNBASE_T",
            "ipfs://base/",
            address(endpoint),
            updater,
            management,
            updater
        );

        // No batch limit enforced in production contracts anymore
    }

    // -----------------------------
    // Helpers
    // -----------------------------
    function _makeTokenIds(uint256 n) internal pure returns (uint256[] memory ids) {
        ids = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            ids[i] = i + 1;
        }
    }

    function _makeUris(uint256 n) internal pure returns (string[] memory uris) {
        uris = new string[](n);
        for (uint256 i = 0; i < n; i++) {
            uris[i] = string(abi.encodePacked("ipfs://Qm.../", vm.toString(i + 1)));
        }
    }

    // -----------------------------
    // Event-only batch benchmarking (Ethereum & Base)
    // -----------------------------
    function test_Eth_BatchMetadata_100_500_1000_Succeeds_AndGas() public {
        uint256[] memory ids100 = _makeTokenIds(100);
        uint256[] memory ids500 = _makeTokenIds(500);
        uint256[] memory ids1000 = _makeTokenIds(1000);

        // Production contract now allows large batches; we use subclass for gas logging

        // Test contract with MAX_BATCH_SIZE = 1000
        vm.prank(updater);
        uint256 g0 = gasleft();
        ethNftMax.batchMetadataUpdate(ids100);
        uint256 gas100 = g0 - gasleft();

        vm.prank(updater);
        uint256 g1 = gasleft();
        ethNftMax.batchMetadataUpdate(ids500);
        uint256 gas500 = g1 - gasleft();

        vm.prank(updater);
        uint256 g2 = gasleft();
        ethNftMax.batchMetadataUpdate(ids1000);
        uint256 gas1000 = g2 - gasleft();

        console2.log("ETH event-only batch gas (approx):");
        console2.log("  100:", gas100);
        console2.log("  500:", gas500);
        console2.log(" 1000:", gas1000);

        // Basic sanity: gas scales roughly linearly
        assertGt(gas1000, gas500);
        assertGt(gas500, gas100);
    }

    function test_Base_BatchMetadata_1000_Succeeds_WithRaisedLimit() public {
        uint256[] memory ids1000 = _makeTokenIds(1000);
        // Production contract now allows large batches; ensure subclass succeeds

        // Raised-limit test contract should pass
        vm.prank(updater);
        baseNftMax.batchMetadataUpdate(ids1000);
    }

}


