#!/usr/bin/env python3
"""Copy original sprite sheets into idTech's TGA material namespace.

Requires Pillow at asset-preparation time (python -m pip install pillow).
No art is redrawn, recompressed with lossy codecs, or replaced.
"""
from pathlib import Path
import struct

SHEETS = {
    "player": "Player.png",
    "enemies": "Enemies.png",
    "tiles": "Tiles.png",
    "collectables": "Collectables.png",
    "ui": "UI.png",
}

def pack_assets(resources: Path, base_dir: Path, header: Path) -> None:
    try:
        from PIL import Image
    except ImportError as exc:
        raise SystemExit("Missing image converter: python -m pip install pillow") from exc
    out = base_dir / "textures" / "meridian"
    out.mkdir(parents=True, exist_ok=True)
    header.parent.mkdir(parents=True, exist_ok=True)
    dimensions = ["#pragma once", "// Generated from the actual resource PNG sizes."]
    materials = []
    for name, filename in SHEETS.items():
        with Image.open(resources / filename) as opened:
            image = opened.convert("RGBA")
        w, h = image.size
        if w > 65535 or h > 65535:
            raise ValueError(f"Texture too large for TGA: {filename}")
        tag=name.upper()
        dimensions.append(f"#define MERIDIAN_{tag}_W {w}.0f")
        dimensions.append(f"#define MERIDIAN_{tag}_H {h}.0f")
        tga = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, w, h, 32, 0x28)
        (out / (name + ".tga")).write_bytes(tga + image.tobytes("raw", "BGRA"))
        materials.append(
            f"meridian/{name}\n{{\n    translucent\n    nonsolid\n"
            f"    {{\n        blend blend\n        map textures/meridian/{name}\n    }}\n}}\n"
        )
    (base_dir / "materials").mkdir(parents=True, exist_ok=True)
    (base_dir / "materials" / "meridian.mtr").write_text("\n".join(materials), encoding="ascii")
    header.write_text("\n".join(dimensions)+"\n", encoding="ascii")
    print(f"Copied {len(SHEETS)} original texture atlases without changing pixel data.")

if __name__ == "__main__":
    pack_assets(Path("Resource"), Path("build/desktop-idtech4/base"),
                Path("build/desktop-idtech4/neo/d3xp/meridian/generated/AtlasDimensions.hpp"))
