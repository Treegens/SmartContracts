require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config()

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.20",
  networks: {
    mumbai: {
      url: 'https://polygon-mumbai.g.alchemy.com/v2/EiEk6hXCVsVB1cy6VIPlNdVaH8qNkCiZ',
      accounts: [process.env.PRIVATE_KEY],
      balance: '1000000000000000'
    },
  }
};
