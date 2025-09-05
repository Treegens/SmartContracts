// SPDX-License-Identifier: GPL
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {CeloMgroOapp} from "../src/bridge/CeloMgroOapp.sol";
import {BaseMgroOapp} from "../src/bridge/BaseMgroOapp.sol";
import {console} from "forge-std/console.sol";

contract SetPeer is Script {
    
    function run(address oapp, uint32 eid, address peer) external {
        vm.startBroadcast();
        
        // Try to cast as CeloMgroOapp first
        try CeloMgroOapp(payable(oapp)).setPeer(eid, bytes32(uint256(uint160(peer)))) {
            console.log("Successfully set peer on CeloMgroOapp");
        } catch {
            // If that fails, try BaseMgroOapp
            BaseMgroOapp(payable(oapp)).setPeer(eid, bytes32(uint256(uint160(peer))));
            console.log("Successfully set peer on BaseMgroOapp");
        }
        
        console.log("Peer set:");
        console.log("  OApp:", oapp);
        console.log("  EID:", eid);
        console.log("  Peer:", peer);
        
        vm.stopBroadcast();
    }
}
