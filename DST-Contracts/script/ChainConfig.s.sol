// SPDX-License-Identifier: GPL
pragma solidity ^0.8.17;

library ChainConfig {
	// Default IPFS base URIs
	string internal constant BASE_URI_A = "ipfs://QmW3h5dB7yKyacNDfo1XCjjWV5zFyeDZfeVYcpYbx1xuNP/";
	string internal constant BASE_URI_B = "ipfs://Qmbza7VprgNZ8eWzjRFWBaZUj11tZ2kEHVA6VUZGnsGVtu/";
	string internal constant BASE_URI_C = "ipfs://QmaHhmm9bwJSF95NDwqyFiCX3LPDi7g6vY2zNXxQuDqgXe/";

	struct LzInfo { uint32 eid; address endpoint; }

	// Testnet EIDs and EndpointV2 for Base Sepolia (diamond) and OP Sepolia (MGRO)
	function testnetLzInfo(uint256 chainId) internal pure returns (LzInfo memory info) {
		// Base Sepolia
		if (chainId == 84532) return LzInfo({ eid: 40245, endpoint: 0x6EDCE65403992e310A62460808c4b910D972f10f });
		// OP Sepolia
		if (chainId == 11155420) return LzInfo({ eid: 40232, endpoint: 0x6EDCE65403992e310A62460808c4b910D972f10f });
	}

	// Mainnet EIDs and EndpointV2 for Base (diamond) and Celo (MGRO)
	function mainnetLzInfo(uint256 chainId) internal pure returns (LzInfo memory info) {
		// Base mainnet
		if (chainId == 8453) return LzInfo({ eid: 30184, endpoint: 0x1a44076050125825900e736c501f859c50fE728c });
		// Celo mainnet
		if (chainId == 42220) return LzInfo({ eid: 30125, endpoint: 0x1a44076050125825900e736c501f859c50fE728c });
	}

	function isTestnet(uint256 chainId) internal pure returns (bool) {
		return chainId == 84532 || chainId == 11155420; // base sepolia or op sepolia
	}

	function getLzInfo(uint256 chainId) internal pure returns (LzInfo memory) {
		if (isTestnet(chainId)) return testnetLzInfo(chainId);
		return mainnetLzInfo(chainId);
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



