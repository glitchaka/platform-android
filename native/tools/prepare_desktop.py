#!/usr/bin/env python3
"""Prepara una copia de la fuente idTech 4 para Ashen Meridian (Windows nativo).
No altera el submodulo ni compila automaticamente.
"""
from __future__ import annotations
import shutil
from pathlib import Path
from pack_assets import pack_assets

ROOT = Path(__file__).resolve().parents[2]
ENGINE = ROOT / "vendor" / "doom3-bfg"
OUT = ROOT / "build" / "desktop-idtech4"
ENTRY = OUT / "neo" / "d3xp" / "Game_local.cpp"

def replace_once(text: str, old: str, new: str, target: str) -> str:
    if text.count(old) != 1:
        raise RuntimeError(f"Patch ambiguous or incompatible: {target}, matches={text.count(old)}")
    return text.replace(old, new, 1)

def main() -> None:
    if not (ENGINE / "neo" / "doom3.sln").is_file():
        raise SystemExit("Missing idTech 4 source. Run: git submodule update --init --recursive")
    if OUT.exists():
        shutil.rmtree(OUT)
    shutil.copytree(ENGINE, OUT, ignore=shutil.ignore_patterns(".git", "*.obj", "*.pdb"))
    src = ROOT / "native"
    staged = OUT / "neo" / "d3xp" / "meridian"
    staged.mkdir(parents=True, exist_ok=True)
    for dirname in ("core", "generated", "idtech"):
        shutil.copytree(src / dirname, staged / dirname, dirs_exist_ok=True)
    source = ENTRY.read_text(encoding="utf-8")
    source = replace_once(source, '#include "Game_local.h"',
        '#include "Game_local.h"\n#include "meridian/idtech/Bridge.cpp"',
        "Game_local.cpp/include")
    source = replace_once(source, '\tInitConsoleCommands();',
        '\tInitConsoleCommands();\n\tMeridianRegisterCommands();',
        "Game_local.cpp/commands")
    source = replace_once(source, 'bool idGameLocal::Draw( int clientNum ) {',
        'bool idGameLocal::Draw( int clientNum ) {\n'
        '\tif ( Meridian_IsActive() ) { Meridian_Tick(); Meridian_Draw(); return true; }',
        "Game_local.cpp/render")
    ENTRY.write_text(source, encoding="utf-8")
    pack_assets(ROOT / "Resource", OUT / "base", staged / "generated" / "AtlasDimensions.hpp")
    print(f"Desktop staging ready: {OUT}")
    print("Engine hook: idGameLocal::Draw; registered commands meridian_start, meridian_load, meridian_stop.")
    print("Not compiled, tested, or verified playable. Build with a compatible Windows toolchain.")

if __name__ == "__main__":
    main()
