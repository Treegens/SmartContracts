// SPDX-License-Identifier: GPL
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {ChainConfig} from "./ChainConfig.s.sol";
import {IMessageLibManager, SetConfigParam} from "../lib/layerzero-v2/packages/layerzero-v2/evm/protocol/contracts/interfaces/IMessageLibManager.sol";
import {UlnConfig} from "../lib/layerzero-v2/packages/layerzero-v2/evm/messagelib/contracts/uln/UlnBase.sol";

contract SetupDvnConfig is Script {
    
    function run() external {
        address base_messenger = vm.envAddress("MAINNET_BASE_MESSENGER");
        address celo_messenger = vm.envAddress("MAINNET_CELO_MESSENGER");
        address nft = vm.envAddress("MAINNET_NFT_ADDRESS");

        uint32 baseEid = uint32(ChainConfig.getLzInfo(8453).eid);
        uint32 celoEid = uint32(ChainConfig.getLzInfo(42220).eid);
        uint32 ethereumEid = uint32(ChainConfig.getLzInfo(1).eid);
        
        console.log("=== Setting up DVN Configuration ===");
        console.log("Base EID:", baseEid);
        console.log("Celo EID:", celoEid);
        console.log("Ethereum EID:", ethereumEid);

        // Configure Base mainnet SEND configurations
        console.log("\n--- Configuring Base Mainnet SEND ---");
        vm.createSelectFork(vm.rpcUrl("base"));
        vm.startBroadcast();

        // BaseMgroOapp SEND: Base -> Celo
        console.log("Setting BaseMgroOapp SEND DVN config (Base -> Celo)");
        {
            ChainConfig.LzInfo memory src = ChainConfig.getLzInfo(8453);
            address endpoint = src.endpoint;
            address sendLib = IMessageLibManager(endpoint).defaultSendLibrary(celoEid);

            address[] memory required = new address[](0);
            address[] memory optional = new address[](3);
            address lzDvn = ChainConfig.getDvnConfig(8453).lz;
            address nethermindDvn = ChainConfig.getDvnConfig(8453).nethermind;
            address googleDvn = ChainConfig.getDvnConfig(8453).google;
            (optional[0], optional[1], optional[2]) = sortThreeAddresses(lzDvn, nethermindDvn, googleDvn);

            UlnConfig memory uln = UlnConfig({
                confirmations: ChainConfig.getDvnConfig(8453).confirmations,
                requiredDVNCount: uint8(required.length),
                optionalDVNCount: uint8(optional.length),
                optionalDVNThreshold: ChainConfig.getDvnConfig(8453).optionalThreshold,
                requiredDVNs: required,
                optionalDVNs: optional
            });

            SetConfigParam[] memory params = new SetConfigParam[](1);
            params[0] = SetConfigParam({ eid: celoEid, configType: 2, config: abi.encode(uln) });
            IMessageLibManager(endpoint).setConfig(base_messenger, sendLib, params);
            console.log("BaseMgroOapp SEND DVN config set");
        }

        // TreegenNFT SEND: Base -> Ethereum
        console.log("Setting TreegenNFT SEND DVN config (Base -> Ethereum)");
        {
            ChainConfig.LzInfo memory src = ChainConfig.getLzInfo(8453);
            address endpoint = src.endpoint;
            address sendLib = IMessageLibManager(endpoint).defaultSendLibrary(ethereumEid);

            address[] memory required = new address[](0);
            address[] memory optional = new address[](3);
            address lzDvn = ChainConfig.getDvnConfig(8453).lz;
            address nethermindDvn = ChainConfig.getDvnConfig(8453).nethermind;
            address googleDvn = ChainConfig.getDvnConfig(8453).google;
            (optional[0], optional[1], optional[2]) = sortThreeAddresses(lzDvn, nethermindDvn, googleDvn);

            UlnConfig memory uln = UlnConfig({
                confirmations: ChainConfig.getDvnConfig(8453).confirmations,
                requiredDVNCount: uint8(required.length),
                optionalDVNCount: uint8(optional.length),
                optionalDVNThreshold: ChainConfig.getDvnConfig(8453).optionalThreshold,
                requiredDVNs: required,
                optionalDVNs: optional
            });

            SetConfigParam[] memory params = new SetConfigParam[](1);
            params[0] = SetConfigParam({ eid: ethereumEid, configType: 2, config: abi.encode(uln) });
            IMessageLibManager(endpoint).setConfig(nft, sendLib, params);
            console.log("TreegenNFT SEND DVN config set");
        }

        vm.stopBroadcast();

        // Configure Celo mainnet RECEIVE configuration
        console.log("\n--- Configuring Celo Mainnet RECEIVE ---");
        vm.createSelectFork(vm.rpcUrl("celo"));
        vm.startBroadcast();

        // CeloMgroOapp RECEIVE: Celo <- Base
        console.log("Setting CeloMgroOapp RECEIVE DVN config (Celo <- Base)");
        {
            ChainConfig.LzInfo memory dst = ChainConfig.getLzInfo(42220);
            address endpoint = dst.endpoint;
            (address recvLib, ) = IMessageLibManager(endpoint).getReceiveLibrary(celo_messenger, baseEid);
            if (recvLib == address(0)) {
                recvLib = IMessageLibManager(endpoint).defaultReceiveLibrary(baseEid);
            }

            address[] memory required = new address[](0);
            address[] memory optional = new address[](3);
            address lzDvn = ChainConfig.getDvnConfig(42220).lz;
            address nethermindDvn = ChainConfig.getDvnConfig(42220).nethermind;
            address googleDvn = ChainConfig.getDvnConfig(42220).google;
            (optional[0], optional[1], optional[2]) = sortThreeAddresses(lzDvn, nethermindDvn, googleDvn);

            UlnConfig memory uln = UlnConfig({
                confirmations: ChainConfig.getDvnConfig(42220).confirmations,
                requiredDVNCount: uint8(required.length),
                optionalDVNCount: uint8(optional.length),
                optionalDVNThreshold: ChainConfig.getDvnConfig(42220).optionalThreshold,
                requiredDVNs: required,
                optionalDVNs: optional
            });

            SetConfigParam[] memory params = new SetConfigParam[](1);
            params[0] = SetConfigParam({ eid: baseEid, configType: 2, config: abi.encode(uln) });
            IMessageLibManager(endpoint).setConfig(celo_messenger, recvLib, params);
            console.log("CeloMgroOapp RECEIVE DVN config set");
        }

        vm.stopBroadcast();

        // Configure Ethereum mainnet RECEIVE configuration
        console.log("\n--- Configuring Ethereum Mainnet RECEIVE ---");
        vm.createSelectFork(vm.rpcUrl("ethereum"));
        vm.startBroadcast();

        // TreegenNFT RECEIVE: Ethereum <- Base
        console.log("Setting TreegenNFT RECEIVE DVN config (Ethereum <- Base)");
        {
            ChainConfig.LzInfo memory dst = ChainConfig.getLzInfo(1);
            address endpoint = dst.endpoint;
            (address recvLib, ) = IMessageLibManager(endpoint).getReceiveLibrary(nft, baseEid);
            if (recvLib == address(0)) {
                recvLib = IMessageLibManager(endpoint).defaultReceiveLibrary(baseEid);
            }

            address[] memory required = new address[](0);
            address[] memory optional = new address[](3);
            address lzDvn = ChainConfig.getDvnConfig(1).lz;
            address nethermindDvn = ChainConfig.getDvnConfig(1).nethermind;
            address googleDvn = ChainConfig.getDvnConfig(1).google;
            (optional[0], optional[1], optional[2]) = sortThreeAddresses(lzDvn, nethermindDvn, googleDvn);

            UlnConfig memory uln = UlnConfig({
                confirmations: ChainConfig.getDvnConfig(1).confirmations,
                requiredDVNCount: uint8(required.length),
                optionalDVNCount: uint8(optional.length),
                optionalDVNThreshold: ChainConfig.getDvnConfig(1).optionalThreshold,
                requiredDVNs: required,
                optionalDVNs: optional
            });

            SetConfigParam[] memory params = new SetConfigParam[](1);
            params[0] = SetConfigParam({ eid: baseEid, configType: 2, config: abi.encode(uln) });
            IMessageLibManager(endpoint).setConfig(nft, recvLib, params);
            console.log("TreegenNFT RECEIVE DVN config set");
        }

        vm.stopBroadcast();

        console.log("\n=== All DVN configurations completed successfully! ===");
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
