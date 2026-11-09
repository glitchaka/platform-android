# Ashen Meridian

## Version nativa Windows (motor idTech 4)

`platform-android` es el destino de la migracion y `DOOM-3-BFG-GES`
es el motor de origen. `Launchers/Ejecutar_Juego.bat` inicia exclusivamente
el ejecutable C++ idTech 4. Debe estar en
`Builds/Desktop/AshenMeridian/` (con `Doom3BFG.exe` y `base/`)
o en `build/desktop-idtech4/game-package/` tras compilar localmente.

GitHub Actions genera el paquete Windows. La validacion automatica
comprueba compilacion, arranque, cuadros del tutorial y movimiento/disparo
durante la ejecucion nativa. No sustituye una partida completa humana.
Las secciones siguientes describen la version original; el APK existente
no utiliza el motor idTech.

## Proyecto original

## Zonas en el editor y nuevos tilesets (0.4.0)

`Scenes/main.tscn` muestra el Tutorial junto al origen al abrirlo en 2D. Selecciona **World → Environment → LevelBuilder** y cambia **Preview Room** en el inspector para ver otra sala. **Preview Tileset** permite comparar los siete estilos nuevos sin cambiar la partida; **Segun zona** recupera el aspecto real. **Actualizar vista** reconstruye la previsualización.

También puedes abrir directamente cualquiera de las **55 escenas de `Scenes/Zonas/`**, organizadas por región, para identificar la sala que quieres retocar. Son previsualizaciones del escenario procedural, no mapas de colisiones independientes. `Scenes/mapa_zonas.tscn` muestra el conjunto cerca del origen. Las plataformas que ves comparten sus rectángulos con las colisiones del juego.

Se usan los atlas de `Resource/tilesets/` a escala nativa, sin modificar sus PNG. Retoques iniciales: **Gruta** (`moss_depths`, musgo), **Abismo oeste** (`deep_west`, roca), **Plaza** (`city_square`, ladrillo) y **Depósito** (`reservoir`, caverna). El nuevo **Alba** combina ladrillo, bosque y escarcha; los props añaden plantas, rocas y vasijas. Brasa también está disponible en el selector de previsualización. La asignación que usa el juego está en `Scripts/world_data.gd` y los recortes en `Scripts/terrain_tiles.gd`.

Tras completar las cinco misiones se abre la puerta **ALBA**, a la derecha del **Trono**. Lleva al Umbral (descanso y tienda), Jardín (plataformas y tesoro) y Santuario (guardián y cofre de 60 monedas). El mapa y el diario indican el acceso. Las partidas que ya terminaron las misiones lo desbloquean al cargar, sin reiniciar. La prueba de tres ecos del Trono sigue disponible.

Para revisar el acceso sin repetir misiones, ejecuta **`Launchers/Probar_Zona_Final.bat`**. Abre una partida de prueba junto a la puerta del Trono, con controles táctiles y `Tests/aurora_preview_save.json` como guardado separado. No carga ni modifica `meridian_save.json`.

Validación de esta revisión: `Tests/final_zone_test.gd`, `Tests/editor_preview_test.gd` (con `--editor`), pruebas existentes de progresión, mundo, postgame y saltos. Capturas: `--script tools/capture_requested.gd -- --aurora --touch`.

El juego abre en el menú principal: **Nuevo juego**, **Cargar** y **Salir**. Nuevo juego reemplaza la partida anterior sin respaldo y reinicia todas las habilidades, monedas, llaves, encargos y compras. Cargar recupera el progreso en el último descanso; queda desactivado si no hay un guardado válido. Abrir o cerrar el menú principal no crea ni sobrescribe una partida.

Durante la partida, **Esc** abre la pausa con **Volver al juego**, **Menú principal** y **Salir del juego**. Las dos salidas guardan el progreso antes de abandonar la partida. También se guarda al cerrar la ventana. Si no se puede guardar, la sesión permanece abierta y se muestra el error. Los menús aceptan W/S o flechas para elegir, Enter/E/Espacio para aceptar, y clic o toque sobre una opción. Esc reanuda la partida; si la tienda, el mapa o el diario están abiertos, Esc cierra primero esa pantalla.

Resolución lógica conservada: **320 × 180 (16:9)**. Ventana: **960 × 540**. Los recortes de los cinco spritesheets originales de `Resource` se dibujan a tamaño nativo, con filtrado nearest; no se modificaron las imágenes.

`Scripts/sprite_atlas.gd` documenta los recortes. Las filas del jugador contienen fotogramas de 8 × 8 para distintas direcciones. Las plataformas combinan una franja superior de 8 píxeles con bordes independientes, siguiendo `como debe usar los sprites.png`. Los árboles y las plantas se recortan completos y se apoyan sobre la superficie, sin invadir plataformas ni puertas.

La interfaz usa exclusivamente recortes de `Resource/UI.png`: corazones, indicadores, marcos y también todas las letras y cifras. `Scripts/pixel_ui.gd` dibuja el alfabeto bitmap y los paneles con esquinas de tamaño nativo. No usa fuentes de Godot, controles de tema ni barras dibujadas para el HUD. Las monedas y recompensas del mundo usan `Collectables.png`; las cajas, mecanismos y puestos usan `Tiles.png`. Los cinco PNG originales permanecen intactos.

Se respeta el alfa original de todos los PNG. Los colores RGB ocultos bajo píxeles transparentes no se hacen visibles: hacerlo engrosaba los contornos y rellenaba huecos de los sprites. Las texturas se utilizan directamente, sin reconstrucción en memoria. Los PNG originales permanecen intactos.

## Controles

- A/D o flechas: moverse.
- Espacio/W/arriba: saltar; segundo salto al obtener la habilidad.
- J: disparar al frente; los proyectiles dañan enemigos, rompen cajas y activan mecanismos.
- E/abajo: hablar, comprar, activar mecanismos, abrir cofres, descansar o cruzar una puerta cercana.
- Shift/K: impulso después de desbloquearlo.
- M/Tab: abrir/cerrar el atlas y pausar la acción.
- Q: abrir/cerrar Encargo, Logros y Aspectos; pausa la acción.
- Esc: menú de pausa, con regreso al inicio y salida del juego.
- F: usar el frasco cargado o un tónico. V: activar/silenciar audio.
- En la tienda: W/S o arriba/abajo para elegir, E/Enter para comprar y Esc para salir. El mundo queda en pausa mientras eliges.

## Mundo

Las 52 salas originales reinterpretan la distribución de `mapa metroidvania.png`: Tutorial y Pueblo arriba, Cruces como núcleo, Hongos al oeste, Bosque de Huesos al este, Ciudad en Ruinas abajo, Palacio Blanco al extremo oeste y dos ramales profundos opcionales. A ellas se suman las tres salas de Jardines del Alba tras las cinco misiones: **55 salas en total**. Las salas se cargan individualmente y se conectan mediante puertas marcadas con E. El atlas conserva la disposición regional de la referencia; los interiores son una adaptación jugable, no una copia exacta de cada boceto.

El atlas muestra la distribución completa desde el principio: las salas visitadas tienen el color de su zona; el resto aparece atenuado. Los iconos señalan tu sala, el siguiente objetivo, descansos y guardianes descubiertos. Las salas alargadas tienen desplazamiento horizontal o vertical. La geometría dibujada y las colisiones comparten una única definición en `level_builder.gd`; las plataformas permiten saltar desde abajo.

El tutorial incluye un mecanismo, un cofre cerrado, cajas y un enemigo. El guía del Pueblo paga **6 monedas** una sola vez al liberar el Nido. Recoger absolutamente todo en Tutorial y Pueblo da **13 monedas**. Hay como máximo 2 monedas sueltas por sala inicial y 3 en las demás; las cajas y enemigos normales pagan 1, los cofres iniciales 2, los comunes 4, los tesoros 8 y los cofres de guardianes 12. Cada enemigo se guarda individualmente para impedir cobros repetidos al salir antes de limpiar una sala.

La tienda tiene 12 opciones, con precios y requisitos visibles. Las compras fuertes requieren avanzar, aunque ya tengas monedas de una partida anterior.

| Compra | Monedas | Requisito y efecto |
| --- | ---: | --- |
| Cañón reforzado | 55 | Vencer al Príncipe de Huesos. Daño por bala: 2. |
| Disparo rápido | 85 | Vencer al guardián real y obtener impulso. Mantener disparo: intervalo 0,125 s. |
| Imán | 20 | Liberar el Nido. Recogida de monedas a 26 píxeles. |
| Frasco | 30 | Liberar el Nido. Cura 2 corazones y recarga gratis en descansos. |
| Corazón extra | 65 / 100 | Vencer a Huesos y visitar 18 salas. Dos compras; máximo total 8 corazones incluyendo exploración. |
| Curación | 3 | Recupera toda la salud. Los bancos también curan gratis. |
| Tónico de viaje | 6 | Liberar el Nido. Consumible: cura 2; capacidad inicial 3. |
| Bolsa de tónicos | 26 | Huesos y 18 salas. Capacidad de tónicos: 5. |
| Amuleto guardián | 70 | Guardián real e impulso. Absorbe un golpe, recarga al descansar. |
| Aspecto Brasa | 18 | Liberar el Nido. Color coral y estela de impulso. |
| Aspecto Tormenta | 35 | Huesos y 18 salas. Color azul y estela de impulso. |
| Aspecto Estelar | 50 | Completar la aventura. Color rosado y estela de impulso. |

F o el corazón táctil usa primero el frasco cargado y después un tónico. Con salud completa no consume nada. Las compras únicas y los límites de inventario impiden pagar por objetos que no se pueden aprovechar. Las existencias, cargas y compras se guardan.

Las salas incluyen recorridos de monedas, cofres, mecanismos, patrullas terrestres y enemigos voladores. Los guardianes avisan con una exclamación antes de cargar. Las cajas rotas, monedas recogidas, mecanismos y cofres abiertos conservan su estado al salir y volver.

Obtén doble salto en el cofre de la Copa de Hongos e impulso en la Aguja de Ciudad. El **Príncipe de Huesos** y el **guardián real** dejan sus llaves visibles en el suelo al morir. Recoger ambas abre la puerta de Hongos al Palacio Blanco. Cada arena tiene además un cofre visible: se abre al vencer al guardián y **no pide llaves**. Los antiguos tesoros de Huesos y Ruinas siguen existiendo como recompensas en monedas.

Las llaves sin recoger reaparecen al volver a la arena, morir o cargar. Las recogidas no se duplican. Si una partida antigua tenía al jefe muerto pero no su llave, puede recuperarla volviendo a su arena; las llaves obtenidas en los antiguos cofres se conservan. El cofre del trono completa la aventura y permite seguir explorando.

## Logros y aspectos

Q abre Ruta, Logros, Aspectos, Armas y T?tulos. A/D cambia pestaña, W/S selecciona y E equipa. En Android se tocan las pestañas, las filas y ELEGIR. Hay **20 logros** por cofres, exploración, enemigos, habilidades, jefes, llaves y final. El diario muestra el requisito y el progreso de cada uno.

Cinco metas regalan aspectos: Nido → Ámbar, doble salto → Musgo, Huesos → Marfil, guardián real → Violeta y final → Amanecer. Se suman el original y tres aspectos de tienda. Se tintan los fotogramas originales del personaje; los aspectos de tienda y Amanecer añaden una estela al impulsarse. No alteran el combate.

## Audio e interfaz móvil

11 temas originales de chiptune: inicio, Tutorial, Pueblo, Cruces, Nido, Hongos, Huesos, Ruinas, Palacio, Profundidades y combate de guardianes. La música continúa al cambiar de habitación dentro de la misma zona. Las transiciones entre mundos se funden; pausa, tienda y diario reducen el volumen. 27 efectos cubren salto, aterrizaje, doble salto, impulso, disparos, golpes, daño, muerte, monedas, cajas, mecanismos, cofres, llaves, curación, compras, menús y logros. V o VOL en el menú activa/silencia el sonido. Las fuentes reproducibles están en `tools/generate_audio.py`; no hay muestras externas. Los cinco efectos nuevos de armas se generan con `tools/generate_weapon_audio.py`.

En Android los controles se activan automáticamente. En escritorio se previsualizan añadiendo `-- --touch` al lanzamiento:

- Joystick translúcido abajo, junto al borde izquierdo, con zona muerta y cambio continuo de dirección.
- Salto grande abajo, junto al borde derecho; disparo encima y acción contextual a la izquierda del salto. Impulso encima de acción y curación abajo a su izquierda, con zonas de toque separadas. La distribución sigue la corrección de controles del usuario.
- Iconos flotantes de `UI.png` con siluetas claras, centros transparentes y áreas de toque mayores que el dibujo. El salto tiene un doble contorno verde tenue. Los botones de habilidades se muestran cuando están disponibles.
- Mapa, diario y pausa arriba a la derecha. Tienda, vestuario y todos los menús aceptan toques.
- Los avisos son translúcidos, ajustan su tamaño al texto y se desvanecen en 1,5–2,8 segundos. Los objetivos siguen disponibles en el diario. No hay una franja permanente sobre el escenario.
- Se permite mover, saltar y disparar con varios dedos. Pausar, cambiar de sala o enviar Android al fondo libera los toques para evitar acciones atascadas. Al pasar al fondo se guarda y se suspende el audio.

El diseño de HUD y controles se ajustó a la imagen `Resource/CORFRECCIONES VISUALES` y a la referencia de controles flotantes proporcionada por el usuario. Los marcos, letras, iconos y píxeles de los contornos proceden de `UI.png`; no hay controles con tema nativo de Godot. El icono Android renderiza el sprite original del personaje.

El progreso se guarda en `user://meridian_save.json`: encargos, compras, objetos, habilidades, tesoros, salas visitadas y guardianes. Los guardados anteriores siguen siendo legibles; se conservan sus llaves, monedas y habilidades. Antes de esta revisión se guardó una copia de los scripts en `.recovery/before-ui-content`.

## Verificación

`Godot_v4.7.2-stable_win64_console.exe --headless --path . --script Tests/world_test.gd`

Comprueba transparencia original, conexión de las 52 salas, plataformas/recompensas/enemigos dentro de sus límites, aparición sobre suelo, bloqueos de habilidades y guardianes, guardado/carga y aterrizaje sobre plataformas. El guardado de prueba usa `Tests/test_save.json`, sin cargar la partida del usuario. Sin `--headless`, también genera capturas de salas anchas, estrechas y del atlas en `Tests`.

`Godot_v4.7.2-stable_win64_console.exe --headless --path . --script Tests/content_test.gd`

Comprueba disparos, cajas, mecanismos, cofres, pagos únicos, compras, falta de dinero, curación, encargo, las dos llaves, final, persistencia, pausa y que ningún objeto tape la interacción de una salida.

`Godot_v4.7.2-stable_win64_console.exe --headless --path . --script Tests/traversal_test.gd`

Simula la física real del salto inicial para verificar que las 392 plataformas de las 55 salas sean alcanzables. `tools/capture_requested.gd` genera capturas reales en `Tests/content_*.png`, con guardado de prueba separado. Estas verificaciones no cargan ni sobrescriben la partida personal.

`Godot_v4.7.2-stable_win64_console.exe --headless --path . --script Tests/shop_test.gd`

Comprueba el menú mediante teclas, compras únicas, falta de dinero, daño real, disparo automático, recogida con imán, uso y recarga del frasco, servicios anteriores y compatibilidad con partidas previas. La captura visual de la tienda se ejecuta con `--script tools/capture_requested.gd -- --shop` y genera `Tests/shop_*.png`.

`Godot_v4.7.2-stable_win64_console.exe --headless --path . --script Tests/menu_test.gd`

Comprueba inicio sin guardado, teclado y ratón, reinicio completo, carga, pausa de movimiento/combate/animación, prioridad de Esc, guardados inválidos y fallos al escribir. `Tests/menu_exit_probe.gd` prueba en procesos separados las salidas reales desde inicio, pausa y cierre de ventana. Las capturas de los menús se generan con `--script tools/capture_requested.gd -- --menus` en `Tests/menu_*.png`.

`Godot_v4.7.2-stable_win64_console.exe --headless --path . --script Tests/progression_test.gd`

52 comprobaciones de economía inicial y bloqueos, llaves físicas y cofres, recuperación de partidas antiguas, logros/aspectos, consumibles, escudo, música por mundo, multitáctil con eventos reales, joystick, compra/equipado táctiles, desaparición de avisos y ciclo de pausa de Android. Las capturas actualizadas se generan con `--script tools/capture_requested.gd -- --progression --touch`.

## Android

APK instalable: `Builds/Android/AshenMeridian.apk`. Compilación de depuración firmada, para ARM de 32 y 64 bits, Android 7 o superior y OpenGL ES 3. Los sprites se mantienen nítidos en formato horizontal 16:9. No solicita acceso a Internet.

Reconstruir: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File Launchers/Exportar_Android.ps1`. Consulte `ANDROID.md` para los archivos de la herramienta local y la instalación.

Se verificaron firma, manifiesto, recursos incluidos y las pantallas reales en escritorio. No había un dispositivo Android conectado durante la validación; la prueba física de instalación, audio y ergonomía queda pendiente.

## Postgame y arsenal

Cinco misiones encadenadas despu?s del final recorren las 52 salas. Se a?aden seis armas con proyectiles visibles, durabilidad y tres mejoras por arma; tiendas y taller junto a los seis guardados; ocho t?tulos equipables y desaf?os repetibles que desbloquean tres armas ?nicas. Consulta [POSTGAME.md](POSTGAME.md) para rutas, precios, condiciones y bonificaciones.

`Tests/postgame_test.gd` comprueba objetivos f?sicos, orden de misiones, todas las salas y tiendas, da?o real, dispersi?n, penetraci?n, quemaduras, r?fagas, desgaste, mejoras, t?tulos, desaf?os, controles t?ctiles y persistencia. Capturas: `--script tools/capture_requested.gd -- --postgame --touch`.
