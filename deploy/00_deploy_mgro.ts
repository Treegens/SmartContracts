import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const deployMGRO: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  await deploy('MGRO', {
    from: deployer,
    args: [],
    log: true,
    autoMine: true
  });
};

export default deployMGRO;
deployMGRO.tags = ['MGRO'];
