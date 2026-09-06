# Gallery context map

Gallery is a collection of independent demo projects in one Git repository.
Its user-facing README showcases work built with gda and AIGen Game Agent Skills
and guides readers from product experiences to technical solutions and reuse.
The repository root owns collection navigation and shared collaboration guidance.
Each directory under `gallery/` owns a complete domain project.

## Domain projects

| Project | Root | Scope | Domain context | User guide |
|---|---|---|---|---|
| Verdant / 青野 | `gallery/verdant/` | A natural grass rendering study with a playable meadow exploration route | [CONTEXT.md](gallery/verdant/CONTEXT.md) | [README.md](gallery/verdant/README.md) |

## Working boundaries

- Select the relevant project before changing code or running project tools.
  Read its local `AGENTS.md`, domain context, and applicable architecture records.
- A demo owns its runtime, assets, tests, tools, build settings, and evidence.
  Its relative paths are resolved from that demo's root unless stated otherwise.
- Demo projects have no runtime dependencies on sibling projects or root agent files.
  Reusable code within a demo stays there until an actual shared consumer requires
  a separate package and an explicit dependency.
- Root `AGENTS.md`, `CLAUDE.md`, and `PITFALLS.md` provide shared guidance.
  Apply tool-specific advice only when the selected project uses that tool.
- `.agents/`, `.claude/`, `RULES.md`, `STATE.md`, and `skills-lock.json` are local,
  ignored working aids. A domain's optional `STATE.md` is a current work report,
  not its product contract or a requirement for running it.
- Keep evidence with its project. Link selected images from README pages; retain
  original captures, receipts, and historical validation context.
- Original code, documentation, and assets use the root [MIT License](LICENSE).
  Keep third-party licenses and notices with their components. Any license copies
  shipped with a demo are derived from the root file and must stay identical.

Add a row when another real demo is introduced. Its project guide owns its setup,
platform support, and commands; this map owns only its scope and location.
