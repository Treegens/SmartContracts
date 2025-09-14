// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CeloMgroOapp} from "../src/CeloMgroOapp.sol";
import {ChainConfig} from "./ChainConfig.s.sol";
import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {MGRO} from "../src/MGRO.sol";

contract DeployCeloOapp is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);
        vm.startBroadcast(privateKey);
        address endpoint = ChainConfig.testnetLzInfo(block.chainid).endpoint;
        address mgro = vm.envAddress("MGRO_ADDRESS");

        CeloMgroOapp oapp = new CeloMgroOapp(endpoint, deployer, mgro);
        console.log("CeloMgroOapp deployed at:", address(oapp));

        MGRO(mgro).setManagementContract(address(oapp));
        console.log("MGRO management set to CeloMgroOapp:", address(MGRO(mgro).management()));

        (bool success, ) = address(oapp).call{value: 0.001 ether}("");
        require(success, "Failed to send ETH to oapp");
        console.log("CeloMgroOapp balance:", address(oapp).balance);

        vm.stopBroadcast();
    }
    
}