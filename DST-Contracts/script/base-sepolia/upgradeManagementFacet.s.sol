// SPDX-License-Identifier: GPL
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {ManagementFacet} from "../../src/facets/ManagementFacet.sol";
import {IDiamondCut} from "../../src/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../../src/interfaces/IDiamondLoupe.sol";
import {ChainConfig} from "../ChainConfig.s.sol";

/**
 * @title UpgradeManagementFacet
 * @notice Generic script for deploying new ManagementFacet and upgrading diamond across networks
 * @dev This script works on Base Sepolia, Base Mainnet, and other supported networks
 */
contract UpgradeManagementFacet is Script {

    function run() external returns (address newManagementFacet_) {
        // Environment variables
        address diamondAddress = vm.envAddress("DIAMOND_ADDRESS");
        address nftAddress = vm.envAddress("NFT_ADDRESS");
        address daoAddress = vm.envAddress("DAO_ADDRESS");
        address mgroAddress = vm.envAddress("MGRO_ADDRESS");
        address messengerAddress = vm.envAddress("BASE_MESSENGER");

        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        uint256 chainId = block.chainid;
        console.log("=== Upgrading ManagementFacet ===");
        console.log("Network Chain ID:", chainId);

        console.log("Diamond Address:", diamondAddress);
        console.log("NFT Address:", nftAddress);
        console.log("DAO Address:", daoAddress);
        console.log("MGRO Address:", mgroAddress);
        console.log("Base Messenger Address:", messengerAddress);

        // Verify we're on a supported network
        require(
            chainId == 84532 || chainId == 8453, // Base Sepolia or Base Mainnet
            "Unsupported network. Use Base Sepolia (84532) or Base Mainnet (8453)"
        );

        // Deploy new ManagementFacet
        console.log("Deploying new ManagementFacet...");
        ManagementFacet newManagementFacet = new ManagementFacet();
        newManagementFacet_ = address(newManagementFacet);
        console.log("New ManagementFacet deployed at:", newManagementFacet_);

        // Get function selectors for the new ManagementFacet
        bytes4[] memory selectors = getManagementFacetSelectors();
        console.log("Function selectors prepared:", selectors.length);

        // Get current ManagementFacet selectors to remove them first
        bytes4[] memory currentSelectors = getCurrentManagementSelectors(diamondAddress);

        // Prepare diamond cuts - remove existing, then add new
        IDiamondCut.FacetCut[] memory cuts;

        if (currentSelectors.length > 0) {
            cuts = new IDiamondCut.FacetCut[](2);

            // First cut: Remove existing ManagementFacet selectors
            cuts[0] = IDiamondCut.FacetCut({
                facetAddress: address(0), // address(0) for removal
                action: IDiamondCut.FacetCutAction.Remove,
                functionSelectors: currentSelectors
            });

            // Second cut: Add all ManagementFacet function selectors to new facet
            cuts[1] = IDiamondCut.FacetCut({
                facetAddress: newManagementFacet_,
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectors
            });
        } else {
            // No existing ManagementFacet, just add all selectors
            cuts = new IDiamondCut.FacetCut[](1);
            cuts[0] = IDiamondCut.FacetCut({
                facetAddress: newManagementFacet_,
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectors
            });
        }

        console.log("Executing diamond cut to upgrade ManagementFacet...");

        // Execute diamond cut (no initialization needed for replacement)
        IDiamondCut(diamondAddress).diamondCut(cuts, address(0), "");

        console.log("Diamond cut executed successfully");

        // Re-initialize the new ManagementFacet with current parameters
        console.log("Re-initializing ManagementFacet with current configuration...");

        ManagementFacet updatedManagement = ManagementFacet(diamondAddress);

        // Set messenger configuration
        if (messengerAddress != address(0)) {
            updatedManagement.xchainSetMessenger(messengerAddress);

            // Set destination EID for partner chain
            uint32 dstEid = ChainConfig.partnerEid(chainId);
            if (dstEid != 0) {
                updatedManagement.xchainSetDstEid(dstEid);
                console.log("Cross-chain configuration updated - Base Messenger:", messengerAddress, "DstEid:", dstEid);
            }
        }

        // Verification
        console.log("Verifying upgrade...");
        console.log("- New ManagementFacet address:", newManagementFacet_);
        console.log("- Base Messenger configured:", updatedManagement.xchainGetMessenger());
        console.log("- DstEid configured:", updatedManagement.xchainGetDstEid());

        console.log("=== ManagementFacet Upgrade Complete ===");
        console.log("New ManagementFacet:", newManagementFacet_);
        console.log("Diamond address:", diamondAddress);
        console.log("Network:", getNetworkName(chainId));

        vm.stopBroadcast();

        return newManagementFacet_;
    }

    /**
     * @notice Deploy ManagementFacet without upgrading diamond
     */
    function deployOnly() external returns (address managementFacet_) {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        uint256 chainId = block.chainid;
        console.log("=== Deploying ManagementFacet Only ===");
        console.log("Network:", getNetworkName(chainId));

        // Deploy new ManagementFacet
        ManagementFacet managementFacet = new ManagementFacet();
        managementFacet_ = address(managementFacet);

        console.log("ManagementFacet deployed at:", managementFacet_);
        console.log("Use this address to upgrade your diamond later");

        vm.stopBroadcast();

        return managementFacet_;
    }

    /**
     * @notice Upgrade existing diamond with pre-deployed ManagementFacet
     * @param managementFacetAddress Address of the already deployed ManagementFacet
     */
    function upgradeOnly(address managementFacetAddress) external {
        address diamondAddress = vm.envAddress("DIAMOND_ADDRESS");

        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        uint256 chainId = block.chainid;
        console.log("=== Upgrading Diamond with Existing ManagementFacet ===");
        console.log("Network:", getNetworkName(chainId));
        console.log("Diamond Address:", diamondAddress);
        console.log("ManagementFacet Address:", managementFacetAddress);

        // Verify the facet address has code
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(managementFacetAddress)
        }
        require(codeSize > 0, "ManagementFacet address has no code");

        // Get function selectors for the ManagementFacet
        bytes4[] memory selectors = getManagementFacetSelectors();

        // Get current ManagementFacet selectors to remove them first
        bytes4[] memory currentSelectors = getCurrentManagementSelectors(diamondAddress);

        // Prepare diamond cuts - remove existing, then add new
        IDiamondCut.FacetCut[] memory cuts;

        if (currentSelectors.length > 0) {
            cuts = new IDiamondCut.FacetCut[](2);

            // First cut: Remove existing ManagementFacet selectors
            cuts[0] = IDiamondCut.FacetCut({
                facetAddress: address(0), // address(0) for removal
                action: IDiamondCut.FacetCutAction.Remove,
                functionSelectors: currentSelectors
            });

            // Second cut: Add all ManagementFacet function selectors to new facet
            cuts[1] = IDiamondCut.FacetCut({
                facetAddress: managementFacetAddress,
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectors
            });
        } else {
            // No existing ManagementFacet, just add all selectors
            cuts = new IDiamondCut.FacetCut[](1);
            cuts[0] = IDiamondCut.FacetCut({
                facetAddress: managementFacetAddress,
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectors
            });
        }

        console.log("Executing diamond cut...");

        // Execute diamond cut
        IDiamondCut(diamondAddress).diamondCut(cuts, address(0), "");

        console.log("Diamond upgrade completed successfully");
        console.log("New ManagementFacet:", managementFacetAddress);

        vm.stopBroadcast();
    }

    /**
     * @notice Add ManagementFacet to diamond (for first-time addition)
     * @param managementFacetAddress Address of the deployed ManagementFacet
     */
    function addFacet(address managementFacetAddress) external {
        address diamondAddress = vm.envAddress("DIAMOND_ADDRESS");

        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        uint256 chainId = block.chainid;
        console.log("=== Adding ManagementFacet to Diamond ===");
        console.log("Network:", getNetworkName(chainId));
        console.log("Diamond Address:", diamondAddress);
        console.log("ManagementFacet Address:", managementFacetAddress);

        // Verify the facet address has code
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(managementFacetAddress)
        }
        require(codeSize > 0, "ManagementFacet address has no code");

        // Get function selectors for the ManagementFacet
        bytes4[] memory selectors = getManagementFacetSelectors();

        // Prepare diamond cut to add ManagementFacet
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);

        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: managementFacetAddress,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        console.log("Executing diamond cut to add ManagementFacet...");

        // Execute diamond cut
        IDiamondCut(diamondAddress).diamondCut(cuts, address(0), "");

        console.log("ManagementFacet added successfully");
        console.log("ManagementFacet:", managementFacetAddress);

        vm.stopBroadcast();
    }

    /**
     * @notice Remove ManagementFacet from diamond
     */
    function removeFacet() external {
        address diamondAddress = vm.envAddress("DIAMOND_ADDRESS");

        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        uint256 chainId = block.chainid;
        console.log("=== Removing ManagementFacet from Diamond ===");
        console.log("Network:", getNetworkName(chainId));
        console.log("Diamond Address:", diamondAddress);

        // Get function selectors for the ManagementFacet
        bytes4[] memory selectors = getManagementFacetSelectors();

        // Prepare diamond cut to remove ManagementFacet
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);

        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(0), // address(0) for removal
            action: IDiamondCut.FacetCutAction.Remove,
            functionSelectors: selectors
        });

        console.log("Executing diamond cut to remove ManagementFacet...");

        // Execute diamond cut
        IDiamondCut(diamondAddress).diamondCut(cuts, address(0), "");

        console.log("ManagementFacet removed successfully");

        vm.stopBroadcast();
    }

    /**
     * @dev Get current ManagementFacet selectors from the diamond
     */
    function getCurrentManagementSelectors(address diamondAddress) internal view returns (bytes4[] memory) {
        // Get all facet addresses from the diamond
        address[] memory facetAddresses = IDiamondLoupe(diamondAddress).facetAddresses();

        // We'll collect selectors in a dynamic array, estimating a reasonable size
        bytes4[] memory tempSelectors = new bytes4[](50);
        uint256 count = 0;

        // Check each facet address
        for (uint256 i = 0; i < facetAddresses.length; i++) {
            address facetAddress = facetAddresses[i];
            bytes4[] memory facetSelectors = IDiamondLoupe(diamondAddress).facetFunctionSelectors(facetAddress);

            // Check if any of this facet's selectors belong to ManagementFacet
            for (uint256 j = 0; j < facetSelectors.length; j++) {
                // Check if this selector belongs to ManagementFacet by comparing with known selectors
                if (isManagementSelector(facetSelectors[j])) {
                    if (count >= tempSelectors.length) {
                        // Resize array if needed
                        bytes4[] memory newArray = new bytes4[](tempSelectors.length * 2);
                        for (uint256 k = 0; k < tempSelectors.length; k++) {
                            newArray[k] = tempSelectors[k];
                        }
                        tempSelectors = newArray;
                    }
                    tempSelectors[count++] = facetSelectors[j];
                }
            }
        }

        // Create final array with exact size
        bytes4[] memory result = new bytes4[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = tempSelectors[i];
        }

        return result;
    }

    /**
     * @dev Check if a selector belongs to ManagementFacet
     */
    function isManagementSelector(bytes4 selector) internal pure returns (bool) {
        return
            selector == ManagementFacet.initialize.selector ||
            selector == ManagementFacet.setFeeCollector.selector ||
            selector == ManagementFacet.setPurchaseToken.selector ||
            selector == ManagementFacet.setVerificationContract.selector ||
            selector == ManagementFacet.setDao.selector ||
            selector == ManagementFacet.setMgroToken.selector ||
            selector == ManagementFacet.setMinter.selector ||
            selector == ManagementFacet.checkUserNFTs.selector ||
            selector == ManagementFacet.checkStats.selector ||
            selector == ManagementFacet.mintMgroTokens.selector ||
            selector == ManagementFacet.burnTokens.selector ||
            selector == ManagementFacet.confirmMint.selector ||
            selector == ManagementFacet.confirmBurn.selector ||
            selector == ManagementFacet.xchainSetMessenger.selector ||
            selector == ManagementFacet.xchainSetDstEid.selector ||
            selector == ManagementFacet.xchainGetMessenger.selector ||
            selector == ManagementFacet.xchainGetDstEid.selector ||
            selector == ManagementFacet.mintNFT.selector ||
            selector == ManagementFacet.mintNFTasUser.selector;
    }

    /**
     * @dev Get all function selectors for ManagementFacet
     */
    function getManagementFacetSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](19);
        uint256 i = 0;
        selectors[i++] = ManagementFacet.initialize.selector;
        selectors[i++] = ManagementFacet.setFeeCollector.selector;
        selectors[i++] = ManagementFacet.setPurchaseToken.selector;
        selectors[i++] = ManagementFacet.setVerificationContract.selector;
        selectors[i++] = ManagementFacet.setDao.selector;
        selectors[i++] = ManagementFacet.setMgroToken.selector;
        selectors[i++] = ManagementFacet.setMinter.selector;
        selectors[i++] = ManagementFacet.checkUserNFTs.selector;
        selectors[i++] = ManagementFacet.checkStats.selector;
        selectors[i++] = ManagementFacet.mintMgroTokens.selector;
        selectors[i++] = ManagementFacet.burnTokens.selector;
        selectors[i++] = ManagementFacet.confirmMint.selector;
        selectors[i++] = ManagementFacet.confirmBurn.selector;
        selectors[i++] = ManagementFacet.xchainSetMessenger.selector;
        selectors[i++] = ManagementFacet.xchainSetDstEid.selector;
        selectors[i++] = ManagementFacet.xchainGetMessenger.selector;
        selectors[i++] = ManagementFacet.xchainGetDstEid.selector;
        selectors[i++] = ManagementFacet.mintNFT.selector;
        selectors[i++] = ManagementFacet.mintNFTasUser.selector;
        return selectors;
    }

    /**
     * @dev Get appropriate buy token for the network
     */
    function getBuyTokenForNetwork(uint256 chainId) internal pure returns (address) {
        if (chainId == 84532) {
            // Base Sepolia USDC
            return 0x036CbD53842c5426634e7929541eC2318f3dCF7e;
        } else if (chainId == 8453) {
            // Base Mainnet USDC
            return 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
        }
        return address(0);
    }

    /**
     * @dev Get network name for logging
     */
    function getNetworkName(uint256 chainId) internal pure returns (string memory) {
        if (chainId == 84532) return "Base Sepolia";
        if (chainId == 8453) return "Base Mainnet";
        if (chainId == 11155111) return "Ethereum Sepolia";
        if (chainId == 11155420) return "OP Sepolia";
        if (chainId == 42220) return "Celo Mainnet";
        return "Unknown Network";
    }
}
