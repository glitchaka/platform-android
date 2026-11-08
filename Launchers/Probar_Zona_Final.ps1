$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$previewEngine = Join-Path $projectRoot '.android-build/godot/Godot_v4.7.2-stable_win64.exe'
if (-not (Test-Path -LiteralPath $previewEngine)) { throw 'No se encontro Godot en .android-build/godot.' }
Start-Process -FilePath $previewEngine -ArgumentList @('--path', ('"' + $projectRoot + '"'), '--script', 'tools/play_aurora.gd', '--', '--touch') -WorkingDirectory $projectRoot -WindowStyle Normal
