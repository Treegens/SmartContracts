// SPDX-License-Identifier: GPL
pragma solidity ^0.8.20;

import { LibDiamond } from "../libraries/LibDiamond.sol";

contract FundManagementFacet {
    event EtherWithdrawn(address indexed recipient, uint256 amount);
    event EmergencyWithdraw(address indexed recipient, uint256 amount);

    function withdrawEther(address payable recipient, uint256 amount) external {
        LibDiamond.enforceIsContractOwner();
        require(recipient != address(0), "Fund: zero recipient");
        require(amount > 0, "Fund: zero amount");
        require(address(this).balance >= amount, "Fund: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Fund: transfer failed");
        emit EtherWithdrawn(recipient, amount);
    }

    function withdrawAllEther(address payable recipient) external {
        LibDiamond.enforceIsContractOwner();
        require(recipient != address(0), "Fund: zero recipient");
        uint256 balance = address(this).balance;
        require(balance > 0, "Fund: no balance");
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "Fund: transfer failed");
        emit EtherWithdrawn(recipient, balance);
    }

    function getEtherBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function emergencyWithdraw(address payable recipient) external {
        LibDiamond.enforceIsContractOwner();
        require(recipient != address(0), "Fund: zero recipient");
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = recipient.call{value: balance}("");
            require(success, "Fund: emergency failed");
            emit EmergencyWithdraw(recipient, balance);
        }
    }
}


