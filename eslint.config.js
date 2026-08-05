import js from "@eslint/js";
import prettier from "eslint-config-prettier";

export default [
  {
    ignores: ["**/dist/**", "**/.turbo/**", "**/node_modules/**", "server/**"],
  },
  js.configs.recommended,
  prettier,
];
