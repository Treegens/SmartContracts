import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const deployNonMangroveTreeNFT: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  const deployment = await deploy('NonMangroveTreeNFT', {
    from: deployer,
    args: [],
    log: true,
    autoMine: true
  });

  const minterAddress =
    process.env.NON_MANGROVE_TREE_NFT_MINTER_ADDRESS?.trim();
  if (minterAddress) {
    const nft = await hre.ethers.getContractAt(
      'NonMangroveTreeNFT',
      deployment.address
    );
    const MINTER_ROLE = await nft.MINTER_ROLE();
    const hasRole = await nft.hasRole(MINTER_ROLE, minterAddress);
    if (!hasRole) {
      const tx = await nft.grantRole(MINTER_ROLE, minterAddress);
      await tx.wait();
      console.log(`Granted MINTER_ROLE to ${minterAddress}`);
    }
  }
};

export default deployNonMangroveTreeNFT;
deployNonMangroveTreeNFT.tags = ['NonMangroveTreeNFT'];
