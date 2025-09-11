// SPDX-License-Identifier: GPL
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {ChainConfig} from "./ChainConfig.s.sol";
import {BaseMgroOapp} from "../src/bridge/BaseMgroOapp.sol";
import {CeloMgroOapp} from "../src/bridge/CeloMgroOapp.sol";
import {TreegenNFT} from "../src/onft/TreegenNFT.sol";
import {OAppOptionsType3} from "../lib/layerzero-v2/packages/layerzero-v2/evm/oapp/contracts/oapp/libs/OAppOptionsType3.sol";
import {OptionsBuilder} from "../lib/layerzero-v2/packages/layerzero-v2/evm/oapp/contracts/oapp/libs/OptionsBuilder.sol";
import {EnforcedOptionParam} from "../lib/layerzero-v2/packages/layerzero-v2/evm/oapp/contracts/oapp/interfaces/IOAppOptionsType3.sol";
import {IMessageLibManager, SetConfigParam} from "../lib/layerzero-v2/packages/layerzero-v2/evm/protocol/contracts/interfaces/IMessageLibManager.sol";
import {UlnConfig} from "../lib/layerzero-v2/packages/layerzero-v2/evm/messagelib/contracts/uln/UlnBase.sol";

contract LayerzeroConfig is Script {
    using OptionsBuilder for bytes;
    function run() external {
        
        address base_messenger = vm.envAddress("BASE_MESSENGER");
        address op_messenger = vm.envAddress("OP_MESSENGER");
        address nft = vm.envAddress("NFT_ADDRESS");

        uint256 baseGas = 300000;
        uint256 opGas = 150000;
        uint256 nftGas = 200000;

        uint32 baseEid = uint32(ChainConfig.testnetLzInfo(84532).eid);
        uint32 opEid = uint32(ChainConfig.testnetLzInfo(11155420).eid);
        uint32 sepoliaEid = uint32(ChainConfig.testnetLzInfo(11155111).eid);
        
        vm.createSelectFork(vm.rpcUrl("base_sepolia"));
        vm.startBroadcast();

        // Set peer for messenger: base to op
        // console.log("BaseMgroOapp delegate:", BaseMgroOapp(base_messenger).delegate());
        BaseMgroOapp(base_messenger).setPeer(opEid, bytes32(uint256(uint160(op_messenger))));
        
        // Set enforced options for messenger
        EnforcedOptionParam[] memory messengerOptions = new EnforcedOptionParam[](1);
        messengerOptions[0] = EnforcedOptionParam({
            eid: opEid,
            msgType: 1,
            options: OptionsBuilder
                .newOptions()
                // Ensure sufficient gas for lzReceive
                .addExecutorLzReceiveOption(uint128(baseGas), 0)
        });
        BaseMgroOapp(base_messenger).setEnforcedOptions(messengerOptions);

        // Configure Endpoint ULN SEND (base -> op) with 1-of-2 DVNs (LZ + Nethermind)
        {
            ChainConfig.LzInfo memory src = ChainConfig.testnetLzInfo(84532);
            address endpoint = src.endpoint;
            // resolve current send library for this OApp and dstEid
            address sendLib = IMessageLibManager(endpoint).defaultSendLibrary(opEid);

            address[] memory required = new address[](0);
            address[] memory optional = new address[](2);
            address lzDvn = ChainConfig.testnetDvnConfig(84532).lz;
            address nethermindDvn = ChainConfig.testnetDvnConfig(84532).nethermind;
            // Sort DVNs in ascending order (required by LayerZero)
            if (lzDvn < nethermindDvn) {
                optional[0] = lzDvn;
                optional[1] = nethermindDvn;
            } else {
                optional[0] = nethermindDvn;
                optional[1] = lzDvn;
            }

            UlnConfig memory uln = UlnConfig({
                confirmations: ChainConfig.testnetDvnConfig(84532).confirmations,
                requiredDVNCount: uint8(required.length),
                optionalDVNCount: uint8(optional.length),
                optionalDVNThreshold: ChainConfig.testnetDvnConfig(84532).optionalThreshold,
                requiredDVNs: required,
                optionalDVNs: optional
            });

            SetConfigParam[] memory params = new SetConfigParam[](1);
            params[0] = SetConfigParam({ eid: opEid, configType: 2, config: abi.encode(uln) });
            IMessageLibManager(endpoint).setConfig(base_messenger, sendLib, params);
        }

        // Set peer for NFT: base to sepolia
        TreegenNFT(nft).setPeer(sepoliaEid, bytes32(uint256(uint160(nft))));
        
        // Set enforced options for NFT
        EnforcedOptionParam[] memory nftOptions = new EnforcedOptionParam[](1);
        nftOptions[0] = EnforcedOptionParam({
            eid: sepoliaEid,
            msgType: 1,
            options: OptionsBuilder
                .newOptions()
                .addExecutorLzReceiveOption(uint128(nftGas), 0)
        });
        TreegenNFT(nft).setEnforcedOptions(nftOptions);

        // Configure Endpoint ULN SEND (base -> sepolia) for NFT with 1-of-2 DVNs
        {
            ChainConfig.LzInfo memory src = ChainConfig.testnetLzInfo(84532);
            address endpoint = src.endpoint;
            address sendLib = IMessageLibManager(endpoint).defaultSendLibrary(sepoliaEid);

            address[] memory required = new address[](0);
            address[] memory optional = new address[](2);
            address lzDvn = ChainConfig.testnetDvnConfig(84532).lz;
            address nethermindDvn = ChainConfig.testnetDvnConfig(84532).nethermind;
            // Sort DVNs in ascending order (required by LayerZero)
            if (lzDvn < nethermindDvn) {
                optional[0] = lzDvn;
                optional[1] = nethermindDvn;
            } else {
                optional[0] = nethermindDvn;
                optional[1] = lzDvn;
            }

            UlnConfig memory uln = UlnConfig({
                confirmations: ChainConfig.testnetDvnConfig(84532).confirmations,
                requiredDVNCount: uint8(required.length),
                optionalDVNCount: uint8(optional.length),
                optionalDVNThreshold: ChainConfig.testnetDvnConfig(84532).optionalThreshold,
                requiredDVNs: required,
                optionalDVNs: optional
            });

            SetConfigParam[] memory params = new SetConfigParam[](1);
            params[0] = SetConfigParam({ eid: sepoliaEid, configType: 2, config: abi.encode(uln) });
            IMessageLibManager(endpoint).setConfig(nft, sendLib, params);
        }

        vm.stopBroadcast();
        
        vm.createSelectFork(vm.rpcUrl("op_sepolia"));
        vm.startBroadcast();
        
        // Set peer for messenger: op to base
        BaseMgroOapp(op_messenger).setPeer(baseEid, bytes32(uint256(uint160(base_messenger))));
        
        // Set enforced options for messenger
        EnforcedOptionParam[] memory opMessengerOptions = new EnforcedOptionParam[](1);
        opMessengerOptions[0] = EnforcedOptionParam({
            eid: baseEid,
            msgType: 1,
            options: OptionsBuilder
                .newOptions()
                .addExecutorLzReceiveOption(uint128(opGas), 0)
        });
        BaseMgroOapp(op_messenger).setEnforcedOptions(opMessengerOptions);

        // Configure Endpoint ULN RECEIVE (op <- base) for messenger with 1-of-2 DVNs
        {
            ChainConfig.LzInfo memory dst = ChainConfig.testnetLzInfo(11155420);
            address endpoint = dst.endpoint;
            (address recvLib, ) = IMessageLibManager(endpoint).getReceiveLibrary(op_messenger, baseEid);
            if (recvLib == address(0)) {
                recvLib = IMessageLibManager(endpoint).defaultReceiveLibrary(baseEid);
            }

            address[] memory required = new address[](0);
            address[] memory optional = new address[](2);
            address lzDvn = ChainConfig.testnetDvnConfig(11155420).lz;
            address nethermindDvn = ChainConfig.testnetDvnConfig(11155420).nethermind;
            // Sort DVNs in ascending order (required by LayerZero)
            if (lzDvn < nethermindDvn) {
                optional[0] = lzDvn;
                optional[1] = nethermindDvn;
            } else {
                optional[0] = nethermindDvn;
                optional[1] = lzDvn;
            }

            UlnConfig memory uln = UlnConfig({
                confirmations: ChainConfig.testnetDvnConfig(11155420).confirmations,
                requiredDVNCount: uint8(required.length),
                optionalDVNCount: uint8(optional.length),
                optionalDVNThreshold: ChainConfig.testnetDvnConfig(11155420).optionalThreshold,
                requiredDVNs: required,
                optionalDVNs: optional
            });

            SetConfigParam[] memory params = new SetConfigParam[](1);
            params[0] = SetConfigParam({ eid: baseEid, configType: 2, config: abi.encode(uln) });
            IMessageLibManager(endpoint).setConfig(op_messenger, recvLib, params);
        }

        vm.stopBroadcast();
        
        vm.createSelectFork(vm.rpcUrl("sepolia"));
        vm.startBroadcast();
        
        // Set peer for NFT: sepolia to base
        TreegenNFT(nft).setPeer(baseEid, bytes32(uint256(uint160(nft))));
        
        // Set enforced options for NFT
        EnforcedOptionParam[] memory sepoliaNftOptions = new EnforcedOptionParam[](1);
        sepoliaNftOptions[0] = EnforcedOptionParam({
            eid: baseEid,
            msgType: 1,
            options: OptionsBuilder
                .newOptions()
                .addExecutorLzReceiveOption(uint128(nftGas), 0)
        });
        TreegenNFT(nft).setEnforcedOptions(sepoliaNftOptions);

        // Configure Endpoint ULN RECEIVE (sepolia <- base) for NFT with 1-of-2 DVNs
        {
            ChainConfig.LzInfo memory dst = ChainConfig.testnetLzInfo(11155111);
            address endpoint = dst.endpoint;
            (address recvLib, ) = IMessageLibManager(endpoint).getReceiveLibrary(nft, baseEid);
            if (recvLib == address(0)) {
                recvLib = IMessageLibManager(endpoint).defaultReceiveLibrary(baseEid);
            }

            address[] memory required = new address[](0);
            address[] memory optional = new address[](2);
            address lzDvn = ChainConfig.testnetDvnConfig(11155111).lz;
            address nethermindDvn = ChainConfig.testnetDvnConfig(11155111).nethermind;
            // Sort DVNs in ascending order (required by LayerZero)
            if (lzDvn < nethermindDvn) {
                optional[0] = lzDvn;
                optional[1] = nethermindDvn;
            } else {
                optional[0] = nethermindDvn;
                optional[1] = lzDvn;
            }

            UlnConfig memory uln = UlnConfig({
                confirmations: ChainConfig.testnetDvnConfig(11155111).confirmations,
                requiredDVNCount: uint8(required.length),
                optionalDVNCount: uint8(optional.length),
                optionalDVNThreshold: ChainConfig.testnetDvnConfig(11155111).optionalThreshold,
                requiredDVNs: required,
                optionalDVNs: optional
            });

            SetConfigParam[] memory params = new SetConfigParam[](1);
            params[0] = SetConfigParam({ eid: baseEid, configType: 2, config: abi.encode(uln) });
            IMessageLibManager(endpoint).setConfig(nft, recvLib, params);
        }

        vm.stopBroadcast();

    }
}