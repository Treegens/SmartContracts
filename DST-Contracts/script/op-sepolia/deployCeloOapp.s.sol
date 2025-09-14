// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CeloMgroOapp} from "../../src/bridge/CeloMgroOapp.sol";
import {OApp} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {ChainConfig} from "../../script/ChainConfig.s.sol";
import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {MGRO} from "../../src/MGRO.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

contract DeployCeloOapp is Script {
    using OptionsBuilder for bytes;
    function run() external {
        uint256 privateKey = vm.envUint("MAINNET_PRIVATE_KEY");
        address deployer = vm.addr(privateKey);
        vm.startBroadcast(privateKey);
        address endpoint = ChainConfig.mainnetLzInfo(block.chainid).endpoint;
        address mgro = vm.envAddress("MAINNET_MGRO_ADDRESS");


        CeloMgroOapp oapp = new CeloMgroOapp(endpoint, deployer, mgro);
        console.log("CeloMgroOapp deployed at:", address(oapp));

        MGRO(mgro).setManagementContract(address(oapp));
        console.log("MGRO management set to CeloMgroOapp:", address(MGRO(mgro).management()));

        (bool success, ) = address(oapp).call{value: 0.001 ether}("");
        require(success, "Failed to send ETH to oapp");
        console.log("CeloMgroOapp balance:", address(oapp).balance);

        // Note: ack options are now enforced by the endpoint
        vm.stopBroadcast();
    }
    
}