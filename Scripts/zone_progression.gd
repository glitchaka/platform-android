extends RefCounted

# Permanent quest rewards. Neither weapons, wear nor equipped titles replace them.
const CAMPAIGN = [
	{"id":"path_medal","name":"MEDALLA DEL SENDERO","quest":"Abre el cofre del Tutorial.","access":"Pueblo y Cruces","attack":1,"armor":1,"icon":"goal"},
	{"id":"nest_amulet","name":"AMULETO DEL NIDO","quest":"Libera el Nido y cobra al guia.","access":"Hongos y Abismo oeste","attack":1,"armor":1,"icon":"enemy"},
	{"id":"living_sprout","name":"BROTE VITAL","quest":"Encuentra el doble salto en la Copa.","access":"Bosque de Huesos","attack":1,"armor":1,"icon":"jump"},
	{"id":"bone_key","name":"LLAVE DE HUESOS","quest":"Vence al Principe y recoge su llave.","access":"Ruinas y Ciudad profunda","attack":1,"armor":1,"icon":"key"},
	{"id":"royal_crest","name":"INSIGNIA REAL","quest":"Consigue el impulso y la llave real.","access":"Palacio Blanco","attack":1,"armor":1,"icon":"key"}
]
const POSTGAME = [
	{"id":"dawn_ember","name":"BRASA DEL ALBA","quest":"Completa Rutas del Alba.","access":"Hongos del postgame","attack":2,"armor":1,"icon":"goal"},
	{"id":"ancient_seed","name":"SEMILLA ANCESTRAL","quest":"Completa Semillas de Vida.","access":"Huesos del postgame","attack":2,"armor":1,"icon":"jump"},
	{"id":"bone_heart","name":"CORAZON DE HUESO","quest":"Completa Deuda de Huesos.","access":"Ruinas del postgame","attack":2,"armor":1,"icon":"heart"},
	{"id":"city_core","name":"NUCLEO DE LA CIUDAD","quest":"Completa Forja de la Ciudad.","access":"Palacio del postgame","attack":2,"armor":1,"icon":"rapid"},
	{"id":"meridian_crown","name":"CORONA DEL MERIDIANO","quest":"Completa Ultima Guardia.","access":"Jardines del Alba y prueba del Trono","attack":2,"armor":1,"icon":"key"}
]
var game: Node
var items: Array = []

func entries() -> Array:
	return CAMPAIGN+POSTGAME

func attack_bonus() -> int:
	var total := 0
	for entry in entries():
		if items.has(entry.id): total += int(entry.attack)
	return total

func armor_bonus() -> int:
	var total := 0
	for entry in entries():
		if items.has(entry.id): total += int(entry.armor)
	return total

func grant(entry: Dictionary, quiet := false) -> bool:
	if items.has(entry.id): return false
	items.append(entry.id)
	game.dirty = true
	game.apply_upgrades()
	game.refresh_doors()
	if not quiet:
		game.tell("%s: ataque +%d, defensa +%d. Abre %s." % [entry.name,entry.attack,entry.armor,entry.access])
		game.audio.play("key")
	return true

func sync_rewards(quiet := false) -> void:
	var done := [game.collected_objects.has("tutorial:chest"),game.quest_paid,game.player.double_jump,game.boss_keys.has("bone_lord"),game.boss_keys.has("royal_spire") and game.player.dash]
	for i in range(CAMPAIGN.size()):
		if done[i]: grant(CAMPAIGN[i],quiet)
	for i in range(game.postgame.stage): grant(POSTGAME[i],quiet)

func region_rank(id: String) -> int:
	if game.data.room(id).get("zone","") == "aurora": return 6
	if id == "deep_west": return 2
	if id == "deep_city": return 4
	return {"tutorial":0,"town":1,"cross":1,"fungus":2,"bone":3,"city":4,"palace":5}.get(game.data.room(id).get("zone",""),0)

func required_item(id: String) -> Dictionary:
	var rank := region_rank(id)
	if rank == 6: return POSTGAME[-1]
	if game.collected.has("throne"):
		# The restored hub is open. Each expedition's reward opens the next world.
		return POSTGAME[rank-2] if rank>=2 else {}
	return CAMPAIGN[rank-1] if rank>=1 else {}

func can_enter(id: String) -> bool:
	if region_rank(id) == 6:
		return final_zone_unlocked()
	var required := required_item(id)
	return required.is_empty() or items.has(required.id)

func final_zone_unlocked() -> bool:
	return game.collected.has("throne") and game.postgame.stage == POSTGAME.size() and items.has("meridian_crown")

func block_reason(id: String) -> String:
	if region_rank(id) == 6 and not final_zone_unlocked():
		return "Completa las cinco misiones y consigue la CORONA DEL MERIDIANO. Acceso desde el Trono."
	var entry := required_item(id)
	if entry.is_empty() or items.has(entry.id): return ""
	return "Necesitas %s. %s" % [entry.name,entry.quest]

func enemy_stats(id: String, boss: bool, flyer: bool) -> Dictionary:
	# Fixed zone tiers, independent of the player's equipment or current strength.
	var rank := region_rank(id)
	if rank == 6:
		return {"hp":288 if boss else 64 if flyer else 48,"damage":11}
	var expected_attack := 1+rank
	return {"hp":expected_attack*(18 if boss else 4 if flyer else 3),"damage":rank+1}

func guardian_stats(stage: int, boss: bool) -> Dictionary:
	var expected_attack := 6+stage*2
	return {"hp":expected_attack*(22 if boss else 5),"damage":6+stage}

func restore(saved: Array, legacy := false) -> void:
	items.clear()
	for entry in entries():
		if saved.has(entry.id): items.append(entry.id)
	if legacy:
		# Reconstruct rewards from completed objectives, never from merely visiting a room.
		var rank := 5 if game.collected.has("throne") else 4 if game.boss_keys.has("royal_spire") else 3 if game.boss_keys.has("bone_lord") else 2 if game.player.double_jump else 1 if game.quest_paid else 0
		for i in range(rank): grant(CAMPAIGN[i],true)
	sync_rewards(true)
