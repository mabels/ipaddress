import { defineConfig } from "vitest/config";

import tsconfigPaths from "vite-tsconfig-paths";

export default defineConfig({
  plugins: [tsconfigPaths()],
  test: {
    name: "generic-js",
    exclude: [],
    include: ["test/**/test_*.?(c|m)[jt]s?(x)"],
    globals: true,
  },
});
