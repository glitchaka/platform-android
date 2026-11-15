# Ashen Meridian — juego nativo C++ sobre idTech 4

Destino: glitchaka/platform-android, rama main.
Motor fuente: glitchaka/DOOM-3-BFG-GES, submodulo vendor/doom3-bfg.
Este repositorio ya no contiene GDScript, escenas de Godot ni exportacion Godot.

## Arquitectura

El codigo de native/core implementa el mundo, las 55 salas, 65 conexiones, personaje,
colisiones, enemigos, combate, arsenal, tienda, progresion y postgame.
Navigation.hpp gestiona el menu nativo, pausa, atlas y diario.
Map.hpp y generated/MapCatalog.inc preservan las coordenadas originales.
native/idtech/Bridge.cpp dibuja con idRenderSystem e idMaterial y lee entrada nativa.
native/tools/pack_assets.py convierte los PNG originales y empaqueta sonidos.
native/tools/prepare_desktop.py prepara el motor BFG para el juego C++.

Los sprites y sonidos originales permanecen en Resource/; el mapa y su topologia
se conservan en Builds/Maps/world-map-data.json.

## Compilar en Windows

Requisitos: Visual Studio Build Tools C++, SDK DirectX (junio 2010), runtime
DirectX (junio 2010), Python 3 y Pillow.

Desde la raiz del repositorio:
    git submodule update --init --recursive
    python -m pip install pillow
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File Launchers/Construir_idTech_Desktop.ps1

La carpeta del juego nativo se genera en build/desktop-idtech4/game-package/.
Launchers/Ejecutar_Juego.bat solo inicia el ejecutable C++ del motor idTech.

## Estado de desarrollo

La compilacion Windows esta disponible, pero aun falta comprobar que el arranque
alcance el primer cuadro de Ashen Meridian. Tampoco se ha verificado una partida
completa. Esta revision no debe considerarse jugable ni terminada sin esas pruebas.

## Android

El APK antiguo no utilizaba idTech y fue retirado. Falta un port Android NDK
del motor y de las entradas, audio y ciclo de vida; consulte ANDROID.md.

## Licencia

El codigo derivado del motor DOOM 3 BFG debe cumplir la GPL y los avisos
que conserva el submodulo del origen.
