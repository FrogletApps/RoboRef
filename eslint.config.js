import eslint from '@eslint/js';

export default [
  eslint.configs.recommended,
  {
    ignores: ['dist/**', 'build/**', '.github/**', 'node_modules/**', 'lib/*/dist/**', 'lib/*/build/**', 'utils/**', 'worker/**', 'scripts/**', '.wrangler/**'],
  },
  {
    rules: {
      'no-undef': 'off',
      'no-useless-assignment': 'off',
      'no-empty': 'off',
      'no-control-regex': 'off',
      'no-prototype-builtins': 'off',
      'no-cond-assign': 'off',
      'no-fallthrough': 'off',
      'no-constant-condition': 'off',
      'no-unassigned-vars': 'off',
      'no-self-assign': 'off',
      'no-case-declarations': 'off',
      'no-constant-binary-expression': 'off',
      'no-func-assign': 'off',
      'getter-return': 'off',
      'no-redeclare': 'off',
      'preserve-caught-error': 'off',
      'no-sparse-arrays': 'off',
      'no-misleading-character-class': 'off',
      'valid-typeof': 'off',
      'no-useless-escape': 'off'
    }
  }
];
// TODO: add react plugin later
// TODO: add typescript-eslint once it fully supports TS 7+
