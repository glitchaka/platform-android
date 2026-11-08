# Postgame, armas y taller

Al abrir el cofre del Trono comienza automáticamente la primera misión. También se activa al cargar una partida antigua que ya completó el final. No hace falta reiniciar.

Desde la versión 0.4.0, terminar las cinco misiones también abre una zona nueva: **Jardines del Alba**. La puerta está a la **derecha del Trono**, rotulada **ALBA**, y exige la Corona del Meridiano. Las partidas con las cinco misiones terminadas reciben el acceso al cargar.

La ruta es **Trono → Umbral del Alba → Jardín del Alba → Santuario del Alba**. El Umbral tiene banco de guardado y tienda; el Jardín incluye plataformas y tesoro; el Santuario contiene un guardián y un cofre de **60 monedas**, que solo se cobra una vez. Las tres salas se pueden recorrer en ambos sentidos. La prueba de los tres ecos permanece en el Trono.

`Launchers/Probar_Zona_Final.bat` permite revisar esta ruta inmediatamente en una partida de prueba con guardado separado.

Las cinco misiones se desbloquean una después de otra y, juntas, pasan por las 52 salas. Cada objetivo existe físicamente en su sala, tiene un número y un icono de misión. El diario muestra las salas pendientes; SUBIR/BAJAR selecciona un destino y MAPA lo destaca en el atlas.

| Misión | Recorrido | Objetivo | Recompensa |
| --- | --- | --- | --- |
| Rutas del Alba | Sendero, Pueblo y Cruces: 11 salas | Defender y activar puestos | 60 monedas, logro y título Caminante |
| Semillas de Vida | Accesos a Hongos, Hongos y Abismo oeste: 12 salas | Recuperar semillas en las plataformas, custodiadas por voladores | 85 monedas, logro y título Custodio |
| Deuda de Huesos | Accesos, Huesos y Pozo profundo: 10 salas | Vencer custodios y al eco del Príncipe, recuperar sus cofres | 110 monedas, logro y título Cazador de Ecos |
| Forja de la Ciudad | Ruinas y Ciudad profunda: 9 salas | Disparar a mecanismos azules, vencer guardianes y recoger piezas | 140 monedas, logro y título Maestro Artesano |
| Última Guardia | Accesos orientales y Palacio: 10 salas | Defender los accesos y vencer al eco del Trono | 180 monedas, logro, título del Meridiano y prueba final |

Los objetivos, mecanismos y guardianes completados se guardan individualmente. Abandonar una sala no duplica premios ni obliga a repetir objetivos completados.

## Armas

Q → ARMAS permite consultar y equipar. R cambia rápidamente entre armas; en Android se toca el indicador del arma en la parte superior. El HUD muestra nivel y durabilidad restante sobre 100. Todas las balas se dibujan por encima del escenario y tienen trayectorias reales.

| Arma | Cómo se consigue | Comportamiento |
| --- | --- | --- |
| Pistola | Inicial | Una bala. Nivel 2 atraviesa dos enemigos; nivel 3, tres. |
| Escopeta | 42 monedas, después del Nido | Tres perdigones en abanico. Las mejoras aumentan daño, alcance, apertura y cadencia; nivel 3 dispara cinco. |
| Lanzallamas | 60 monedas, después de Huesos | Disparo continuo corto que atraviesa y quema. Mejora alcance, cadencia y daño de quemadura. |
| Aguja del Alba | Logro Sin una herida | Proyectil largo y rápido, daño alto y penetración de varios enemigos. |
| Tempestad | Logro Tres relámpagos | Ráfagas de tres balas separadas en el tiempo. Nivel 2 añade penetración. |
| Fénix | Logro Inquebrantable | Tres chorros de fuego en abanico con quemadura intensa. |

Cada arma tiene tres mejoras independientes, de 30, 60 y 100 monedas. Se habilitan al vencer a Huesos, vencer al guardián real y restaurar el Meridiano, respectivamente. La mejora incluye reparación. Las compras anteriores de Cañón reforzado (+1 daño) y Disparo rápido (doble cadencia y disparo mantenido) se conservan y afectan a todas las armas.

Cada disparo o ráfaga consume durabilidad. Las armas especiales agotadas cambian a la pistola; la pistola agotada conserva un disparo de emergencia de daño 1, menor alcance y cadencia. Descansar repara gratis la pistola. El taller repara cualquier arma equipada: cobra según desgaste, sin cobrar cuando está completa. Las armas nunca desaparecen del inventario.

## Tiendas y desafíos repetibles

Hay tienda junto a los siete guardados: Pueblo, Santuario, Refugio de Hongos, Osario, Puerta de Ciudad, Entrada del Palacio y Umbral del Alba. Todas venden el mismo catálogo y ofrecen mejoras/reparaciones. En la tienda, tocar el número de página lleva rápidamente al taller de la página 3.

Tras el final aparecen altares para repetir los ecos del Nido, Príncipe de Huesos y guardián real. Si esa arena tiene un objetivo de misión pendiente, primero se recupera. Los ecos tienen 120, 160 y 200 de vida y una carga más rápida; los enemigos normales también tienen más resistencia según su mundo.

- **Sin una herida:** vencer cada uno de los tres ecos sin recibir golpes, incluyendo impactos al escudo. Otorga Aguja del Alba e Intocable. Las tres victorias se acumulan; un fallo permite reintentar ese eco.
- **Tres relámpagos:** vencer cada eco en un máximo de 12 segundos de combate activo. Otorga Tempestad y Relámpago. Las pausas detienen el reloj y el combate juntos.
- **Inquebrantable:** tras completar las cinco misiones, activar el altar del Trono y vencer tres ecos consecutivos sin curarse. Otorga Fénix e Inquebrantable. Usar curas invalida ese intento, pero permite terminarlo y volver a intentar.

Salir de la sala, morir o cargar cancela el intento activo. Los récords ya obtenidos permanecen guardados. Repetir un eco paga 8 monedas; completar la prueba del Trono paga 24, por lo que siempre queda una fuente de dinero para reparaciones y mejoras.

## Títulos equipables

Q → TÍTULO. Se equipa uno a la vez; los aspectos siguen siendo cosméticos y se eligen por separado.

| Título | Bonificación real |
| --- | --- |
| Caminante | +12% velocidad de carrera |
| Custodio | −20% desgaste |
| Cazador de Ecos | +1 daño directo |
| Maestro Artesano | −25% coste de reparación, redondeado hacia arriba |
| Del Meridiano | +12% cadencia, +10% alcance |
| Intocable | +20% alcance |
| Relámpago | +20% cadencia |
| Inquebrantable | +1 daño directo, −15% desgaste |

Guardado versión 4, compatible con versiones anteriores. Conserva monedas, habilidades, compras, aspectos, llaves y objetos de misión. Nuevo juego borra también las misiones, títulos, armas y récords del postgame.
