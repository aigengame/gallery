# Verdant 0.1.0 acceptance — 2026-09-05

Historical record: the current shadow fix is documented in [0.1.1 validation](SHADOW_FIX.md).

The local macOS player build is accepted for the seven-item production goal.
Runtime source: `12700686e6ab3f15018e4c36e52f9de8b62adf2b`.
The later evidence-only commit does not change the player.

## Player artifact

- File: `builds/Verdant-macOS-0.1.0.zip`, 76,507,001 bytes.
- SHA-256: `f260c8cb8551d2a1fa4aec408c4d47c1936efb121a317053ee451d297f05c915`.
- gda release export: success, no export warnings. Godot 4.6.3.
- Universal executable: x86_64 + arm64; tested on Apple M2, 8 GPU cores.
- `codesign --verify --deep --strict`: passed. Local ad-hoc signature, no notarization.
- PCK directory: 31 files, every entry's stored content hash verified. Font, audio,
  shaders and compiled application scripts present. OFL matches source exactly.
  gda harness, tests, tools, evidence and prompts are absent.
- Offline bilingual player guide, font license, Godot MIT license and third-party
  copyright notices are included in the ZIP. [Machine-readable audit](release-audit-0.1.0.json).

The actual exported executable was launched from an empty directory outside the
project, with the gda daemon stopped. Its title was `Verdant`, not a debug editor
window. Both languages, controls, 4K selection, fullscreen, grass quality, wind
selection, volume, start and Escape pause were observed through native UI automation.
A fresh windowed run resumed exploration and quit through the player menu with
exit code 0. Neither export session logged an application error.
See [player smoke evidence](player-smoke.json) for exact observations and boundaries.

## Gameplay and display

`tools/playtest.py` passed on the final runtime source at 2560×1440: both language
buttons, Start, sustained movement, paused movement freeze, Resume, three viewpoints
reached by walking and recorded with E, completion/continue, and restart/reset.
It issued 63 gda operations. [Route result](route-validation.json).

Additional real-engine input checks changed camera yaw from -1.3916 to -1.4796
through a mouse motion event, lowered the eye to 0.48049 m while crouched, and
observed 0.7375 m jump height. No runtime errors were reported. The 4K close view
uses the actual viewport image (3840×2160), with a camera placement fixture;
it is not an upscaled screenshot. Menu-driven 4K selection was separately checked
in the exported application. The UI keeps its size and placement in both targets.

[English 2K](title-en-2k.png) · [Chinese 2K](title-zh-2k.png) ·
[Viewpoint 2K](viewpoint-1-2k.png) · [Grass close view 4K](close-4k.png).

Script validation: all 11 scripts valid. Exploration and geometry checks: engine
exit 0, no diagnostics. Geometry checks cover winding, roots, shared LOD blades,
hysteresis, deterministic placement, quality ordering and distant culling.
The asset verifier passed prompt/generator/output hashes, license and PCM QA.
Git LFS fsck passed for the locally stored binary assets.

## Measured performance

Apple M2, Metal Mobile renderer, FXAA, no MSAA, VSync enabled. Same stationary
starting view, high grass quality, final 2K/4K CanvasLayer scaling. 600 wall-clock frame intervals per target;
a separate 60-frame Godot monitor window supplies the FPS values.

| Actual render target | Frame p50 | Frame p95 | Monitor FPS mean |
|---|---:|---:|---:|
| 2560×1440 | 16.699 ms | 18.465 ms | 60.0 |
| 3840×2160 | 16.697 ms | 18.295 ms | 60.0 |

[Raw statistic summaries](performance.json) include draw-call and primitive counts.
These are bounded, stationary, windowed measurements, not route-wide or universal
FPS guarantees. An earlier 4K window measured 54.9 FPS; samples vary with load. Fullscreen automation and active captures produced variable FPS;
those mixed samples are not substituted for a controlled benchmark. Start with 2K
on this Mac. Lower quality reduces detail and density; 4K needs more GPU capacity.
GPU timers returned unavailable, so no GPU millisecond claim is made. The Mobile
plus FXAA configuration was chosen after Forward+ with 4× MSAA proved expensive at 4K.

## Production closure and limits

The four-layer architecture is recorded in `docs/ARCHITECTURE.md`. The committed
prompt predates generation; `tools/assets.py` and its receipt provide deterministic
preprocessing, generation, admission and postprocessing. Four concrete gda feedback
items remain recorded locally in `docs/DOGFOODING.md`. No external issues were sent.
Source and binary assets are committed locally; no remote or push exists.

Acceptance is automated and agent-reviewed. It is not a human playtest or subjective
audio listening pass. The complete native keyboard/mouse route was not repeated in
the export; the same runtime passed it through gda, and the independent export passed
startup/UI smoke. Only Apple Silicon macOS was run. Other machines and operating
systems have no performance or compatibility claim.
