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

	// Mainnet EIDs and EndpointV2 for Base (diamond) and Celo (MGRO)
	function mainnetLzInfo(uint256 chainId) internal pure returns (LzInfo memory info) {
		// Base mainnet
		if (chainId == 8453) return LzInfo({ eid: 30184, endpoint: 0x1a44076050125825900e736c501f859c50fE728c });
		// Celo mainnet
		if (chainId == 42220) return LzInfo({ eid: 30125, endpoint: 0x1a44076050125825900e736c501f859c50fE728c });
	}

	function isTestnet(uint256 chainId) internal pure returns (bool) {
		return chainId == 84532 || chainId == 11155420 || chainId == 11155111; // base sepolia, op sepolia, or ethereum sepolia
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



