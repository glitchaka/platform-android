$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $Root
python native/tools/prepare_desktop.py
if ($LASTEXITCODE -ne 0) { throw "Native staging failed." }
$Source = Join-Path $Root 'build/desktop-idtech4/neo/doom3.sln'
$Msbuild = Get-Command MSBuild.exe -ErrorAction SilentlyContinue
if (-not $Msbuild) {
    throw "MSBuild not found. Install Visual Studio C++ build tools and the dependencies required by the idTech 4 source."
}
& $Msbuild.Source $Source '/m' '/p:Configuration=Release' '/p:Platform=Win32'
if ($LASTEXITCODE -ne 0) { throw "Native idTech 4 compilation failed. See compiler output." }
Write-Host "Build succeeded. Check the generated executable and game data before declaring the game playable."
