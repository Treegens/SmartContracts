
/* global ethers task */
require('@nomiclabs/hardhat-waffle')
require("@nomicfoundation/hardhat-verify");
require('dotenv').config()

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
  solidity: '0.8.17',
  networks: {
    sepolia: {
      url: 'https://eth-sepolia.g.alchemy.com/v2/AvrIkafWEUKzbxPxkPQJh55e99WFgqO-',
      accounts: [process.env.PRIVATE_KEY],
    },

    
    },
    etherscan: {
      apiKey: '3IEI6TA9TI51MGY6SWRRMNN5GC1ZVCW7UP'
    },
  
// },
    sourcify: {
      enabled: true
    },

  settings: {
    optimizer: {
      enabled: true,
      runs: 200
    }
  }
}
