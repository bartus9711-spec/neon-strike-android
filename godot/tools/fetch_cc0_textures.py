#!/usr/bin/env python3
"""Download small CC0 Poly Haven PBR maps for TeamCS Godot scene visual QA.

These images are from https://polyhaven.com (CC0 / public domain).
This script keeps source repository text-only and makes material sourcing repeatable.
Downloads happen only in a controlled build/test environment, never on player's phone.
"""
import json
import pathlib
import time
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1] / "assets"
ASSETS = [
    "asphalt_01",
    "cobblestone_pavement",
    "painted_plaster_wall",
    "red_brick",
]

def fetch_json(url):
    request = urllib.request.Request(url, headers={"User-Agent": "TeamCS-OpenSource-Demo/1.0"})
    for attempt in range(3):
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                return json.load(response)
        except Exception:
            if attempt == 2:
                raise
            time.sleep(2 * (attempt + 1))

def walk_urls(value):
    if isinstance(value, dict):
        for item in value.values():
            yield from walk_urls(item)
    elif isinstance(value, list):
        for item in value:
            yield from walk_urls(item)
    elif isinstance(value, str) and value.startswith("https://"):
        yield value

def download(url, target):
    request = urllib.request.Request(url, headers={"User-Agent": "TeamCS-OpenSource-Demo/1.0"})
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists() and target.stat().st_size > 16000:
        return
    for attempt in range(3):
        try:
            with urllib.request.urlopen(request, timeout=80) as response:
                content = response.read()
            if not content.startswith(b"\xff\xd8"):
                raise ValueError(f"Not a JPEG: {url} / {content[:30]!r}")
            target.write_bytes(content)
            print("Asset downloaded:", target.name, len(content), "bytes")
            return
        except Exception:
            if attempt == 2:
                raise
            time.sleep(2 * (attempt + 1))

def main():
    ROOT.mkdir(parents=True, exist_ok=True)
    for slug in ASSETS:
        files = fetch_json(f"https://api.polyhaven.com/files/{slug}")
        urls = list(walk_urls(files))
        for channel, patterns in [
            ("diff", [f"{slug}_diff_1k.jpg", f"{slug}_diffuse_1k.jpg"]),
            ("normal", [f"{slug}_nor_gl_1k.jpg"]),
        ]:
            matching = [url for url in urls if url.split("?")[0].endswith(tuple(patterns))]
            if not matching:
                raise RuntimeError(f"Missing {channel} 1K JPEG for {slug} in API. JPGs={list(u for u in urls if '_1k.jpg' in u)[:8]}")
            download(matching[0], ROOT / f"{slug}_{channel}.jpg")
    print("CC0 texture bundle ready at", ROOT)

if __name__ == "__main__":
    main()
