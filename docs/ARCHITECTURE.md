# Architecture

The root `main.gd` composes World and Overlay. It is the only source that connects
Content and UI. No autoload owns game state; the installed gda harness is tooling.

| Owner | Files | Responsibility |
|---|---|---|
| Add-ons | `addons/meadow_renderer/` | Reusable chunked rendering, injected height/coverage/material |
| Systems | `systems/exploration/visit_progress.gd` | Visit identity, uniqueness, reset and completion |
| Content | `content/meadow/`, `content/explorer/` | Concrete landscape, viewpoint route, player movement, light and sound |
| UI | `ui/overlay.gd` | Bilingual menus, settings, HUD and user interaction |

Dependencies point down; instantiation is a dependency. GrassField receives callables
and a Shader from World and has no Content paths. World owns application state and
emits `state_changed` and `pause_requested`; it does not know any UI type or node.
Overlay reads public state and sends commands to World. Scene composition connects
pause signals to the Overlay. VisitProgress knows neither terrain nor UI.

The terrain's `height_at`, `coverage_at`, and `path_distance` functions are the shared
landscape authority. Ground generation, grass generation, player movement and route
placements use them. No second heightmap implementation can drift from the visible ground.

Grass is opaque geometry. Chunk AABBs include the maximum height and wind reach.
World-anchored deterministic grass generation preserves placement across quality
changes. Runtime distance selection is independent of viewport frustum culling.
Stats labelled visible in the current implementation count distance candidates;
GPU primitives and captured pixels provide actual rendered evidence.

Source procedures, generation brief and asset receipts are under `assets/` and
`tools/`. Only runtime content is exported. Test and evidence directories are not
runtime dependencies. See `tools/asset_pipeline.md` for regeneration and admission.
