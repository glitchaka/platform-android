@echo off
setlocal
set "PROJECT=%~dp0.."
set "GODOT="
where godot.exe >nul 2>nul && set "GODOT=godot.exe"
if not defined GODOT if exist "%ProgramFiles%\Godot\Godot.exe" set "GODOT=%ProgramFiles%\Godot\Godot.exe"
if not defined GODOT if exist "%ProgramFiles%\Godot\Godot_v4.exe" set "GODOT=%ProgramFiles%\Godot\Godot_v4.exe"
if not defined GODOT if exist "%LOCALAPPDATA%\Godot\Godot.exe" set "GODOT=%LOCALAPPDATA%\Godot\Godot.exe"
if not defined GODOT if exist "%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe" set "GODOT=%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe"
if not defined GODOT for /r "%LOCALAPPDATA%\Microsoft\WinGet\Packages" %%G in (Godot_v*_win64.exe) do if not defined GODOT set "GODOT=%%G"
if not defined GODOT (
  echo No se encontro Godot. Abre Godot manualmente y selecciona:
  echo %PROJECT%project.godot
  pause
  exit /b 1
)
start "Ashen Meridian - Editor" "%GODOT%" --editor --path "%PROJECT%"