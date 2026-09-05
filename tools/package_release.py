"""Package offline player notes/licenses and audit a Godot 4.6 macOS ZIP.

Run after a successful gda export. Does not launch, sign, publish, or push anything.
"""
import hashlib
import json
from pathlib import Path
import plistlib
import struct
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ZIP = ROOT / "builds/Verdant-macOS.zip"


def audit(archive):
    pck_name = next(n for n in archive.namelist() if n.endswith("/Resources/Verdant.pck"))
    data = archive.read(pck_name)
    magic, version, major, minor, patch, flags = struct.unpack_from("<6I", data)
    assert magic == 0x43504447 and version == 3 and flags == 2
    file_base, directory = struct.unpack_from("<QQ", data, 24)
    count = struct.unpack_from("<I", data, directory)[0]
    pos = directory + 4
    files = {}
    for _ in range(count):
        length = struct.unpack_from("<I", data, pos)[0]
        pos += 4
        path = data[pos:pos + length].split(b"\0", 1)[0].decode()
        pos += length
        offset, size = struct.unpack_from("<QQ", data, pos)
        digest = data[pos + 16:pos + 32].hex()
        file_flags = struct.unpack_from("<I", data, pos + 32)[0]
        pos += 36
        assert path not in files and file_flags == 0, path
        content = data[file_base + offset:file_base + offset + size]
        assert len(content) == size and hashlib.md5(content).hexdigest() == digest, path
        files[path] = {"bytes": size, "md5": digest}
        if path == "content/fonts/OFL.txt":
            assert content == (ROOT / path).read_bytes()
    assert "content/fonts/OFL.txt" in files
    forbidden = ("tests/", "tools/", "docs/", "evidence/", "assets/", "builds/",
                 "distribution/", "addons/gda_harness/", ".agents/", ".claude/")
    assert not [p for p in files if p.startswith(forbidden)]
    for marker in ("NotoSansSC", "meadow_ambience", "grass_footstep", "grass.gdshader"):
        assert any(marker in p for p in files), marker
    app_info = plistlib.loads(archive.read("Verdant.app/Contents/Info.plist"))
    return {"engine": f"{major}.{minor}.{patch}", "pck_format": version,
            "pck_sha256": hashlib.sha256(data).hexdigest(), "pck_files": files,
            "font_license_matches_source": True, "tooling_excluded": True,
            "bundle_identifier": app_info["CFBundleIdentifier"],
            "version": app_info["CFBundleShortVersionString"]}


def main():
    extras = {"README.txt": ROOT / "distribution/README.txt",
              "licenses/OFL.txt": ROOT / "content/fonts/OFL.txt"}
    for path in (ROOT / "distribution/licenses").glob("*.txt"):
        extras["licenses/" + path.name] = path
    with zipfile.ZipFile(ZIP) as source:
        report = audit(source)
        temporary = ZIP.with_suffix(".packaging.zip")
        with zipfile.ZipFile(temporary, "w", compression=zipfile.ZIP_DEFLATED) as target:
            for entry in source.infolist():
                if entry.filename not in extras:
                    target.writestr(entry, source.read(entry.filename))
            for name, path in extras.items():
                target.write(path, name)
    temporary.replace(ZIP)
    with zipfile.ZipFile(ZIP) as archive:
        assert audit(archive) == report
        assert archive.testzip() is None
    report.update({"zip": ZIP.name, "bytes": ZIP.stat().st_size,
                   "sha256": hashlib.sha256(ZIP.read_bytes()).hexdigest(),
                   "source_commit": subprocess.check_output(
                       ["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
                   "offline_files": {name: hashlib.sha256(path.read_bytes()).hexdigest()
                                     for name, path in extras.items()}})
    (ROOT / "builds/release-audit.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({k: v for k, v in report.items() if k != "pck_files"}, indent=2))


if __name__ == "__main__":
    main()
