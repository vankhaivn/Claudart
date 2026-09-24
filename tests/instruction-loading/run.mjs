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
  symlinkSync,
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
// Output examples contain downstream-relative links inside fenced Markdown.
// Only prose links declare module resources; keep checking those recursively.
function resourceLinks(file) {
  let fence;
  const prose = [];
  for (const line of read(file).split("\n")) {
    const marker = /^ {0,3}(`{3,}|~{3,})(.*)$/.exec(line);
    if (fence) {
      if (
        marker &&
        marker[1][0] === fence[0] &&
        marker[1].length >= fence.length &&
        !marker[2].trim()
      )
        fence = undefined;
      continue;
    }
    if (marker) fence = marker[1];
    else prose.push(line);
  }
  return [...prose.join("\n").matchAll(/\]\(([^)#]+)(?:#[^)]*)?\)/g)]
    .map((match) => match[1])
    .filter((target) => !/^https?:/.test(target))
    .map((target) => resolve(dirname(file), target));
}
function resourceGraph(file, seen = new Set()) {
  assert(existsSync(file), `Missing resource: ${file}`);
  if (seen.has(file)) return seen;
  seen.add(file);
  if (file.endsWith(".md")) {
    for (const target of resourceLinks(file)) resourceGraph(target, seen);
  }
  return seen;
}
try {
  const source = join(scratch, "archive/claudart");
  mkdirSync(source, { recursive: true });
  for (const layer of [
    ".claudart",
    ".claude",
    ".codex",
    ".agents",
    "modules/project-docs",
  ])
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

  function verifyDoctor(dest, mode, label) {
    for (const layer of ["claude", "codex"]) {
      if (mode !== "both" && mode !== layer) continue;
      check(
        `${label}: ${layer} doctor helpers install and execute offline`,
        () => {
          for (const name of [
            "doctor-check.sh",
            "doctor-check.awk",
            "knowledge-check.sh",
          ]) {
            const relative = `.${layer}/scripts/${name}`;
            assert.equal(
              read(join(dest, relative)),
              read(join(root, relative)),
            );
          }
          const output = execFileSync(
            "/bin/bash",
            [
              join(dest, `.${layer}/scripts/doctor-check.sh`),
              "--root",
              dest,
              "--layer",
              layer,
            ],
            { cwd: dest, encoding: "utf8", stdio: "pipe" },
          );
          assert.match(output, /INFO\|D000\|/);
          assert.doesNotMatch(output, /^ERROR\|/m);
        },
      );
    }
  }

  for (const mode of ["claude", "codex", "both"]) {
    const dest = join(scratch, `install ${mode}`);
    install(dest, [`--${mode}`]);
    verifyDoctor(dest, mode, `${mode} core`);
    check(`${mode}: only selected runtime layers installed`, () => {
      assert.equal(existsSync(join(dest, ".claude")), mode !== "codex");
      assert.equal(existsSync(join(dest, ".codex")), mode !== "claude");
      assert.equal(existsSync(join(dest, ".agents")), mode !== "claude");
      assert.equal(existsSync(join(dest, "CLAUDE.md")), mode !== "codex");
      assert.equal(existsSync(join(dest, "AGENTS.md")), mode !== "claude");
      assert(!existsSync(join(dest, ".claude/CLAUDE.md")));
      assert(!existsSync(join(dest, ".codex/AGENTS.md")));
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
      check(`${mode}: Claude loader is installed at root without a duplicate`, () => {
        assert.equal(
          read(join(dest, "CLAUDE.md")),
          read(join(root, ".claude/CLAUDE.md")),
        );
        assert(!existsSync(join(dest, ".claude/CLAUDE.md")));
        const graph = importGraph(join(dest, "CLAUDE.md"));
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
  check("output examples do not hide missing prose resource links", () => {
    const fixture = join(scratch, "example links");
    mkdirSync(fixture);
    const entry = join(fixture, "entry.md");
    const reference = join(fixture, "reference.md");
    const asset = join(fixture, "template.md");
    writeFileSync(
      entry,
      [
        "````md",
        "```md",
        "[Output link](not-a-module-file.md)",
        "```",
        "````",
        "~~~md",
        "[Another output link](also-not-a-module-file.md)",
        "~~~",
        "[Reference](reference.md)",
      ].join("\n"),
    );
    assert.throws(() => resourceGraph(entry), /Missing resource/);
    writeFileSync(reference, "[Template](template.md)\n");
    assert.throws(() => resourceGraph(entry), /Missing resource/);
    writeFileSync(asset, "# Output template\n");
    assert.deepEqual(resourceGraph(entry), new Set([entry, reference, asset]));
  });
  check(
    "Project Docs output templates and example content match across runtimes",
    () => {
      const codex = join(moduleSource, ".agents/skills/codex-project-docs");
      const claude = join(moduleSource, ".claude/references/project-docs");
      for (const [from, to] of [
        ["assets/templates", "assets/templates"],
        ["references/examples", "examples"],
      ]) {
        const originals = files(join(codex, from));
        assert.deepEqual(
          originals.map((file) => file.slice(join(codex, from).length + 1)),
          files(join(claude, to)).map((file) =>
            file.slice(join(claude, to).length + 1),
          ),
        );
        for (const file of originals) {
          const relative = file.slice(join(codex, from).length + 1);
          assert.equal(read(file), read(join(claude, to, relative)), relative);
        }
      }
      const guides = [
        join(codex, "references/templates.md"),
        join(claude, "templates.md"),
      ].map((file) =>
        read(file)
          .replaceAll("../assets/templates/", "assets/templates/")
          .split("\n")
          // Different link lengths change only the formatter's table padding.
          .map((line) =>
            line.startsWith("|")
              ? line
                  .split("|")
                  .map((cell) => cell.trim().replace(/^-+$/, "---"))
                  .join("|")
              : line,
          )
          .join("\n"),
      );
      assert.equal(guides[0], guides[1]);
    },
  );
  for (const mode of ["claude", "codex", "both"]) {
    for (const moduleFirst of [false, true]) {
      const dest = join(scratch, `module ${mode} ${moduleFirst}`);
      const args = [`--${mode}`, "--project-docs"];
      if (moduleFirst) args.reverse();
      install(dest, args);
      const label = `${mode}, module ${moduleFirst ? "first" : "last"}`;
      verifyDoctor(dest, mode, label);
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
              for (const target of resourceLinks(installed)) {
                assert(
                  existsSync(target),
                  `Broken module link: ${relative} -> ${target}`,
                );
              }
            }
          }
          if (mode !== "codex") {
            assert.equal(
              importGraph(join(dest, "CLAUDE.md")).size,
              2,
              "The optional module must not expand unconditional imports",
            );
          }
        },
      );
      check(
        `${label}: all module resources are reachable from their entrypoint`,
        () => {
          for (const [folder, entry] of [
            ...(mode !== "codex" ? [[".claude", moduleEntries[0]]] : []),
            ...(mode !== "claude" ? [[".agents", moduleEntries[1]]] : []),
          ]) {
            const graph = resourceGraph(join(dest, entry));
            for (const file of files(join(moduleSource, folder))) {
              const relative = file.slice(moduleSource.length + 1);
              assert(
                graph.has(join(dest, relative)),
                `Unreachable module resource: ${relative}`,
              );
            }
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
        "CLAUDE.md": "# Custom Claude root loader\n",
        ".claude/commands/project-discovery.md":
          "Custom team interview; preserve this file.\n",
        ".agents/skills/codex-project-discovery/SKILL.md":
          "Custom team discovery skill.\n",
        [moduleEntries[0]]: "Custom project documentation command.\n",
        [moduleEntries[1]]: "Custom project documentation skill.\n",
        ".claudart/knowledge/team-route.md":
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
    "legacy nested Claude loader is preserved without creating a duplicate root loader",
    () => {
      const dest = join(scratch, "legacy Claude loader");
      mkdirSync(join(dest, ".claude"), { recursive: true });
      const legacy = "# Legacy project-owned Claude loader\n\nSee @rules/ai-behavior.md\n";
      writeFileSync(join(dest, ".claude/CLAUDE.md"), legacy);
      install(dest, ["--claude", "--force"]);
      assert.equal(read(join(dest, ".claude/CLAUDE.md")), legacy);
      assert(!existsSync(join(dest, "CLAUDE.md")));
      assert(existsSync(join(dest, ".claude/commands/start.md")));
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
      assert(existsSync(join(dest, "CLAUDE.md")));
      assert(!existsSync(join(dest, ".claude/CLAUDE.md")));
    },
  );
  check("root Claude loader resolves adapter-prefixed imports", () => {
    const fixture = join(scratch, "root-loader");
    mkdirSync(join(fixture, ".claude/rules"), { recursive: true });
    writeFileSync(
      join(fixture, ".claude/rules/ai-behavior.md"),
      "Universal baseline\n",
    );
    writeFileSync(join(fixture, "CLAUDE.md"), "See @rules/ai-behavior.md\n");
    assert.throws(
      () => importGraph(join(fixture, "CLAUDE.md")),
      /Missing import/,
    );
    writeFileSync(
      join(fixture, "CLAUDE.md"),
      "See @.claude/rules/ai-behavior.md\n",
    );
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
  // Shared-state behavior uses the real installer and checker binaries, not a
  // test-only implementation of state selection. Fixtures are anonymous data.
  const seeds = [
    "CONTEXT.md",
    "JOURNAL.md",
    "knowledge/INDEX.md",
    "tasks/index.md",
    "tasks/done/.gitkeep",
    "specs/INDEX.md",
    "specs/done/.gitkeep",
  ].sort();
  function stateSnapshot(dest) {
    const state = join(dest, ".claudart");
    return files(state)
      .sort()
      .map((file) => [
        file.slice(state.length + 1),
        readFileSync(file).toString("hex"),
      ]);
  }
  function variantArchive(name, mutate) {
    const dir = join(scratch, name, "claudart");
    cpSync(source, dir, { recursive: true });
    mutate(dir);
    const tar = join(scratch, `${name}.tar.gz`);
    execFileSync("tar", ["-czf", tar, "-C", dirname(dir), "claudart"]);
    return tar;
  }
  check("source distributes only the seven empty shared-state seeds", () => {
    assert.deepEqual(
      files(join(root, ".claudart"))
        .map((f) => f.slice(join(root, ".claudart").length + 1))
        .sort(),
      seeds,
    );
    for (const adapter of [".claude", ".codex"])
      for (const name of [
        "CONTEXT.md",
        "JOURNAL.md",
        "HANDOFF.md",
        "knowledge",
        "tasks",
        "specs",
      ])
        assert(!existsSync(join(root, adapter, name)), `${adapter}/${name}`);
  });
  check(
    "current docs and runtime consumers use the shared state contract",
    () => {
      const productFiles = [
        ...["README.md", "README_VI.md", "CONTRIBUTING.md", "INTEGRATE.md"].map(
          (p) => join(root, p),
        ),
        ...["docs", ".claude", ".codex", ".agents", "modules"].flatMap((p) =>
          files(join(root, p)),
        ),
      ];
      for (const file of productFiles)
        assert.doesNotMatch(
          read(file),
          /\.(?:claude|codex)\/(?:CONTEXT\.md|JOURNAL\.md|HANDOFF\.md|knowledge|tasks|specs)(?:\b|\/)/,
          file,
        );
      for (const [adapter, rules, commands, suffix] of [
        [".claude", ".claude/rules", ".claude/commands/", ".md"],
        [".codex", ".codex/guidelines", ".agents/skills/codex-", "/SKILL.md"],
      ]) {
        for (const workflow of ["task-management", "spec-workflow"]) {
          const contract = read(join(root, rules, `${workflow}.md`));
          assert.match(
            contract,
            /Resume the same workspace regardless of its `agent` metadata/,
          );
          assert.match(
            contract,
            /Changing runtimes preserves scope, approval, execution evidence and review gates/,
          );
        }
        assert.match(
          read(join(root, `${commands}checkpoint${suffix}`)),
          /Absence from this conversation is not completion/,
        );
        assert.match(
          read(join(root, `${commands}handoff${suffix}`)),
          /Never silently overwrite an unconsumed baton/,
        );
        assert.match(
          read(join(root, `${commands}start${suffix}`)),
          /confirm it is the same content/,
        );
        assert.doesNotMatch(
          read(join(root, adapter, "scripts/doctor-check.sh")),
          /\$LAYER_DIR\/(?:knowledge|tasks|specs|CONTEXT|JOURNAL|HANDOFF)/,
        );
      }
    },
  );
  for (const mode of ["claude", "codex", "both"]) {
    check(`${mode}: one shared seed set and no provider-specific state`, () => {
      const dest = join(scratch, `shared-seeds-${mode}`);
      install(dest, [`--${mode}`]);
      assert.deepEqual(
        stateSnapshot(dest).map(([path]) => path),
        seeds,
      );
      for (const adapter of [".claude", ".codex"])
        for (const name of [
          "CONTEXT.md",
          "JOURNAL.md",
          "HANDOFF.md",
          "knowledge",
          "tasks",
          "specs",
        ])
          assert(!existsSync(join(dest, adapter, name)), `${adapter}/${name}`);
    });
  }
  for (const first of ["claude", "codex"]) {
    check(
      `${first}: adapter addition, reinstall and force preserve every state byte`,
      () => {
        const dest = join(scratch, `preserve-${first}`);
        install(dest, [`--${first}`]);
        const records = {
          "CONTEXT.md":
            "# Current work\n\nUnresolved work from another session.\n",
          "JOURNAL.md":
            "# History\n2026-09-20 | decision | Preserve the approved scope.\n",
          "HANDOFF.md": `---\ncreated: 2026-09-20 09:00Z\nagent: ${first}\ntask: review-contract\n---\n# Unconsumed handoff\n`,
          "tasks/index.md":
            "## Active\n\n- [Review contract](2026-09-20-001-review-contract/TASK.md)\n",
          "tasks/2026-09-20-001-review-contract/TASK.md": `---\nslug: review-contract\nstatus: awaiting-review\ncreated: 2026-09-20\nupdated: 2026-09-20\nagent: ${first}\ndelegation: none\ntags: [contract]\n---\n# Review contract\n\nUser confirmation is required before closure.\n`,
          "tasks/2026-09-20-001-review-contract/artifacts/input.bin":
            Buffer.from([0, 255, 128, 1, 10, 0, 13]),
          "tasks/done/2026-09-19-001-reviewed-work/TASK.md":
            "---\nstatus: done\n---\n# Retained archive\n",
          "knowledge/INDEX.md":
            "# Project Knowledge\n\n## Knowledge\n\n- _(none)_\n",
          "knowledge/_maps/review-candidates.md":
            "# Unindexed candidate preserved for review\n",
          "specs/INDEX.md":
            "## Active\n\n- [Approved mission](2026-09-20-approved-mission/SPEC.md)\n",
          "specs/2026-09-20-approved-mission/SPEC.md": `---\nslug: approved-mission\nstatus: running\ncreated: 2026-09-20\nupdated: 2026-09-20\nagent: ${first}\ncommits: user\n---\n# Approved mission\n\n## Mission\nPreserve the approved scope and evidence.\n`,
          "specs/2026-09-20-approved-mission/ROADMAP.md":
            "# Roadmap\n\n- [x] P1.1 Verified fixture step\n- [ ] P1.2 Pending fixture step\n",
          "specs/2026-09-20-approved-mission/LEDGER.md":
            "# Evidence\n\n### 2026-09-20 09:00Z — task-completed P1.1\n\n- Evidence: retained fixture result.\n",
          "specs/2026-09-20-approved-mission/NOTES.md":
            "# Notes\n\nThe current task is still pending.\n",
          "specs/2026-09-20-approved-mission/artifacts/reference.bin":
            Buffer.from([7, 0, 255, 128]),
        };
        for (const [relative, body] of Object.entries(records)) {
          const file = join(dest, ".claudart", relative);
          mkdirSync(dirname(file), { recursive: true });
          writeFileSync(file, body);
        }
        const before = stateSnapshot(dest);
        const loaders = {
          "AGENTS.md": "# Project-owned Codex root instructions\n",
          "CLAUDE.md": "# Project-owned Claude root instructions\n",
        };
        for (const [name, body] of Object.entries(loaders))
          writeFileSync(join(dest, name), body);
        for (const args of [
          [first === "claude" ? "--codex" : "--claude"],
          ["--both"],
          ["--both", "--force", "--project-docs"],
        ]) {
          install(dest, args);
          assert.deepEqual(stateSnapshot(dest), before);
          for (const [name, body] of Object.entries(loaders))
            assert.equal(read(join(dest, name)), body);
          assert(!existsSync(join(dest, ".codex/AGENTS.md")));
          assert(!existsSync(join(dest, ".claude/CLAUDE.md")));
        }
        const payload = ".codex/guidelines/ai-behavior.md";
        writeFileSync(join(dest, payload), "# Locally modified payload\n");
        install(dest, ["--both", "--force"]);
        assert.equal(read(join(dest, payload)), read(join(root, payload)));
        assert.deepEqual(stateSnapshot(dest), before);
      },
    );
  }
  check(
    "installer does not distribute upstream handoffs, live tasks or artifacts",
    () => {
      const tar = variantArchive("unselected-state", (dir) => {
        const work = join(dir, ".claudart/tasks/2026-09-20-001-private-work");
        mkdirSync(work, { recursive: true });
        writeFileSync(join(work, "TASK.md"), "# Must not be installed\n");
        writeFileSync(
          join(dir, ".claudart/HANDOFF.md"),
          "# Must not be installed\n",
        );
        writeFileSync(join(dir, ".claudart/unused.bin"), Buffer.from([0, 255]));
      });
      const dest = join(scratch, "ignore-upstream-work");
      install(dest, ["--both", "--force"], tar);
      assert.deepEqual(
        stateSnapshot(dest).map(([path]) => path),
        seeds,
      );
    },
  );
  check("missing shared seed fails before a partial installation", () => {
    const tar = variantArchive("missing-state", (dir) =>
      rmSync(join(dir, ".claudart/specs/INDEX.md")),
    );
    const dest = join(scratch, "missing-state-dest");
    assert.throws(
      () => install(dest, ["--both"], tar),
      /Shared state seed is missing/,
    );
    assert.deepEqual(readdirSync(dest), []);
  });
  for (const [relative, kind] of [
    [".claudart", "link"],
    [".claudart/knowledge", "link"],
    [".claudart/CONTEXT.md", "link"],
    [".claudart/tasks", "file"],
    [".claudart/CONTEXT.md", "directory"],
    [".claudart/JOURNAL.md", "dangling"],
  ]) {
    check(
      `installer refuses ${kind} at ${relative} before any payload writes`,
      () => {
        const dest = join(scratch, `collision-${checks}`);
        const target = join(dest, relative);
        const outside = join(scratch, `outside-${checks}`);
        mkdirSync(outside);
        writeFileSync(
          join(outside, "sentinel"),
          "Keep outside state intact.\n",
        );
        mkdirSync(dirname(target), { recursive: true });
        if (kind === "link") symlinkSync(outside, target);
        else if (kind === "dangling")
          symlinkSync(join(outside, "absent"), target);
        else if (kind === "file")
          writeFileSync(target, "Keep collision intact.\n");
        else mkdirSync(target);
        assert.throws(
          () => install(dest, ["--both", "--force"]),
          /Shared state/,
        );
        assert(!existsSync(join(dest, ".claude")));
        assert(!existsSync(join(dest, ".codex")));
        assert.equal(
          read(join(outside, "sentinel")),
          "Keep outside state intact.\n",
        );
        assert.deepEqual(readdirSync(outside), ["sentinel"]);
      },
    );
  }
  check(
    "both adapters validate the same knowledge from nested working directories",
    () => {
      const dest = join(scratch, "nested shared project");
      install(dest, ["--both"]);
      const fixture = join(
        root,
        "tests/knowledge-check/fixtures/healthy-direct",
      );
      cpSync(
        join(fixture, "layer/knowledge"),
        join(dest, ".claudart/knowledge"),
        { recursive: true },
      );
      cpSync(join(fixture, "docs"), join(dest, "docs"), { recursive: true });
      const topic = join(dest, ".claudart/knowledge/core-model.md");
      writeFileSync(
        topic,
        read(topic).replace(
          "related:\n",
          'related:\n  - "rule:ai-behavior"\n  - "guideline:ai-behavior"\n',
        ),
      );
      const cwd = join(dest, "src/nested");
      mkdirSync(cwd, { recursive: true });
      const before = stateSnapshot(dest);
      for (const adapter of [".claude", ".codex"]) {
        const args = [
          join(dest, adapter, "scripts/knowledge-check.sh"),
          "--today",
          "2026-07-29",
          "--fail-on",
          "warning",
        ];
        const findings = execFileSync("/bin/bash", args, {
          cwd,
          encoding: "utf8",
        });
        assert.equal(findings, "");
        const doctor = execFileSync(
          "/bin/bash",
          [
            join(dest, adapter, "scripts/doctor-check.sh"),
            "--today",
            "2026-07-29",
          ],
          { cwd, encoding: "utf8" },
        );
        assert.match(doctor, /INFO\|D000\|/);
        assert.doesNotMatch(doctor, /^ERROR\|/m);
      }
      assert.deepEqual(stateSnapshot(dest), before);
      rmSync(join(dest, ".claude/rules/ai-behavior.md"));
      for (const adapter of [".claude", ".codex"])
        assert.throws(
          () =>
            execFileSync(
              "/bin/bash",
              [
                join(dest, adapter, "scripts/knowledge-check.sh"),
                "--today",
                "2026-07-29",
              ],
              { cwd, stdio: "pipe" },
            ),
          (err) =>
            err.status === 1 &&
            /K141/.test(err.stdout.toString()) &&
            !/K140/.test(err.stdout.toString()),
        );
    },
  );
  check(
    "knowledge checker rejects a symlinked shared root without reading it",
    () => {
      const dest = join(scratch, "knowledge-linked-state");
      install(dest, ["--both"]);
      const outside = join(scratch, "linked-knowledge-target");
      mkdirSync(join(outside, "knowledge"), { recursive: true });
      writeFileSync(
        join(outside, "knowledge/INDEX.md"),
        "- [private marker](missing-file.md) — marker · reference · active\n",
      );
      rmSync(join(dest, ".claudart"), { recursive: true });
      symlinkSync(outside, join(dest, ".claudart"));
      for (const adapter of [".claude", ".codex"])
        assert.throws(
          () =>
            execFileSync(
              "/bin/bash",
              [join(dest, adapter, "scripts/knowledge-check.sh")],
              { stdio: "pipe" },
            ),
          (err) =>
            err.status === 1 &&
            /K001/.test(err.stdout.toString()) &&
            !/private marker|K20/.test(err.stdout.toString()),
        );
    },
  );
  check(
    "a missing shared store is not replaced by a provider-local fallback",
    () => {
      const dest = join(scratch, "no-shared-store");
      install(dest, ["--both"]);
      rmSync(join(dest, ".claudart"), { recursive: true });
      for (const adapter of [".claude", ".codex"]) {
        mkdirSync(join(dest, adapter, "knowledge"));
        writeFileSync(
          join(dest, adapter, "knowledge/INDEX.md"),
          "# Project Knowledge\n\n## Knowledge\n\n- _(none)_\n",
        );
        assert.throws(
          () =>
            execFileSync(
              "/bin/bash",
              [join(dest, adapter, "scripts/knowledge-check.sh")],
              { stdio: "pipe" },
            ),
          (err) => err.status === 1 && /K001/.test(err.stdout.toString()),
        );
      }
    },
  );

  console.log(`1..${checks}`);
} finally {
  rmSync(scratch, { recursive: true, force: true });
}
