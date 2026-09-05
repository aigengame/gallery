# Verdant 0.1.1 — grass shadow continuity

This update addresses the straight shadow boundary reported in the grass view.
The player artifact is `builds/Verdant-macOS.zip`; its source commit, version,
size and content hashes are recorded in [the release audit](release-audit.json).
The [0.1.0 acceptance record](VALIDATION.md) remains historical evidence.

## Diagnosis and change

Three discontinuities overlapped:

- The two directional shadow cascades had no blending. Their resolution change
  was visible across thin blades. Blending alone softened the boundary but left
  the other shadow inconsistencies. The first split is now 0.2 (7.2 m of the
  unchanged 36 m shadow range), with split blending enabled. Atlas size, cascade
  count, grass density, and maximum shadow distance are unchanged.
- The grass shader used `CAMERA_POSITION_WORLD` for blade LOD and distance fade.
  That value comes from the current rendering view, including the light's view
  during shadow rendering. It now uses `MAIN_CAM_INV_VIEW_MATRIX[3]`, so color
  and shadow passes retain the same blades. A shader-only screenshot comparison
  changed shadow coverage while preserving the fixed terrain and blade poses.
- An 8 m grass chunk stopped casting shadows when it changed to a medium or far
  mesh. Every visible LOD now remains a caster. The light's existing distance
  fade bounds distant shadows instead of an abrupt per-chunk switch.

These are consistent with the [Godot spatial shader reference](https://docs.godotengine.org/en/4.6/tutorials/shaders/shader_reference/spatial_shader.html)
and [directional light reference](https://docs.godotengine.org/en/4.6/classes/class_directionallight3d.html).
The renderer source also maps `CAMERA_POSITION_WORLD` to the current inverse
view matrix, and explicitly keeps the main camera matrix during shadow passes.

## Regression evidence

The real-render fixture in `tests/shadow_regression.tscn` loads the production
world and shader. It fixes the camera at x=8, z=26, yaw=0, pitch=-0.22, disables
wind, and disables physical player input. It is not included in the player PCK.

```sh
gda daemon start --windowed --scene res://tests/shadow_regression.tscn --project . --json
gda screen capture --output /tmp/verdant-shadow.png --project . --json
gda game set /root/ShadowRegression --property quality --value low --project . --json
gda daemon stop --project . --json
gda script run tests/grass_geometry.gd --strict --completion-marker GRASS_VERIFICATION_COMPLETE --project . --json
```

The geometry test exercises actual chunk selection in both movement directions
at all three quality settings. Reinstating the old implementation produces
`script_failed`, engine exit 1, and `Visible LOD 2 lost its chunk shadow`.
The corrected implementation exits 0 with no diagnostics. The test uses a simple
material and cannot prove shader appearance; the rendered comparisons cover that
separate boundary. All 12 GDScripts pass static validation.

[Before, 2K](shadow-before-2k.png) · [After, 2K](shadow-after-2k.png) ·
[After, 4K](shadow-after-4k.png).

## Performance and scope

[Paired measurements](shadow-performance.json) use the same fresh fixture,
high quality, a visible 1600×900 window, actual 2560×1440 / 3840×2160 render
targets, and a 14-second settling period after each resolution change.
Each frame-time summary covers 600 wall-clock intervals; each monitor summary
covers a separate 120-frame window. Screenshots occur after measurement.
Window mode is verified as windowed, not minimized. Earlier samples taken with
an unfixed camera or a minimized window are excluded.

Keeping medium and far LOD casters increases shadow draw work. These bounded,
stationary, wind-off measurements are not a whole-route performance guarantee.
GPU timing is unavailable on this runtime; no GPU-millisecond claim is made.
Only Apple Silicon macOS is validated.

| Render target | Before p50 / p95 | After p50 / p95 | Monitor FPS, before / after |
|---|---:|---:|---:|
| 2560×1440 | 16.643 / 18.077 ms | 16.658 / 18.230 ms | 60.0 / 60.0 |
| 3840×2160 | 16.645 / 18.252 ms | 16.651 / 18.318 ms | 60.0 / 60.0 |

At the fixed high-quality view, render counters increased from 192 to 343 draw
calls and from 2,228,481 to 3,208,248 primitives. The visible grass geometry
remained identical (1,717,041 candidate triangles); the increase comes from
shadow passes and does not mean extra grass instances were added. VSync limits
these samples, so matching FPS does not establish equal GPU cost.

## Player checks

The fixture walked 24.30 m across chunks, changed yaw through three directions,
and captured a crouched view. The normal player scene separately started from
its title, walked 7.60 m with wind enabled, and captured the [player view](shadow-player-2k.png).
Both runs reported no runtime errors. [Check results](shadow-checks.json).
The independent code review found no mechanism issue; the shader appearance
claim depends on these rendered observations, not on the headless property test.

The 0.1.1 release export completed without warnings. Its 31-file PCK contains
the corrected grass shader byte-for-byte; tooling and regression scenes remain
excluded. The app passed strict signature verification and ran independently
from `/tmp` for 180 frames with engine exit 0 and no runtime errors. This is a
startup/render smoke check; the gameplay and visual comparisons above used gda.
The source commit is `12af7cc`; later evidence-only changes do not alter the player.
