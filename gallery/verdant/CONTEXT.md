# Verdant / 青野

A quiet, player-facing meadow exploration demo made with Godot 4.6 and gda.
The player walks through natural green grass, inspects moving blades at close
range, and visits three viewpoints. English and Simplified Chinese are equally
supported. The target desktop resolutions are 2560×1440 and 3840×2160.

## Product contract

- A Godot-exported macOS player build must start independently of the editor and gda.
- A free camera supports walking, looking, sprinting, and close inspection.
- Finished natural green grass uses geometry, chunked MultiMesh rendering, distance
  detail, rooted wind, terrain coverage, and matching distant color.
- Players can change language, resolution, quality, and wind, pause, resume, restart,
  and complete a short exploration route. UI scales to both target resolutions.
- Author and validate with gda. Record observed tool feedback in docs/DOGFOODING.md.
- Keep source, asset prompts, pipeline, and evidence, including original captures
  and receipts. Binary assets and screenshots use Git LFS.

This directory is an independent project within Gallery. See the repository
[context map](../../CONTEXT-MAP.md) for collection boundaries. The user's current
instructions govern commits, pushes, and release publication.

## Architecture

`addons/` owns reusable technical rendering. `systems/` owns reusable visit progress.
`content/` owns the terrain, meadow, explorer, lighting, and concrete art.
`ui/` owns bilingual presentation and player controls. The root bootstrap composes
content and UI. Dependencies point down: UI → Content → Systems → Add-ons → Godot.
Lower layers never load UI. Application operations and signals connect the layers.

## Vocabulary

- Blade: a tapered, curved ribbon of grass geometry.
- Clump: several differently oriented blades in one instanced mesh.
- Chunk: a bounded patch whose grass is culled and assigned detail together.
- Viewpoint: one of three authored places the player can discover.
- Quality: a preset for detail distances and instance density, not a promise of FPS.
