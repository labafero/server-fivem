import js from "@eslint/js";
import vue from "eslint-plugin-vue";
import prettier from "eslint-config-prettier";
import globals from "globals";

export default [
  {
    ignores: ["**/dist/**", "**/.turbo/**", "**/node_modules/**", "server/**"],
  },
  js.configs.recommended,
  ...vue.configs["flat/recommended"],
  {
    files: ["**/*.js"],
    languageOptions: {
      globals: globals.node,
    },
  },
  {
    files: ["packages/ui-loading-screen/**/*.{js,vue}"],
    languageOptions: {
      globals: globals.browser,
    },
  },
  prettier,
];
