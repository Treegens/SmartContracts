// SPDX-License-Identifier: GPL
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {ChainConfig} from "./ChainConfig.s.sol";
import {BaseMgroOapp} from "../src/bridge/BaseMgroOapp.sol";
import {CeloMgroOapp} from "../src/bridge/CeloMgroOapp.sol";
import {TreegenNFT} from "../src/onft/TreegenNFT.sol";
import {OptionsBuilder} from "../lib/layerzero-v2/packages/layerzero-v2/evm/oapp/contracts/oapp/libs/OptionsBuilder.sol";
import {EnforcedOptionParam} from "../lib/layerzero-v2/packages/layerzero-v2/evm/oapp/contracts/oapp/interfaces/IOAppOptionsType3.sol";

contract SetupEnforcedOptions is Script {
    using OptionsBuilder for bytes;
    
    function run() external {
        address base_messenger = vm.envAddress("MAINNET_BASE_MESSENGER");
        address celo_messenger = vm.envAddress("MAINNET_CELO_MESSENGER");
        address nft = vm.envAddress("MAINNET_NFT_ADDRESS");

        uint32 baseEid = uint32(ChainConfig.getLzInfo(8453).eid);
        uint32 celoEid = uint32(ChainConfig.getLzInfo(42220).eid);
        uint32 ethereumEid = uint32(ChainConfig.getLzInfo(1).eid);
        
        // Gas limits for different operations
        uint256 baseGas = 300000;
        uint256 celoGas = 150000;
        uint256 nftGas = 200000;
        
        console.log("=== Setting up Enforced Options ===");
        console.log("Base EID:", baseEid);
        console.log("Celo EID:", celoEid);
        console.log("Ethereum EID:", ethereumEid);

        // Configure Base mainnet
        console.log("\n--- Configuring Base Mainnet ---");
        vm.createSelectFork(vm.rpcUrl("base"));
        vm.startBroadcast();

        // BaseMgroOapp: Base -> Celo
        console.log("Setting BaseMgroOapp enforced options (Base -> Celo)");
        EnforcedOptionParam[] memory messengerOptions = new EnforcedOptionParam[](1);
        messengerOptions[0] = EnforcedOptionParam({
            eid: celoEid,
            msgType: 1,
            options: OptionsBuilder
                .newOptions()
                .addExecutorLzReceiveOption(uint128(baseGas), 0)
        });
        BaseMgroOapp(base_messenger).setEnforcedOptions(messengerOptions);
        console.log("BaseMgroOapp enforced options set");

        // TreegenNFT: Base -> Ethereum
        console.log("Setting TreegenNFT enforced options (Base -> Ethereum)");
        EnforcedOptionParam[] memory nftOptions = new EnforcedOptionParam[](1);
        nftOptions[0] = EnforcedOptionParam({
            eid: ethereumEid,
            msgType: 1,
            options: OptionsBuilder
                .newOptions()
                .addExecutorLzReceiveOption(uint128(nftGas), 0)
        });
        TreegenNFT(nft).setEnforcedOptions(nftOptions);
        console.log("TreegenNFT enforced options set");

        vm.stopBroadcast();

        // Configure Celo mainnet
        console.log("\n--- Configuring Celo Mainnet ---");
        vm.createSelectFork(vm.rpcUrl("celo"));
        vm.startBroadcast();

        // CeloMgroOapp: Celo -> Base
        console.log("Setting CeloMgroOapp enforced options (Celo -> Base)");
        EnforcedOptionParam[] memory celoMessengerOptions = new EnforcedOptionParam[](1);
        celoMessengerOptions[0] = EnforcedOptionParam({
            eid: baseEid,
            msgType: 1,
            options: OptionsBuilder
                .newOptions()
                .addExecutorLzReceiveOption(uint128(celoGas), 0)
        });
        CeloMgroOapp(payable(celo_messenger)).setEnforcedOptions(celoMessengerOptions);
        console.log("CeloMgroOapp enforced options set");

        vm.stopBroadcast();

        console.log("\n=== All enforced options configured successfully! ===");
    }
}
