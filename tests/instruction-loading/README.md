# Instruction loading fixtures

Run `npm run test:instruction-loading` (also included in `npm run check`). Node's standard library and the installer's existing Bash/tar prerequisites are sufficient; this adds no downstream runtime dependency.

The test stages the core runtime directories and Project Docs module in a temporary archive, substitutes an offline `curl` fixture, and runs the actual installer in Claude, Codex, and combined modes. It checks loader placement, relative import resolution, conditional reference copies and links, and the absence of universal path globs on conditional Claude workflows. A negative fixture demonstrates that repeating the `.claude/` prefix breaks a relative import.

Project Docs cases cover core-only installs, opt-in installs with both flag orders, the default Claude runtime, intact module resources, and no unconditional loader expansion. An existing-project fixture checks additive preservation of custom commands, skills, knowledge, current docs, and supported-version docs; a core-only forced refresh must leave the optional module and retired discovery customizations alone. Forcing the module refresh affects only the selected runtime. A source archive missing the selected module fails before copying files. Installation never authors or migrates project docs.

These checks validate the shipped files and installer output. They do not run a model, emulate the full Claude Markdown parser, measure token usage, or establish model behavior or quality improvements. Lifecycle decisions such as identifying the right owner, distinguishing approved intent from implementation, or choosing what to retire require semantic source review; the preservation fixture does not simulate those decisions.
