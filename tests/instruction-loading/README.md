# Instruction loading fixtures

Run `npm run test:instruction-loading` (also included in `npm run check`). Node's standard library and the installer's existing Bash/tar prerequisites are sufficient; this adds no downstream runtime dependency.

The test stages only the installable layer directories in a temporary archive, substitutes an offline `curl` fixture, and runs the actual installer in Claude, Codex, and combined modes. It checks loader placement, relative import resolution, conditional reference copies and links, and the absence of universal path globs on conditional Claude workflows. A negative fixture demonstrates that repeating the `.claude/` prefix breaks a relative import.

These checks validate the shipped files and installer output. They do not run a model, emulate the full Claude Markdown parser, measure token usage, or establish model behavior or quality improvements.
