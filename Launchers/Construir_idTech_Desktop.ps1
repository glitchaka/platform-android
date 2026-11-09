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
$GameRoot = Join-Path $Root 'build/desktop-idtech4'
$Bundle = Join-Path $GameRoot 'game-package'
$Bin = Join-Path $GameRoot 'build/Win32/Release/Doom3BFG.exe'
if (-not (Test-Path $Bin)) { throw "Build produced no native executable: $Bin" }
New-Item -Path $Bundle -ItemType Directory -Force | Out-Null
Copy-Item $Bin (Join-Path $Bundle 'Doom3BFG.exe') -Force
Copy-Item (Join-Path $GameRoot 'base') (Join-Path $Bundle 'base') -Recurse -Force
Copy-Item (Join-Path $Root 'native/packaging/Ejecutar_Ashen_Meridian.bat') $Bundle -Force
Write-Host "Native Windows game assembled at: $Bundle"
