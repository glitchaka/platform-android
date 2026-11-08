$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
$exportEngine = Join-Path $projectRoot '.android-build/godot/Godot_v4.7.2-stable_win64_console.exe'
if (-not (Test-Path -LiteralPath $exportEngine)) { throw 'Falta preparar .android-build. Consulta ANDROID.md.' }
New-Item -ItemType Directory -Force 'Builds/Android' | Out-Null
& $exportEngine --headless --path $projectRoot --export-debug Android 'Builds/Android/AshenMeridian.apk' --log-file 'Tests/android-export.log'
if ($LASTEXITCODE -ne 0) { throw 'La exportacion fallo. Revisa Tests/android-export.log.' }
Write-Output 'APK creado: Builds/Android/AshenMeridian.apk'
