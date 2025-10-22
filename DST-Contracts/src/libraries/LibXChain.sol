// SPDX-License-Identifier: GPL
pragma solidity 0.8.24;

import {LibDiamond} from "./LibDiamond.sol";

/**
 * @title LibXChain
 * @notice Library for cross-chain messaging storage and management
 * @dev Handles LayerZero integration for cross-chain operations
 */
library LibXChain {
    bytes32 internal constant XCHAIN_STORAGE_POSITION = keccak256("treegen.management.xchain.storage");

    // Events for state changes
    event MessengerUpdated(address indexed oldMessenger, address indexed newMessenger);
    event DstEidUpdated(uint32 indexed oldEid, uint32 indexed newEid);
    event LzOptionsUpdated(bytes oldOptions, bytes newOptions);

    struct XChainStorage {
        address messenger; // BaseMgroOapp on Base
        uint32 dstEid;     // Celo Endpoint ID
        bytes lzOptions;   // default LayerZero options
    }

    function xchainStorage() internal pure returns (XChainStorage storage xs) {
        bytes32 position = XCHAIN_STORAGE_POSITION;
        assembly {
            xs.slot := position
        }
    }

    /**
     * @notice Sets the messenger address for cross-chain operations
     * @param _messenger The new messenger address
     * @dev Only callable by contract owner
     */
    function setMessenger(address _messenger) internal {
        LibDiamond.enforceIsContractOwner();
        require(_messenger != address(0), "LibXChain: Zero address");
        
        XChainStorage storage xs = xchainStorage();
        address oldMessenger = xs.messenger;
        xs.messenger = _messenger;
        
        emit MessengerUpdated(oldMessenger, _messenger);
    }

    /**
     * @notice Sets the destination endpoint ID for LayerZero
     * @param _eid The destination endpoint ID
     * @dev Only callable by contract owner
     */
    function setDstEid(uint32 _eid) internal {
        LibDiamond.enforceIsContractOwner();
        require(_eid != 0, "LibXChain: Invalid EID");
        
        XChainStorage storage xs = xchainStorage();
        uint32 oldEid = xs.dstEid;
        xs.dstEid = _eid;
        
        emit DstEidUpdated(oldEid, _eid);
    }

    /**
     * @notice Sets the LayerZero options for cross-chain messages
     * @param _opts The LayerZero options bytes
     * @dev Only callable by contract owner
     */
    function setLzOptions(bytes memory _opts) internal {
        LibDiamond.enforceIsContractOwner();
        require(_opts.length > 0, "LibXChain: Empty options");
        
        XChainStorage storage xs = xchainStorage();
        bytes memory oldOptions = xs.lzOptions;
        xs.lzOptions = _opts;
        
        emit LzOptionsUpdated(oldOptions, _opts);
    }

    /**
     * @notice Gets the current messenger address
     * @return The messenger address
     */
    function getMessenger() internal view returns (address) {
        XChainStorage storage xs = xchainStorage();
        return xs.messenger;
    }

    /**
     * @notice Gets the current destination endpoint ID
     * @return The destination endpoint ID
     */
    function getDstEid() internal view returns (uint32) {
        XChainStorage storage xs = xchainStorage();
        return xs.dstEid;
    }

    /**
     * @notice Gets the current LayerZero options
     * @return The LayerZero options bytes
     */
    function getLzOptions() internal view returns (bytes memory) {
        XChainStorage storage xs = xchainStorage();
        return xs.lzOptions;
    }
}


