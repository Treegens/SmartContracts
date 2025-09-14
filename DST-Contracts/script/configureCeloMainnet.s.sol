// SPDX-License-Identifier: GPL
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {ChainConfig} from "./ChainConfig.s.sol";
import {CeloMgroOapp} from "../src/bridge/CeloMgroOapp.sol";
import {OAppOptionsType3} from "../lib/layerzero-v2/packages/layerzero-v2/evm/oapp/contracts/oapp/libs/OAppOptionsType3.sol";
import {OptionsBuilder} from "../lib/layerzero-v2/packages/layerzero-v2/evm/oapp/contracts/oapp/libs/OptionsBuilder.sol";
import {EnforcedOptionParam} from "../lib/layerzero-v2/packages/layerzero-v2/evm/oapp/contracts/oapp/interfaces/IOAppOptionsType3.sol";
import {IMessageLibManager, SetConfigParam} from "../lib/layerzero-v2/packages/layerzero-v2/evm/protocol/contracts/interfaces/IMessageLibManager.sol";
import {UlnConfig} from "../lib/layerzero-v2/packages/layerzero-v2/evm/messagelib/contracts/uln/UlnBase.sol";

contract ConfigureCeloMainnet is Script {
    using OptionsBuilder for bytes;
    
    function run() external {
        address celo_messenger = vm.envAddress("MAINNET_CELO_MESSENGER");
        address base_messenger = vm.envAddress("MAINNET_BASE_MESSENGER");

        uint256 celoGas = 150000;

        uint32 celoEid = uint32(ChainConfig.getLzInfo(42220).eid);
        uint32 baseEid = uint32(ChainConfig.getLzInfo(8453).eid);
        
        console.log("Celo EID:", celoEid);
        console.log("Base EID:", baseEid);

        vm.createSelectFork(vm.rpcUrl("celo"));
        vm.startBroadcast();

        // Configure CeloMgroOapp: Celo -> Base
        console.log("Configuring CeloMgroOapp...");
        // CeloMgroOapp(payable(celo_messenger)).setPeer(baseEid, bytes32(uint256(uint160(base_messenger))));
        
        EnforcedOptionParam[] memory messengerOptions = new EnforcedOptionParam[](1);
        messengerOptions[0] = EnforcedOptionParam({
            eid: baseEid,
            msgType: 1,
            options: OptionsBuilder
                .newOptions()
                .addExecutorLzReceiveOption(uint128(celoGas), 0)
        });
        CeloMgroOapp(payable(celo_messenger)).setEnforcedOptions(messengerOptions);

        // Configure ULN RECEIVE for CeloMgroOapp (Celo <- Base)
        // {
        //     ChainConfig.LzInfo memory dst = ChainConfig.getLzInfo(42220);
        //     address endpoint = dst.endpoint;
        //     (address recvLib, ) = IMessageLibManager(endpoint).getReceiveLibrary(celo_messenger, baseEid);
        //     if (recvLib == address(0)) {
        //         recvLib = IMessageLibManager(endpoint).defaultReceiveLibrary(baseEid);
        //     }

        //     address[] memory required = new address[](0);
        //     address[] memory optional = new address[](3);
        //     address lzDvn = ChainConfig.getDvnConfig(42220).lz;
        //     address nethermindDvn = ChainConfig.getDvnConfig(42220).nethermind;
        //     address googleDvn = ChainConfig.getDvnConfig(42220).google;
        //     (optional[0], optional[1], optional[2]) = sortThreeAddresses(lzDvn, nethermindDvn, googleDvn);

        //     UlnConfig memory uln = UlnConfig({
        //         confirmations: ChainConfig.getDvnConfig(42220).confirmations,
        //         requiredDVNCount: uint8(required.length),
        //         optionalDVNCount: uint8(optional.length),
        //         optionalDVNThreshold: ChainConfig.getDvnConfig(42220).optionalThreshold,
        //         requiredDVNs: required,
        //         optionalDVNs: optional
        //     });

        //     SetConfigParam[] memory params = new SetConfigParam[](1);
        //     params[0] = SetConfigParam({ eid: baseEid, configType: 2, config: abi.encode(uln) });
        //     IMessageLibManager(endpoint).setConfig(celo_messenger, recvLib, params);
        // }

        vm.stopBroadcast();
        console.log("Celo mainnet configuration completed!");
    }

    function sortThreeAddresses(address a, address b, address c) internal pure returns (address, address, address) {
        if (a < b) {
            if (b < c) return (a, b, c);
            else if (a < c) return (a, c, b);
            else return (c, a, b);
        } else {
            if (a < c) return (b, a, c);
            else if (b < c) return (b, c, a);
            else return (c, b, a);
        }
    }
}
