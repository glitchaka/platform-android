# Android: Ashen Meridian 0.4.1

APK: `Builds/Android/AshenMeridian.apk`. Está firmado para pruebas e instalación directa; no es una publicación en Google Play. Copiar al teléfono, abrir y permitir la instalación desde la aplicación usada para abrirlo. Requiere Android 7 o posterior, OpenGL ES 3 y procesador ARM de 32 o 64 bits.

El juego se abre en horizontal con Nuevo juego, Cargar y Salir. Los controles táctiles se activan automáticamente. El botón Atrás cierra primero la tienda o el diario/mapa y luego controla la pausa. Enviar la aplicación al fondo guarda y pausa la partida; volver mantiene el menú de pausa abierto.

El mapa abre la lista de portales de la sala actual, numerados igual que en el escenario, de izquierda a derecha. Tocar una fila la selecciona y muestra su requisito; tocarla otra vez permite consultar la sala de destino sin mover al personaje. ATLAS muestra las conexiones de la sala seleccionada, META selecciona el objetivo y AQUÍ vuelve a la sala del personaje. En teclado: A/D cambia la vista, W/S selecciona y E consulta el destino.

## Reconstrucción en este equipo

Desde la raíz del proyecto:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File Launchers/Exportar_Android.ps1
```

La herramienta está aislada en `.android-build`: Godot 4.7.2 en modo portátil, plantillas oficiales, SDK Build Tools 35.0.1, Platform Tools y clave de depuración. Usa el JDK 21 ya instalado en este equipo. No cambia la configuración del editor Godot habitual. El registro de exportación queda en `Tests/android-export.log`.

Los archivos oficiales descargados se verifican contra los hashes de los catálogos mediante `tools/prepare_android.py`. Este script recompone la instalación local a partir de `.android-build/templates.tpz`, `build-tools.zip`, `platform-tools.zip`, `release.json` y `repository.xml`. Los catálogos proceden de Godot en GitHub y del repositorio Android de Google. Conserva `.android-build/debug.keystore` para que las siguientes versiones de prueba se puedan instalar como actualización.

`export_presets.cfg` excluye pruebas, capturas, herramientas, documentación y referencias. La música y los sonidos sí se incluyen. El icono de Android se renderiza desde `Player.png` y `UI.png` mediante `tools/capture_requested.gd -- --icons`; los atlas originales no se modifican.

## Verificación

- `apksigner verify --verbose` comprueba la firma del APK.
- `aapt dump badging` comprueba nombre, versión, SDK mínimo y arquitecturas.
- `Tests/progression_test.gd` prueba eventos multitáctiles simultáneos, joystick con zona muerta, interacción con la tienda, vestuario, guardado al fondo y liberación de controles.
- `Tests/mobile_*.png` muestra el render real de Godot, incluido el HUD flotante corregido.

No había teléfono conectado por ADB durante la validación. La instalación y la comodidad en pantalla física aún deben probarse en un dispositivo Android.

Documentación oficial consultada: [exportar Android en Godot 4.7](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_android.html).
