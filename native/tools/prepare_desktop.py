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
    # Skip original campaign setup and its missing commercial data in native mode.
    source = replace_once(source,
        '\t// register game specific decl types',
        '\tif (meridian_native.GetBool()) {\n'
        '\t\tMeridianRegisterCommands();\n'
        '\t\tMeridianStart_f(idCmdArgs());\n'
        '\t\treturn;\n'
        '\t}\n'
        '\t// register game specific decl types',
        'Game_local.cpp/native-init')
    source = replace_once(source,
        'void idGameLocal::Shutdown() {',
        'void idGameLocal::Shutdown() {\n'
        '\tif (meridian_native.GetBool()) { return; }',
        'Game_local.cpp/native-shutdown')
    ENTRY.write_text(source, encoding="utf-8")

    common_frame = OUT / "neo" / "framework" / "common_frame.cpp"
    text = common_frame.read_text(encoding="utf-8")
    text = replace_once(text,
        'if ( loadGUI != NULL ) {',
        'if ( cvarSystem->GetCVarBool("meridian_native") && game != NULL ) {\n'
        '\t\tgame->Draw(-1);\n'
        '\t} else if ( loadGUI != NULL ) {',
        'common_frame.cpp/native-draw')
    common_frame.write_text(text, encoding="utf-8")

    common = OUT / "neo" / "framework" / "Common.cpp"
    text = common.read_text(encoding="utf-8")
    text = replace_once(text,
        'void idCommonLocal::CreateMainMenu() {',
        'void idCommonLocal::CreateMainMenu() {\n'
        '\tif ( cvarSystem->GetCVarBool("meridian_native") ) { return; }',
        'Common.cpp/native-shell')
    common.write_text(text, encoding="utf-8")
    # VS2010 marked every warning fatal. Modern MSVC raises deprecation
    # warnings in Windows headers; disable legacy /WX on staged copies only.
    import re
    for project in OUT.rglob("*.vcxproj"):
        original = project.read_text(encoding="utf-8-sig")
        updated = re.sub(r"(<TreatWarningAsError(?:\\s+[^>]*)?>)true(</TreatWarningAsError>)",
                         r"\\1false\\2", original)
        if updated != original:
            project.write_text(updated, encoding="utf-8")
    # C++11 requires whitespace when concatenating a string literal and macro.
    classic = OUT / "doomclassic" / "doom" / "d_main.cpp"
    text = classic.read_text(encoding="utf-8")
    text = text.replace('\\\\"SAVEGAMENAME"', '\\\\" SAVEGAMENAME "')
    text = text.replace('SAVEGAMENAME"%c.dsg"', 'SAVEGAMENAME "%c.dsg"')
    classic.write_text(text, encoding="utf-8")
    pack_assets(ROOT / "Resource", OUT / "base", staged / "generated" / "AtlasDimensions.hpp")
    print(f"Desktop staging ready: {OUT}")
    print("Engine hooks: idGameLocal, idCommonLocal::Draw and CreateMainMenu; native standalone startup.")
    print("Not compiled, tested, or verified playable. Build with a compatible Windows toolchain.")

if __name__ == "__main__":
    main()
