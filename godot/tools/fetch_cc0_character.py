#!/usr/bin/env python3
"""Fetch verified public animated humans for the native Godot TeamCS project.

Soldier.glb is distributed in the three.js examples (MIT-licensed repository).
It contains humanoid skinned meshes and Idle/Walk/Run animation clips.
RobotExpressive.glb is a CC0 fallback from Tomás Laulhé / Quaternius.
No registration, attribution-only commercial assets, or AI remote generation.
"""
from pathlib import Path
import struct
from urllib.request import Request, urlopen

root = Path(__file__).resolve().parents[1] / "assets" / "models"
root.mkdir(parents=True, exist_ok=True)
assets = [
    ("Soldier.glb", "https://raw.githubusercontent.com/mrdoob/three.js/dev/examples/models/gltf/Soldier.glb", 900_000),
    ("RobotExpressive.glb", "https://raw.githubusercontent.com/mrdoob/three.js/dev/examples/models/gltf/RobotExpressive/RobotExpressive.glb", 100_000),
]
for name, url, minimum in assets:
    path = root / name
    if not path.exists() or path.stat().st_size < minimum:
        req = Request(url, headers={"User-Agent":"TeamCS-3D-Asset-Builder/1.0"})
        with urlopen(req, timeout=70) as response:
            data = response.read()
        if data[:4] != b"glTF" or len(data) < minimum:
            raise RuntimeError(f"Damaged game asset: {name} ({len(data)} bytes)")
        path.write_bytes(data)
    header = path.read_bytes()[:12]
    assert header[:4] == b"glTF", f"Invalid GLB header in {name}"
    assert struct.unpack("<I", header[8:12])[0] == path.stat().st_size, f"Truncated GLB {name}"
    print("TEAMCS_ANIMATED_CHARACTER_READY", name, path.stat().st_size)
