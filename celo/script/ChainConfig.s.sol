// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

contract ChainConfig {
    struct LzInfo {
        address endpoint;
        uint16 eid;
    }

    // LayerZero v1 endpoint addresses for different chains
    function getLzInfo(uint256 chainId) public pure returns (LzInfo memory) {
        if (chainId == 42220) {
            // Celo Mainnet
            return LzInfo({
                endpoint: 0x3A73033C0b1407574C76BdBAc3fB3A0000dFC23D,
                eid: 125
            });
        } else if (chainId == 44787) {
            // Celo Alfajores Testnet
            return LzInfo({
                endpoint: 0x6EDCE65403992e310A62460808c4b910D972f10f,
                eid: 125
            });
        } else if (chainId == 10) {
            // Optimism Mainnet
            return LzInfo({
                endpoint: 0x1a44076050125825900e736c501f859c50fE728c,
                eid: 111
            });
        } else if (chainId == 420) {
            // Optimism Sepolia
            return LzInfo({
                endpoint: 0x6EDCE65403992e310A62460808c4b910D972f10f,
                eid: 402
            });
        } else {
            revert("Unsupported chain");
        }
    }

    function testnetLzInfo(uint256 chainId) public pure returns (LzInfo memory) {
        return getLzInfo(chainId);
    }
}
