extends RefCounted

const ACHIEVEMENTS = [
	{"id":"first_chest","name":"CURIOSIDAD","description":"Abre tu primer cofre.","target":1,"cosmetic":""},
	{"id":"nest","name":"CAMINO LIBRE","description":"Vence al guardian del Nido.","target":1,"cosmetic":"amber"},
	{"id":"double","name":"ENTRE LAS ESPORAS","description":"Encuentra el doble salto.","target":1,"cosmetic":"moss"},
	{"id":"explorer","name":"EXPLORADOR","description":"Visita 18 salas distintas.","target":18,"cosmetic":""},
	{"id":"bone","name":"CAIDA DEL PRINCIPE","description":"Vence al Principe de Huesos.","target":1,"cosmetic":"ivory"},
	{"id":"dash","name":"SIN FRENOS","description":"Encuentra el impulso.","target":1,"cosmetic":""},
	{"id":"royal","name":"FIN DE LA GUARDIA","description":"Vence al guardian real.","target":1,"cosmetic":"violet"},
	{"id":"keys","name":"DOS LLAVES","description":"Recoge las llaves de ambos jefes.","target":2,"cosmetic":""},
	{"id":"treasure","name":"BUSCATESOROS","description":"Abre 15 cofres distintos.","target":15,"cosmetic":""},
	{"id":"hunter","name":"PROTECTOR","description":"Derrota a 40 enemigos distintos.","target":40,"cosmetic":""},
	{"id":"ending","name":"NUEVO AMANECER","description":"Restaura el Meridiano.","target":1,"cosmetic":"gold"},
	{"id":"atlas","name":"CADA RINCON","description":"Visita las 52 salas de la aventura original.","target":52,"cosmetic":""},
	{"id":"post_1","name":"CAMINOS SEGUROS","description":"Mision 1. Premio: 60 monedas y titulo CAMINANTE.","target":1,"cosmetic":"","title":"ranger"},
	{"id":"post_2","name":"VIDA EN EL ABISMO","description":"Mision 2. Premio: 85 monedas y titulo CUSTODIO.","target":2,"cosmetic":"","title":"keeper"},
	{"id":"post_3","name":"DEUDA SALDADA","description":"Mision 3. Premio: 110 monedas y titulo CAZADOR DE ECOS.","target":3,"cosmetic":"","title":"slayer"},
	{"id":"post_4","name":"FORJA RESTAURADA","description":"Mision 4. Premio: 140 monedas y titulo MAESTRO ARTESANO.","target":4,"cosmetic":"","title":"smith"},
	{"id":"post_5","name":"CINCO JURAMENTOS","description":"Mision 5. Premio: 180 monedas, titulo DEL MERIDIANO, Jardines del Alba y prueba del Trono.","target":5,"cosmetic":"","title":"sovereign"},
	{"id":"clean_trials","name":"SIN UNA HERIDA","description":"Vence los ecos del Nido, Huesos y Ruinas sin golpes, ni al escudo. Arma AGUJA DEL ALBA y titulo INTOCABLE.","target":3,"cosmetic":"","weapon":"needle","title":"untouched"},
	{"id":"speed_trials","name":"TRES RELAMPAGOS","description":"Vence cada eco en 12s. Arma TEMPESTAD y titulo RELAMPAGO. Pruebas tras el final.","target":3,"cosmetic":"","weapon":"tempest","title":"swift"},
	{"id":"marathon","name":"INQUEBRANTABLE","description":"Tras 5 misiones: vence 3 ecos seguidos en el Trono sin curas. Arma FENIX y titulo INQUEBRANTABLE.","target":1,"cosmetic":"","weapon":"phoenix","title":"immortal"}
]
const STYLES = [
	{"id":"classic","name":"ORIGINAL","tint":Color.WHITE,"trail":false,"hint":"Disponible desde el inicio."},
	{"id":"amber","name":"AMBAR DEL NIDO","tint":Color("ffc176"),"trail":false,"hint":"Libera el Nido."},
	{"id":"moss","name":"MUSGO","tint":Color("9dffb3"),"trail":false,"hint":"Encuentra el doble salto."},
	{"id":"ivory","name":"MARFIL","tint":Color("fff7bc"),"trail":false,"hint":"Vence al Principe de Huesos."},
	{"id":"violet","name":"VIOLETA REAL","tint":Color("c2a0ff"),"trail":false,"hint":"Vence al guardian real."},
	{"id":"gold","name":"AMANECER","tint":Color("ffdd66"),"trail":true,"hint":"Restaura el Meridiano."},
	{"id":"ember","name":"BRASA","tint":Color("ff8b91"),"trail":true,"hint":"Liberar el Nido. Tienda: 18."},
	{"id":"storm","name":"TORMENTA","tint":Color("83d5ff"),"trail":true,"hint":"Huesos y 18 salas. Tienda: 35."},
	{"id":"starlight","name":"ESTELAR","tint":Color("ffa9e6"),"trail":true,"hint":"Completar la aventura. Tienda: 50."}
]

static func progress(game: Node, id: String) -> int:
	if id.begins_with("post_"): return game.postgame.stage
	match id:
		"clean_trials": return game.postgame.clean_trials.size()
		"speed_trials": return game.postgame.speed_trials.size()
		"marathon": return int(game.postgame.marathon_won)
		"first_chest","treasure":
			var count := 0
			for object_id in game.collected_objects:
				if str(object_id).ends_with(":chest"):
					count += 1
			return count
		"nest": return int(game.defeated.has("nest"))
		"double": return int(game.player.double_jump)
		"explorer": return game.visited.size()
		"atlas": return game.visited.filter(func(room): return game.data.room(room).get("zone","") != "aurora").size()
		"bone": return int(game.defeated.has("bone_lord"))
		"dash": return int(game.player.dash)
		"royal": return int(game.defeated.has("royal_spire"))
		"keys": return game.keys
		"hunter": return game.defeated_enemies.size()
		"ending": return int(game.collected.has("throne"))
	return 0

static func style(id: String) -> Dictionary:
	for entry in STYLES:
		if entry.id == id:
			return entry
	return STYLES[0]
