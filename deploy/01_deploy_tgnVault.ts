import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types';
import { envIntOrDefault, envOrDefault } from './env';

const DEFAULT_TGN_TOKEN_ADDRESS = '0xA10336e3e0ee9CC81397db91aC585BA32460Cdcf';
const DEFAULT_SLASHING_PERCENT = 10;

const deployTGNVault: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  const admin = envOrDefault('TGN_VAULT_ADMIN_ADDRESS', deployer);
  const tgnToken = envOrDefault('TGN_TOKEN_ADDRESS', DEFAULT_TGN_TOKEN_ADDRESS);
  const slasher = envOrDefault('TGN_VAULT_SLASHER_ADDRESS', deployer);
  const slashingPercent = envIntOrDefault(
    'TGN_VAULT_SLASHING_PERCENT',
    DEFAULT_SLASHING_PERCENT,
    { min: 0, max: 100 }
  );
  const treasury = envOrDefault('TGN_VAULT_TREASURY_ADDRESS', deployer);

  await deploy('TGNVault', {
    from: deployer,
    args: [admin, tgnToken, slasher, slashingPercent, treasury],
    log: true,
    autoMine: true
  });
};

export default deployTGNVault;
deployTGNVault.tags = ['TGNVault'];
