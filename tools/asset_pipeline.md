# Verdant asset pipeline

`tools/assets.py` owns Verdant's small reproducible asset set. It uses only the
Python standard library and does not require an audio workstation or an image
generator.

## Asset ownership

- `content/audio/meadow_ambience.wav` is a 24-second, seamless stereo wind bed
  with three sparse synthesized bird calls.
- `content/audio/grass_footstep.wav` is a short, gentle synthesized grass rustle.
- `content/icon.svg` is original vector artwork generated from a fixed SVG recipe.
- `content/fonts/NotoSansSC[wght].ttf` is an unmodified Noto Sans SC variable
  font from the official Google Fonts repository. It covers Simplified Chinese
  and Latin. `content/fonts/OFL.txt` is its SIL Open Font License 1.1.
- `assets/receipts/meadow-assets.json` records the prompt, generator, seeds,
  upstream revision, source URLs, file hashes, durations, channel layout, peak,
  RMS, DC offset, and ambience loop-boundary QA.

Reusable grass geometry and shader generation belong to
`addons/meadow_renderer`. Their generator must normalize blade roots to `y=0`,
blade length to `y=1`, and encode root-to-tip position in `UV.y`, as required by
`assets/prompts/meadow-v1.md`. This audio/font/icon pipeline does not write that
add-on or Godot project settings.

## Generate and verify

Run from the repository root with Python 3.9 or newer:

```sh
python3 tools/assets.py --generate
python3 tools/assets.py --verify
```

Generation rewrites the procedural audio and icon deterministically. It downloads
the font and license only when they are absent, then checks both against pinned
SHA-256 values before admitting them. It refuses to replace an existing font file
whose hash differs. Verification is offline and read-only. It fails when an input,
generator, output, license, or recorded QA value has drifted.

The WAV files use stereo 16-bit PCM at 22,050 Hz. The verifier rejects peaks over
0.25 full scale, excessive DC offset, an ambience loop seam over 0.025 full scale,
or a channel/sample-rate mismatch. These checks catch technical faults; listen in
the exported player to accept balance, repetition, and spatial fit.

## Prompt and candidate lifecycle

`assets/prompts/meadow-v1.md` is the authority for this candidate. Commit a new or
changed prompt before any external generation call. Keep the old prompt and receipt
when an earlier candidate must remain reproducible. After changing the prompt,
generator, seed, pinned font revision, or output recipe, run `--generate`, inspect
the receipt diff, import through gda, and validate the result in the player camera.

Binary WAV and TTF files match repository Git LFS rules. Confirm before staging:

```sh
git check-attr filter -- content/audio/*.wav 'content/fonts/*.ttf'
git lfs ls-files
```

The first command must report `filter: lfs`. The second command lists the files
after they are staged or committed.

## Font attribution

Noto Sans SC copyright: 2014-2021 Adobe, with Reserved Font Name `Source`.
The unmodified font is redistributed under SIL Open Font License 1.1. The pinned
official source URLs and their exact SHA-256 values are in the receipt. Keep
`content/fonts/OFL.txt` with every distributed copy of the font.
