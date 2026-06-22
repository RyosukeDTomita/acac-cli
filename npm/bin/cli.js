#!/usr/bin/env node
"use strict";

// 現在のプラットフォーム向け optionalDependency (acac-<platform>-<arch>) の
// ネイティブバイナリを解決して起動する薄いシム。
const { spawnSync } = require("child_process");

function resolveBinary() {
  const platformPackage = `acac-${process.platform}-${process.arch}`;
  const exe = process.platform === "win32" ? "acac.exe" : "acac";
  try {
    return require.resolve(`${platformPackage}/bin/${exe}`);
  } catch {
    return null;
  }
}

const binary = resolveBinary();

if (!binary) {
  console.error(
    `acac: no prebuilt binary for ${process.platform}-${process.arch}.\n` +
      "Only linux-x64 is supported for now."
  );
  process.exit(1);
}

const result = spawnSync(binary, process.argv.slice(2), { stdio: "inherit" });

if (result.error) {
  console.error("acac: failed to run binary:", result.error.message);
  process.exit(1);
}

process.exit(result.status === null ? 1 : result.status);
