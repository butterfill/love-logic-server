import { describe, expect, it, vi } from "vitest";

import { runExtractCommand } from "../src/cli.js";

describe("runExtractCommand", () => {
  it("writes the export to <email>.json in the current working directory", async () => {
    const writeFile = vi.fn();
    const fileExists = vi.fn().mockResolvedValue(false);
    const extractInstructorData = vi.fn().mockResolvedValue({ instructor: { emailAddress: "teacher@example.com" } });

    await runExtractCommand("teacher@example.com", {
      cwd: "/tmp/project",
      confirmOverwrite: vi.fn(),
      extractInstructorData,
      fileExists,
      writeFile
    });

    expect(extractInstructorData).toHaveBeenCalledWith("teacher@example.com");
    expect(fileExists).toHaveBeenCalledWith("/tmp/project/teacher@example.com.json");
    expect(writeFile).toHaveBeenCalledWith(
      "/tmp/project/teacher@example.com.json",
      '{\n  "instructor": {\n    "emailAddress": "teacher@example.com"\n  }\n}\n'
    );
  });

  it("asks before overwriting an existing file", async () => {
    const confirmOverwrite = vi.fn().mockResolvedValue(false);

    await expect(
      runExtractCommand("teacher@example.com", {
        cwd: "/tmp/project",
        confirmOverwrite,
        extractInstructorData: vi.fn(),
        fileExists: vi.fn().mockResolvedValue(true),
        writeFile: vi.fn()
      })
    ).rejects.toThrow("Refusing to overwrite existing file.");
  });

  it("skips the prompt when force is enabled", async () => {
    const confirmOverwrite = vi.fn();
    const writeFile = vi.fn();

    await runExtractCommand("teacher@example.com", {
      cwd: "/tmp/project",
      force: true,
      confirmOverwrite,
      extractInstructorData: vi.fn().mockResolvedValue({ ok: true }),
      fileExists: vi.fn().mockResolvedValue(true),
      writeFile
    });

    expect(confirmOverwrite).not.toHaveBeenCalled();
    expect(writeFile).toHaveBeenCalledOnce();
  });
});
