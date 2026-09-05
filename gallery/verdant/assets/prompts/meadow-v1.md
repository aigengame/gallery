# meadow-v1 — procedural production brief

Purpose: runtime meadow assets for Verdant / 青野, a natural green grass exploration demo.
Generator family: deterministic procedural Godot geometry/shaders and seeded Python audio.
Reference: user-approved brief in CONTEXT.md, no third-party artwork input.

Exact brief:

Create a calm, sunlit green meadow with tapering curved grass blades, dark emerald
roots, varied leaf greens and gentle yellow-green tips. Preserve actual silhouettes
and rooted motion when seen close from any direction. Use broad coherent wind and
subtle per-clump variation. Ground and distant grass share the same color family.
Terrain rises in soft hills with a narrow worn path and three unobtrusive viewpoints.
Use restrained natural rocks and sparse flowers for scale. Avoid brown line art,
cream blockout fills, plastic gloss, flat grass walls, checkerboard placement,
billboards facing the camera in the near field, and unrelated gameplay clutter.
Ambient sound is a quiet seamless wind bed with sparse original synthesized birds;
no speech, music, copyrighted recordings, or sudden loud events.

Preprocess: normalize blade roots to y=0, length to y=1, encode root-to-tip in UV.y,
use stable world positions and fixed generation seeds. Keep all materials opaque.
Postprocess: assign normals/indices, bound wind displacement, verify geometry and
audio ranges, hash generated outputs, import through gda, inspect rendered results.
Admission: geometric and acoustic checks plus actual player-camera inspection.
Any changed generator or output creates a new candidate and requires revalidation.
