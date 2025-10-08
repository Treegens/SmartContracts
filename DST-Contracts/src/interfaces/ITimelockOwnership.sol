// SPDX-License-Identifier: GPL
pragma solidity ^0.8.20;

interface ITimelockOwnership {
    event OwnershipTransferProposed(address indexed currentOwner, address indexed proposedOwner, uint256 executeAfter);
    event OwnershipTransferCancelled(address indexed proposedOwner);
    event OwnershipAccepted(address indexed previousOwner, address indexed newOwner);

    function proposeOwnershipTransfer(address newOwner) external;
    function cancelOwnershipTransfer() external;
    function acceptOwnership() external;
    function getPendingOwnershipTransfer() external view returns (address proposedOwner, uint256 executeAfter);
}


