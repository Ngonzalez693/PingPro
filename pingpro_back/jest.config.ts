import type { Config } from 'jest';

// Configuración de `npm test`: solo tests unitarios, sin emuladores. Los de
// tests/integration/ corren con `npm run test:integration`
// (jest.integration.config.ts).
const config: Config = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/tests'],
  testPathIgnorePatterns: ['/node_modules/', '/tests/integration/'],
  moduleFileExtensions: ['ts', 'js', 'json'],
  modulePaths: ['<rootDir>/src'],
  collectCoverage: true,
  collectCoverageFrom: [
    'src/**/*.{ts,js}',
    '!src/**/*.d.ts',
    '!src/server.ts',
    '!src/app.ts',
  ],
  coverageDirectory: 'coverage',
  testTimeout: 10000,
  setupFilesAfterEnv: ['<rootDir>/tests/setup.ts']
};

export default config;
