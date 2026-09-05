# Verdant contributor context

Follow the repository [agent guidance](../../AGENTS.md). Read [CONTEXT.md](CONTEXT.md)
for the product contract and [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for module
ownership. Read local `STATE.md` if present and the repository's
[PITFALLS.md](../../PITFALLS.md) when its tool guidance applies.

This directory is the Godot project root. `res://` paths and commands in the
[project guide](README.md) are relative to it. From the repository root, pass
`--project gallery/verdant` to gda, or change into this directory first.

Use gda for engine validation and live interaction. Inspect structured results:
an exit code alone does not prove that script validation or diagnostics passed.
Keep runtime code independent of `tools/`, `tests/`, and `evidence/`.
