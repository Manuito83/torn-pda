import js from '@eslint/js';
import tseslint from '@typescript-eslint/eslint-plugin';
import tsparser from '@typescript-eslint/parser';

export default [
  js.configs.recommended,
  {
    files: ['**/*.ts'],
    languageOptions: {
      parser: tsparser,
      parserOptions: {
        project: ['./tsconfig.json', './tsconfig.dev.json'],
        sourceType: 'module',
      },
      globals: {
        console: 'readonly',
        require: 'readonly',
        setTimeout: 'readonly',
        clearTimeout: 'readonly',
        AbortController: 'readonly',
        Record: 'readonly',
        module: 'readonly',
      },
    },
    plugins: {
      '@typescript-eslint': tseslint,
    },
    rules: {
      // Basic rules
      'prefer-const': 'warn',
      'no-var': 'warn',
      'eqeqeq': 'off', // OFF for now
      'no-duplicate-imports': 'error',
      '@typescript-eslint/no-floating-promises': 'off', // OFF for now
      '@typescript-eslint/no-unused-vars': ['warn', { 'argsIgnorePattern': '^_|^e$' }],
      '@typescript-eslint/explicit-function-return-type': 'off',
      '@typescript-eslint/no-explicit-any': 'off', // OFF for now
      '@typescript-eslint/ban-ts-comment': 'off',
      'quotes': 'off', // OFF for now
      'object-curly-spacing': 'off',
      'comma-dangle': 'off', // OFF for now
      'no-trailing-spaces': 'off',
      'no-multiple-empty-lines': 'off',
      'semi': 'off', // OFF for now
      'no-unreachable': 'warn',
      'no-useless-escape': 'warn',
      'no-undef': 'off', // We already have globals
      'no-unused-vars': 'off', // We use the TypeScript version
    },
  },
  {
    ignores: ['lib/**/*', 'key/**/*'],
  },
];
