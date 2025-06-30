require("dotenv").config();            // Optional for managing env variables
const { ethers } = require("ethers");

// ----------------------------------------------------------------
// 1. Define Relevant Addresses, ABIs, and Setup
// ----------------------------------------------------------------

// The address of your deployed Diamond (or the facet address if using direct calls)
const DIAMOND_ADDRESS = "0x0056b2725c6493E94A9835397d4Fe04aFD8F684E";

// The address of the ERC20 token used to buy the NFT
const BUY_TOKEN_ADDRESS = "0xA270Fd444d75b1f6B7B4bc8dcb0632633E9255cc";

// The ABI for the ManagementFacet (the relevant part at least, specifically `mintNFTasUser()`).
// Ideally you'd import the complete ABI JSON for your ManagementFacet or your Diamond.
// const MANAGEMENT_FACET_ABI = [
//   // Only what's needed to call `mintNFTasUser()`:
//   "function mintNFT() external",
//   "function setPurchaseToken(address _token, uint256 _price) external",
//   'function setFeeCollector(address _address) external'
// ];

// Standard minimal ERC20 ABI (approve, allowance, balanceOf, etc.):
const ERC20_ABI = [
  "function approve(address spender, uint256 amount) external returns (bool)",
  "function allowance(address owner, address spender) external view returns (uint256)",
  "function balanceOf(address owner) external view returns (uint256)",
];

// Use your preferred JSON-RPC provider or Infura/Alchemy URL
const provider = new ethers.providers.JsonRpcProvider("https://eth-sepolia.g.alchemy.com/v2/AvrIkafWEUKzbxPxkPQJh55e99WFgqO-");

// Use a private key or a wallet. You can load from .env or Hardhat configs
const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

// ----------------------------------------------------------------
// 2. Instantiate Contract Instances
// ----------------------------------------------------------------

// Create contract instance for ManagementFacet
// const managementFacetContract = new ethers.Contract(
//   DIAMOND_ADDRESS,
//   MANAGEMENT_FACET_ABI,
//   signer
// );

// // Create contract instance for Buy Token (ERC20)
// const buyTokenContract = new ethers.Contract(
//   BUY_TOKEN_ADDRESS,
//   ERC20_ABI,
//   signer
// );

// ----------------------------------------------------------------
// 3. Approve and Mint NFT
// ----------------------------------------------------------------
(async () => {
  try {
    // // --- 3.1. Check Buy Token balance
    // const requiredAmount = ethers.utils.parseEther("1.0"); 
    // // ^ adjust this to match the price (ds.nftPrice) set in your contract.
    // // For example, if ds.nftPrice = 50 * 10^18, parseEther("50") etc.

    // const balance = await buyTokenContract.balanceOf(signer.address);
    // console.log("User buyToken balance:", ethers.utils.formatEther(balance));

    // if (balance.lt(requiredAmount)) {
    //   throw new Error("Insufficient balance to buy NFT.");
    // }

    // --- 3.2. Approve Diamond (if not already approved)
    // Check existing allowance
    // const currentAllowance = await buyTokenContract.allowance(
   

    // --- 3.3. Mint NFT as user
  //   console.log("Calling mintNFTasUser() ...");
  //   //await managementFacetContract.setFeeCollector('0x34d235fC47593EA72A493804FEd11C1499A7826C')
  //   const txMint = await managementFacetContract.mintNFT();
  //   const receiptMint = await txMint.wait();
  //   console.log("mintNFTasUser() Transaction hash:", txMint.hash);
  //   console.log("NFT successfully minted. Receipt:", receiptMint);

  // } catch (err) {
  //   console.error("Error while minting NFT:", err);
  // }
})();
