// SPDX-License-Identifier: GPL
pragma solidity ^0.8.20;

import {LibDiamond} from "./LibDiamond.sol";

library LibXChain {
    bytes32 internal constant XCHAIN_STORAGE_POSITION = keccak256("treegen.management.xchain.storage");

    struct XChainStorage {
        address messenger; // BaseMgroMessenger on Base
        uint32 dstEid;     // Celo Endpoint ID
        bytes lzOptions;   // default LayerZero options
    }

    function xchainStorage() internal pure returns (XChainStorage storage xs) {
        bytes32 position = XCHAIN_STORAGE_POSITION;
        assembly {
            xs.slot := position
        }
    }

    function setMessenger(address _messenger) internal {
        LibDiamond.enforceIsContractOwner();
        XChainStorage storage xs = xchainStorage();
        xs.messenger = _messenger;
    }

    function setDstEid(uint32 _eid) internal {
        LibDiamond.enforceIsContractOwner();
        XChainStorage storage xs = xchainStorage();
        xs.dstEid = _eid;
    }

    function setLzOptions(bytes memory _opts) internal {
        LibDiamond.enforceIsContractOwner();
        XChainStorage storage xs = xchainStorage();
        xs.lzOptions = _opts;
    }

    // Getter functions to read the stored values
    function getMessenger() internal view returns (address) {
        XChainStorage storage xs = xchainStorage();
        return xs.messenger;
    }

    function getDstEid() internal view returns (uint32) {
        XChainStorage storage xs = xchainStorage();
        return xs.dstEid;
    }

    function getLzOptions() internal view returns (bytes memory) {
        XChainStorage storage xs = xchainStorage();
        return xs.lzOptions;
    }
}


