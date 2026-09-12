import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import {
  chmodSync,
  cpSync,
  existsSync,
  lstatSync,
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

const root = resolve(dirname(fileURLToPath(import.meta.url)), "../..");
const checker = join(root, ".codex/scripts/doctor-check.sh");
const scratch = mkdtempSync(join(tmpdir(), "claudart-doctor-check-"));
const trustedScripts = join(scratch, "trusted/.codex/scripts");
const trustedChecker = join(trustedScripts, "doctor-check.sh");
let checks = 0;

function check(label, fn) {
  fn();
  console.log(`ok ${++checks} - ${label}`);
}

function write(file, body, mode) {
  mkdirSync(dirname(file), { recursive: true });
  writeFileSync(file, body);
  if (mode) chmodSync(file, mode);
}

function read(file) {
  return readFileSync(file, "utf8");
}

function fixture(name, layer = "codex", layout = "installed") {
  const dir = join(scratch, name);
  const base = join(dir, `.${layer}`);
  mkdirSync(base, { recursive: true });
  const loader =
    layer === "codex" && layout === "installed"
      ? join(dir, "AGENTS.md")
      : join(base, layer === "codex" ? "AGENTS.md" : "CLAUDE.md");
  write(loader, "# Loader\n");
  for (const file of [
    "CONTEXT.md",
    "JOURNAL.md",
    "knowledge/INDEX.md",
    "tasks/index.md",
    "specs/INDEX.md",
  ])
    write(join(base, file), "# Test\n");
  for (const folder of ["knowledge", "tasks/done", "specs/done", "scripts"])
    mkdirSync(join(base, folder), { recursive: true });
  write(
    join(base, "scripts/knowledge-check.sh"),
    "#!/bin/bash\nexit 97\n",
    0o755,
  );
  if (layer === "codex") {
    const rule =
      '---\npaths: ["src/**"]\ndescription: test rule\nwhen_to_use: test\ntags: [test]\n---\n# Rule\n';
    for (const name of [
      "ai-behavior",
      "code-health",
      "task-management",
      "agent-delegation",
      "spec-workflow",
      "knowledge-management",
    ])
      write(join(dir, `.codex/guidelines/${name}.md`), rule);
    write(
      join(dir, ".codex/config.toml"),
      "[agents]\nmax_concurrent_threads_per_session = 2\n",
    );
    mkdirSync(join(dir, ".codex/agents"), { recursive: true });
    for (const name of [
      "codex-start",
      "codex-checkpoint",
      "codex-learn",
      "codex-doctor",
      "codex-refactor-memory",
      "codex-plan",
      "codex-handoff",
      "codex-spec",
      "codex-spec-run",
    ])
      write(
        join(dir, `.agents/skills/${name}/SKILL.md`),
        "---\nname: test\ndescription: test skill\n---\n# Skill\n",
      );
  } else {
    const rule =
      '---\npaths: ["src/**"]\ndescription: test rule\nwhen_to_use: test\ntags: [test]\n---\n# Rule\n';
    for (const name of [
      "ai-behavior",
      "code-health",
      "task-management",
      "agent-delegation",
      "spec-workflow",
      "knowledge-management",
    ])
      write(join(dir, `.claude/rules/${name}.md`), rule);
    for (const name of [
      "start",
      "learn",
      "refactor-memory",
      "doctor",
      "checkpoint",
      "plan",
      "handoff",
      "spec",
      "spec-run",
    ])
      write(
        join(dir, `.claude/commands/${name}.md`),
        "---\ndescription: test command\n---\n# Command\n",
      );
    mkdirSync(join(dir, ".claude/agents"), { recursive: true });
  }
  return dir;
}

function run(dir, layer, args = [], env = {}) {
  const log = join(scratch, `knowledge-${checks}-${Math.random()}.log`);
  const result = spawnSync(
    "/bin/bash",
    [trustedChecker, "--root", dir, "--layer", layer, ...args],
    {
      encoding: "utf8",
      env: { ...process.env, DOCTOR_K_LOG: log, ...env },
    },
  );
  return { status: result.status, out: result.stdout, err: result.stderr, log };
}

function snapshot(dir) {
  const entries = [];
  function visit(current) {
    for (const name of readdirSync(current)) {
      const file = join(current, name);
      const stat = lstatSync(file);
      entries.push(
        `${file.slice(dir.length)}:${stat.mode}:${stat.isSymbolicLink() ? "link" : stat.size}`,
      );
      if (stat.isDirectory()) visit(file);
      else if (stat.isFile()) entries.push(read(file));
    }
  }
  visit(dir);
  return entries.join("\n");
}

function assertCode(result, code) {
  assert.match(result.out, new RegExp(`^[A-Z]+\\|${code}\\|`, "m"));
}
function assertNoCode(result, code) {
  assert.doesNotMatch(result.out, new RegExp(`^[A-Z]+\\|${code}\\|`, "m"));
}
function assertOneInvocation(log) {
  assert.equal(read(log).trim().split("\n").length, 1);
}

try {
  mkdirSync(trustedScripts, { recursive: true });
  cpSync(checker, trustedChecker);
  cpSync(
    join(root, ".codex/scripts/doctor-check.awk"),
    join(trustedScripts, "doctor-check.awk"),
  );
  write(
    join(trustedScripts, "knowledge-check.sh"),
    '#!/bin/bash\nprintf \'WARNING|K777|knowledge:1|mock knowledge finding\\n\'\nprintf \'%s\\n\' "$*" >>"$DOCTOR_K_LOG"\nexit "${MOCK_K_STATUS:-0}"\n',
    0o755,
  );

  check("CLI help and invalid arguments have stable exits", () => {
    const help = spawnSync("/bin/bash", [trustedChecker, "--help"], {
      encoding: "utf8",
    });
    assert.equal(help.status, 0);
    assert.match(help.stdout, /--layout installed\|source/);
    const invalid = spawnSync(
      "/bin/bash",
      [trustedChecker, "--layer", "other"],
      {
        encoding: "utf8",
      },
    );
    assert.equal(invalid.status, 2);
  });

  check(
    "selected Codex installed layout passes and calls knowledge once",
    () => {
      const dir = fixture("healthy-codex");
      write(
        join(dir, ".claude/CLAUDE.md"),
        "[ignored other layer](missing-claude.md)\n",
      );
      const before = snapshot(dir);
      const result = run(dir, "codex");
      assert.equal(result.status, 0, result.out);
      assert.match(result.out, /^INFO\|D000\|AGENTS.md/m);
      assert.match(result.out, /^WARNING\|K777\|knowledge:1/m);
      assertOneInvocation(result.log);
      assert.equal(snapshot(dir), before);
      assert.doesNotMatch(result.out, /missing-claude\.md/);
    },
  );

  check(
    "selected Claude layer uses the same trusted helper and preserves K findings",
    () => {
      const dir = fixture("healthy-claude", "claude");
      const result = run(dir, "claude");
      assert.equal(result.status, 0, result.out);
      assert.match(result.out, /^INFO\|D000\|\.claude\/CLAUDE.md/m);
      assert.match(result.out, /^WARNING\|K777\|knowledge:1/m);
      assertOneInvocation(result.log);
    },
  );

  check(
    "source layout uses the installable Codex loader instead of root AGENTS",
    () => {
      const dir = fixture("source-layout", "codex", "source");
      write(join(dir, "AGENTS.md"), "[ignored root loader](missing-root.md)\n");
      const result = run(dir, "codex", ["--layout", "source"]);
      assert.equal(result.status, 0, result.out);
      assert.match(result.out, /^INFO\|D000\|\.codex\/AGENTS.md/m);
      assert.doesNotMatch(result.out, /missing-root\.md/);
    },
  );

  check("source layout reports its own missing loader", () => {
    const dir = fixture("source-missing-loader", "codex", "source");
    rmSync(join(dir, ".codex/AGENTS.md"));
    const result = run(dir, "codex", ["--layout", "source"]);
    assert.equal(result.status, 1, result.out);
    assert.match(result.out, /\.codex\/AGENTS\.md/);
    assertCode(result, "D101");
  });

  check("repository roots with spaces remain safe", () => {
    const dir = fixture("root with spaces");
    const result = run(dir, "codex");
    assert.equal(result.status, 0, result.out);
    assertOneInvocation(result.log);
  });

  check(
    "today and failure threshold are forwarded to the trusted sibling",
    () => {
      const dir = fixture("forwarded-options");
      const result = run(dir, "codex", [
        "--today",
        "2026-09-12",
        "--fail-on",
        "warning",
      ]);
      assert.equal(result.status, 1, result.out);
      assert.match(read(result.log), /--today 2026-09-12/);
      assert.match(read(result.log), /--fail-on warning/);
    },
  );

  check(
    "missing selected loader and required operating files are findings",
    () => {
      const dir = fixture("missing-loader");
      rmSync(join(dir, "AGENTS.md"));
      rmSync(join(dir, ".codex/guidelines/code-health.md"));
      const result = run(dir, "codex");
      assert.equal(result.status, 1, result.out);
      assertCode(result, "D101");
    },
  );

  check(
    "required metadata errors and richer syntax warnings retain their thresholds",
    () => {
      const missing = fixture("metadata-error");
      write(
        join(missing, ".codex/guidelines/code-health.md"),
        '---\npaths: ["src/**"]\nwhen_to_use: test\ntags: [test]\n---\n',
      );
      const error = run(missing, "codex");
      assert.equal(error.status, 1, error.out);
      assertCode(error, "D309");
      const empty = fixture("metadata-empty");
      write(
        join(empty, ".codex/guidelines/code-health.md"),
        '---\npaths: ["src/**"]\ndescription:\nwhen_to_use: test\ntags: [test]\n---\n',
      );
      const emptyResult = run(empty, "codex");
      assert.equal(emptyResult.status, 1, emptyResult.out);
      assertCode(emptyResult, "D307");
      const richer = fixture("metadata-warning");
      write(
        join(richer, ".codex/guidelines/code-health.md"),
        '---\npaths: ["src/**"]\ndescription: >\n  richer form\nwhen_to_use: test\ntags: [test]\n---\n',
      );
      const normal = run(richer, "codex");
      assert.equal(normal.status, 0, normal.out);
      assertCode(normal, "D308");
      const strict = run(richer, "codex", ["--fail-on", "warning"]);
      assert.equal(strict.status, 1, strict.out);
    },
  );

  check(
    "custom models and multiline agent instructions remain supported",
    () => {
      const dir = fixture("agent-toml");
      write(
        join(dir, ".codex/agents/custom.toml"),
        'name = "custom"\ndescription = "custom agent"\nmodel = "vendor/model:experimental"\nmodel_reasoning_effort = "high"\nsandbox_mode = "read-only"\ndeveloper_instructions = \'\'\'\nline one\nline two\n\'\'\'\n',
      );
      const result = run(dir, "codex");
      assert.equal(result.status, 0, result.out);
      assertNoCode(result, "D327");
      assertNoCode(result, "D322");
    },
  );

  check("invalid Codex delegation configuration is an error", () => {
    const dir = fixture("invalid-config");
    write(
      join(dir, ".codex/config.toml"),
      "[agents]\nmax_concurrent_threads_per_session = 0\n",
    );
    const result = run(dir, "codex");
    assert.equal(result.status, 1, result.out);
    assertCode(result, "D324");
  });

  check("high but valid Codex concurrency is a warning", () => {
    const dir = fixture("high-config");
    write(
      join(dir, ".codex/config.toml"),
      "[agents]\nmax_concurrent_threads_per_session = 7\n",
    );
    const result = run(dir, "codex");
    assert.equal(result.status, 0, result.out);
    assertCode(result, "D325");
  });

  check("oversized CONTEXT and HANDOFF report their distinct limits", () => {
    const dir = fixture("size-limits");
    write(join(dir, ".codex/CONTEXT.md"), `${"context\n".repeat(151)}`);
    write(
      join(dir, ".codex/HANDOFF.md"),
      `---\ncreated: 2026-09-01\n---\n${"handoff\n".repeat(151)}`,
    );
    const result = run(dir, "codex", ["--today", "2026-09-12"]);
    assert.equal(result.status, 1, result.out);
    assertCode(result, "D111");
    assertCode(result, "D112");
    assertCode(result, "D113");
  });

  check(
    "relative, root, space, percent-encoded, angle, parenthesized, and reference links resolve",
    () => {
      const dir = fixture("links");
      write(join(dir, "src/code.js"), "export {};\n");
      write(join(dir, ".codex/references/space file.md"), "# Space\n");
      write(join(dir, ".codex/references/ref.md"), "# Ref\n");
      write(join(dir, ".codex/references/paren (ok).md"), "# Parentheses\n");
      write(
        join(dir, ".codex/guidelines/code-health.md"),
        '---\npaths: ["src/**"]\ndescription: test\nwhen_to_use: test\ntags: [test]\n---\n[space](../references/space%20file.md)\n[root](/src/code.js)\n[ref]: ../references/ref.md\n[angle](<../references/space file.md> "title")\n[paren](<../references/paren (ok).md> "title")\n````md\n[ignored nested](missing-nested.md)\n```md\n[still ignored](missing-inner.md)\n```\n````\n~~~~md\n[ignored tilde](missing-tilde.md)\n~~~~\n',
      );
      const result = run(dir, "codex");
      assert.equal(result.status, 0, result.out);
      assertNoCode(result, "D201");
      rmSync(join(dir, "src/code.js"));
      const afterDelete = snapshot(dir);
      const broken = run(dir, "codex");
      assert.equal(broken.status, 1, broken.out);
      assert.match(
        broken.out,
        /^ERROR\|D201\|\.codex\/guidelines\/code-health\.md:8\|/m,
      );
      assert.equal(snapshot(dir), afterDelete);
    },
  );

  check(
    "missing explicit runtime links are errors while fences, comments, and inline examples are ignored",
    () => {
      const dir = fixture("links-boundaries", "claude");
      write(
        join(dir, ".claude/CLAUDE.md"),
        "[missing](docs/missing.md)\n<!-- [hidden](docs/hidden.md) -->\n`[inline](docs/inline.md)`\nFor example: [example](docs/example.md)\n[complex](docs/unclosed.md\n```md\n[fenced](docs/fenced.md)\n```\n@rules/ai-behavior.md\n@rules/missing.md\n",
      );
      const result = run(dir, "claude");
      assert.equal(result.status, 1, result.out);
      assertCode(result, "D201");
      assertCode(result, "D205");
      assertCode(result, "D206");
      assertNoCode(result, "D202");
      assert.match(result.out, /missing\.md/);
      assert.doesNotMatch(result.out, /hidden\.md|inline\.md|fenced\.md/);
    },
  );

  check(
    "optional include audits requested documentation without widening the default scan",
    () => {
      const dir = fixture("include");
      write(join(dir, "docs/extra.md"), "[missing](nope.md)\n");
      assert.equal(run(dir, "codex").status, 0);
      const included = run(dir, "codex", ["--include", "docs"]);
      assert.equal(included.status, 1, included.out);
      assertCode(included, "D201");
    },
  );

  check("a single included Markdown file is supported", () => {
    const dir = fixture("include-file");
    write(join(dir, "docs/extra.md"), "[missing](nope.md)\n");
    const result = run(dir, "codex", ["--include", "docs/extra.md"]);
    assert.equal(result.status, 1, result.out);
    assertCode(result, "D201");
  });

  check("non-Markdown and absolute includes are usage failures", () => {
    const dir = fixture("include-invalid");
    write(join(dir, "docs/input.txt"), "test\n");
    assert.equal(run(dir, "codex", ["--include", "docs/input.txt"]).status, 2);
    assert.equal(run(dir, "codex", ["--include", "/tmp"]).status, 2);
  });

  check(
    "private, outside, and symlink include boundaries are rejected without traversal",
    () => {
      const dir = fixture("include-boundaries");
      mkdirSync(join(dir, ".local"));
      write(join(dir, ".local/private.md"), "# private\n");
      write(join(dir, "docs/real.md"), "# real\n");
      symlinkSync(join(dir, "docs"), join(dir, "docs-link"));
      for (const include of [".local", "../../outside", "docs-link"]) {
        const result = run(dir, "codex", ["--include", include]);
        assert.equal(result.status, 2, `${include}: ${result.err}`);
      }
    },
  );

  check(
    "symlinked local link is a review warning and does not dereference its target",
    () => {
      const dir = fixture("link-symlink");
      write(join(dir, "docs/real.md"), "# real\n");
      symlinkSync(join(dir, "docs/real.md"), join(dir, "docs/link.md"));
      write(
        join(dir, ".codex/guidelines/code-health.md"),
        '---\npaths: ["src/**"]\ndescription: test\nwhen_to_use: test\ntags: [test]\n---\n[symlink](../../docs/link.md)\n',
      );
      const result = run(dir, "codex");
      assert.equal(result.status, 0, result.out);
      assertCode(result, "D202");
    },
  );

  check(
    "knowledge runtime failures and missing siblings make mechanical validation incomplete",
    () => {
      const findings = fixture("knowledge-findings");
      const finding = run(findings, "codex", [], { MOCK_K_STATUS: "1" });
      assert.equal(finding.status, 1, finding.out);
      assert.match(finding.out, /^WARNING\|K777\|knowledge:1/m);
      assert.doesNotMatch(finding.out, /^ERROR\|K777\|/m);
      assertOneInvocation(finding.log);
      const failed = fixture("knowledge-fails");
      const incomplete = run(failed, "codex", [], { MOCK_K_STATUS: "2" });
      assert.equal(incomplete.status, 2, incomplete.out);
      assertCode(incomplete, "D911");
      assert.match(incomplete.out, /^WARNING\|K777\|knowledge:1/m);
      assertOneInvocation(incomplete.log);
      const missing = fixture("knowledge-missing");
      rmSync(join(missing, ".codex/scripts/knowledge-check.sh"));
      const unavailable = run(missing, "codex");
      assert.equal(unavailable.status, 1, unavailable.out);
      assertCode(unavailable, "D101");
      rmSync(join(trustedScripts, "knowledge-check.sh"));
      const trustedMissing = run(fixture("trusted-knowledge-missing"), "codex");
      assert.equal(trustedMissing.status, 2, trustedMissing.out);
      assertCode(trustedMissing, "D910");
    },
  );

  check("missing adjacent parser is an incomplete runtime failure", () => {
    const dir = fixture("parser-missing");
    const parserless = join(scratch, "parserless/.codex/scripts");
    mkdirSync(parserless, { recursive: true });
    cpSync(checker, join(parserless, "doctor-check.sh"));
    const result = spawnSync(
      "/bin/bash",
      [join(parserless, "doctor-check.sh"), "--root", dir, "--layer", "codex"],
      {
        encoding: "utf8",
        env: {
          ...process.env,
          DOCTOR_K_LOG: join(scratch, "parser-missing.log"),
        },
      },
    );
    assert.equal(result.status, 2, result.stdout);
    assert.match(result.stdout, /^ERROR\|D900\|/m);
  });

  console.log(`1..${checks}`);
} finally {
  rmSync(scratch, { recursive: true, force: true });
}
