# Ashen Meridian

Proyecto Godot 4.7. Abrir `project.godot` o ejecutar `Launchers/Ejecutar_Juego.bat`.

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
- Q: abrir/cerrar los encargos y pausar la acción.
- Esc: menú de pausa, con regreso al inicio y salida del juego.
- F: usar el frasco curativo después de comprarlo.
- En la tienda: W/S o arriba/abajo para elegir, E/Enter para comprar y Esc para salir. El mundo queda en pausa mientras eliges.

## Mundo

52 salas jugables reinterpretan la distribución de `mapa metroidvania.png`: Tutorial y Pueblo arriba, Cruces como núcleo, Hongos al oeste, Bosque de Huesos al este, Ciudad en Ruinas abajo, Palacio Blanco al extremo oeste y dos ramales profundos opcionales. Las salas se cargan individualmente y se conectan mediante puertas marcadas con E. El atlas conserva la disposición regional de la referencia; los interiores son una adaptación jugable, no una copia exacta de cada boceto.

El atlas muestra la distribución completa desde el principio: las salas visitadas tienen el color de su zona; el resto aparece atenuado. Los iconos señalan tu sala, el siguiente objetivo, descansos y guardianes descubiertos. Las salas alargadas tienen desplazamiento horizontal o vertical. La geometría dibujada y las colisiones comparten una única definición en `level_builder.gd`; las plataformas permiten saltar desde abajo.

El tutorial incluye un mecanismo, un cofre cerrado, cajas y un enemigo antes de la salida al Pueblo. En el Pueblo, el guía encarga liberar el Nido: vencer al guardián y regresar permite cobrar 12 monedas una sola vez. La tienda cobra 3 monedas por curar o 12 por un corazón adicional, hasta seis. Los bancos curan gratis y fijan el punto de reaparición. Las monedas de las plataformas, cajas rompibles y cofres dan recursos para las compras.

El mercader abre un catálogo con seis opciones. Las mejoras permanentes se aplican al comprarlas y se guardan con la partida:

| Compra | Monedas | Efecto |
| --- | ---: | --- |
| Cañón reforzado | 20 | Cada bala causa 2 puntos de daño en lugar de 1. |
| Disparo rápido | 24 | Mantener J dispara automáticamente; el intervalo pasa de 0,25 a 0,125 segundos. |
| Imán de monedas | 14 | Amplía la distancia de recogida de 9 a 26 píxeles. |
| Frasco curativo | 18 | F restaura hasta 2 corazones. Una carga, recargable gratis en cualquier descanso. |
| Corazón extra | 12 | Suma un corazón y restaura la salud, hasta un máximo de 6. |
| Curación | 3 | Restaura toda la salud actual. |

Las mejoras adquiridas figuran como LISTO y no se pueden volver a cobrar. La tienda impide pagar una curación con salud llena o un corazón por encima del máximo. El frasco conserva su carga si se intenta usar con salud completa; su carga también se recupera al reaparecer en el descanso. Su estado vacío se conserva al guardar y cargar. Los guardados anteriores se cargan con las mejoras nuevas disponibles para comprar.

Las salas incluyen recorridos de monedas, cofres, mecanismos, patrullas terrestres y enemigos voladores. Los guardianes avisan con una exclamación antes de cargar. Las cajas rotas, monedas recogidas, mecanismos y cofres abiertos conservan su estado al salir y volver.

Obtén doble salto en el cofre de la Copa de Hongos e impulso en el de la Aguja de Ciudad. Estas habilidades abren ramales opcionales. Los guardianes de Huesos y de la Aguja Real protegen cofres con las **llaves de Huesos y Ruinas**: ambas abren la puerta al Palacio desde Hongos. Las llaves tienen un sprite visible, un cofre, un bloqueo y una entrada en el diario. El cofre del trono completa el objetivo y permite seguir explorando.

El progreso se guarda en `user://meridian_save.json`: encargos, compras, objetos, habilidades, tesoros, salas visitadas y guardianes. Los guardados anteriores siguen siendo legibles; se conservan sus llaves, monedas y habilidades. Antes de esta revisión se guardó una copia de los scripts en `.recovery/before-ui-content`.

## Verificación

`Godot_v4.7.2-stable_win64_console.exe --headless --path . --script Tests/world_test.gd`

Comprueba transparencia original, conexión de las 52 salas, plataformas/recompensas/enemigos dentro de sus límites, aparición sobre suelo, bloqueos de habilidades y guardianes, guardado/carga y aterrizaje sobre plataformas. El guardado de prueba usa `Tests/test_save.json`, sin cargar la partida del usuario. Sin `--headless`, también genera capturas de salas anchas, estrechas y del atlas en `Tests`.

`Godot_v4.7.2-stable_win64_console.exe --headless --path . --script Tests/content_test.gd`

Comprueba disparos, cajas, mecanismos, cofres, pagos únicos, compras, falta de dinero, curación, encargo, las dos llaves, final, persistencia, pausa y que ningún objeto tape la interacción de una salida.

`Godot_v4.7.2-stable_win64_console.exe --headless --path . --script Tests/traversal_test.gd`

Simula la física real del salto inicial para verificar que las 367 plataformas de las 52 salas sean alcanzables. `tools/capture_requested.gd` genera capturas reales en `Tests/content_*.png`, con guardado de prueba separado. Estas verificaciones no cargan ni sobrescriben la partida personal.

`Godot_v4.7.2-stable_win64_console.exe --headless --path . --script Tests/shop_test.gd`

Comprueba el menú mediante teclas, compras únicas, falta de dinero, daño real, disparo automático, recogida con imán, uso y recarga del frasco, servicios anteriores y compatibilidad con partidas previas. La captura visual de la tienda se ejecuta con `--script tools/capture_requested.gd -- --shop` y genera `Tests/shop_*.png`.

`Godot_v4.7.2-stable_win64_console.exe --headless --path . --script Tests/menu_test.gd`

Comprueba inicio sin guardado, teclado y ratón, reinicio completo, carga, pausa de movimiento/combate/animación, prioridad de Esc, guardados inválidos y fallos al escribir. `Tests/menu_exit_probe.gd` prueba en procesos separados las salidas reales desde inicio, pausa y cierre de ventana. Las capturas de los menús se generan con `--script tools/capture_requested.gd -- --menus` en `Tests/menu_*.png`.

La validación realizada es de escritorio. Este proyecto todavía no incluye controles táctiles ni un preset de exportación Android.
