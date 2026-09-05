"""Author the player InputMap through gda's engine-backed project operations."""
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
bindings = {
    "walk_forward": ["W", "Up"], "walk_back": ["S", "Down"],
    "walk_left": ["A", "Left"], "walk_right": ["D", "Right"],
    "sprint": ["Shift"], "crouch": ["Ctrl"],
}
receipts = []
for name, keys in bindings.items():
    command = ["gda", "--user-data-root", "/tmp/verdant-input-authoring", "project", "add-input-action", name, "--physical"]
    for key in keys:
        command += ["--key", key]
    command += ["--project", str(ROOT), "--json"]
    result = subprocess.run(command, capture_output=True, text=True, check=True)
    payload = json.loads(result.stdout)
    if "error" in payload:
        raise RuntimeError(payload)
    receipts.append(payload)
evidence = ROOT / "evidence/raw/input-authoring.json"
evidence.parent.mkdir(parents=True, exist_ok=True)
evidence.write_text(json.dumps(receipts, indent=2) + "\n")
print(f"Authored {len(bindings)} physical InputMap actions through gda.")
