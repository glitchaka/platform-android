# Integracion nativa de Ashen Meridian sobre DOOM 3 BFG

Destino: glitchaka/platform-android (main).
Origen: glitchaka/DOOM-3-BFG-GES (master,
revision 1caba1979589971b5ed44e315d9ead30b278d8b4).

La simulacion de juego esta en native/core (C++). El motor se incorpora por
submodulo en vendor/doom3-bfg. La preparacion crea una copia del motor en
build/desktop-idtech4, enlaza el codigo de Meridian y empaqueta los recursos
independientes en formatos que lee idTech 4.

El render utiliza idRenderSystem e idMaterial, y la entrada idKeyInput.
No se usa un segundo motor de videojuegos.

Los recursos comerciales del DOOM 3 BFG no vienen con el codigo GPL; se
suministran materiales propios para las rutas basicas del renderer. Se
conservan los sprites, sonidos y mapa propios de Ashen Meridian.

Limitaciones sin resolver: arranque hasta el primer cuadro jugable, paridad
de toda la interfaz/sonido, migracion del antiguo guardado, pruebas de la
campana completa y port Android nativo. La compilacion por si sola no
demuestra jugabilidad.
