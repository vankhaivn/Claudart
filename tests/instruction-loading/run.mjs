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
  for (const layer of [".claude", ".codex", ".agents", "modules/project-docs"])
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

  function install(dest, args = [], sourceArchive = archive) {
    mkdirSync(dest, { recursive: true });
    return execFileSync("/bin/bash", [join(root, "install.sh"), ...args], {
      cwd: dest,
      env: {
        ...process.env,
        PATH: `${bin}:${process.env.PATH}`,
        CLAUDART_TEST_ARCHIVE: sourceArchive,
      },
      stdio: "pipe",
    });
  }

  for (const mode of ["claude", "codex", "both"]) {
    const dest = join(scratch, `install ${mode}`);
    install(dest, [`--${mode}`]);
    check(`${mode}: only selected runtime layers installed`, () => {
      assert.equal(existsSync(join(dest, ".claude")), mode !== "codex");
      assert.equal(existsSync(join(dest, ".codex")), mode !== "claude");
      assert.equal(existsSync(join(dest, ".agents")), mode !== "claude");
    });
    check(`${mode}: core install leaves optional Project Docs absent`, () => {
      assert(!existsSync(join(dest, ".claude/commands/project-docs.md")));
      assert(!existsSync(join(dest, ".agents/skills/codex-project-docs")));
      assert(!existsSync(join(dest, "docs")));
    });
    check(
      `${mode}: fresh installs exclude the retired discovery payload`,
      () => {
        assert(
          !existsSync(join(dest, ".claude/commands/project-discovery.md")),
        );
        assert(!existsSync(join(dest, ".claude/references/project-discovery")));
        assert(
          !existsSync(join(dest, ".agents/skills/codex-project-discovery")),
        );
      },
    );
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
  const moduleSource = join(root, "modules/project-docs");
  const moduleEntries = [
    ".claude/commands/project-docs.md",
    ".agents/skills/codex-project-docs/SKILL.md",
  ];
  for (const mode of ["claude", "codex", "both"]) {
    for (const moduleFirst of [false, true]) {
      const dest = join(scratch, `module ${mode} ${moduleFirst}`);
      const args = [`--${mode}`, "--project-docs"];
      if (moduleFirst) args.reverse();
      install(dest, args);
      const label = `${mode}, module ${moduleFirst ? "first" : "last"}`;
      check(`${label}: module overlays only selected runtime layers`, () => {
        assert.equal(
          existsSync(join(dest, moduleEntries[0])),
          mode !== "codex",
        );
        assert.equal(
          existsSync(join(dest, moduleEntries[1])),
          mode !== "claude",
        );
        assert.equal(existsSync(join(dest, ".claude")), mode !== "codex");
        assert.equal(existsSync(join(dest, ".codex")), mode !== "claude");
        assert.equal(existsSync(join(dest, ".agents")), mode !== "claude");
        assert(
          !existsSync(join(dest, "modules")),
          "Source wrapper is not runtime state",
        );
        assert(
          !existsSync(join(dest, "docs")),
          "Installing does not author project docs",
        );
        assert(
          !existsSync(join(dest, "README.md")),
          "Module packaging docs stay upstream",
        );
      });
      check(
        `${label}: module resources are copied intact and links resolve`,
        () => {
          for (const folder of [
            ...(mode !== "codex" ? [".claude"] : []),
            ...(mode !== "claude" ? [".agents"] : []),
          ]) {
            for (const file of files(join(moduleSource, folder))) {
              const relative = file.slice(moduleSource.length + 1);
              const installed = join(dest, relative);
              assert.equal(
                read(installed),
                read(file),
                `Module differs: ${relative}`,
              );
              for (const [, target] of read(installed).matchAll(
                /\]\(([^)#]+)(?:#[^)]*)?\)/g,
              )) {
                if (/^https?:/.test(target)) continue;
                assert(
                  existsSync(resolve(dirname(installed), target)),
                  `Broken module link: ${relative} -> ${target}`,
                );
              }
            }
          }
          if (mode !== "codex") {
            assert.equal(
              importGraph(join(dest, ".claude/CLAUDE.md")).size,
              2,
              "The optional module must not expand unconditional imports",
            );
          }
        },
      );
    }
  }
  check("module flag alone keeps the default Claude runtime", () => {
    const dest = join(scratch, "module default");
    install(dest, ["--project-docs"]);
    assert(existsSync(join(dest, moduleEntries[0])));
    assert(!existsSync(join(dest, ".codex")));
    assert(!existsSync(join(dest, ".agents")));
  });
  check(
    "existing docs, custom discovery, and module edits survive additive installs",
    () => {
      const dest = join(scratch, "existing project");
      install(dest, ["--both"]);
      const custom = {
        "docs/README.md":
          "# Team documentation\n\n[Product](project/product.md)\n",
        "docs/project/product.md":
          "# Approved intent\n\nE is approved; C is implemented.\n",
        "docs/releases/v1.md":
          "# Supported release\n\nVersion 1 remains supported.\n",
        ".claude/commands/project-discovery.md":
          "Custom team interview; preserve this file.\n",
        ".agents/skills/codex-project-discovery/SKILL.md":
          "Custom team discovery skill.\n",
        [moduleEntries[0]]: "Custom project documentation command.\n",
        [moduleEntries[1]]: "Custom project documentation skill.\n",
        ".codex/knowledge/team-route.md":
          "Existing team-owned knowledge route.\n",
      };
      for (const [relative, body] of Object.entries(custom)) {
        mkdirSync(dirname(join(dest, relative)), { recursive: true });
        writeFileSync(join(dest, relative), body);
      }
      install(dest, ["--both", "--project-docs"]);
      for (const [relative, body] of Object.entries(custom))
        assert.equal(
          read(join(dest, relative)),
          body,
          `Additive install overwrote ${relative}`,
        );
      assert(
        existsSync(join(dest, ".claude/references/project-docs/ownership.md")),
      );
      assert(
        existsSync(
          join(
            dest,
            ".agents/skills/codex-project-docs/references/ownership.md",
          ),
        ),
      );
      install(dest, ["--both", "--force"]);
      for (const [relative, body] of Object.entries(custom))
        assert.equal(
          read(join(dest, relative)),
          body,
          `Core-only refresh touched ${relative}`,
        );
      install(dest, ["--codex", "--force", "--project-docs"]);
      assert.equal(
        read(join(dest, moduleEntries[1])),
        read(join(moduleSource, moduleEntries[1])),
      );
      assert.equal(
        read(join(dest, moduleEntries[0])),
        custom[moduleEntries[0]],
        "Forcing the Codex module does not overwrite the Claude module",
      );
      for (const [relative, body] of Object.entries(custom)) {
        if (relative === moduleEntries[1]) continue;
        assert.equal(
          read(join(dest, relative)),
          body,
          `Module refresh touched ${relative}`,
        );
      }
    },
  );
  check(
    "missing selected module fails before writing a partial install",
    () => {
      rmSync(join(source, "modules"), { recursive: true });
      const coreArchive = join(scratch, "core-only.tar.gz");
      execFileSync("tar", [
        "-czf",
        coreArchive,
        "-C",
        dirname(source),
        "claudart",
      ]);
      const dest = join(scratch, "missing module");
      assert.throws(
        () => install(dest, ["--both", "--project-docs"], coreArchive),
        /Project Docs payload is missing/,
      );
      assert.deepEqual(readdirSync(dest), []);
      install(dest, ["--both"], coreArchive);
      assert(existsSync(join(dest, "AGENTS.md")));
    },
  );
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
