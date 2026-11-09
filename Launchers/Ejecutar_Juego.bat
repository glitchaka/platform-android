@echo off
setlocal EnableExtensions
set "ROOT=%~dp0.."
set "GAME=%ROOT%\Builds\Desktop\AshenMeridian"
if not exist "%GAME%\Doom3BFG.exe" set "GAME=%ROOT%\build\desktop-idtech4\game-package"
if not exist "%GAME%\Doom3BFG.exe" (
    echo ERROR: falta el ejecutable idTech de Ashen Meridian.
    echo Compila con Launchers\Construir_idTech_Desktop.ps1 o extrae
    echo el paquete Windows en Builds\Desktop\AshenMeridian.
    exit /b 1
)
if not exist "%GAME%\base\meridian" (
    echo ERROR: faltan los recursos nativos en "%GAME%\base\meridian".
    exit /b 1
)
start "Ashen Meridian" /D "%GAME%" "%GAME%\Doom3BFG.exe" +set fs_basepath "%GAME%" +set r_fullscreen 0
