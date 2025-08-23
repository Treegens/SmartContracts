
/* global ethers task */
require('@nomiclabs/hardhat-waffle')
require("@nomicfoundation/hardhat-verify");
require('dotenv').config({ path: '../../.env' })

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task('accounts', 'Prints the list of accounts', async () => {
  const accounts = await ethers.getSigners()

  for (const account of accounts) {
    console.log(account.address)
  }
})

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    compilers: [
      // { version: '0.8.17', settings: { optimizer: { enabled: true, runs: 200 } } },
      { version: '0.8.30', settings: { optimizer: { enabled: true, runs: 200 } } },
      { version: '0.8.20', settings: { optimizer: { enabled: true, runs: 200 } } },
    ],
  },
  networks: {
    // Testnets
    baseSepolia: {
      url: `https://base-sepolia.g.alchemy.com/v2/${process.env.RPC_API_KEY}`,
      chainId: 84532,
      accounts: [process.env.TESTNET_PRIVATE_KEY].filter(Boolean),
    },
    celoAlfajores: {
      url: `https://celo-alfajores.g.alchemy.com/v2/${process.env.RPC_API_KEY}`,
      chainId: 44787,
      accounts: [process.env.TESTNET_PRIVATE_KEY].filter(Boolean),
    },

    // Mainnets
    base: {
      url: `https://base-mainnet.g.alchemy.com/v2/${process.env.RPC_API_KEY}`,
      chainId: 8453,
      accounts: [process.env.PRIVATE_KEY].filter(Boolean),
    },
    celo: {
      url: `https://celo-mainnet.g.alchemy.com/v2/${process.env.RPC_API_KEY}`,
      chainId: 42220,
      accounts: [process.env.PRIVATE_KEY].filter(Boolean),
    },
  },

  etherscan: {
    apiKey: '3IEI6TA9TI51MGY6SWRRMNN5GC1ZVCW7UP',
    customChains: [
      {
        network: 'celo',
        chainId: 42220,
        urls: {
          apiURL: 'https://api.celoscan.io/api',
          browserURL: 'https://celoscan.io',
        },
      },
      {
        network: 'celo-alfajores',
        chainId: 44787,
        urls: {
          apiURL: 'https://api-alfajores.celoscan.io/api',
          browserURL: 'https://alfajores.celoscan.io',
        },
      },
    ],
  },

  sourcify: {
    enabled: true,
  },

  settings: {},
}
