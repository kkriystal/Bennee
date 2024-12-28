require("dotenv").config();
require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.28",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000000,
          },
          evmVersion: "cancun",
        },
      },
    ],
  },
  networks: {
    sepolia: {
      url: process.env.URL_SEPOLIA,
      accounts: [process.env.PRIVATE_KEY_SEPOLIA],
    },
  },
  etherscan: {
    apiKey: process.env.API_KEY,
  },
};
