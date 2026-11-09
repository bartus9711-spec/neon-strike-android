#!/usr/bin/env python3
"""Fetch CC BY 4.0 3D character art before Godot resource import."""
from __future__ import annotations
import json
import pathlib
import struct
import time
import urllib.request

HERE = pathlib.Path(__file__).resolve().parents[1]
DEST = HERE / "assets" / "characters"
ASSETS = {
    "ct_operator.glb": (
        "https://raw.githubusercontent.com/cktang88/3d-fps/main/"
        "public/assets/models/characters/soldier_tac.glb"
    ),
    "t_operator.glb": (
        "https://raw.githubusercontent.com/cktang88/3d-fps/main/"
        "public/assets/models/characters/soldier.glb"
    ),
}

def check_glb(path: pathlib.Path) -> dict:
    with path.open("rb") as f:
        header = f.read(20)
        if len(header) != 20:
            raise ValueError(f"{path}: truncated GLB header")
        magic, version, total, json_len, json_type = struct.unpack("<4s4I", header)
        if magic != b"glTF" or version != 2 or json_type != 0x4E4F534A:
            raise ValueError(f"{path}: invalid glTF 2 binary format")
        if total != path.stat().st_size or json_len > total - 20:
            raise ValueError(f"{path}: inconsistent GLB length")
        metadata = json.loads(f.read(json_len))
    if not metadata.get("meshes") or not metadata.get("nodes"):
        raise ValueError(f"{path}: no character geometry")
    return metadata

def download_once(url: str, dest: pathlib.Path) -> dict:
    temporary = dest.with_suffix(".tmp")
    request = urllib.request.Request(url, headers={"User-Agent": "TeamCS-Character-Art-Importer/1.0"})
    try:
        with urllib.request.urlopen(request, timeout=35) as response:
            with temporary.open("wb") as output:
                while True:
                    chunk = response.read(512 * 1024)
                    if not chunk:
                        break
                    output.write(chunk)
        if temporary.stat().st_size < 300_000:
            raise ValueError("Downloaded model unexpectedly small")
        info = check_glb(temporary)
        temporary.replace(dest)
        return info
    finally:
        temporary.unlink(missing_ok=True)

def main() -> None:
    DEST.mkdir(parents=True, exist_ok=True)
    for name, url in ASSETS.items():
        path = DEST / name
        if path.exists():
            info = check_glb(path)
        else:
            for attempt in range(4):
                try:
                    info = download_once(url, path)
                    break
                except Exception:
                    if attempt == 3:
                        raise
                    time.sleep(3 * (attempt + 1))
        clips = [str(animation.get("name", "unnamed")) for animation in info.get("animations", [])]
        print(
            "TEAMCS_HUMANOID_ASSET_OK",
            name,
            f"bytes={path.stat().st_size}",
            f"meshes={len(info['meshes'])}",
            f"skins={len(info.get('skins', []))}",
            f"animations={len(clips)}",
            f"clips={clips[:15]}",
            flush=True,
        )

if __name__ == "__main__":
    main()
