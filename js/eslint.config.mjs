import eslint from "@eslint/js";
import tseslint from "typescript-eslint";

const opts = tseslint.config(
  eslint.configs.recommended,
  //   ...tseslint.configs.recommended,
  ...tseslint.configs.strict,
  ...tseslint.configs.stylistic,
  {
    ignores: ["dist/**"],
  },
  {
    // Test fixtures assume success (e.g. IPAddress.parse of a hardcoded
    // literal); non-null assertions there are a known-safe convenience
    // that production code (src/**) must not rely on.
    files: ["test/**/*.ts"],
    rules: {
      "@typescript-eslint/no-non-null-assertion": "off",
    },
  },
);

export default opts;
