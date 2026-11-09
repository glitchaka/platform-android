@echo off
setlocal EnableExtensions
set "GAME=%~dp0"
if not exist "%GAME%\Doom3BFG.exe" (
    echo ERROR: falta Doom3BFG.exe.
    pause
    exit /b 1
)
if not exist "%GAME%\base\meridian" (
    echo ERROR: faltan recursos en base\meridian.
    pause
    exit /b 1
)
start "Ashen Meridian" /D "%GAME%" "%GAME%\Doom3BFG.exe" +set fs_basepath "%GAME%" +set r_fullscreen 0
