#!/usr/bin/env python3
"""Prepara una copia de la fuente idTech 4 para Ashen Meridian (Windows nativo).
No altera el submodulo ni compila automaticamente.
"""
from __future__ import annotations
import shutil
import re
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
        '\t\tMeridianBoot_f(idCmdArgs());\n'
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
    trace_header = "#include <cstdio>\n#include <cstdlib>\nstatic void MeridianEngineStage(const char *stage) {\n    const char *path = std::getenv(\"MERIDIAN_NATIVE_TRACE\");\n    if (path == NULL || path[0] == '\\0') return;\n    FILE *f = std::fopen(path, \"a\");\n    if (f != NULL) { std::fputs(stage, f); std::fputc('\\n', f); std::fclose(f); }\n}"
    text = replace_once(text, '#pragma hdrstop',
        '#pragma hdrstop\n' + trace_header, 'common_frame.cpp/trace-header')
    text = replace_once(text, 'void idCommonLocal::Draw() {',
        'void idCommonLocal::Draw() {\n'
        '    static bool traced = false;\n'
        '    if (!traced) { traced = true; MeridianEngineStage("common.Draw"); }',
        'common_frame.cpp/trace-draw')
    text = replace_once(text, 'void idCommonLocal::Frame() {',
        'void idCommonLocal::Frame() {\n'
        '    static bool traced = false;\n'
        '    if (!traced) { traced = true; MeridianEngineStage("common.Frame"); }',
        'common_frame.cpp/trace-frame')
    text = replace_once(text,
        'if ( loadGUI != NULL ) {',
        'if ( cvarSystem->GetCVarBool("meridian_native") && game != NULL ) {\n'
        '\t\tgame->Draw(-1);\n'
        '\t} else if ( loadGUI != NULL ) {',
        'common_frame.cpp/native-draw')
    # Ashen Meridian owns its game loop. BFG's session/map/SWF frame orchestration
    # cannot drive a standalone 2D game without commercial campaign resources.
    text = replace_once(text,
        'if ( cvarSystem->GetCVarBool("meridian_native") && game != NULL ) {' + chr(10) +
        chr(9)*2 + 'game->Draw(-1);',
        'if ( cvarSystem->GetCVarBool("meridian_native") && game != NULL ) {' + chr(10) +
        chr(9)*2 + 'game->Draw(-1);' + chr(10) +
        chr(9)*2 + 'return;',
        'common_frame.cpp/native-exclusive-draw')
    text = replace_once(text,
        'void idCommonLocal::Frame() {' + chr(10) +
        '    static bool traced = false;' + chr(10) +
        '    if (!traced) { traced = true; MeridianEngineStage("common.Frame"); }',
        'void idCommonLocal::Frame() {' + chr(10) +
        '    static bool traced = false;' + chr(10) +
        '    if (!traced) { traced = true; MeridianEngineStage("common.Frame"); }' + chr(10) +
        '    if (cvarSystem->GetCVarBool("meridian_native")) {' + chr(10) +
        '        ++idLib::frameNumber;' + chr(10) +
        '        Sys_GenerateEvents();' + chr(10) +
        '        eventLoop->RunEventLoop();' + chr(10) +
        '        UpdateScreen(false);' + chr(10) +
        '        soundSystem->Render();' + chr(10) +
        '        Sys_Sleep(1);' + chr(10) +
        '        return;' + chr(10) +
        '    }',
        'common_frame.cpp/native-frame-loop')
    common_frame.write_text(text, encoding="utf-8")

    common = OUT / "neo" / "framework" / "Common.cpp"
    text = common.read_text(encoding="utf-8")
    text = replace_once(text, '#pragma hdrstop',
        '#pragma hdrstop\n' + trace_header, 'Common.cpp/trace-header')
    for label, call in (
        ("commands", "cmdSystem->Init()"),
        ("cvars", "cvarSystem->Init()"),
        ("system", "Sys_Init()"),
        ("filesystem", "fileSystem->Init()"),
        ("decls", "declManager->Init()"),
        ("opengl", "renderSystem->InitOpenGL()"),
        ("sound", "soundSystem->Init()"),
        ("renderer", "renderSystem->Init()"),
        ("decls2", "declManager->Init2()"),
        ("gameDLL", "LoadGameDLL()"),
        ("session", "session->Initialize()"),
        ("shell", "CreateMainMenu()"),
        ("startmenu", "StartMenu( true )"),
        ("finish-files", "fileSystem->EndLevelLoad()"),
        ("unload-resources", 'fileSystem->UnloadResourceContainer( "_ordered" )'),
        ("renderworld", "renderWorld = renderSystem->AllocRenderWorld()"),
        ("soundworld", "soundWorld = soundSystem->AllocSoundWorld( renderWorld )"),
        ("menuworld", "menuSoundWorld = soundSystem->AllocSoundWorld( NULL )"),
        ("session-audio", "session->InitializeSoundRelatedSystems()"),
        ("multiplayer-maps", "InitializeMPMapsModes()"),
        ("dialog", "commonDialog.Init()"),
        ("console-history", "consoleHistory.LoadHistoryFile()"),
        ("startup-commands", "AddStartupCommands()"),
        ("storage-check", "CheckStartupStorageRequirements()"),
    ):
        token = chr(9) * 2 + call + ";"
        text = replace_once(text, token,
            '        MeridianEngineStage("before.' + label + '");' + chr(10) + token +
            chr(10) + '        MeridianEngineStage("after.' + label + '");',
            "Common.cpp/" + label)
    text = replace_once(text,
        'void idCommonLocal::Init( int argc, const char * const * argv, const char *cmdline ) {',
        'void idCommonLocal::Init( int argc, const char * const * argv, const char *cmdline ) {\n'
        '    MeridianEngineStage("common.Init");',
        'Common.cpp/trace-init')
    text = replace_once(text, '\t\tgame->Init();',
        '\t\tMeridianEngineStage("game.Init.begin");\n'
        '\t\tgame->Init();\n'
        '\t\tMeridianEngineStage("game.Init.end");',
        'Common.cpp/trace-game-init')
    text = replace_once(text,
        'void idCommonLocal::CreateMainMenu() {',
        'void idCommonLocal::CreateMainMenu() {\n'
        '\tif ( cvarSystem->GetCVarBool("meridian_native") ) { return; }',
        'Common.cpp/native-shell')
    # Meridian has its own C++ menus; do not start DOOM's proprietary SWF UI.
    text = replace_once(text, chr(9)*2 + 'uiManager->Init();',
        chr(9)*2 + 'if (!cvarSystem->GetCVarBool("meridian_native")) uiManager->Init();',
        'Common.cpp/native-no-SWF')
    text = replace_once(text, chr(9)*2 + 'StartMenu( true );',
        chr(9)*2 + 'if (!cvarSystem->GetCVarBool("meridian_native")) StartMenu( true );',
        'Common.cpp/native-no-DOOM-menu')
    # Do not eagerly load original DOOM splash/font assets that are absent
    # from the open-source engine. Meridian renders its own native UI sprites.
    text = replace_once(text,
        'if ( !fileSystem->UsingResourceFiles() ) {' + chr(10) +
        chr(9)*3 + 'declManager->FindMaterial( "guis/assets/splash/legal_english" );',
        'if ( !cvarSystem->GetCVarBool("meridian_native") && !fileSystem->UsingResourceFiles() ) {' + chr(10) +
        chr(9)*3 + 'declManager->FindMaterial( "guis/assets/splash/legal_english" );',
        'Common.cpp/native-skip-proprietary-font')
    # Native title, pause and HUD never access commercial SWF dialogs or
    # leaderboards. These systems are excluded from native startup.
    text = replace_once(text, chr(9)*2+'commonDialog.Init();',
        chr(9)*2+'if (!cvarSystem->GetCVarBool("meridian_native")) commonDialog.Init();',
        'Common.cpp/native-no-DOOM-dialogs')
    text = replace_once(text, chr(9)*2+'InitializeMPMapsModes();',
        chr(9)*2+'if (!cvarSystem->GetCVarBool("meridian_native")) InitializeMPMapsModes();',
        'Common.cpp/native-no-multiplayer')
    text = replace_once(text, chr(9)*2+'CheckStartupStorageRequirements();',
        chr(9)*2+'if (!cvarSystem->GetCVarBool("meridian_native")) CheckStartupStorageRequirements();',
        'Common.cpp/native-no-DOOM-storage-dialog')
    text = replace_once(text, chr(9)*2+'game->Leaderboards_Init();',
        chr(9)*2+'if (!cvarSystem->GetCVarBool("meridian_native")) game->Leaderboards_Init();',
        'Common.cpp/native-no-DOOM-leaderboards')
    text = replace_once(text,
        'while ( Sys_Milliseconds() - legalStartTime < legalMinTime ) {',
        'while ( !cvarSystem->GetCVarBool("meridian_native") && Sys_Milliseconds() - legalStartTime < legalMinTime ) {',
        'Common.cpp/native-no-DOOM-intro')
    text = replace_once(text,
        chr(9)*2 + 'menuSoundWorld->PlaceListener( vec3_origin, mat3_identity, 0 );',
        chr(9)*2 + 'menuSoundWorld->PlaceListener( vec3_origin, mat3_identity, 0 );' + chr(10) +
        chr(9)*2 + 'if (cvarSystem->GetCVarBool("meridian_native")) soundSystem->SetPlayingSoundWorld(menuSoundWorld);',
        'Common.cpp/native-music-world')
    # Complete only the systems that the native game actually needs.
    # Skip the BFG session, multiplayer maps, profile UI and missing commercial
    # assets; otherwise the desktop process can remain alive without frames.
    text = replace_once(text,
        '        MeridianEngineStage("after.gameDLL");',
        '        MeridianEngineStage("after.gameDLL");' + chr(10) +
        '        if (cvarSystem->GetCVarBool("meridian_native")) {' + chr(10) +
        '            MeridianEngineStage("native.bootstrap");' + chr(10) +
        '            fileSystem->UnloadResourceContainer("_ordered");' + chr(10) +
        '            renderWorld = renderSystem->AllocRenderWorld();' + chr(10) +
        '            soundWorld = soundSystem->AllocSoundWorld(renderWorld);' + chr(10) +
        '            menuSoundWorld = soundSystem->AllocSoundWorld(NULL);' + chr(10) +
        '            menuSoundWorld->PlaceListener(vec3_origin, mat3_identity, 0);' + chr(10) +
        '            soundSystem->SetPlayingSoundWorld(menuSoundWorld);' + chr(10) +
        '            fileSystem->EndLevelLoad();' + chr(10) +
        '            com_fullyInitialized = true;' + chr(10) +
        '            MeridianEngineStage("native.ready");' + chr(10) +
        '            return;' + chr(10) +
        '        }',
        'Common.cpp/native-direct-bootstrap')
    common.write_text(text, encoding="utf-8")
    # The original code targets WINVER 0x0501 (Windows XP). Visual Studio
    # 2026 ATL requires newer Windows APIs such as LCMapStringEx.
    win_headers = OUT / "neo" / "idlib" / "sys" / "sys_includes.h"
    win_text = win_headers.read_text(encoding="utf-8")
    win_text, count = re.subn(
        r"(?m)^#define[ \t]+WINVER[ \t]+0x501[ \t]*$",
        "#define WINVER 0x0601\n#define _WIN32_WINNT 0x0601",
        win_text,
    )
    if count != 1:
        raise RuntimeError(f"Expected Windows XP target macro once, found {count}")
    win_headers.write_text(win_text, encoding="utf-8")
    # Modern VS emits different warnings than VS2010. Keep legacy flags
    # out of staged builds, without modifying the original engine repository.
    # The source release predates C++11 and defines the keyword 'nullptr' as
    # an idNullPtr() macro. In modern MSVC that rewrites the STL's nullptr
    # expressions into non-constexpr conversions (C3615 in xcall_once.h).
    # Remove the keyword-redefining compatibility macro in the staging copy.
    types_header = OUT / "neo" / "idlib" / "sys" / "sys_types.h"
    types_text = types_header.read_text(encoding="utf-8")
    types_text, removed = re.subn(
        r"(?m)^[ \t]*#ifndef[ \t]+nullptr[^\n]*\n[ \t]*#define[ \t]+nullptr[^\n]*\n[ \t]*#endif[ \t]*(?:\n|$)",
        "", types_text,
    )
    if removed != 1:
        raise RuntimeError(f"Expected one legacy nullptr macro, found {removed}")
    types_header.write_text(types_text, encoding="utf-8")
    for project in OUT.rglob("*.vcxproj"):
        original = project.read_text(encoding="utf-8-sig")
        updated = re.sub(r"(<TreatWarningAsError(?:\s+[^>]*)?>)true(</TreatWarningAsError>)",
                         r"\1false\2", original)
        if updated != original:
            project.write_text(updated, encoding="utf-8")
    # C++11 refuses MSVC2010-style adjacent string literals + preprocessor macro.
    classic = OUT / "doomclassic" / "doom" / "d_main.cpp"
    text = classic.read_text(encoding="utf-8")
    text = text.replace('"SAVEGAMENAME', '" SAVEGAMENAME')
    text = text.replace('SAVEGAMENAME"', 'SAVEGAMENAME "')
    classic.write_text(text, encoding="utf-8")
    # In C++11 string literals and macro names need a separating space.
    syscmds = OUT / "neo" / "d3xp" / "gamesys" / "SysCmds.cpp"
    sys_text = syscmds.read_text(encoding="utf-8")
    sys_text = sys_text.replace('"S_COLOR_WHITE"', '" S_COLOR_WHITE "')
    syscmds.write_text(sys_text, encoding="utf-8")
    # The original 2012 repository omits this generated introspection header;
    # these three includes do not require definitions beyond Class.h.
    typeinfo = OUT / "neo" / "d3xp" / "gamesys" / "TypeInfo.h"
    if not typeinfo.exists():
        typeinfo.write_text("#pragma once" + chr(10) + "// Generated type metadata is not included in this GPL source release." + chr(10), encoding="ascii")
    # WGL ARB function pointers are obtained from a temporary OpenGL context
    # in the old Windows renderer. On current systems those pointers can become
    # invalid when that context is destroyed (software NX fault in
    # GLW_ChoosePixelFormat, confirmed by the native crash dump and PDB).
    # Use Win32's tested ChoosePixelFormat and an ordinary compatibility
    # context instead; a modern graphics driver still exposes its GL features.
    glimp = OUT / "neo" / "sys" / "win32" / "win_glimp.cpp"
    text = glimp.read_text(encoding="utf-8")
    text = replace_once(text,
        '\tGLW_GetWGLExtensionsWithFakeWindow();',
        '\tGLW_GetWGLExtensionsWithFakeWindow();\n'
        '\t// Avoid calling WGL extensions acquired on a destroyed fake context.\n'
        '\twglChoosePixelFormatARB = NULL;\n'
        '\twglCreateContextAttribsARB = NULL;\n'
        '\tcommon->Printf("Ashen Meridian: Win32 OpenGL compatibility context\\n");',
        'win_glimp.cpp/stale-WGL-pointers')
    text = replace_once(text,
        'static HGLRC CreateOpenGLContextOnDC( const HDC hdc, const bool debugContext ) {\n',
        'static HGLRC CreateOpenGLContextOnDC( const HDC hdc, const bool debugContext ) {\n'
        '\tif ( wglCreateContextAttribsARB == NULL ) {\n'
        '\t\treturn qwglCreateContext( hdc );\n'
        '\t}\n',
        'win_glimp.cpp/legacy-compat-context')
    # A separate stereo probe calls GLW_ChoosePixelFormat unconditionally
    # even when WGL_ARB_pixel_format is unavailable. This was the immediate
    # call site in the second Windows minidump (GLW_ChoosePixelFormat+0x99).
    text = replace_once(text,
        'if ( GLW_ChoosePixelFormat( win32.hDC, parms.multiSamples, true ) != -1 ) {',
        'if ( wglChoosePixelFormatARB != NULL && '
        'GLW_ChoosePixelFormat( win32.hDC, parms.multiSamples, true ) != -1 ) {',
        'win_glimp.cpp/guard-stereo-query')
    text = replace_once(text,
        'static int GLW_ChoosePixelFormat( const HDC hdc, const int multisamples, const bool stereo3D ) {',
        'static int GLW_ChoosePixelFormat( const HDC hdc, const int multisamples, const bool stereo3D ) {\n'
        '\tif ( wglChoosePixelFormatARB == NULL ) { return -1; }',
        'win_glimp.cpp/guard-ARB-pixel-format')
    glimp.write_text(text, encoding="utf-8")
    # A missing shader-language string means there is no usable OpenGL 2+
    # context. Report the graphics requirement before the 2012 renderer passes
    # a NULL pointer to atof() and terminates with c0000409.
    renderer = OUT / "neo" / "renderer" / "RenderSystem_init.cpp"
    text = renderer.read_text(encoding="utf-8")
    text = replace_once(text,
        '\tglConfig.extensions_string = (const char *)qglGetString( GL_EXTENSIONS );',
        '\tglConfig.extensions_string = (const char *)qglGetString( GL_EXTENSIONS );\n'
        '\tif ( glConfig.version_string == NULL || glConfig.shading_language_string == NULL ) {\n'
        '\t\tcommon->FatalError("Ashen Meridian requires an OpenGL 2.0+ driver with GLSL. Windows CI must use Mesa llvmpipe.");\n'
        '\t}',
        'RenderSystem_init.cpp/validate-GLSL')
    # Trace the render initialization separately. Mesa LLVMpipe may spend
    # significant time compiling shaders on a hosted Windows worker.
    text = replace_once(text, '#pragma hdrstop', '#pragma hdrstop' + chr(10) + trace_header,
                        'RenderSystem_init.cpp/trace-header')
    marker = 'void idRenderSystemLocal::Init() {'
    start = text.index(marker)
    stop = text.index('void idRenderSystemLocal::Shutdown()', start)
    section = text[start:stop]
    for label, call in (
        ("cvars", "R_InitCvars()"),
        ("commands", "R_InitCommands()"),
        ("images", "globalImages->Init()"),
        ("cinema", "idCinematic::InitCinematic( )"),
        ("materials", "R_InitMaterials()"),
        ("models", "renderModelManager->Init()"),
        ("swap", "SwapCommandBuffers( NULL, NULL, NULL, NULL )"),
    ):
        token = call + ";"
        section = replace_once(section, token,
            'MeridianEngineStage("renderer.before.' + label + '");' + chr(10) +
            chr(9) + token + chr(10) +
            'MeridianEngineStage("renderer.after.' + label + '");',
            "RenderSystem_init.cpp/" + label)
    text = text[:start] + section + text[stop:]
    renderer.write_text(text, encoding="utf-8")
    pack_assets(ROOT / "Resource", OUT / "base", staged / "generated" / "AtlasDimensions.hpp")
    # Bring the original world references and exported maps into the native base.
    references = OUT / "base" / "meridian-source" / "maps"
    references.mkdir(parents=True, exist_ok=True)
    for name in ("mapa metroidvania.png", "como debe usar los sprites.png"):
        if (ROOT / name).is_file():
            shutil.copy2(ROOT / name, references / name)
    map_exports = ROOT / "Builds" / "Maps"
    if map_exports.is_dir():
        for name in ("world-map-data.json", "map-drawing.json",
                     "mapa-completo.png", "mapa-completo.svg"):
            source = map_exports / name
            if source.is_file():
                shutil.copy2(source, references / name)
    print(f"Desktop staging ready: {OUT}")
    print("Engine hooks: idGameLocal, idCommonLocal::Draw and CreateMainMenu; native standalone startup.")
    print("Not compiled, tested, or verified playable. Build with a compatible Windows toolchain.")

if __name__ == "__main__":
    main()
