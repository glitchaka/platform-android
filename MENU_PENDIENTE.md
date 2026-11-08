# Menús implementados

Implementados por pedido del usuario el 17 de septiembre de 2026. Ya no hay trabajo pendiente en este listado.

## Menú de inicio

- Nuevo juego: empezar desde cero y reemplazar el guardado anterior, sin conservar un respaldo.
- Cargar: continuar la partida guardada; indicar cuando no hay una partida disponible.
- Salir: cerrar el juego.

## Menú dentro de la partida

- Volver al juego.
- Salir al menú principal.
- Salir del juego.

Pausar la partida mientras el menú esté abierto. Guardar el progreso al salir de una partida hacia el menú principal o al escritorio, para que Cargar sea útil. Nuevo juego debe reiniciar también las mejoras de la tienda, el frasco, monedas, llaves, encargos, objetos y salas exploradas.

## Interfaz y controles

- Usar los marcos, iconos, letras y números de Resource/UI.png, mediante Scripts/pixel_ui.gd.
- Mantener la resolución lógica de 320 × 180 y los sprites originales.
- Esc abre el menú durante el juego. Si la tienda está abierta, Esc debe cerrarla primero.
- Comprobados nuevo juego, carga, regreso al menú, salida al escritorio y ausencia de filtraciones de input hacia la partida pausada en Tests/menu_test.gd.

La petición de reiniciar sin respaldo se cumple con Nuevo juego. Las partidas posteriores se guardan normalmente.
