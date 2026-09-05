# STATE — Verdant / 青野

- **Phase:** 0.1.1 shadow continuity fix delivered after user playtest feedback.
- **Delivered:** Continuous grass shadows across mesh LODs and directional cascades; grass fade uses the main camera in both color and shadow passes.
- **Runtime source:** `12af7cc`; later evidence-only changes do not alter the exported player.
- **Artifact:** `builds/Verdant-macOS.zip` (0.1.1); extracted app in `builds/player-0.1.1/Verdant.app`. Hash and PCK closure: `evidence/release-audit.json`.
- **Validation:** Old caster policy fails the regression with engine exit 1; fixed test exits 0 without diagnostics. All 12 scripts valid. Fixed-view A/B, three qualities, 24.30 m movement/crouch, wind-enabled player scene, independent export startup and strict signature checks passed.
- **Performance:** Visible, fixed-camera M2 comparison at high quality: both 2K/4K retain 60 FPS; new frame p95 18.23/18.318 ms. Draw calls increase 192→343 because more grass casts shadows. GPU timer unavailable; see `evidence/SHADOW_FIX.md` for bounds.
- **Experience:** Lock fixture input; verify window mode before sampling. Minimized-window and moving-camera counters are unsuitable for paired benchmarks. Headless node checks do not validate shader appearance.
- **History:** Original seven-item production goal and bilingual 2K/4K player remain delivered. 0.1.0 ZIP retained as `builds/Verdant-macOS-0.1.0.zip`; its original acceptance and audit remain separate.
- **Git:** Source and LFS evidence committed locally; no remote or push.
- **Next up:** Further user playtest feedback and optional hardware coverage. No required work remains for this shadow report.

_Updated: 2026-09-05_
