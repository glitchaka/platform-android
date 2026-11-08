# Native desktop migration — Ashen Meridian -> DOOM 3 BFG (idTech 4)

## Estado

**Migracion en desarrollo; no hay un juego nativo ejecutable verificado.** Este directorio
contiene una implementacion C++ independiente de la escena original, un adaptador que
se compila dentro de `Game_local.cpp` y una preparacion de recursos para el renderizador
idTech 4. El motor de la fuente original NO incluye los datos comerciales de DOOM 3 BFG.

## Codigo del juego

- `core/Types.hpp`: entidades, salas, entradas y geometria.
- `core/World.*`: 55 salas, 65 conexiones reales y generacion de plataformas, puertas,
  recompensas y adversarios mediante el catalogo exportado.
- `core/Game.*`: personaje, gravedad y colisiones unidireccionales, transiciones,
  llaves, bloqueos, cofres, curaciones, guardado/carga y camara.
- `core/Combat.*`: balas y comprobacion continua de impacto contra enemigos.
- `idtech/Bridge.cpp`: usa `idRenderSystem`, `idMaterial` e `idKeyInput` de
  idTech para dibujar y controlar la capa 2D de Ashen Meridian.
- `generated/RoomCatalog.inc`: topologia extraida de
  `Builds/Maps/world-map-data.json`, no inventada.
- `tools/pack_assets.py`: convierte los cinco atlas originales PNG a TGA sin alterar
  colores ni alfa; registra sus dimensiones y genera materiales idTech.
- `tools/prepare_desktop.py`: copia el codigo de DOOM 3 BFG a una zona de compilacion
  y enlaza `Bridge.cpp` en el juego C++ real sin modificar el repositorio fuente.

## Preparacion en Windows

Se requiere una version de Visual Studio / MSBuild capaz de compilar el antiguo
proyecto Windows de `DOOM-3-BFG-GES`, el SDK de DirectX que cita su README,
Python y Pillow. La compatibilidad de esa solucion antigua con compiladores
actuales NO ha sido verificada.

```powershell
git submodule update --init --recursive
python -m pip install pillow
powershell.exe -NoProfile -ExecutionPolicy Bypass -File Launchers/Construir_idTech_Desktop.ps1
```

La preparacion crea `build/desktop-idtech4/`, fuera del control de versiones.
La compilacion NO se ha realizado en esta sesion. En un ejecutable que logre iniciar
una partida en el motor, los comandos incorporados son `meridian_start`,
`meridian_load` y `meridian_stop`. Se necesita arrancar el motor e ingresar
a una sesion de juego para que se ejecute `idGameLocal::Draw`.

## Limitaciones que impiden afirmar que esta terminado

1. El motor fuente es una version Windows antigua que requiere adaptaciones de
   compilacion y datos base. No hay binario comprobado.
2. El puente actualmente se engancha al dibujo de una sesion de juego existente:
   falta un arranque autonomo directamente en Ashen Meridian y eliminar la
   dependencia de mapas/GUI originales.
3. El mapa, movimiento, combate basico y progreso estan portados, pero la tienda,
   las seis armas completas, postgame, todas las variantes de enemigos, HUD, audio
   y contenido de las 55 salas siguen necesitando paridad con el juego original.
4. Los sprites se convierten al formato del motor, pero el render visual actual
   utiliza geometria coloreada y el primer fotograma del jugador. Faltan
   capas de escenario y animaciones completas.
5. El archivo de guardado nativo es nuevo (`meridian-native.save`); requiere
   migracion del guardado JSON original.
6. Solo despues de cerrar y verificar esta version nativa corresponde preparar Android.

No se afirma que un submodulo por si mismo sea una migracion del motor.
