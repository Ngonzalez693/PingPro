// Configuración de ESLint 9 (flat config) del backend.
//
// Solo reglas de calidad: recomendadas de ESLint + de typescript-eslint. El
// formato lo resuelve Prettier, así que aquí no hay reglas de estilo que
// puedan contradecirlo.
//
// No hace falta declarar globales de Node ni de Jest: flat/recommended apaga
// no-undef en archivos .ts porque ya lo comprueba TypeScript.
import js from '@eslint/js';
import tseslint from '@typescript-eslint/eslint-plugin';

const scope = ['src/**/*.ts', 'tests/**/*.ts'];

export default [
  { ignores: ['dist/', 'coverage/', 'node_modules/'] },
  { ...js.configs.recommended, files: scope },
  ...tseslint.configs['flat/recommended'].map((config) => ({ ...config, files: scope })),
  {
    files: scope,
    rules: {
      // Express reconoce un manejador de errores por tener 4 parámetros, así
      // que `_next` existe aunque no se use. El "_" marca esos casos.
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
    },
  },
];
