# Integración de DOOM 3 BFG en platform-android

## Origen y destino

- **Destino:** `glitchaka/platform-android`, rama `main`; Ashen Meridian, Godot 4.7, 2D y Android.
- **Origen:** `glitchaka/DOOM-3-BFG-GES`, rama `master`, revisión `1caba1979589971b5ed44e315d9ead30b278d8b4`.
- El código del motor se enlaza completo como submódulo en `vendor/doom3-bfg`. El juego original permanece sin modificar. Para obtenerlo: `git submodule update --init --recursive`.
- El submódulo está excluido de la importación de Godot y del APK: el motor C++ no se compila ni ejecuta dentro de Godot.

## Qué se ha adaptado al juego actual

| Código origen de DOOM 3 BFG | Adaptación funcional en Godot |
| --- | --- |
| `neo/d3xp/Projectile.cpp` (ciclo del proyectil e impacto) | `Scripts/IdTech/projectiles.gd`: avance por tiempo, penetración, quemadura, eliminación de balas y efectos de impacto. |
| `neo/d3xp/Weapon.cpp` y trazados del motor | `Scripts/IdTech/trace2d.gd`: consulta de primer contacto y ordenación por fracción de recorrido contra enemigos y objetos. |
| `neo/d3xp/ai/AI.cpp` | Se conserva en el submódulo, sin portar por ahora. |
| `base/renderprogs/`, `neo/renderer/`, `neo/sound/` | Se conservan como referencia, sin ejecutar shaders OpenGL ni el backend de sonido C++ en Godot. |

`Scripts/main.gd` delega ahora la simulación de disparos a `Scripts/IdTech/projectiles.gd`. Se preservan las seis armas existentes, los sprites, sonidos, escenas, tiendas, lógica de misiones, interfaz táctil, progreso y formato de guardado.

**Cambio de comportamiento:** los impactos de un mismo segmento se resuelven en orden de contacto. Antes se procesaban los enemigos antes de comprobar los objetos, independientemente de cuál estuviera delante. La caja o mecanismo puede ahora interceptar un disparo antes que un enemigo situado detrás. La penetración mantiene sus límites actuales.

## Qué NO está portado

Esta integración no convierte un plataformas 2D en DOOM 3, no ejecuta idTech 4 nativamente en Android y no cambia la escena principal. La fuente original **no incluye los datos del juego** (mapas, modelos, texturas, sonidos o paquetes comerciales), tal como indica `vendor/doom3-bfg/README.txt`. No se pueden trasladar recursos ausentes del origen.

Un port nativo real exigiría un proyecto Android NDK, adaptar el arranque y ciclo de vida, el renderizador, los dispositivos de entrada y el backend de audio, además de disponer legalmente de los datos del juego. No se afirma que esas tareas estén completadas.

## Licencias y distribución

El submódulo conserva el aviso y la licencia GPL y términos adicionales propios del repositorio fuente (`COPYING.txt`, `README.txt`). El código de Godot no enlaza el ejecutable del motor C++; estas nuevas implementaciones 2D utilizan las ideas de trazado y ciclo de proyectiles, sin copiar código C++ literalmente. Si se construye y redistribuye un binario derivado del motor, hay que cumplir las licencias y avisos del código efectivamente incorporado.

## Verificación posterior a la subida

No se han compilado ni ejecutado pruebas durante esta primera integración. Comprobaciones previstas:

```powershell
git submodule update --init --recursive
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script Tests/idtech_trace_test.gd
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script Tests/postgame_test.gd
Godot_v4.7.2-stable_win64_console.exe --headless --path . --script Tests/progression_test.gd
```

Después de las pruebas del proyecto, exportar un nuevo APK. El APK existente en `Builds/Android/` pertenece a una compilación anterior y **no incorpora este cambio**.
