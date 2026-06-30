#!/usr/bin/env node
"use strict";

import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const generatedDir = path.dirname(fileURLToPath(import.meta.url));
const difyConfigDir = path.resolve(generatedDir, "../../..");
const script = path.join(difyConfigDir, "setup-openai-compatible-models.mjs");
const args = [
  script,
  "--classification-json",
  path.join(generatedDir, "local-llm-classification.generated.json"),
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
