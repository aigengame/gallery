# Gallery directory migration validation

Validated on 2026-09-05 with Godot 4.6.3, gda 0.14.0, and Apple M2 macOS.
The tested tree was uncommitted, based on `f2f3b70`. This record describes the
directory migration, not a new player release or a new performance benchmark.

## Scope and preservation

Verdant now owns `gallery/verdant/` as its Godot project root. Its runtime,
resources, tools, tests, build settings, and evidence moved together. The
repository root owns collection navigation and shared contributor guidance.

All 214 pre-move files were found at their new locations. Runtime files, assets,
import sidecars, tools, tests, historical evidence, and local builds kept their
SHA-256 hashes. The domain context and project README were updated for the new
layout; the ignored local state report was updated after validation. The
[pre-move manifest](raw/migration/pre-move-manifest.json) and
[preservation result](raw/migration/preservation.json) record the comparison.

All evidence, including `evidence/raw/`, remains eligible for Git tracking.
Binary assets and screenshots retain their Git LFS attributes. Engine caches,
build outputs, local agent directories, rules, state, and skill locks remain
ignored. `PITFALLS.md` stays at the repository root and remains tracked.

## Checks at the new project root

| Check | Result | Record |
|---|---|---|
| Asset provenance verification and clean resource import | Passed; four requested assets imported, no source sidecars created | Existing asset receipt and gda import result |
| Script validation | All 12 scripts valid | [Scripts](raw/migration/scripts.json) |
| Geometry and exploration tests | Strict engine exit 0, no diagnostics | [Geometry](raw/migration/geometry.json), [exploration](raw/migration/exploration.json) |
| Windowed gda player route | Language switching, movement, pause, three viewpoints, continuation, and restart passed; no runtime errors | [Summary](raw/migration/playtest/summary.json), [operations](raw/migration/playtest/operations.json) |
| macOS release export | Passed with no export warnings | [Export](raw/migration/export.json) |
| Exported PCK audit | 31 files; content hashes and font license verified; tooling and evidence excluded | [Audit](raw/migration/export-audit.json) |

The export check wrote `builds/migration-check/Verdant-macOS.zip`. The existing
0.1.1 player ZIP was preserved. The windowed validation session was stopped after
the checks. No commit, push, or publication was performed as part of this run.

`git diff --check` reports two pre-existing trailing spaces in the newly tracked
`raw/player-console.log` and `raw/player-runtime.log` (the `Project FPS:` lines).
Those original logs remain byte-for-byte intact. The check passes with those two
logs excluded; this exception does not apply to source or documentation.

![Player after the migrated route and restart](raw/migration/playtest/after-restart.png)
