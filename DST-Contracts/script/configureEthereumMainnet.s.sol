// SPDX-License-Identifier: GPL
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import {ChainConfig} from "./ChainConfig.s.sol";
import {TreegenNFT} from "../src/onft/TreegenNFT.sol";
import {OAppOptionsType3} from "../lib/layerzero-v2/packages/layerzero-v2/evm/oapp/contracts/oapp/libs/OAppOptionsType3.sol";
import {OptionsBuilder} from "../lib/layerzero-v2/packages/layerzero-v2/evm/oapp/contracts/oapp/libs/OptionsBuilder.sol";
import {EnforcedOptionParam} from "../lib/layerzero-v2/packages/layerzero-v2/evm/oapp/contracts/oapp/interfaces/IOAppOptionsType3.sol";
import {IMessageLibManager, SetConfigParam} from "../lib/layerzero-v2/packages/layerzero-v2/evm/protocol/contracts/interfaces/IMessageLibManager.sol";
import {UlnConfig} from "../lib/layerzero-v2/packages/layerzero-v2/evm/messagelib/contracts/uln/UlnBase.sol";

contract ConfigureEthereumMainnet is Script {
    using OptionsBuilder for bytes;
    
    function run() external {
        address nft = vm.envAddress("MAINNET_NFT_ADDRESS");

        uint256 nftGas = 200000;

        uint32 ethereumEid = uint32(ChainConfig.getLzInfo(1).eid);
        uint32 baseEid = uint32(ChainConfig.getLzInfo(8453).eid);
        
        console.log("Ethereum EID:", ethereumEid);
        console.log("Base EID:", baseEid);

        vm.createSelectFork(vm.rpcUrl("ethereum"));
        vm.startBroadcast();

        // Configure TreegenNFT: Ethereum -> Base
        // console.log("Configuring TreegenNFT...");
        // TreegenNFT(nft).setPeer(baseEid, bytes32(uint256(uint160(nft))));
        
        EnforcedOptionParam[] memory nftOptions = new EnforcedOptionParam[](1);
        nftOptions[0] = EnforcedOptionParam({
            eid: baseEid,
            msgType: 1,
            options: OptionsBuilder
                .newOptions()
                .addExecutorLzReceiveOption(uint128(nftGas), 0)
        });
        TreegenNFT(nft).setEnforcedOptions(nftOptions);

        // // Configure ULN RECEIVE for TreegenNFT (Ethereum <- Base)
        // {
        //     ChainConfig.LzInfo memory dst = ChainConfig.getLzInfo(1);
        //     address endpoint = dst.endpoint;
        //     (address recvLib, ) = IMessageLibManager(endpoint).getReceiveLibrary(nft, baseEid);
        //     if (recvLib == address(0)) {
        //         recvLib = IMessageLibManager(endpoint).defaultReceiveLibrary(baseEid);
        //     }

        //     address[] memory required = new address[](0);
        //     address[] memory optional = new address[](3);
        //     address lzDvn = ChainConfig.getDvnConfig(1).lz;
        //     address nethermindDvn = ChainConfig.getDvnConfig(1).nethermind;
        //     address googleDvn = ChainConfig.getDvnConfig(1).google;
        //     (optional[0], optional[1], optional[2]) = sortThreeAddresses(lzDvn, nethermindDvn, googleDvn);

        //     UlnConfig memory uln = UlnConfig({
        //         confirmations: ChainConfig.getDvnConfig(1).confirmations,
        //         requiredDVNCount: uint8(required.length),
        //         optionalDVNCount: uint8(optional.length),
        //         optionalDVNThreshold: ChainConfig.getDvnConfig(1).optionalThreshold,
        //         requiredDVNs: required,
        //         optionalDVNs: optional
        //     });

        //     SetConfigParam[] memory params = new SetConfigParam[](1);
        //     params[0] = SetConfigParam({ eid: baseEid, configType: 2, config: abi.encode(uln) });
        //     IMessageLibManager(endpoint).setConfig(nft, recvLib, params);
        // }

        vm.stopBroadcast();
        console.log("Ethereum mainnet configuration completed!");
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
