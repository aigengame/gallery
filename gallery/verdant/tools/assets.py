#!/usr/bin/env python3
"""Generate and verify Verdant's small reproducible asset set.

The generator uses only the Python standard library. It creates original PCM WAV
audio and an SVG icon. It also fetches one immutable, openly licensed font input.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import random
import struct
import sys
import urllib.request
import wave
from array import array
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
SCRIPT_PATH = ROOT / "tools/assets.py"
PROMPT_PATH = ROOT / "assets/prompts/meadow-v1.md"
RECEIPT_PATH = ROOT / "assets/receipts/meadow-assets.json"

SAMPLE_RATE = 22_050
AMBIENCE_SECONDS = 24
AMBIENCE_SEED = 0x56455244
FOOTSTEP_SEED = 0x47524153

FONT_REVISION = "a85815a42757630ce188fdad368c2dfc444d4773"
FONT_NAME = "NotoSansSC[wght].ttf"
FONT_PATH = ROOT / "content/fonts" / FONT_NAME
FONT_LICENSE_PATH = ROOT / "content/fonts/OFL.txt"
FONT_URL = (
    "https://raw.githubusercontent.com/google/fonts/"
    f"{FONT_REVISION}/ofl/notosanssc/NotoSansSC%5Bwght%5D.ttf"
)
FONT_LICENSE_URL = (
    "https://raw.githubusercontent.com/google/fonts/"
    f"{FONT_REVISION}/ofl/notosanssc/OFL.txt"
)
FONT_SHA256 = "a3041811a78c361b1de50f953c805e0244951c21c5bd412f7232ef0d899af0da"
FONT_LICENSE_SHA256 = "1c05c68c34f9708415aada51f17e1b0092d2cea709bf4a94cd38114f9e73d7d9"

AMBIENCE_PATH = ROOT / "content/audio/meadow_ambience.wav"
FOOTSTEP_PATH = ROOT / "content/audio/grass_footstep.wav"
ICON_PATH = ROOT / "content/icon.svg"

GENERATOR_ID = "verdant-procedural-assets"
GENERATOR_VERSION = 1


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def project_path(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def periodic_lowpass(seed: int, frame_count: int, cutoff_hz: float) -> array:
    """Return deterministic filtered noise whose filter state closes at the loop."""
    rng = random.Random(seed)
    source = array("f", (rng.uniform(-1.0, 1.0) for _ in range(frame_count)))
    coefficient = math.exp(-2.0 * math.pi * cutoff_hz / SAMPLE_RATE)
    feed = 1.0 - coefficient

    zero_start_end = 0.0
    for value in source:
        zero_start_end = coefficient * zero_start_end + feed * value
    previous = zero_start_end / (1.0 - coefficient**frame_count)

    result = array("f")
    append = result.append
    for value in source:
        previous = coefficient * previous + feed * value
        append(previous)
    return result


def remove_dc(samples: array) -> None:
    mean = math.fsum(samples) / len(samples)
    for index in range(len(samples)):
        samples[index] -= mean


def add_bird(
    left: array,
    right: array,
    start_seconds: float,
    duration_seconds: float,
    base_hz: float,
    rise_hz: float,
    pan: float,
    amplitude: float,
) -> None:
    start = round(start_seconds * SAMPLE_RATE)
    count = round(duration_seconds * SAMPLE_RATE)
    phase = 0.0
    left_gain = math.sqrt((1.0 - pan) * 0.5)
    right_gain = math.sqrt((1.0 + pan) * 0.5)
    for offset in range(count):
        position = offset / count
        trill = 55.0 * math.sin(2.0 * math.pi * 7.0 * position)
        frequency = base_hz + rise_hz * math.sin(math.pi * position) + trill
        phase += 2.0 * math.pi * frequency / SAMPLE_RATE
        envelope = math.sin(math.pi * position) ** 2
        tone = (math.sin(phase) + 0.22 * math.sin(2.0 * phase)) * envelope * amplitude
        index = start + offset
        left[index] += tone * left_gain
        right[index] += tone * right_gain


def normalized_pcm(left: array, right: array, target_peak: float) -> bytes:
    peak = max(max(abs(value) for value in left), max(abs(value) for value in right))
    scale = target_peak / peak
    frames = bytearray(len(left) * 4)
    for index, (left_value, right_value) in enumerate(zip(left, right)):
        left_pcm = round(max(-1.0, min(1.0, left_value * scale)) * 32767.0)
        right_pcm = round(max(-1.0, min(1.0, right_value * scale)) * 32767.0)
        struct.pack_into("<hh", frames, index * 4, left_pcm, right_pcm)
    return bytes(frames)


def write_wav(path: Path, frames: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as target:
        target.setnchannels(2)
        target.setsampwidth(2)
        target.setframerate(SAMPLE_RATE)
        target.writeframes(frames)


def generate_ambience() -> None:
    frame_count = SAMPLE_RATE * AMBIENCE_SECONDS
    shared = periodic_lowpass(AMBIENCE_SEED, frame_count, 620.0)
    left_detail = periodic_lowpass(AMBIENCE_SEED + 1, frame_count, 980.0)
    right_detail = periodic_lowpass(AMBIENCE_SEED + 2, frame_count, 980.0)
    gust = periodic_lowpass(AMBIENCE_SEED + 3, frame_count, 5.0)

    left = array("f", [0.0]) * frame_count
    right = array("f", [0.0]) * frame_count
    for index in range(frame_count):
        position = index / frame_count
        slow = 0.78 + 0.13 * math.sin(2.0 * math.pi * 3.0 * position + 0.4)
        slow += 0.07 * math.sin(2.0 * math.pi * 7.0 * position + 2.1)
        breath = max(0.45, slow + gust[index] * 2.2)
        left[index] = (shared[index] * 0.84 + left_detail[index] * 0.30) * breath
        right[index] = (shared[index] * 0.84 + right_detail[index] * 0.30) * breath

    add_bird(left, right, 4.1, 0.72, 1_520.0, 520.0, -0.52, 0.085)
    add_bird(left, right, 11.8, 0.58, 1_830.0, 410.0, 0.43, 0.065)
    add_bird(left, right, 19.3, 0.83, 1_420.0, 620.0, 0.18, 0.075)
    remove_dc(left)
    remove_dc(right)
    write_wav(AMBIENCE_PATH, normalized_pcm(left, right, 0.20))


def generate_footstep() -> None:
    frame_count = round(SAMPLE_RATE * 1.08)
    left_noise = periodic_lowpass(FOOTSTEP_SEED, frame_count, 2_100.0)
    right_noise = periodic_lowpass(FOOTSTEP_SEED + 1, frame_count, 2_100.0)
    left = array("f", [0.0]) * frame_count
    right = array("f", [0.0]) * frame_count
    bursts = ((0.08, 0.27, 1.0), (0.31, 0.38, 0.58), (0.57, 0.34, 0.30))
    for index in range(frame_count):
        time_seconds = index / SAMPLE_RATE
        envelope = 0.0
        for start, duration, strength in bursts:
            if start <= time_seconds < start + duration:
                position = (time_seconds - start) / duration
                envelope += math.sin(math.pi * position) ** 2 * strength
        low_body = math.sin(2.0 * math.pi * 92.0 * time_seconds) * math.exp(-8.0 * time_seconds)
        left[index] = left_noise[index] * envelope + low_body * 0.06
        right[index] = right_noise[index] * envelope + low_body * 0.055
    remove_dc(left)
    remove_dc(right)
    write_wav(FOOTSTEP_PATH, normalized_pcm(left, right, 0.24))


def icon_svg() -> bytes:
    svg = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" role="img" aria-labelledby="title desc">
  <title id="title">Verdant meadow</title>
  <desc id="desc">Three green meadow leaves above a softly curved hill.</desc>
  <defs>
    <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#dff4d2"/>
      <stop offset="1" stop-color="#9fd58f"/>
    </linearGradient>
    <linearGradient id="leaf" x1="0" y1="1" x2="0.7" y2="0">
      <stop offset="0" stop-color="#155b3b"/>
      <stop offset="0.62" stop-color="#3f9551"/>
      <stop offset="1" stop-color="#9bcf62"/>
    </linearGradient>
  </defs>
  <rect width="512" height="512" rx="112" fill="url(#sky)"/>
  <path d="M0 374C95 326 165 351 235 372C330 401 407 347 512 316V512H0Z" fill="#236c43"/>
  <path d="M0 414C110 373 189 411 273 420C359 429 425 399 512 368V512H0Z" fill="#174f38" opacity="0.9"/>
  <path d="M255 392C237 315 239 217 277 116C309 204 298 306 255 392Z" fill="url(#leaf)"/>
  <path d="M244 394C200 335 168 264 169 180C224 235 250 309 244 394Z" fill="url(#leaf)" opacity="0.94"/>
  <path d="M267 393C295 333 337 282 397 249C374 320 327 369 267 393Z" fill="url(#leaf)" opacity="0.9"/>
  <path d="M255 392C255 298 263 211 277 116" fill="none" stroke="#d3e77b" stroke-width="6" stroke-linecap="round" opacity="0.72"/>
</svg>
"""
    return svg.encode("utf-8")


def fetch_checked(url: str, destination: Path, expected_sha256: str) -> None:
    if destination.exists():
        actual = sha256_file(destination)
        if actual != expected_sha256:
            raise RuntimeError(
                f"refusing to replace {project_path(destination)}: expected {expected_sha256}, got {actual}"
            )
        return
    request = urllib.request.Request(url, headers={"User-Agent": GENERATOR_ID})
    with urllib.request.urlopen(request, timeout=90) as response:
        payload = response.read()
    actual = sha256_bytes(payload)
    if actual != expected_sha256:
        raise RuntimeError(f"download hash mismatch for {url}: expected {expected_sha256}, got {actual}")
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(payload)


def wav_qa(path: Path) -> dict[str, Any]:
    with wave.open(str(path), "rb") as source:
        channels = source.getnchannels()
        sample_width = source.getsampwidth()
        frame_rate = source.getframerate()
        frame_count = source.getnframes()
        raw = source.readframes(frame_count)
    if channels != 2 or sample_width != 2:
        raise RuntimeError(f"{project_path(path)} must be stereo 16-bit PCM")
    values = struct.unpack(f"<{len(raw) // 2}h", raw)
    left = values[0::2]
    right = values[1::2]
    peak = max(abs(value) for value in values) / 32768.0
    rms = math.sqrt(math.fsum(value * value for value in values) / len(values)) / 32768.0
    left_dc = math.fsum(left) / len(left) / 32768.0
    right_dc = math.fsum(right) / len(right) / 32768.0
    seam_delta = max(abs(left[-1] - left[0]), abs(right[-1] - right[0])) / 32768.0
    return {
        "channels": channels,
        "sample_width_bits": sample_width * 8,
        "sample_rate_hz": frame_rate,
        "frame_count": frame_count,
        "duration_seconds": round(frame_count / frame_rate, 6),
        "peak": round(peak, 6),
        "rms": round(rms, 6),
        "dc_offset_max": round(max(abs(left_dc), abs(right_dc)), 8),
        "loop_seam_delta": round(seam_delta, 6),
    }


def file_record(path: Path) -> dict[str, Any]:
    return {
        "path": project_path(path),
        "bytes": path.stat().st_size,
        "sha256": sha256_file(path),
    }


def assert_audio_qa(name: str, qa: dict[str, Any], expected_duration: float) -> None:
    if qa["channels"] != 2 or qa["sample_rate_hz"] != SAMPLE_RATE:
        raise RuntimeError(f"{name}: expected stereo {SAMPLE_RATE} Hz audio")
    if qa["sample_width_bits"] != 16 or qa["duration_seconds"] != expected_duration:
        raise RuntimeError(f"{name}: unexpected PCM width or duration")
    if qa["peak"] > 0.25:
        raise RuntimeError(f"{name}: peak {qa['peak']} exceeds quiet-asset limit 0.25")
    if qa["dc_offset_max"] > 0.002:
        raise RuntimeError(f"{name}: DC offset {qa['dc_offset_max']} exceeds 0.002")
    if name == "meadow_ambience" and qa["loop_seam_delta"] > 0.025:
        raise RuntimeError(f"{name}: loop seam delta {qa['loop_seam_delta']} exceeds 0.025")


def build_receipt() -> dict[str, Any]:
    prompt = file_record(PROMPT_PATH)
    script = file_record(SCRIPT_PATH)
    ambience_qa = wav_qa(AMBIENCE_PATH)
    footstep_qa = wav_qa(FOOTSTEP_PATH)
    assert_audio_qa("meadow_ambience", ambience_qa, float(AMBIENCE_SECONDS))
    assert_audio_qa("grass_footstep", footstep_qa, 1.08)
    return {
        "schema_version": 1,
        "generator": {
            "id": GENERATOR_ID,
            "version": GENERATOR_VERSION,
            "script": script,
        },
        "prompt": prompt,
        "resources": [
            {
                "kind": "generated_audio",
                "name": "meadow_ambience",
                "seed": AMBIENCE_SEED,
                "inputs": {"prompt_sha256": prompt["sha256"]},
                "output": file_record(AMBIENCE_PATH),
                "qa": ambience_qa,
            },
            {
                "kind": "generated_audio",
                "name": "grass_footstep",
                "seed": FOOTSTEP_SEED,
                "inputs": {"prompt_sha256": prompt["sha256"]},
                "output": file_record(FOOTSTEP_PATH),
                "qa": footstep_qa,
            },
            {
                "kind": "generated_svg",
                "name": "verdant_icon",
                "seed": None,
                "inputs": {"prompt_sha256": prompt["sha256"]},
                "output": file_record(ICON_PATH),
                "qa": {"view_box": "0 0 512 512"},
            },
            {
                "kind": "third_party_font",
                "name": "Noto Sans SC",
                "upstream_revision": FONT_REVISION,
                "source_url": FONT_URL,
                "license": {
                    **file_record(FONT_LICENSE_PATH),
                    "spdx": "OFL-1.1",
                    "source_url": FONT_LICENSE_URL,
                },
                "output": file_record(FONT_PATH),
                "qa": {"format": "TrueType variable font", "languages": ["en", "zh-Hans"]},
            },
        ],
    }


def generate() -> None:
    if not PROMPT_PATH.is_file():
        raise RuntimeError(f"missing committed production brief: {project_path(PROMPT_PATH)}")
    generate_ambience()
    generate_footstep()
    ICON_PATH.parent.mkdir(parents=True, exist_ok=True)
    ICON_PATH.write_bytes(icon_svg())
    fetch_checked(FONT_URL, FONT_PATH, FONT_SHA256)
    fetch_checked(FONT_LICENSE_URL, FONT_LICENSE_PATH, FONT_LICENSE_SHA256)
    receipt = build_receipt()
    RECEIPT_PATH.parent.mkdir(parents=True, exist_ok=True)
    RECEIPT_PATH.write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"generated {len(receipt['resources'])} resources and {project_path(RECEIPT_PATH)}")


def verify() -> None:
    if not RECEIPT_PATH.is_file():
        raise RuntimeError(f"missing receipt: {project_path(RECEIPT_PATH)}")
    recorded = json.loads(RECEIPT_PATH.read_text(encoding="utf-8"))
    if sha256_file(FONT_PATH) != FONT_SHA256:
        raise RuntimeError("font differs from the pinned official source")
    if sha256_file(FONT_LICENSE_PATH) != FONT_LICENSE_SHA256:
        raise RuntimeError("font license differs from the pinned official source")
    current = build_receipt()
    if recorded != current:
        recorded_text = json.dumps(recorded, indent=2, sort_keys=True)
        current_text = json.dumps(current, indent=2, sort_keys=True)
        for line_number, (old, new) in enumerate(
            zip(recorded_text.splitlines(), current_text.splitlines()), start=1
        ):
            if old != new:
                raise RuntimeError(f"receipt drift at line {line_number}: recorded {old!r}, current {new!r}")
        raise RuntimeError("receipt drift: recorded and current lengths differ")
    if FONT_PATH.stat().st_size < 1_000_000:
        raise RuntimeError("font payload is unexpectedly small")
    print(
        "verified prompt, generator, 4 resources, font license, hashes, and audio QA "
        f"from {project_path(RECEIPT_PATH)}"
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--generate", action="store_true", help="create assets and write the receipt")
    mode.add_argument("--verify", action="store_true", help="verify assets without changing files")
    args = parser.parse_args()
    try:
        if args.generate:
            generate()
        else:
            verify()
    except (OSError, RuntimeError, ValueError, json.JSONDecodeError) as error:
        print(f"asset pipeline failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
