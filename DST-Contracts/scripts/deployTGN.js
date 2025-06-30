// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers } = require("hardhat");
const hre = require("hardhat");
const { deployDiamond } = require('../scripts/deploy.js')

async function main() {
  const TGN = await hre.ethers.getContractFactory("TGNToken");
  const TGNToken  = await TGN.deploy();
  console.log("TGN Contract Address: ", TGNToken.address);

  const DAO = await hre.ethers .getContractFactory("TGNDAO")
  const DAOContract  = await DAO.deploy(TGNToken.address, 4, 3600, 400);
  console.log("DAO Contract Address: ", DAOContract.address);

  const MGRO = await hre.ethers.getContractFactory('MGRO')
  const MGROToken  = await MGRO.deploy();
  console.log("MGRO Contract Address: ", MGROToken.address);

//   // const NFT = await hre.ethers.getContractFactory('TreegenNFT')
//   // const NFTMinter = await NFT.deploy("ipfs://QmXzFFAoqVuNvmHhGjHf83fuPoNcYchgqnoApQ7TQrawdH/");
//   // console.log("Treegens NFT Contract Address: ", NFTMinter.address);

//   // const DAO = await hre.ethers.getContractFactory('TGNDAO');
//   // const TGNDAO = await DAO.deploy(TGNToken.address, 4, 300, 300 );
//   // console.log("DAO Contract Address: ", TGNDAO.address);



//   // const diamondAddress = deployDiamond();
//   // diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress);
//   //     diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', diamondAddress);
//   //     ownershipFacet = await ethers.getContractAt('OwnershipFacet', diamondAddress);
//   //     managementFacet = await ethers.getContractAt('ManagementFacet', diamondAddress);

//    const TGN = '0xA270Fd444d75b1f6B7B4bc8dcb0632633E9255cc'
//   const diamondAddress = '0x9C03D6189660fBEF2Df3Cf4e57e5d4c00F10886f'
//   const  TGNDAO = '0xAE76077383D9DADeD1ffecD3198Df4E70ac83D55'
//  const   MGRO = '0x6f9355917d5028559E7eB68b5c0ebF0eDD90465d'
//   const TGNFT = '0xf113b29c256E92B2f2Fcf9B263cc24CAA82bF704'
//    const   TGVault = '0x05df91414504da6Fd582c82E692462a0783d990C'
//   const TGVerification = '0xb50319d25a2d7eBc0e50CFEb8332283923684294'

//       const Vault = await hre.ethers.getContractFactory('TGNVault');
//       const TGNVault = await Vault.deploy(TGN, TGNDAO );
//       console.log("Vault Contract Address: ", TGNVault.address);
//       const Verification = await hre.ethers.getContractFactory('MGROVerification');
//       const MVerification = await Verification.deploy(TGNVault.address, diamondAddress,1500, TGNDAO);
//       console.log("Verification Contract Address: ", MVerification.address);


//       // await managementFacet.initialize(NFTMinter.address, MGROToken.address, MVerification.address, TGNToken.address);
//       // await managementFacet.addBaseURI("ipfs://QmXzFFAoqVuNvmHhGjHf83fuPoNcYchgqnoApQ7TQrawdH/");
//       // await managementFacet.addBaseURI("ipfs://QmbiW58L447GyaHnSgAtfPv5HwpxSd4N6fptGDrQFXMbPt/");
//       // await managementFacet.addBaseURI("ipfs://QmV7hEVZqAbnHZcAfg8pVqXJNEdX9two2gisSQkfTNbEbS/");

//       // // Set the Management contract address in MGRADD and NFTADD
//       // await MGROToken.setManagementContract(diamondAddress);
//       // await NFTMinter.setManagementContract(diamondAddress);

      










}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});