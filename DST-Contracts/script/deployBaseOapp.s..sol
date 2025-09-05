// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BaseMgroOapp} from "../src/bridge/BaseMgroOapp.sol";
import {OApp} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {ChainConfig} from "./ChainConfig.s.sol";
import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {ManagementFacet} from "../src/facets/ManagementFacet.sol";

contract DeployBaseOapp is Script {
    function run() external {
        vm.startBroadcast();
        address endpoint = ChainConfig.testnetLzInfo(block.chainid).endpoint;
        address diamond = 0x0f6fd7483C9ED740e6bc0a203059001c2907D0Db;

        BaseMgroOapp oapp = new BaseMgroOapp(endpoint, msg.sender, diamond);
        console.log("BaseMgroOapp deployed at:", address(oapp));

        (bool success, ) = address(oapp).call{value: 0.001 ether}("");
        require(success, "Failed to send ETH to oapp");
        console.log("BaseMgroOapp balance:", address(oapp).balance);

        // ManagementFacet(diamond).xchainSetMessenger(address(oapp));
        vm.stopBroadcast();
    }
}