import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';
import { vars } from 'hardhat/config';

const ONE_GWEI: bigint = 1_000_000_000n;

const SotatekStandardTokenModule = buildModule('SotatekStandardTokenModule', (m) => {
  const initialSupply = m.getParameter('initialSupply', ONE_GWEI);
  const minter = m.getParameter('minter', process.env.MINTER_ADDRESS ?? vars.get('MINTER_ADDRESS'));

  const sotatekStandardToken = m.contract('SotatekStandardToken', [initialSupply, minter]);

  return { sotatekStandardToken };
});

export default SotatekStandardTokenModule;
