import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';

const TGN_TOKEN_ADDRESS = '0xA10336e3e0ee9CC81397db91aC585BA32460Cdcf';
const DEFAULT_SLASHING_PERCENT = 10;

const deployTGNVault: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  await deploy('TGNVault', {
    from: deployer,
    args: [
      TGN_TOKEN_ADDRESS,
      process.env.TGN_VAULT_SLASHER_ADDRESS || deployer,
      Number(
        process.env.TGN_VAULT_SLASHING_PERCENT || DEFAULT_SLASHING_PERCENT
      ),
      process.env.TGN_VAULT_TREASURY_ADDRESS || deployer
    ],
    log: true,
    autoMine: true
  });
};

export default deployTGNVault;
deployTGNVault.tags = ['TGNVault'];
