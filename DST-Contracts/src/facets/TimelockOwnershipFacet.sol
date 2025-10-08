// SPDX-License-Identifier: GPL
pragma solidity ^0.8.20;

import { LibDiamond } from "../libraries/LibDiamond.sol";
import { ITimelockOwnership } from "../interfaces/ITimelockOwnership.sol";

contract TimelockOwnershipFacet is ITimelockOwnership {
    function proposeOwnershipTransfer(address newOwner) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.proposeOwnershipTransfer(newOwner);
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        emit OwnershipTransferProposed(msg.sender, newOwner, ds.ownershipTransferTimestamp);
    }

    function cancelOwnershipTransfer() external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        address proposed = ds.proposedOwner;
        LibDiamond.cancelOwnershipTransfer();
        emit OwnershipTransferCancelled(proposed);
    }

    function acceptOwnership() external override {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(msg.sender == ds.proposedOwner, "TimelockOwnership: not proposed owner");
        address previousOwner = ds.contractOwner;
        LibDiamond.acceptOwnership();
        emit OwnershipAccepted(previousOwner, msg.sender);
    }

    function getPendingOwnershipTransfer() external view override returns (address proposedOwner, uint256 executeAfter) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return (ds.proposedOwner, ds.ownershipTransferTimestamp);
    }

    function enableTimelock(uint256 delay) external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.enableTimelock(delay);
    }

    function disableTimelock() external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.disableTimelock();
    }

    function isTimelockEnabled() external view returns (bool) {
        return LibDiamond.diamondStorage().timelockEnabled;
    }

    function getTimelockDelay() external view returns (uint256) {
        return LibDiamond.diamondStorage().timelockDelay;
    }
}


