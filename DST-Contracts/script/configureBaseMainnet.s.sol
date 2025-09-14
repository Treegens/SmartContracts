// SPDX-License-Identifier: GPL
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {ChainConfig} from "./ChainConfig.s.sol";
import {BaseMgroOapp} from "../src/bridge/BaseMgroOapp.sol";
import {TreegenNFT} from "../src/onft/TreegenNFT.sol";
import {OAppOptionsType3} from "../lib/layerzero-v2/packages/layerzero-v2/evm/oapp/contracts/oapp/libs/OAppOptionsType3.sol";
import {OptionsBuilder} from "../lib/layerzero-v2/packages/layerzero-v2/evm/oapp/contracts/oapp/libs/OptionsBuilder.sol";
import {EnforcedOptionParam} from "../lib/layerzero-v2/packages/layerzero-v2/evm/oapp/contracts/oapp/interfaces/IOAppOptionsType3.sol";
import {IMessageLibManager, SetConfigParam} from "../lib/layerzero-v2/packages/layerzero-v2/evm/protocol/contracts/interfaces/IMessageLibManager.sol";
import {UlnConfig} from "../lib/layerzero-v2/packages/layerzero-v2/evm/messagelib/contracts/uln/UlnBase.sol";

contract ConfigureBaseMainnet is Script {
    using OptionsBuilder for bytes;
    
    function run() external {
        address base_messenger = vm.envAddress("MAINNET_BASE_MESSENGER");
        address celo_messenger = vm.envAddress("MAINNET_CELO_MESSENGER");
        address nft = vm.envAddress("MAINNET_NFT_ADDRESS");

        uint256 baseGas = 300000;
        uint256 nftGas = 200000;

        uint32 baseEid = uint32(ChainConfig.getLzInfo(8453).eid);
        uint32 celoEid = uint32(ChainConfig.getLzInfo(42220).eid);
        uint32 ethereumEid = uint32(ChainConfig.getLzInfo(1).eid);
        
        console.log("Base EID:", baseEid);
        console.log("Celo EID:", celoEid);
        console.log("Ethereum EID:", ethereumEid);

        vm.createSelectFork(vm.rpcUrl("base"));
        vm.startBroadcast();

        // Configure BaseMgroOapp: Base -> Celo
        // console.log("Configuring BaseMgroOapp...");
        // BaseMgroOapp(base_messenger).setPeer(celoEid, bytes32(uint256(uint160(celo_messenger))));
        
        EnforcedOptionParam[] memory messengerOptions = new EnforcedOptionParam[](1);
        messengerOptions[0] = EnforcedOptionParam({
            eid: celoEid,
            msgType: 1,
            options: OptionsBuilder
                .newOptions()
                .addExecutorLzReceiveOption(uint128(baseGas), 0)
        });
        BaseMgroOapp(base_messenger).setEnforcedOptions(messengerOptions);

        // Note: ULN SEND configuration skipped - LayerZero V2 may not be fully activated on Base
        // console.log("Skipping ULN SEND configuration for Base -> Celo (LayerZero V2 not fully activated)");

        // Configure TreegenNFT: Base -> Ethereum
        // console.log("Configuring TreegenNFT...");
        // TreegenNFT(nft).setPeer(ethereumEid, bytes32(uint256(uint160(nft))));
        
        EnforcedOptionParam[] memory nftOptions = new EnforcedOptionParam[](1);
        nftOptions[0] = EnforcedOptionParam({
            eid: ethereumEid,
            msgType: 1,
            options: OptionsBuilder
                .newOptions()
                .addExecutorLzReceiveOption(uint128(nftGas), 0)
        });
        TreegenNFT(nft).setEnforcedOptions(nftOptions);

        // // Note: ULN SEND configuration skipped - LayerZero V2 may not be fully activated on Base
        // console.log("Skipping ULN SEND configuration for Base -> Ethereum (LayerZero V2 not fully activated)");

        vm.stopBroadcast();
        console.log("Base mainnet configuration completed!");
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
