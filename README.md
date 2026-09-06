# AIGen Game Gallery: Playable Godot Demos Developed with AI Agents

**Playable Godot demos developed and verified with AI agents using gda and
AIGen Game Agent Skills.**

Explore playable projects, source code, architecture, and recorded runtime
evidence. Each demo states how to run it, where its evidence was captured, and
whether a downloadable build is available.

**[Explore demos](#projects) · [Get gda](https://github.com/aigengame/godot-agent#installation) · [Explore skills](https://github.com/aigengame/skills#find-the-right-skill)**

![Verdant grass and continuous shadows](gallery/verdant/evidence/shadow-after-2k.png)

*Verdant / 青野 — a playable meadow with natural green grass. See the
[shadow continuity study](gallery/verdant/evidence/SHADOW_FIX.md) for the rendering
decisions, visual comparisons, and measured tradeoffs.*

<table>
  <tr>
    <td width="50%">
      <a href="gallery/verdant/evidence/raw/shadow-fix/movement/crouch.png"><img src="gallery/verdant/evidence/raw/shadow-fix/movement/crouch.png" alt="Close view of curved grass blades, fixed roots, and ground shadows in Verdant" width="100%"></a>
      <strong>Grass up close</strong><br>Curved blades, fixed roots, and ground shadows.
    </td>
    <td width="50%">
      <a href="gallery/verdant/evidence/raw/migration/playtest/after-restart.png"><img src="gallery/verdant/evidence/raw/migration/playtest/after-restart.png" alt="Wide view along a meadow path toward distant hills in Verdant" width="100%"></a>
      <strong>Across the meadow</strong><br>Walking paths, dense grass, and distant hills.
    </td>
  </tr>
  <tr>
    <td width="50%">
      <a href="gallery/verdant/evidence/title-zh-2k.png"><img src="gallery/verdant/evidence/title-zh-2k.png" alt="Verdant main menu in Simplified Chinese, with language selection and exploration controls" width="100%"></a>
      <strong>Chinese main menu</strong><br>Switch language, start exploring, or open the controls.
    </td>
    <td width="50%">
      <a href="gallery/verdant/evidence/raw/display/final-settings-4k.png"><img src="gallery/verdant/evidence/raw/display/final-settings-4k.png" alt="Verdant settings menu in English showing 4K resolution, grass quality, wind, and volume" width="100%"></a>
      <strong>English settings menu</strong><br>Adjust resolution, grass quality, wind, and volume.
    </td>
  </tr>
</table>

Select an image to open the original capture. These views come from recorded
gameplay and rendering checks in the demo's [evidence directory](gallery/verdant/evidence/).

## Projects

Here, *playable* means that each project can be built and run from source using
its guide. Downloadable builds are listed separately when available.

| Demo | Product experience | Technical highlights | Evidence captured on | Explore |
|---|---|---|---|---|
| **Verdant / 青野** | Natural green grass; free exploration and close inspection; three viewpoints; English and Simplified Chinese menus. | Chunked MultiMesh rendering with distance LOD; continuous shadows across LODs and shadow cascades; wind with fixed blade roots. | Apple Silicon macOS; 2K / 4K rendering | [Guide](gallery/verdant/README.md) · [Architecture](gallery/verdant/docs/ARCHITECTURE.md) · [Evidence](gallery/verdant/evidence/SHADOW_FIX.md) |

## How these demos are built and verified

**[gda — Godot Automation for AI Agents](https://github.com/aigengame/godot-agent)**
provides the Godot automation and structured results used to build and verify
each demo, including runtime evidence from the running game.

**[AIGen Game Agent Skills](https://github.com/aigengame/skills)** provide reusable
development and review methods. Each project's records show how agents applied
those methods alongside gda.

## Explore and reuse

Each demo keeps its source, assets, tools, tests, and evidence together under
`gallery/`. Start with the part you want to learn or adapt:

1. **Explore the product.** Open its guide for the player experience, supported
   platform, and run or build instructions. Verdant currently provides source and
   build instructions; a player download has not been published.
2. **Study the solution.** Follow the architecture and evidence links for module
   responsibilities, technical tradeoffs, and the conditions behind measurements.
3. **Trace the implementation.** Read the relevant source, its dependencies, and
   its tests together. Verdant's [grass renderer](gallery/verdant/addons/meadow_renderer/)
   accepts terrain height, coverage, and shader inputs from the surrounding
   project; its [geometry checks](gallery/verdant/tests/grass_geometry.gd) show
   how placement, detail levels, and shadow casting at each level are verified.

The [asset pipeline](gallery/verdant/tools/asset_pipeline.md) records how Verdant's
assets are produced and checked. The [gda production notes](gallery/verdant/docs/DOGFOODING.md)
and [live route record](gallery/verdant/evidence/route-validation.json) connect
tool use to observed behavior. Each demo retains original evidence and
third-party notices alongside its source.

Binary assets and screenshots use Git LFS. Install Git LFS before cloning, or run
`git lfs pull` in an existing clone. Open the selected demo's `project.godot`
and run its documented commands from that demo's directory. The repository root
owns the collection; local build outputs and engine caches are ignored.

See the [context map](CONTEXT-MAP.md) for project boundaries and contributor entry points.

## License

Gallery's original code, documentation, and assets are available under the
[MIT License](LICENSE). Third-party components retain their own licenses and
notices; see each demo's guide. Verdant includes
[Noto Sans SC under SIL OFL 1.1](gallery/verdant/content/fonts/OFL.txt) and the
[Godot notices](gallery/verdant/distribution/licenses/).
