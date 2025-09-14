// SPDX-License-Identifier: GPL
pragma solidity ^0.8.17;

library ChainConfig {
	// Default IPFS base URIs
	string internal constant BASE_URI_A = "ipfs://QmPJDasQGQvJu22nokBUNpybUQbYM6dwfwD6zEHE5oWxcv/";
	string internal constant BASE_URI_B = "ipfs://Qmbza7VprgNZ8eWzjRFWBaZUj11tZ2kEHVA6VUZGnsGVtu/";
	string internal constant BASE_URI_C = "ipfs://QmaHhmm9bwJSF95NDwqyFiCX3LPDi7g6vY2zNXxQuDqgXe/";

	// Testnet USDC addresses
	function getTestnetUSDC(uint256 chainId) internal pure returns (address) {
		// Base Sepolia USDC
		if (chainId == 84532) return 0x036CbD53842c5426634e7929541eC2318f3dCF7e;
		// OP Sepolia USDC
		// if (chainId == 11155420) return 0x5dEaC602762362FE5f135Fa5904351916CA540D95;
		// Ethereum Sepolia USDC
		if (chainId == 11155111) return 0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238;
		return address(0);
	}

	struct LzInfo { uint32 eid; address endpoint; }

	// Testnet EIDs and EndpointV2 for Base Sepolia (diamond), OP Sepolia (MGRO), and Ethereum Sepolia (NFT)
	function testnetLzInfo(uint256 chainId) internal pure returns (LzInfo memory info) {
		// Base Sepolia
		if (chainId == 84532) return LzInfo({ eid: 40245, endpoint: 0x6EDCE65403992e310A62460808c4b910D972f10f });
		// OP Sepolia
		if (chainId == 11155420) return LzInfo({ eid: 40232, endpoint: 0x6EDCE65403992e310A62460808c4b910D972f10f });
		// Ethereum Sepolia
		if (chainId == 11155111) return LzInfo({ eid: 40161, endpoint: 0x6EDCE65403992e310A62460808c4b910D972f10f });
	}

	// Mainnet EIDs and EndpointV2 for Base (diamond), Celo (MGRO), and Ethereum
	function mainnetLzInfo(uint256 chainId) internal pure returns (LzInfo memory info) {
		// Base mainnet
		if (chainId == 8453) return LzInfo({ eid: 30184, endpoint: 0x1a44076050125825900e736c501f859c50fE728c });
		// Celo mainnet
		if (chainId == 42220) return LzInfo({ eid: 30125, endpoint: 0x1a44076050125825900e736c501f859c50fE728c });
		// Ethereum mainnet
		if (chainId == 1) return LzInfo({ eid: 30101, endpoint: 0x1a44076050125825900e736c501f859c50fE728c });
	}

	function isTestnet(uint256 chainId) internal pure returns (bool) {
		return chainId == 84532 || chainId == 11155420 || chainId == 11155111; // base sepolia, op sepolia, or ethereum sepolia
	}

	function getLzInfo(uint256 chainId) internal pure returns (LzInfo memory) {
		if (isTestnet(chainId)) return testnetLzInfo(chainId);
		return mainnetLzInfo(chainId);
	}

	// ---------------- DVN CONFIG ----------------
	struct DvnConfig { address lz; address nethermind; address google; uint8 optionalThreshold; uint64 confirmations; }

	// Testnet DVN config
	// function testnetDvnConfig(uint256 chainId) internal pure returns (DvnConfig memory cfg) {
	// 	// 1-of-2 quorum: LayerZero Labs + Nethermind; 1 confirmation
	// 	if (chainId == 84532) {
	// 		// Base Sepolia
	// 		return DvnConfig({
	// 			lz: 0xe1a12515F9AB2764b887bF60B923Ca494EBbB2d6,
	// 			nethermind: 0xd9222CC3Ccd1DF7c070d700EA377D4aDA2B86Eb5,
	// 			optionalThreshold: 1,
	// 			confirmations: 1
	// 		});
	// 	}
	// 	if (chainId == 11155420) {
	// 		// OP Sepolia
	// 		return DvnConfig({
	// 			lz: 0xd680ec569f269aa7015F7979b4f1239b5aa4582C,
	// 			nethermind: 0x2d15d4e61558480A9300632772E68d8b5e7Cc7e5,
	// 			optionalThreshold: 1,
	// 			confirmations: 1
	// 		});
	// 	}
	// 	if (chainId == 11155111) {
	// 		// Ethereum Sepolia
	// 		return DvnConfig({
	// 			lz: 0x8eebf8b423B73bFCa51a1Db4B7354AA0bFCA9193,
	// 			nethermind: 0x68802e01D6321D5159208478f297d7007A7516Ed,
	// 			optionalThreshold: 1,
	// 			confirmations: 1
	// 		});
	// 	}
	// }


	function mainnetDvnConfig(uint256 chainId) internal pure returns (DvnConfig memory cfg) {
		// 2-of-3 quorum: LayerZero Labs + Nethermind + Google; 15 confirmations
		if (chainId == 8453) {
			// Base Mainnet
			return DvnConfig({
				lz: 0x9e059a54699a285714207b43B055483E78FAac25,
				nethermind: 0xcd37CA043f8479064e10635020c65FfC005d36f6,
				google: 0xD56e4eAb23cb81f43168F9F45211Eb027b9aC7cc,
				optionalThreshold: 2,
				confirmations: 15
			});
		}
		if (chainId == 42220) {
			// Celo Mainnet
			return DvnConfig({
				lz: 0x75b073994560A5c03Cd970414d9170be0C6e5c36,
				nethermind: 0xDd7B5E1dB4AaFd5C8EC3b764eFB8ed265Aa5445B,
				google: 0xD56e4eAb23cb81f43168F9F45211Eb027b9aC7cc,
				optionalThreshold: 2,
				confirmations: 2
			});
		}
		if (chainId == 1) {
			// Ethereum Mainnet
			return DvnConfig({
				lz: 0x589dEDbD617e0CBcB916A9223F4d1300c294236b,
				nethermind: 0xa59BA433ac34D2927232918Ef5B2eaAfcF130BA5,
				google: 0xD56e4eAb23cb81f43168F9F45211Eb027b9aC7cc,
				optionalThreshold: 2,
				confirmations: 2
			});
		}
	}

	// Unified DVN config getter
	function getDvnConfig(uint256 chainId) internal pure returns (DvnConfig memory) {
		// if (isTestnet(chainId)) return testnetDvnConfig(chainId);
		return mainnetDvnConfig(chainId);
	}

	function partnerEid(uint256 chainId) internal pure returns (uint32) {
		// For diamond on Base, partner is MGRO on OP (testnet) or Celo (mainnet)
		if (chainId == 84532) return 40232; // base sepolia -> op sepolia
		if (chainId == 8453) return 30125;  // base mainnet -> celo mainnet
		// For MGRO chains, partner is diamond on Base
		if (chainId == 11155420) return 40245; // op sepolia -> base sepolia
		if (chainId == 42220) return 30184;    // celo mainnet -> base mainnet
		return 0;
	}
}
