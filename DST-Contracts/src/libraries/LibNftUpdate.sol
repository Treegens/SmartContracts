// SPDX-License-Identifier: GPL
pragma solidity ^0.8.20;

import {LibDiamond} from "./LibDiamond.sol";

library LibNftUpdate {
    bytes32 internal constant NFT_UPDATE_STORAGE_POSITION = keccak256("treegen.management.nft.update.storage");

    struct NftUpdateStorage {
        bool autoEnabled; // default configured in initializer
        mapping(address => uint8) lastTierCode; // compact code: baseIndex*10 + imageNo
    }

    function s() internal pure returns (NftUpdateStorage storage ns) {
        bytes32 position = NFT_UPDATE_STORAGE_POSITION;
        assembly {
            ns.slot := position
        }
    }

    function setAutoUpdate(bool on) internal {
        LibDiamond.enforceIsContractOwner();
        s().autoEnabled = on;
    }

    function isAutoUpdateEnabled() internal view returns (bool) {
        return s().autoEnabled;
    }

    function getLastTier(address user) internal view returns (uint8) {
        return s().lastTierCode[user];
    }

    function setLastTier(address user, uint8 code) internal {
        s().lastTierCode[user] = code;
    }
}


