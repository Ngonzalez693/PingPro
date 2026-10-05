import type { Config } from 'jest';

// Configuración de `npm test`: solo tests unitarios, sin emuladores. Los de
// tests/integration/ corren con `npm run test:integration`
// (jest.integration.config.ts).
const config: Config = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  // jose (firebase-admin → jwks-rsa) solo se publica como ESM. Node ≥22.12 lo
  // carga con require(), pero el runtime CommonJS de Jest no: se transforma
  // a CommonJS solo ese paquete, el resto de node_modules sigue sin tocarse.
  // [/\\] porque Jest compara contra la ruta real, y en Windows lleva "\".
  transform: {
    '^.+\\.ts$': 'ts-jest',
    '[/\\\\]node_modules[/\\\\]jose[/\\\\].+\\.js$': [
      'ts-jest',
      { tsconfig: { allowJs: true } },
    ],
  },
  transformIgnorePatterns: ['[/\\\\]node_modules[/\\\\](?!jose[/\\\\])'],
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
