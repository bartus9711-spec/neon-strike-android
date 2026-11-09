#!/usr/bin/env python3
"""Fetch CC0 humanoid animated RobotExpressive by Tomás Laulhé (Quaternius).
Asset from three.js examples, edited by Don McCurdy. Source README: 
https://github.com/mrdoob/three.js/tree/master/examples/models/gltf/RobotExpressive
Use and redistribute CC0 1.0. Downloads only if needed; validates binary GLB.
"""
import pathlib, struct, urllib.request
p=pathlib.Path(__file__).resolve().parents[1]/"assets"/"models"/"RobotExpressive.glb"
url="https://raw.githubusercontent.com/mrdoob/three.js/master/examples/models/gltf/RobotExpressive/RobotExpressive.glb"
p.parent.mkdir(parents=True,exist_ok=True)
if not p.exists() or p.stat().st_size<100_000:
    req=urllib.request.Request(url,headers={"User-Agent":"TeamCS-CC0-Asset-Fetcher"})
    with urllib.request.urlopen(req, timeout=35) as response:
        payload=response.read()
    if len(payload)<100_000 or payload[:4]!=b"glTF":
        raise RuntimeError("Downloaded asset is not a complete glTF binary")
    p.write_bytes(payload)
header=p.read_bytes()[:12]
assert header[:4]==b"glTF", "Invalid GLB"
assert struct.unpack("<I",header[8:12])[0]==p.stat().st_size
print("TEAMCS_CC0_ANIMATED_HUMANOID_READY",p,p.stat().st_size)
