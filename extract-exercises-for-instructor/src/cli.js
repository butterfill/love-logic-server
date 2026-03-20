#!/usr/bin/env node

import { access, writeFile } from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

import confirm from "@inquirer/confirm";
import { Command } from "commander";

import { extractInstructorData } from "./extractor.js";

export async function runExtractCommand(emailAddress, options = {}) {
  const cwd = options.cwd ?? process.cwd();
  const targetPath = path.join(cwd, `${emailAddress}.json`);
  const exists = await (options.fileExists ?? fileExists)(targetPath);

  if (exists && !options.force) {
    const shouldOverwrite = await (options.confirmOverwrite ?? defaultConfirmOverwrite)(targetPath);
    if (!shouldOverwrite) {
      throw new Error("Refusing to overwrite existing file.");
    }
  }

  const payload = await (options.extractInstructorData ?? extractInstructorData)(emailAddress);
  const json = JSON.stringify(payload, null, 2) + "\n";
  await (options.writeFile ?? writeFile)(targetPath, json);

  return { targetPath };
}

async function fileExists(filePath) {
  try {
    await access(filePath);
    return true;
  } catch {
    return false;
  }
}

async function defaultConfirmOverwrite(filePath) {
  return confirm({
    default: false,
    message: `${path.basename(filePath)} already exists. Overwrite it?`
  });
}

async function main(argv) {
  const program = new Command();

  program
    .name("extract-exercises-for-instructor")
    .description("Export all courses, exercises, and submitted answers for an instructor.")
    .command("extract")
    .argument("<email-address>")
    .option("-f, --force", "overwrite the output file without prompting")
    .action(async (emailAddress, commandOptions) => {
      const { targetPath } = await runExtractCommand(emailAddress, commandOptions);
      process.stdout.write(`Wrote ${targetPath}\n`);
    });

  await program.parseAsync(argv);
}

const isEntrypoint =
  process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url);

if (isEntrypoint) {
  main(process.argv).catch((error) => {
    process.stderr.write(`${error.message}\n`);
    process.exitCode = 1;
  });
}
