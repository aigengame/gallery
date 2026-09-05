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

Use Godot 4.6.3, gda 0.14.0, Python 3.9+ and Git LFS. Run `git lfs pull` when
cloning from a location that has the LFS objects. This repository currently has no
remote. Binary assets are stored as LFS pointers in Git and exist locally.

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

- [Product contract](CONTEXT.md) and [module ownership](docs/ARCHITECTURE.md)
- [Asset pipeline](tools/asset_pipeline.md), [prompt](assets/prompts/meadow-v1.md)
  and [provenance receipt](assets/receipts/meadow-assets.json)
- [gda dogfooding](docs/DOGFOODING.md)
- [Current shadow fix and performance](evidence/SHADOW_FIX.md)
- [Original 0.1.0 validation](evidence/VALIDATION.md)

The geometry renderer uses 256 spatial MultiMesh chunks, deterministic clumps,
three mesh details, smooth density reduction and opaque grass. Reported renderer
candidate counts are distinct from actual GPU primitive counters. GPU timings are
not claimed when the engine's timer is unavailable.
