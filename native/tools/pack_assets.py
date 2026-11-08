#!/usr/bin/env python3
"""Package every original Ashen Meridian resource for native idTech 4.

- All PNG source atlases are converted pixel-for-pixel to uncompressed RGBA TGA.
- All original WAV/OGG audio is copied without transcoding or loss.
- Original files (except editor import caches) are retained under meridian-source.
- A manifest records source names, native material names, texture sizes and sound IDs.
"""
from __future__ import annotations

import json
import shutil
import struct
from pathlib import Path

ROOT_ATLASES = {"Player.png", "Enemies.png", "Tiles.png", "UI.png", "Collectables.png"}


def pack_assets(resources: Path, base_dir: Path, header: Path) -> None:
    try:
        from PIL import Image
    except ImportError as exc:
        raise SystemExit("Install Pillow to prepare original PNG assets: python -m pip install pillow") from exc

    textures = base_dir / "textures" / "meridian"
    sounds = base_dir / "sound" / "meridian"
    original = base_dir / "meridian-source"
    header.parent.mkdir(parents=True, exist_ok=True)
    textures.mkdir(parents=True, exist_ok=True)
    sounds.mkdir(parents=True, exist_ok=True)
    original.mkdir(parents=True, exist_ok=True)
    dimensions = ["#pragma once", "// Actual dimensions read from the original sprite PNG atlases."]
    materials = []
    shaders = []
    manifest = {"textures": [], "audio": [], "other": []}

    for source in sorted(resources.rglob("*")):
        if not source.is_file() or source.name.endswith(".import"):
            continue
        relative = source.relative_to(resources)
        rel = relative.as_posix()
        raw_dest = original / relative
        raw_dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, raw_dest)

        if source.suffix.lower() == ".png":
            name = relative.with_suffix("").as_posix().lower()
            output = textures / (name + ".tga")
            output.parent.mkdir(parents=True, exist_ok=True)
            with Image.open(source) as opened:
                image = opened.convert("RGBA")
            width, height = image.size
            if width > 65535 or height > 65535:
                raise ValueError(f"TGA dimension limit exceeded by {rel}")
            # Type 2, uncompressed BGRA; upper-left origin and 8 alpha bits.
            header_bytes = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0,
                                       0, 0, width, height, 32, 0x28)
            output.write_bytes(header_bytes + image.tobytes("raw", "BGRA"))
            materials.append(
                f"meridian/{name}\n{{\n    translucent\n    nonsolid\n"
                f"    {{\n        blend blend\n        map textures/meridian/{name}\n    }}\n}}\n"
            )
            manifest["textures"].append({
                "source": rel, "material": f"meridian/{name}",
                "width": width, "height": height,
            })
            if relative.name in ROOT_ATLASES and len(relative.parts) == 1:
                macro = name.upper()
                dimensions += [f"#define MERIDIAN_{macro}_W {width}.0f",
                               f"#define MERIDIAN_{macro}_H {height}.0f"]
        elif source.suffix.lower() in (".wav", ".ogg"):
            name = relative.with_suffix("").as_posix().lower()
            sound_path = sounds / relative
            sound_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, sound_path)
            shaders.append(
                f"meridian/{name}\n{{\n"
                + ("    looping\n" if source.suffix.lower() == ".ogg" else "")
                + f"    sound/meridian/{rel}\n}}\n"
            )
            manifest["audio"].append({
                "source": rel, "shader": f"meridian/{name}",
                "path": f"sound/meridian/{rel}",
            })
        else:
            manifest["other"].append(rel)

    material_dir = base_dir / "materials"
    material_dir.mkdir(parents=True, exist_ok=True)
    (material_dir / "meridian.mtr").write_text("\n".join(materials), encoding="utf-8")
    sound_dir = base_dir / "sound"
    (sound_dir / "meridian.sndshd").write_text("\n".join(shaders), encoding="utf-8")
    (original / "asset_manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    header.write_text("\n".join(dimensions) + "\n", encoding="ascii")
    print(f"Native resource package: {len(manifest['textures'])} PNG atlases, "
          f"{len(manifest['audio'])} audio files, {len(manifest['other'])} supporting sources.")
    if len(manifest["textures"]) < 27 or len(manifest["audio"]) < 38:
        raise RuntimeError("Some original PNG or sound resources were not packaged.")


if __name__ == "__main__":
    pack_assets(Path("Resource"), Path("build/desktop-idtech4/base"),
                Path("build/desktop-idtech4/neo/d3xp/meridian/generated/AtlasDimensions.hpp"))
