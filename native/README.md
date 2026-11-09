# Native desktop migration — Ashen Meridian -> DOOM 3 BFG (idTech 4)

## Estado

**Migracion en desarrollo.** CI compila el ejecutable Windows y verifica
arranque; el chequeo ampliado exige cuadros reales del tutorial, simulacion
de movimiento y disparos. Una partida completa y Android idTech todavia no
estan certificados. Este directorio
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
GitHub Actions compila la version Windows y crea `game-package/` con
`Doom3BFG.exe`, `base/` y un lanzador nativo. En un ejecutable del motor que consiga arrancar, se inicia la partida nativa\nautomaticamente; los comandos de consola disponibles son `meridian_start`,
`meridian_load` y `meridian_stop`. No es necesario abrir una sesion de DOOM: `common_frame.cpp` presenta la capa\nnativa aun sin un mapa comercial cargado.

## Limitaciones que impiden afirmar que esta terminado

1. El motor fuente es una version Windows antigua que requiere adaptaciones de
   compilacion y datos base. No hay binario comprobado.
2. Se ha incorporado un arranque alternativo y directo en `idCommonLocal::Draw`\n   y se omite el menu original en modo nativo. Sigue sin estar compilado ni\n   probado en un ejecutable Windows; pueden existir dependencias iniciales del motor.
3. El mapa, movimiento, combate basico y progreso estan portados, pero la tienda,
   las mejoras y el menu completo de las seis armas, postgame, todas las variantes de enemigos, HUD, audio
   y contenido de las 55 salas siguen necesitando paridad con el juego original.
4. Los sprites se convierten al formato del motor, pero el render visual actual
   utiliza geometria coloreada y el primer fotograma del jugador. Faltan
   capas de escenario y animaciones completas.
5. El archivo de guardado nativo es nuevo (`meridian-native.save`); requiere
   migracion del guardado JSON original.
6. Solo despues de cerrar y verificar esta version nativa corresponde preparar Android.

**El intento de arranque directo utiliza realmente los subsistemas del motor idTech 4.**\nNo se afirma que un submodulo por si mismo sea una migracion del motor.


## Runtime en Windows

El motor BFG legado enlaza contra DLL de DirectX de junio de 2010, especialmente XAudio 2.7, XInput 1.3 y X3DAudio 1.7. El SDK usado para compilar **no** instala necesariamente el runtime en una maquina destino. Se requiere instalar el paquete oficial **Microsoft DirectX End-User Runtimes (June 2010)** desde https://www.microsoft.com/en-us/download/details.aspx?id=8109. No se distribuyen DLL de Microsoft copiadas en el repositorio. La prueba CI instala el runtime en Windows antes de arrancar el ejecutable.

### Arsenal nativo (fase en curso)

La base C++ contiene ahora las seis armas y sus estadisticas originales (nivel, cadencia, alcance, rafaga, penetracion, quemadura y desgaste). Q alterna las armas disponibles. Se guarda propiedad, nivel y durabilidad en la revision 2 del archivo nativo, manteniendo lectura de la revision 1. La tienda permite acceder a escopeta y lanzallamas mediante interaccion directa si se cumplen los requisitos de progreso. Las armas unicas siguen pendientes de sus respectivas pruebas de posjuego. El menu completo de la tienda, mejoras y titulos no estan migrados.
