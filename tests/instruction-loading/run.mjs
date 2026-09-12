import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import {
  cpSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  readdirSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

// Offline install smoke test. No agent/model calls and no downloads.
const root = resolve(dirname(fileURLToPath(import.meta.url)), "../..");
const scratch = mkdtempSync(join(tmpdir(), "claudart-loading-"));
let checks = 0;
function check(label, fn) {
  fn();
  console.log(`ok ${++checks} - ${label}`);
}
function read(path) {
  return readFileSync(path, "utf8");
}
function files(path) {
  return readdirSync(path, { withFileTypes: true }).flatMap((entry) => {
    const child = join(path, entry.name);
    return entry.isDirectory() ? files(child) : [child];
  });
}
// The shipped loader uses simple prose imports. Exclude code examples; this is
// a fixture resolver for that syntax, not a reimplementation of Claude's parser.
function imports(file) {
  const prose = read(file)
    .replace(/```[^]*?```/g, "")
    .replace(/`[^`]*`/g, "");
  return [...prose.matchAll(/(?:^|\s)@([\w./-]+\.md)\b/g)].map((match) =>
    resolve(dirname(file), match[1]),
  );
}
function importGraph(file, seen = new Set()) {
  assert(existsSync(file), `Missing import: ${file}`);
  if (seen.has(file)) return seen;
  seen.add(file);
  for (const target of imports(file)) importGraph(target, seen);
  return seen;
}
try {
  const source = join(scratch, "archive/claudart");
  mkdirSync(source, { recursive: true });
  for (const layer of [".claude", ".codex", ".agents"])
    cpSync(join(root, layer), join(source, layer), { recursive: true });
  const archive = join(scratch, "source.tar.gz");
  execFileSync("tar", ["-czf", archive, "-C", dirname(source), "claudart"]);
  const bin = join(scratch, "bin");
  mkdirSync(bin);
  writeFileSync(
    join(bin, "curl"),
    '#!/bin/sh\ncat "$CLAUDART_TEST_ARCHIVE"\n',
    { mode: 0o755 },
  );

  for (const mode of ["claude", "codex", "both"]) {
    const dest = join(scratch, `install ${mode}`);
    mkdirSync(dest);
    execFileSync("/bin/bash", [join(root, "install.sh"), `--${mode}`], {
      cwd: dest,
      env: {
        ...process.env,
        PATH: `${bin}:${process.env.PATH}`,
        CLAUDART_TEST_ARCHIVE: archive,
      },
      stdio: "pipe",
    });
    check(`${mode}: only selected runtime layers installed`, () => {
      assert.equal(existsSync(join(dest, ".claude")), mode !== "codex");
      assert.equal(existsSync(join(dest, ".codex")), mode !== "claude");
      assert.equal(existsSync(join(dest, ".agents")), mode !== "claude");
    });
    if (mode !== "codex") {
      check(`${mode}: Claude imports resolve from the installed loader`, () => {
        const graph = importGraph(join(dest, ".claude/CLAUDE.md"));
        assert(graph.has(join(dest, ".claude/rules/ai-behavior.md")));
        assert.equal(
          graph.size,
          2,
          "Only the universal behavior rule is auto-imported",
        );
      });
    }
    if (mode !== "claude") {
      check(
        `${mode}: Codex loader is installed at root without a duplicate`,
        () => {
          assert.equal(
            read(join(dest, "AGENTS.md")),
            read(join(root, ".codex/AGENTS.md")),
          );
          assert(!existsSync(join(dest, ".codex/AGENTS.md")));
        },
      );
    }
    check(
      `${mode}: conditional support files survive actual installer copying`,
      () => {
        const support = [
          ...(mode !== "codex" ? [".claude/references"] : []),
          ...(mode !== "claude" ? [".codex/references", ".agents/skills"] : []),
        ];
        for (const folder of support) {
          assert(
            existsSync(join(root, folder)),
            `Missing source reference directory: ${folder}`,
          );
          for (const file of files(join(root, folder))) {
            const relative = file.slice(root.length + 1);
            assert.equal(
              read(join(dest, relative)),
              read(file),
              `Installed reference differs: ${relative}`,
            );
          }
        }
      },
    );
    check(
      `${mode}: declared conditional Markdown links resolve after installation`,
      () => {
        const entrypoints = [
          ...(mode !== "codex"
            ? [".claude/rules/knowledge-management.md"]
            : []),
          ...(mode !== "claude"
            ? [".codex/guidelines/knowledge-management.md"]
            : []),
        ];
        for (const folder of [
          ...(mode !== "codex" ? [".claude/commands"] : []),
          ...(mode !== "claude" ? [".agents/skills"] : []),
        ]) {
          entrypoints.push(
            ...files(join(dest, folder))
              .filter((file) => file.endsWith(".md"))
              .map((file) => file.slice(dest.length + 1)),
          );
        }
        for (const entry of entrypoints) {
          const file = join(dest, entry);
          for (const [, target] of read(file).matchAll(
            /\]\(([^)#]+)(?:#[^)]*)?\)/g,
          )) {
            if (/^https?:/.test(target)) continue;
            assert(
              existsSync(resolve(dirname(file), target)),
              `Broken link in ${entry}: ${target}`,
            );
          }
        }
      },
    );
  }
  check("regression fixture rejects a repeated .claude prefix", () => {
    const fixture = join(scratch, "bad/.claude");
    mkdirSync(join(fixture, "rules"), { recursive: true });
    writeFileSync(
      join(fixture, "rules/ai-behavior.md"),
      "Universal baseline\n",
    );
    writeFileSync(
      join(fixture, "CLAUDE.md"),
      "See @.claude/rules/ai-behavior.md\n",
    );
    assert.throws(
      () => importGraph(join(fixture, "CLAUDE.md")),
      /Missing import/,
    );
    writeFileSync(join(fixture, "CLAUDE.md"), "See @rules/ai-behavior.md\n");
    assert.equal(importGraph(join(fixture, "CLAUDE.md")).size, 2);
  });
  check("conditional Claude workflows do not use universal path globs", () => {
    for (const rule of [
      "task-management",
      "spec-workflow",
      "agent-delegation",
      "knowledge-management",
      "code-health",
    ]) {
      const text = read(join(root, `.claude/rules/${rule}.md`));
      const paths = /^paths: (.+)$/m.exec(text);
      assert(paths, `Missing paths: ${rule}`);
      assert(
        !JSON.parse(paths[1]).includes("**/*"),
        `Globally activated workflow: ${rule}`,
      );
      assert(
        read(join(root, ".claude/CLAUDE.md")).includes(
          `.claude/rules/${rule}.md`,
        ),
        `Missing conditional route: ${rule}`,
      );
    }
  });
  console.log(`1..${checks}`);
} finally {
  rmSync(scratch, { recursive: true, force: true });
}
