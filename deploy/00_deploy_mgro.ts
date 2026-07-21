import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';
import { envOrDefault } from './env';

const deployMGRO: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  const admin = envOrDefault('MGRO_ADMIN_ADDRESS', deployer);

  await deploy('MGRO', {
    from: deployer,
    args: [admin],
    log: true,
    autoMine: true
  });
};

export default deployMGRO;
deployMGRO.tags = ['MGRO'];
