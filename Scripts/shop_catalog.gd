extends RefCounted

const PERMANENT = ["power","rapid","magnet","flask","guard","satchel"]
const ITEMS = [
	{"id":"power","name":"CANON REFORZADO","price":55,"icon":"power","gate":"bone","description":"Dano +1 en todas las armas. Requiere vencer al Principe de Huesos."},
	{"id":"rapid","name":"DISPARO RAPIDO","price":85,"icon":"rapid","gate":"royal","description":"Disparo mantenido y doble cadencia en todas las armas. Guardian real e impulso."},
	{"id":"magnet","name":"IMAN DE MONEDAS","price":20,"icon":"coin","gate":"nest","description":"Atrae monedas cercanas. Disponible al liberar el Nido."},
	{"id":"flask","name":"FRASCO CURATIVO","price":30,"icon":"heart","gate":"nest","description":"Cura 2 corazones. Recarga gratis al descansar. Requiere liberar el Nido."},
	{"id":"heart","name":"CORAZON EXTRA","price":65,"icon":"heart","gate":"explorer","description":"Dos compras: 65 y 100 monedas. Requiere Huesos y explorar 18 salas."},
	{"id":"heal","name":"CURACION","price":3,"icon":"heart","gate":"","description":"Restaura toda tu salud. Los bancos tambien curan gratis."},
	{"id":"tonic","name":"TONICO DE VIAJE","price":6,"icon":"heart","gate":"nest","description":"Lleva hasta 3. Cura 2 corazones cuando el frasco esta vacio. F o CURA."},
	{"id":"satchel","name":"BOLSA DE TONICOS","price":26,"icon":"save","gate":"explorer","description":"Aumenta la capacidad de tonicos a 5. Requiere Huesos y 18 salas."},
	{"id":"guard","name":"AMULETO GUARDIAN","price":70,"icon":"enemy","gate":"royal","description":"Absorbe un golpe. Recarga al descansar. Requiere guardian real e impulso."},
	{"id":"ember","name":"ASPECTO BRASA","price":18,"icon":"player","gate":"nest","description":"Color coral y estela al impulsarte. Requiere liberar el Nido."},
	{"id":"storm","name":"ASPECTO TORMENTA","price":35,"icon":"player","gate":"explorer","description":"Color azul y estela al impulsarte. Requiere Huesos y 18 salas."},
	{"id":"starlight","name":"ASPECTO ESTELAR","price":50,"icon":"player","gate":"ending","description":"Color rosado y estela al impulsarte. Requiere restaurar el Meridiano."},
	{"id":"shotgun","name":"ESCOPETA","price":42,"icon":"power","gate":"nest","description":"Tres perdigones en abanico. N3: cinco. Mejoras: alcance, apertura y cadencia."},
	{"id":"flame","name":"LANZALLAMAS","price":60,"icon":"power","gate":"bone","description":"Chorro continuo, corto alcance y quemadura. Mejora alcance, cadencia y fuego."},
	{"id":"forge","name":"MEJORAR ARMA","price":30,"icon":"rapid","gate":"","description":"Mejora el arma equipada. Tres niveles: 30, 60 y 100. Incluye reparacion."},
	{"id":"repair","name":"REPARAR ARMA","price":1,"icon":"power","gate":"","description":"Restaura toda la durabilidad del arma equipada."}
]
