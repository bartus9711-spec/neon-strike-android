#!/usr/bin/env python3
"""Fetch attributed, game-ready 3D human character assets for native Godot import.

Models are CC BY 4.0, not CC0. See assets/models/ATTRIBUTION.md.
Pinned upstream commit protects builds from unreviewed binary changes.
"""
import pathlib, struct, urllib.request, json, hashlib
root=pathlib.Path(__file__).resolve().parents[1]/"assets"/"models"
root.mkdir(parents=True,exist_ok=True)
commit="130ac2a5c856401ec36e7d35afcfefe40c5801f4"
base=f"https://raw.githubusercontent.com/cktang88/3d-fps/{commit}/public/assets/models/characters"
specs=[
    ("soldier.glb",3_094_592,"6f229176b1ca49ff33605718ebfcca7fcee8f65d6d311ce3c86693df9310d2d7"),
    ("soldier_tac.glb",4_532_132,"fe02bc307077d7a5a74069d085893988d93751495871c84082256e60bf9bfc9e"),
]
for name,expected_size,expected_digest in specs:
    dest=root/name
    if not dest.is_file() or dest.stat().st_size!=expected_size:
        url=f"{base}/{name}"
        req=urllib.request.Request(url,headers={"User-Agent":"TeamCS-Character-Asset-Importer/1.0"})
        with urllib.request.urlopen(req,timeout=65) as response:
            blob=response.read()
        if len(blob)!=expected_size or blob[:4]!=b"glTF":
            raise ValueError(f"Invalid source binary: {name} ({len(blob)} bytes)")
        dest.write_bytes(blob)
    data=dest.read_bytes()
    if hashlib.sha256(data).hexdigest() != expected_digest:
        raise ValueError(f"Source checksum mismatch: {name}; review source before changing the pin")
    declared=struct.unpack_from("<I",data,8)[0]
    if declared!=len(data):
        raise ValueError(f"Invalid glTF binary header: {name}")
    chunk_len,chunk_type=struct.unpack_from("<II",data,12)
    if chunk_type!=0x4E4F534A:
        raise ValueError(f"Missing glTF JSON data: {name}")
    doc=json.loads(data[20:20+chunk_len].decode("utf-8"))
    animation_names=[a.get("name","") for a in doc.get("animations",[])]
    mesh_count=len(doc.get("meshes",[]))
    print(f"TEAMCS_HUMAN_MODEL: {name} bytes={len(data)} meshes={mesh_count} animations={animation_names[:30]}")
    if mesh_count<1:
        raise RuntimeError(f"No meshes: {name}")
print("TEAMCS_HUMAN_MODELS_READY")
