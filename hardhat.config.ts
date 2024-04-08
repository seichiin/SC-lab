import { HardhatUserConfig, vars } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';
import dotenv from 'dotenv';

dotenv.config();

const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY ?? vars.get('ALCHEMY_API_KEY');
const SEPOLIA_PRIVATE_KEY = process.env.SEPOLIA_PRIVATE_KEY ?? vars.get('SEPOLIA_PRIVATE_KEY');

const config: HardhatUserConfig = {
  solidity: '0.8.24',
  networks: {
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
      accounts: [SEPOLIA_PRIVATE_KEY],
    },
  },
};

export default config;
