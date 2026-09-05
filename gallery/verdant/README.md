# Verdant / 青野

A small, finished green meadow study for desktop playtesting. Walk through curved
blades, crouch near rooted wind, and follow three viewpoints. English and Simplified
Chinese menus support real 2560×1440 and 3840×2160 rendering.

## Play

The local player build is `builds/Verdant-macOS.zip`. Extract and open `Verdant.app`.
The [player guide](distribution/README.txt) contains both languages and controls.
No Godot editor or gda is required to play. The universal macOS build is locally
signed; it is not notarized or published. Other platforms are not validated.

## Develop

Use Godot 4.6.3, gda 0.14.0, Python 3.9+ and Git LFS. Run `git lfs pull` after
cloning if binary assets are still LFS pointers. All commands below run from this
project directory. From the repository root, enter it first:

```sh
cd gallery/verdant
```

```sh
python3 tools/assets.py --verify
gda resource import content/icon.svg content/audio/meadow_ambience.wav content/audio/grass_footstep.wav 'content/fonts/NotoSansSC[wght].ttf' --project .
gda script validate --all --project . --json
gda daemon start --windowed --project . --json
python3 tools/playtest.py
gda daemon stop --project . --json
```

A windowed gda session needs normal desktop/WindowServer access. A headless test
is not proof of rendered playability. The route runner must start at the title.

## Build

Install the official Godot 4.6.3 export templates, then:

```sh
gda export run --preset macOS --mode release --output builds/Verdant-macOS.zip --project . --json
python3 tools/package_release.py
```

The packaging step includes offline player instructions and licenses and audits
the actual PCK directory. Source, harness, tests, prompts and evidence are excluded
from the player. Exported builds stay local and are not committed.

## Production records

- [Gallery context map](../../CONTEXT-MAP.md)
- [Product contract](CONTEXT.md) and [module ownership](docs/ARCHITECTURE.md)
- [Asset pipeline](tools/asset_pipeline.md), [prompt](assets/prompts/meadow-v1.md)
  and [provenance receipt](assets/receipts/meadow-assets.json)
- [gda dogfooding](docs/DOGFOODING.md)
- [Gallery migration validation](evidence/MIGRATION.md)
- [Current shadow fix and performance](evidence/SHADOW_FIX.md)
- [Original 0.1.0 validation](evidence/VALIDATION.md)

Evidence includes the original files in `evidence/raw/`. Historical receipts may
name the workspace location used before the move into Gallery; those paths and
commit references are preserved as recorded. Current project-relative paths are
resolved from this directory.

The geometry renderer uses 256 spatial MultiMesh chunks, deterministic clumps,
three mesh details, smooth density reduction and opaque grass. Reported renderer
candidate counts are distinct from actual GPU primitive counters. GPU timings are
not claimed when the engine's timer is unavailable.

## License

Verdant's original code, documentation, and assets use Gallery's
[MIT License](../../LICENSE). The packaging step adds an identical copy as
`licenses/VERDANT-LICENSE.txt`, sourced from
[the distribution copy](distribution/licenses/VERDANT-LICENSE.txt).

Third-party components retain their original terms: [Noto Sans SC](content/fonts/OFL.txt)
uses SIL OFL 1.1, and [Godot](distribution/licenses/GODOT-LICENSE.txt) uses MIT
with additional [third-party notices](distribution/licenses/GODOT-COPYRIGHT.txt).
