// SPDX-License-Identifier: GPL
pragma solidity ^0.8.17;

// import "forge-std/Script.sol";

// import {Diamond} from "src/Diamond.sol";
// import {DiamondCutFacet} from "src/facets/DiamondCutFacet.sol";
// import {DiamondLoupeFacet} from "src/facets/DiamondLoupeFacet.sol";
// import {OwnershipFacet} from "src/facets/OwnershipFacet.sol";
// import {ManagementFacet} from "src/facets/ManagementFacet.sol";
// import {IDiamondCut} from "src/interfaces/IDiamondCut.sol";
// import {DiamondInit} from "src/upgradeInitializers/DiamondInit.sol";
// import {BaseMgroOapp} from "src/bridge/BaseMgroOapp.sol";
// import { OptionsBuilder } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";

// import {MGRO} from "src/MGRO.sol";
// import {TreegenNFT} from "src/NFTMinter.sol";
// import {MockLzEndpointV2} from "../test/MockLzEndpointV2.sol";
// import {ChainConfig} from "../script/ChainConfig.s.sol";

// contract FullSetup is Script {
//     using OptionsBuilder for bytes;

// 	struct Deployed {
// 		address diamond;
// 		address mgro;
// 		address nft;
// 	}

// 	function run() external returns (Deployed memory out) {
// 		vm.startBroadcast();

// 		// --- 0. Resolve env configuration ---
// 		address dao = msg.sender; // Default to deployer
// 		address feeCollector = dao; // Default to DAO
// 		address verification = dao; // Default to DAO
// 		console.log("[Vars] deployer:", msg.sender);
// 		console.log("[Vars] dao:", dao);
// 		console.log("[Vars] feeCollector:", feeCollector);
// 		console.log("[Vars] verification:", verification);

// 		// LayerZero endpoint + delegate
// 		address lzEndpoint = ChainConfig.getLzInfo(block.chainid).endpoint;
// 		address mgroDelegate = msg.sender;

// 		// Purchase token + price
// 		uint256 price = 10; // Default: no purchase price set
// 		address buyTokenEnv = 0x036CbD53842c5426634e7929541eC2318f3dCF7e; // USDC

// 		// Base URIs (defaults from ChainConfig)
// 		string memory baseA = ChainConfig.BASE_URI_A;
// 		string memory baseB = ChainConfig.BASE_URI_B;
// 		string memory baseC = ChainConfig.BASE_URI_C;
// 		string memory defaultNFTURI = ChainConfig.BASE_URI_A;

// 		// Optional ownership handoff
// 		address newOwner = address(0);


// 		// --- 1. Deploy Diamond + facets ---
// 		DiamondCutFacet cut = new DiamondCutFacet();
// 		Diamond diamond = new Diamond(msg.sender, address(cut));

// 		DiamondInit init = new DiamondInit();
// 		DiamondLoupeFacet loupe = new DiamondLoupeFacet();
// 		OwnershipFacet own = new OwnershipFacet();
// 		ManagementFacet management = new ManagementFacet();

// 		IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](3);
// 		{
// 			bytes4[] memory selectors = new bytes4[](4);
// 			selectors[0] = loupe.facets.selector;
// 			selectors[1] = loupe.facetFunctionSelectors.selector;
// 			selectors[2] = loupe.facetAddresses.selector;
// 			selectors[3] = loupe.facetAddress.selector;
// 			cuts[0] = IDiamondCut.FacetCut({
// 				facetAddress: address(loupe),
// 				action: IDiamondCut.FacetCutAction.Add,
// 				functionSelectors: selectors
// 			});
// 		}
// 		{
// 			bytes4[] memory selectors = new bytes4[](2);
// 			selectors[0] = own.transferOwnership.selector;
// 			selectors[1] = own.owner.selector;
// 			cuts[1] = IDiamondCut.FacetCut({
// 				facetAddress: address(own),
// 				action: IDiamondCut.FacetCutAction.Add,
// 				functionSelectors: selectors
// 			});
// 		}
// 		{
// 			bytes4[] memory primary = new bytes4[](10);
// 			uint256 i;
// 			primary[i++] = ManagementFacet.initialize.selector;
// 			primary[i++] = ManagementFacet.setFeeCollector.selector;
// 			primary[i++] = ManagementFacet.setPurchaseToken.selector;
// 			primary[i++] = ManagementFacet.setVerificationContract.selector;
// 			primary[i++] = ManagementFacet.setMgroToken.selector;
// 			primary[i++] = ManagementFacet.addBaseURI.selector;
// 			primary[i++] = ManagementFacet.checkUserNFTs.selector;
// 			primary[i++] = ManagementFacet.checklength.selector;
// 			primary[i++] = ManagementFacet.checkStats.selector;
// 			primary[i++] = ManagementFacet.mintMgroTokens.selector;

// 			bytes4[] memory more = new bytes4[](12);
// 			more[0] = ManagementFacet.burnTokens.selector;
// 			more[1] = ManagementFacet.mintNFT.selector;
// 			more[2] = ManagementFacet.mintNFTasUser.selector;
// 			more[3] = ManagementFacet.updateNFTs.selector;
// 			more[4] = ManagementFacet.xchainSetMessenger.selector;
// 			more[5] = ManagementFacet.xchainSetDstEid.selector;
// 			more[7] = ManagementFacet.confirmMint.selector;
// 			more[8] = ManagementFacet.confirmBurn.selector;
// 			more[9] = ManagementFacet.xchainGetMessenger.selector;
// 			more[10] = ManagementFacet.xchainGetDstEid.selector;
// 			more[11] = ManagementFacet.xchainGetOptions.selector;
	

// 			bytes4[] memory all = new bytes4[](primary.length + more.length);
// 			for (uint256 j = 0; j < primary.length; j++) all[j] = primary[j];
// 			for (uint256 j = 0; j < more.length; j++) all[primary.length + j] = more[j];

// 			cuts[2] = IDiamondCut.FacetCut({
// 				facetAddress: address(management),
// 				action: IDiamondCut.FacetCutAction.Add,
// 				functionSelectors: all
// 			});
// 		}

// 		IDiamondCut(address(diamond)).diamondCut(cuts, address(init), abi.encodeWithSelector(DiamondInit.init.selector));
// 		console.log("[DiamondCut] Deployed Diamond and applied cut:", address(diamond));


// 		// --- 2. Deploy external dependencies ---

// 		// Deploy messenger 
// 		BaseMgroOapp baseMgroOapp = new BaseMgroOapp(lzEndpoint, mgroDelegate, address(diamond));
// 		address messenger = address(baseMgroOapp);
// 		console.log("[BaseMgroOapp] Deployed BaseMgroOapp:", messenger);

// 		uint32 dstEid = ChainConfig.partnerEid(block.chainid);
// 		uint32 gasLimit = 200000;

// 		if (lzEndpoint == address(0)) {
// 			ChainConfig.LzInfo memory info = ChainConfig.getLzInfo(block.chainid);
// 			if (info.endpoint != address(0)) {
// 				lzEndpoint = info.endpoint;
// 				console.log("[BaseMgroOapp] Using chain LZ endpoint:", lzEndpoint);
// 			} else {
// 				MockLzEndpointV2 mockEndpoint = new MockLzEndpointV2();
// 				lzEndpoint = address(mockEndpoint);
// 				console.log("[BaseMgroOapp] Deployed Mock LZ Endpoint:", lzEndpoint);
// 			}
// 		}

// 				// MGRO Contract - can be set later if not available now
// 		address mgroProvided = address(0);
// 		MGRO mgro;
// 		bool mgroDeployedHere = false;
// 		if (mgroProvided != address(0)) {
// 			mgro = MGRO(mgroProvided);
// 			console.log("[MGRO] Using provided MGRO:", address(mgro));
// 		}

// 		TreegenNFT nft = new TreegenNFT(defaultNFTURI);
// 		console.log("[TreegenNFT] Deployed TreegenNFT:", address(nft));
// 		console.log("[TreegenNFT] defaultURI:", defaultNFTURI);


// 		// --- 3. Wire trust relationships ---
// 		// Only set management on MGRO if it was deployed on this chain
// 		if (mgroDeployedHere) {
// 			mgro.setManagementContract(address(diamond));
// 		}
// 		nft.setManagementContract(address(diamond));

// 		// --- 4. Initialize management state ---
// 		address buyToken = buyTokenEnv == address(0) ? address(mgro) : buyTokenEnv;
// 		ManagementFacet(address(diamond)).initialize(address(nft), address(mgro), dao, buyToken);
// 		console.log("[ManagementFacet] management.initialize done. nft=", address(nft));
// 		console.log("[ManagementFacet] mgro=", address(mgro));
// 		console.log("[ManagementFacet] buyToken=", buyToken);
// 		ManagementFacet(address(diamond)).setVerificationContract(verification);
// 		console.log("[ManagementFacet] setVerificationContract:", verification);
// 		ManagementFacet(address(diamond)).addBaseURI(baseA);
// 		ManagementFacet(address(diamond)).addBaseURI(baseB);
// 		ManagementFacet(address(diamond)).addBaseURI(baseC);
// 		console.log("[ManagementFacet] Base URI A:", baseA);
// 		console.log("[ManagementFacet] Base URI B:", baseB);
// 		console.log("[ManagementFacet] Base URI C:", baseC);

// 		// DAO-only settings (caller must be ds.dao); we set dao to msg.sender above
// 		ManagementFacet(address(diamond)).setFeeCollector(feeCollector);
// 		if (price > 0) {
// 			ManagementFacet(address(diamond)).setPurchaseToken(buyToken, price);
// 		}

// 		// --- 5. Optional XChain/LayerZero configuration ---
// 		if (dstEid == 0) {
// 			uint32 inferred = ChainConfig.partnerEid(block.chainid);
// 			if (inferred != 0) dstEid = inferred;
// 		}
// 		if (messenger != address(0)) {
// 			ManagementFacet(address(diamond)).xchainSetMessenger(messenger);
// 			console.log("[ManagementFacet] xchainSetMessenger:", messenger);
// 		}
// 		if (dstEid != 0) {
// 			ManagementFacet(address(diamond)).xchainSetDstEid(dstEid);
// 			console.log("[ManagementFacet] xchainSetDstEid:", dstEid);
// 		}
// 		{
// 			// ABA pattern: include return fee estimate for ack back to Base
// 			uint256 returnFeeEstimate = 0.0001 ether; // Estimate for ack fee (adjust based on network)
			
// 			// Type 3 options with executor lzReceive gas + return fee as value + native drop
// 			bytes memory abaOptions = OptionsBuilder
// 				.newOptions()
// 				.addExecutorLzReceiveOption(uint128(gasLimit), uint128(returnFeeEstimate));
// 			console.logBytes(abaOptions);
// 			ManagementFacet(address(diamond)).xchainSetOptions(abaOptions);
// 			console.log("[ManagementFacet] xchainSetOptions set (ABA Type3) gasLimit:", gasLimit);
// 			console.log("[ManagementFacet] Return fee estimate included:", returnFeeEstimate);
// 		}

// 		// Optionally set peer if provided via env var REMOTE_OAPP
// 		// {
// 		// 	(address remotePeer, bool ok) = _tryEnvAddress("REMOTE_OAPP");
// 		// 	if (ok && remotePeer != address(0) && dstEid != 0) {
// 		// 		bytes32 peer = bytes32(uint256(uint160(remotePeer)));
// 		// 		BaseMgroOapp(messenger).setPeer(dstEid, peer);
// 		// 		console.log("[BaseMgroOapp] setPeer dstEid=", dstEid, " peer=", remotePeer);
// 		// 	} else {
// 		// 		console.log("[BaseMgroOapp] REMOTE_OAPP not set or dstEid=0; skipping setPeer");
// 		// 	}
// 		// }

// 		// --- 6. Optional ownership transfer ---
// 		if (newOwner != address(0) && newOwner != msg.sender) {
// 			OwnershipFacet(address(diamond)).transferOwnership(newOwner);
// 			console.log("[OwnershipFacet] Ownership transferred to:", newOwner);
// 		}

// 		// --- 7. Output deployment details ---
// 		console.log("[FullSetup] DAO:", dao);
// 		console.log("[Diamond] Diamond:", address(diamond));
// 		console.log("[MGRO] MGRO:", address(mgro));
// 		console.log("[TreegenNFT] NFT:", address(nft));
// 		console.log("[ManagementFacet] FeeCollector:", feeCollector);
// 		console.log("[ManagementFacet] Verification:", verification);
// 		console.log("[ManagementFacet] BuyToken:", buyToken);
// 		console.log("[ManagementFacet] PurchasePrice:", price);
// 		console.log("[BaseMgroOapp] Messenger:", messenger);
// 		console.log("[ManagementFacet] DstEid:", dstEid);
// 		console.log("[ManagementFacet] chainId:", block.chainid);
// 		console.log("[ManagementFacet] gasLimit:", gasLimit);
// 		console.log("[ManagementFacet] baseUriA:", baseA);
// 		console.log("[ManagementFacet] baseUriB:", baseB);
// 		console.log("[ManagementFacet] baseUriC:", baseC);
// 		console.log("[TreegenNFT] defaultNFTURI:", defaultNFTURI);
// 		console.log("[FullSetup] role: DIAMOND_CHAIN");

// 		vm.stopBroadcast();

// 		out = Deployed({diamond: address(diamond), mgro: address(mgro), nft: address(nft)});
// 	}

// }


