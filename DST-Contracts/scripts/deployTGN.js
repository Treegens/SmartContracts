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
  const NFTMinter = await NFT.deploy("ipfs://QmXzFFAoqVuNvmHhGjHf83fuPoNcYchgqnoApQ7TQrawdH/");
  console.log("Treegens NFT Contract Address: ", NFTMinter.address);

  // const DAO = await hre.ethers.getContractFactory('TGNDAO');
  // const TGNDAO = await DAO.deploy(TGNToken.address, 4, 300, 300 );
  // console.log("DAO Contract Address: ", TGNDAO.address);



  const diamondAddress = deployDiamond();
  diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress);
      diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', diamondAddress);
      ownershipFacet = await ethers.getContractAt('OwnershipFacet', diamondAddress);
      managementFacet = await ethers.getContractAt('ManagementFacet', diamondAddress);




      const Vault = await hre.ethers.getContractFactory('TGNVault');
      const TGNVault = await Vault.deploy(TGNToken.address, diamondAddress );
      console.log("Vault Contract Address: ", TGNVault.address);
      const Verification = await hre.ethers.getContractFactory('MGROVerification');
      const MVerification = await Verification.deploy(TGNVault.address, diamondAddress,1500 );
      console.log("Verification Contract Address: ", MVerification.address);
  //  TGNDAO = '0xC808A0B23de47691CCF0DB1fb948Fe67f7FC8BE5'
  //  MGRO = '0x4df88c93779eCE53D8EaB0ad714a7AafE928a059'
  //  TGNFT = '0x8b3b92004C9Dc05440309458fE8B970dd93AF18c'

      await managementFacet.initialize(NFTMinter.address, MGROToken.address, MVerification.address, TGNToken.address);
      await managementFacet.addBaseURI("ipfs://QmXzFFAoqVuNvmHhGjHf83fuPoNcYchgqnoApQ7TQrawdH/");
      await managementFacet.addBaseURI("ipfs://QmbiW58L447GyaHnSgAtfPv5HwpxSd4N6fptGDrQFXMbPt/");
      await managementFacet.addBaseURI("ipfs://QmV7hEVZqAbnHZcAfg8pVqXJNEdX9two2gisSQkfTNbEbS/");

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