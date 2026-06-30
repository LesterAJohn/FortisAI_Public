#!/usr/bin/env node
"use strict";

import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const generatedDir = path.dirname(fileURLToPath(import.meta.url));
const difyConfigDir = path.resolve(generatedDir, "../../..");
const script = path.join(difyConfigDir, "import-local-openai-compatible-router.mjs");
const args = [
  script,
  "--yaml",
  path.resolve(generatedDir, "../configurations/local-openai-compatible-router.yaml"),
  ...process.argv.slice(2),
];

const result = spawnSync(process.execPath, args, {
  env: process.env,
  stdio: "inherit",
});

if (result.error) {
  console.error(JSON.stringify({ status: "error", message: result.error.message }, null, 2));
  process.exit(1);
}
process.exit(result.status ?? 1);
