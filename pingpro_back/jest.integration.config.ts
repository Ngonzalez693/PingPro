import type { Config } from 'jest';
import baseConfig from './jest.config';

// Tests contra los emuladores de Firebase. Se lanzan con
// `npm run test:integration`, que arranca los emuladores, corre jest y los
// apaga.
//
// maxWorkers: 1 es obligatorio: todas las suites comparten un emulador y lo
// vacían antes de cada caso, así que en paralelo se borrarían los datos entre sí.
const config: Config = {
  ...baseConfig,
  roots: ['<rootDir>/tests/integration'],
  testPathIgnorePatterns: ['/node_modules/'],
  collectCoverage: false,
  testTimeout: 30000,
  maxWorkers: 1,
};

export default config;
