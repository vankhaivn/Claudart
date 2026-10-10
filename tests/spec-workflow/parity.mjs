import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "../..");

function body(source) {
  return source
    .replace(/^---\r?\n[\s\S]*?\r?\n---\r?\n+/, "")
    .replace(/^# Codex Spec(?: Run)?\r?\n+/, "")
    .replaceAll("$cda-", "/cda-")
    .replaceAll(".codex/guidelines/", ".claude/rules/")
    .replaceAll(".codex/scripts/", ".claude/scripts/")
    .replaceAll("agent: codex #", "agent: claude #")
    .replaceAll("This skill", "This command")
    .replaceAll("this skill", "this command")
    .trim();
}

const pairs = [
  [".codex/guidelines/spec-workflow.md", ".claude/rules/spec-workflow.md"],
  [".agents/skills/cda-spec/SKILL.md", ".claude/commands/cda-spec.md"],
  [".agents/skills/cda-spec-run/SKILL.md", ".claude/commands/cda-spec-run.md"],
];

// Runtime paths, command names, provenance and entrypoint headings differ;
// the complete shared contract must survive packaging in either adapter.
for (const [codexPath, claudePath] of pairs) {
  const codex = readFileSync(resolve(root, codexPath), "utf8");
  const claude = readFileSync(resolve(root, claudePath), "utf8");
  assert.equal(
    body(codex),
    body(claude),
    `Adapter contract drift: ${codexPath}`,
  );
}

// Negative controls: normalization must not hide a lost obligation or changed authority.
const original = "Read the selected contract.\n\nThe user confirms completion.";
assert.notEqual(body(original), body("The user confirms completion."));
assert.notEqual(body(original), body(original.replace("user", "runner")));
console.log(
  "Spec adapter parity: 3 complete contracts and 2 negative controls pass.",
);
