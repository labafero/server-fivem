#!/usr/bin/env node

import { overrideBuild, overrideRestore, OverrideBuildError } from "../src/override.js";

const commands = {
  "override:build": overrideBuild,
  "override:restore": overrideRestore,
};

function main() {
  const command = process.argv[2];
  const handler = commands[command];

  if (!handler) {
    console.error(`Comando desconhecido: ${command ?? "(nenhum)"}`);
    console.error(`Comandos disponíveis: ${Object.keys(commands).join(", ")}`);
    process.exitCode = 1;
    return;
  }

  try {
    handler();
  } catch (err) {
    if (err instanceof OverrideBuildError) {
      console.error(`Erro: ${err.message}`);
      process.exitCode = 1;
      return;
    }
    throw err;
  }
}

main();
