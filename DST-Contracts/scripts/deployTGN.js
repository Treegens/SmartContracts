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

  const MGRO = await hre.ethers.getContractFactory('MGRO')
  const MGROToken  = await MGRO.deploy();
  console.log("MGRO Contract Address: ", MGROToken.address);

  const NFT = await hre.ethers.getContractFactory('TreegenNFT')
  const NFTMinter = await NFT.deploy();
  console.log("Treegens NFT Contract Address: ", NFTMinter.address);

  const DAO = await hre.ethers.getContractFactory('TGNDAO');
  const TGNDAO = await DAO.deploy(TGNToken.address, 4, 7200, 300 );
  console.log("DAO Contract Address: ", TGNDAO.address);

  const diamondAddress = deployDiamond();
  diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress);
      diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', diamondAddress);
      ownershipFacet = await ethers.getContractAt('OwnershipFacet', diamondAddress);
      managementFacet = await ethers.getContractAt('ManagementFacet', diamondAddress);



      await managementFacet.initialize(NFTMinter.address, MGROToken.address, TGNDAO.address);

      // Set the Management contract address in MGRADD and NFTADD
      await MGROToken.setManagementContract(diamondAddress);
      await NFTMinter.setManagementContract(diamondAddress);










}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});