# gda dogfooding

Record only observed production actions. Tool feedback stays local; no external
issue or message is sent without authorization. A workaround does not mean the
underlying tool issue is fixed.

Each entry records ID, type, tool version, operation, expected and actual result,
evidence, production impact, workaround, requested outcome, and retest status.

## GDA-DF-001 — Capture pixels and injected input use different coordinates

- Type: enhancement; observed 2026-09-05 with gda 0.14.0, Godot 4.6.3.
- Production: bilingual menu click in a 1280×720 window with a 2560×1440 UI canvas.
- Expected workflow: use a screenshot to select the language button, inject the click,
  and verify the language change.
- Observed: screenshot pixel (189,309) did not activate the button. `game rect`
  reported logical position (313,590), size (126,54); logical center (376,617)
  activated it and `game get` returned `current_locale=zh`.
- Evidence: `evidence/raw/click-chinese.json`, `click-chinese-local.json`,
  `title-v1.png`. The harness calls `Viewport.push_input(event, true)` for mouse
  input. This is a coordinate-space workflow gap, not a demonstrated contract bug.
- Impact/workaround: query Control rect and inject logical center. Screenshot-driven
  agents otherwise silently miss controls when the UI is scaled.
- Requested outcome: capture and rect receipts identify coordinate spaces and provide
  the pixel-to-input transform, or input accepts an explicit screenshot coordinate mode.
- Status: safe workaround verified; tool enhancement remains open and local.

## GDA-DF-002 — Native GPU frame-window measurements

- Type: new feature requirement; gda 0.14.0.
- Production: compare grass LOD and 2K/4K quality costs on Apple M2.
- Observed: `perf monitors --schema` exposes FPS, process time, primitives and draw
  calls, but no GPU frame time. Process time does not isolate GPU rendering cost.
- Workaround: a declared read-only World method exposes RenderingServer viewport
  timings and wall-clock frame intervals. The first local GPU timer returned zero;
  the evidence explicitly records unavailable rather than reporting zero GPU cost.
- Evidence: `.runtime/gda-schema.json` and `evidence/raw/first-frame-metrics.json`.
- Requested outcome: bounded CPU/GPU rendering samples with explicit unsupported /
  disabled states and renderer, viewport, resolution and synchronization metadata.
- Status: open; final performance claims must preserve unavailable timer evidence.

## GDA-DF-003 — Export-preset authoring

- Type: new feature requirement; gda 0.14.0.
- Production: make an independently runnable macOS player artifact.
- Observed: the command schema can list presets and run export but has no operation
  to create/configure a preset. The project must first author `export_presets.cfg`.
- Workaround: use a tracked explicit Godot config, then `gda export list` and
  `gda export run` for discovery and export. Cost: platform config syntax and
  exclusion validation remain a separate workflow.
- Requested outcome: schema-driven preset creation/update with platform-specific
  options and a preview of runtime resource inclusion.
- Status: open; no tool fix or external issue is claimed.

## Environment boundary — WindowServer permission

The sandboxed `daemon start --windowed` returned `live_windowed_permission_denied`.
The same authorized launch outside the sandbox succeeded and screen capture returned
real viewport pixels. This is environment evidence, not a gda defect. Subsequent live
operations use the authorized local execution scope.

## GDA-DF-004 — Key injection does not update polled Input state

- Type: bug / input-fidelity gap; gda 0.14.0, Godot 4.6.3, 2026-09-05.
- Production: after clicking Start, hold W for 120 physics frames using
  `gda input sequence`. The original controller polls `Input.is_physical_key_pressed`.
- Expected: the key hold advances the explorer as a physical W press does.
- Actual: sequence succeeds, but distance_walked remains 0.0 and position is unchanged.
- Evidence: `evidence/raw/walk-input-v1.json`, `walk-state-v1.json`, and the minimal
  `tests/input_boundary.gd` run in `evidence/raw/input-boundary.json`.
- Mechanism: the harness sets keycode and physical_keycode, then calls
  `Viewport.push_input`. The minimal real-engine test returns false for polled W
  after that operation and true after `Input.parse_input_event`. Delivery to
  event callbacks is not equivalent to updating the global Input singleton.
- Impact: common continuous-movement controllers can appear unresponsive during
  otherwise successful gda key sequences. UI event delivery still works.
- Workaround: use the standard InputMap actions in the product, authored with
  `gda project add-input-action`, and use `gda input action` / action sequences for
  continuous test input. Real keyboard bindings remain available to players.
- Requested outcome: key input fidelity for polling and event paths, or an explicit
  documented distinction with a supported complete-input mode and regression test.
- Status: engine mechanism reproduced; InputMap action workaround passed the complete
  live walking route in `evidence/raw/playtest/summary.json`.
  The installed tool was not patched and no external issue was posted.

Project parse errors and incorrect CLI arguments are corrected in the project
workflow and are not misclassified as tool bugs.
