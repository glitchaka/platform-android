# Validación de la versión Android y progresión

Mapa y portales 0.4.1 (código Android 7), 21 de septiembre de 2026:

- `portal_map_test.gd`: **2608 comprobaciones, 0 fallos**. Se accionaron físicamente los 130 portales dirigidos (65 enlaces en ambos sentidos), verificando destino y aparición junto al portal de retorno. Registro por sala y número en `portal-map-audit.json`.
- Se comprobaron los bloqueos por región, doble salto, impulso, dos llaves, jefe vivo y las cinco misiones. La interacción, los marcadores del escenario y el mapa comparten el mismo cálculo de bloqueo.
- Se conservaron todas las posiciones y destinos originales. La numeración procede de `world_data.gd`; el atlas y el mapa exportado usan las mismas rutas entre portales, sin atravesar otras salas. Las 55 cajas del atlas ya no se solapan por un tamaño mínimo artificial.
- Navegación táctil y por teclado del mapa comprobada. Consultar una sala no mueve al jugador. Capturas OpenGL revisadas: `map_portals_*.png`, `map_atlas_*.png`, `map_numbered_portal.png`; registro visual sin errores.
- Regresiones: progresión de zonas **362**, zona final **27** y controles/progresión **52**, todas sin fallos.
- `Builds/Maps/mapa-completo.png` y `.svg` actualizados con los 130 números de portal. El generador contrasta los destinos con el registro de cruces reales.
- APK **0.4.1**, código **7**, reconstruido; firmas v2/v3 válidas, ARM32/ARM64, SDK mínimo 24. SHA-256 actualizado. Verificado en Godot de escritorio; no probado en un teléfono físico.

Zonas y tilesets 0.4.0 (código Android 6), 21 de septiembre de 2026:

- `zone_progression_test.gd`: **362 comprobaciones, 0 fallos**. Las cinco misiones conservan sus 52 objetivos; las tres salas del Alba solo son accesibles al completarlas.
- `final_zone_test.gd`: **27 comprobaciones, 0 fallos**. Entrada y regreso mediante interacción real, bloqueo antes de completar las cinco misiones, diario/mapa, descanso y tienda, guardián, cofre de 60 monedas sin duplicación, guardado/carga y acceso para partidas completadas de la versión anterior.
- `postgame_test.gd`: **498 comprobaciones, 0 fallos**; `progression_test.gd`: **52 comprobaciones, 0 fallos**, incluidos controles multitáctiles corregidos.
- `world_test.gd`: 55 salas conectadas y geometría, objetos y apariciones dentro de sus límites. `traversal_test.gd`: las **392 plataformas** se alcanzan con la física real del salto inicial.
- `editor_preview_test.gd` ejecutado con `--editor`: las 55 escenas en `Scenes/Zonas/` muestran plataformas junto al origen, y todas caben en la vista de conjunto; **0 fallos**. Esta prueba confirma `Engine.is_editor_hint() == true`.
- Se revisaron las capturas OpenGL `aurora_*.png`: las tres salas nuevas, puerta ALBA, cuatro salas retocadas, atlas y diario. El recorte del suelo del bosque/escarcha excluye los props del atlas. El registro visual no contiene errores.
- `tools/play_aurora.gd` arranca sin errores de script con acceso abierto y guardado de prueba independiente en `Tests/aurora_preview_save.json`. No usa el guardado personal.
- APK **0.4.0**, código **6**, exportado y firmado: firmas v2/v3 válidas, ARM32/ARM64, SDK mínimo 24. Los nuevos scripts y atlas están incluidos; las escenas de previsualización, pruebas y herramientas quedan excluidas. Hash actualizado en `Builds/Android/SHA256.txt`.
- Persisten los avisos conocidos de certificados y recursos al cerrar pruebas headless; el proceso de editor headless también avisa de recursos de editor al salir. No se probó en un teléfono físico.

Corrección de controles 0.3.1 (código Android 5), 21 de septiembre de 2026:

- Joystick junto al borde izquierdo; salto grande abajo a la derecha, disparo encima y acción a la izquierda del salto. Impulso y curación se separan de acción. Los cinco círculos de toque caben en 320 × 180 y no se superponen.
- `progression_test.gd`: **52 comprobaciones, 0 fallos**, con las posiciones corregidas y eventos reales de movimiento, salto y disparo simultáneos, interacción, pausa y ciclo de Android. La ejecución headless sigue emitiendo los avisos conocidos de certificados y recursos al cerrar.
- Capturas reales de Godot revisadas: `mobile_controls.png` y `mobile_controls_unlocked.png`, generadas con `--script tools/capture_requested.gd -- --controls --touch`. El registro visual no contiene errores.
- APK 0.3.1 reconstruido, versión y arquitecturas ARM32/ARM64 comprobadas; firma v2/v3 válida. SHA-256 actualizado en `Builds/Android/SHA256.txt`. Esta corrección se verificó en escritorio; no se probó en un teléfono físico.

Actualización 0.3.0 (código Android 4), 18 de septiembre de 2026:

- `postgame_test.gd`: **492 comprobaciones, 0 fallos**. Cinco misiones en orden, objetivos físicos en las 52 salas, seis tiendas junto a guardados, compras fuera del Pueblo, mejoras independientes y bloqueos, durabilidad/reparación/emergencia, penetración, dispersión con daño de todos los perdigones, quemadura, ráfagas temporizadas, títulos con bonos reales, desafíos fallidos y exitosos, muerte/abandono, controles táctiles, persistencia parcial/completa y reinicio.
- Pruebas anteriores de progresión (52), contenido, tienda, mundo y menús: pasan. Los valores fijos de vida del jefe en el test de tienda se sustituyeron por comprobaciones de daño sobre su nueva vida máxima; el toque de Aspectos se actualizó a su posición entre las cinco pestañas.
- Capturas reales con OpenGL en `postgame_*.png`: ruta, logros, armas, títulos, taller, guardado con tienda, mecanismo, prueba del Trono y cinco tipos de disparos. Se detectó y corrigió el dibujo de las balas detrás del escenario, utilizando una capa de proyectiles sobre los actores. `requested-visual.log` no contiene errores.
- APK 0.3.0 reconstruido y firmado; firmas v2 y v3 verificadas. Incluye los tres scripts nuevos y los 38 recursos de audio (11 músicas y 27 efectos), incluidos cinco efectos originales de armas. No incluye pruebas, herramientas ni copias de recuperación. ARM32/ARM64, mínimo SDK 24 y objetivo 36; alias MAIN/LAUNCHER presente.
- La inspección con `aapt2` advierte una referencia `themed_icon` ausente en los recursos de la plantilla. El icono principal y el alias de inicio están presentes; la exportación y la verificación de firma pasan. Sigue pendiente comprobar instalación y ejecución en un teléfono físico.

- `progression_test.gd`: 52 comprobaciones, 0 fallos. Incluye las dos llaves físicas, cofres, carga, partidas anteriores, compras bloqueadas, tónicos, amuleto, aspectos, logros, música por mundo y eventos multitáctiles a través de Input.
- `content_test.gd`: 0 fallos en interacciones, disparos, encargos, compras, persistencia, final y contenido de las 52 salas.
- `shop_test.gd`: 0 fallos en teclado, combate con mejoras, imán, frasco, precios, límites y guardados antiguos.
- `menu_test.gd`: 0 fallos, incluidas salidas reales en procesos separados y prioridad de los menús.
- `world_test.gd`: recorrido correcto de las 52 salas, geometría, alfa original, habilidades, guardado y aterrizaje.
- Capturas de Godot con OpenGL: HUD flotante, joystick, tienda, logros, aspectos, pausa, cofre del Príncipe y llave visible. `requested-visual.log` no muestra errores de script ni render.
- Exportación Android completada. Firma APK v2 y v3 válida, ARM de 32 y 64 bits, mínimo SDK 24, objetivo SDK 36, orientación horizontal y actividad de inicio presente. Los 38 recursos de audio están empaquetados; pruebas y herramientas quedan excluidas.

Las ejecuciones rápidas en modo headless emiten el aviso del almacén de certificados del entorno y advertencias de liberación de recursos de audio al cerrar. Las comprobaciones funcionales pasan; las capturas con el controlador real no muestran esas advertencias. No había dispositivo Android conectado, por lo que instalación, audio y ergonomía en un teléfono físico todavía no están validados.

El hash del APK final está en `Builds/Android/SHA256.txt`.
