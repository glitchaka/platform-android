extends RefCounted

const QUESTS = [
	{"name":"RUTAS DEL ALBA","story":"Protege y activa los puestos del Sendero, Pueblo y Cruces.","reward":60,"title":"ranger","rooms":["tutorial","town","west_tower","upper_gallery","central_shaft","well","nest","shrine","west_road","heart_room","lower_gallery"]},
	{"name":"SEMILLAS DE VIDA","story":"Recupera semillas en las alturas de Hongos y del Abismo.","reward":85,"title":"keeper","rooms":["fungal_road","fungal_drop","moss_gate","spore_hall","fungal_stem","canopy","roots","moss_depths","root_shaft","fungal_exit","buried_path","deep_west"]},
	{"name":"DEUDA DE HUESOS","story":"Vence custodios y al eco del Principe. Recupera sus cofres.","reward":110,"title":"slayer","rooms":["bone_road","bone_gate","ossuary","rib_hall","bone_crown","bone_lord","bone_return","lower_tower","junction","deep_well"]},
	{"name":"FORJA DE LA CIUDAD","story":"Dispara a los mecanismos azules y derrota a sus guardianes.","reward":140,"title":"smith","rooms":["city_gate","reservoir","city_spire","city_square","east_spire","archive","royal_spire","city_end","deep_city"]},
	{"name":"ULTIMA GUARDIA","story":"Defiende los accesos y vence al eco del Trono. Recupera cofres.","reward":180,"title":"sovereign","rooms":["east_tower","east_shaft","caverns","east_bridge","east_lift","palace_gate","palace_stairs","palace_hall","palace_tower","throne"]}
]
const TRIAL_ROOMS = ["nest","bone_lord","royal_spire"]
const ENEMY = preload("res://Scripts/enemy.gd")
var game: Node
var stage := 0
var recovered: Array = []
var kills: Array = []
var switches: Array = []
var clean_trials: Array = []
var speed_trials: Array = []
var marathon_won := false
var trial := ""
var trial_time := 0.0
var trial_hits := 0
var trial_healed := false
var trial_round := 0

func active() -> bool:
	return game.collected.has("throne") and stage < QUESTS.size()

func token(room: String) -> String:
	return "%d:%s" % [stage,room]

func target_rooms() -> Array:
	return QUESTS[stage].rooms if active() else []

func remaining_rooms() -> Array:
	return target_rooms().filter(func(id): return not recovered.has(token(id)))

func objective() -> String:
	if not active(): return ""
	var todo := remaining_rooms()
	return "MISION %d: %s. %d-%d. %s" % [stage+1,QUESTS[stage].name,target_rooms().size()-todo.size(),target_rooms().size(),QUESTS[stage].story]

func enter_room() -> void:
	trial = "" # Leaving, dying or loading abandons a trial, never grants a win.
	if not game.collected.has("throne"): return
	var id: String = game.current
	if remaining_rooms().has(id):
		var safe: bool = game.data.room(id).reward == "rest"
		var position: Vector2 = game.level.reward_position if stage == 1 and not safe else Vector2(game.level.room_size.x*0.42,game.level.floor_y-4)
		if stage != 1 or safe:
			for x in range(48,int(game.level.room_size.x)-32,16):
				var candidate := Vector2(x,game.level.floor_y-4)
				var clear := true
				for door in game.level.exits:
					if candidate.distance_to(door.position)<26: clear = false
				for existing in game.level.objects:
					if candidate.distance_to(existing.position)<26: clear = false
				if clear:
					position = candidate
					break
		# A distinct physical cache/relay, never an invisible visit counter.
		game.level.add_object("quest",position,"post_"+str(stage))
		var object: Dictionary = game.level.objects[-1]
		object["quest_stage"] = stage
		object["activated"] = switches.has(token(id))
		if not safe:
			var count := 2 if stage in [1,4] else 1
			for index in range(count):
				var kill_id := token(id)+":"+str(index)
				if kills.has(kill_id): continue
				var boss: bool = id in ["nest","bone_lord","royal_spire","throne"] and index == 0
				var enemy_pos: Vector2 = position+Vector2(32+index*28,-8 if stage==1 else 0)
				var combat: Dictionary = game.progression.guardian_stats(stage,boss)
				spawn(enemy_pos,boss,stage==1,kill_id,combat.hp,combat.damage)
	elif id in TRIAL_ROOMS or (id == "throne" and stage == 5):
		game.level.add_object("trial",Vector2(game.level.room_size.x*0.42,game.level.floor_y-4),"trial")
	game.level.queue_redraw()

func spawn(pos: Vector2, boss: bool, flyer: bool, id: String, health: int, damage := 1) -> void:
	var enemy = ENEMY.new()
	pos.x = clampf(pos.x,48,game.level.room_size.x-48)
	if boss: pos.y = game.level.floor_y-4
	else: pos.y = minf(pos.y,game.level.floor_y-4)
	# Match the current platform height for airborne seed guardians.
	enemy.position = pos
	enemy.boss = boss
	enemy.kind = "boss" if boss else "flyer" if flyer else "crawler"
	enemy.hp = health
	enemy.max_hp = health
	enemy.contact_damage = damage
	enemy.elite = true
	enemy.patrol_min = maxf(40,pos.x-48)
	enemy.patrol_max = minf(game.level.room_size.x-32,pos.x+88)
	if boss:
		enemy.patrol_min = 48
		enemy.patrol_max = game.level.room_size.x-32
	enemy.configure(game.player)
	enemy.set_meta("post_id",id)
	enemy.touched_player.connect(game.player.take_damage.bind(enemy.contact_damage))
	enemy.defeated.connect(defeated_enemy.bind(enemy,id))
	game.get_node("World/Actors").add_child(enemy)
	game.enemies.append(enemy)

func guards_alive() -> bool:
	for enemy in game.enemies:
		if enemy.alive and enemy.has_meta("post_id"): return true
	return false

func use_object(object: Dictionary) -> void:
	if object.kind == "trial":
		start_trial()
		return
	if not active() or int(object.get("quest_stage",-1)) != stage or object.active: return
	if guards_alive():
		game.tell("Primero vence a los guardianes de este objetivo.")
		return
	if stage == 3 and not switches.has(token(game.current)):
		game.tell("Dispara al mecanismo azul antes de recoger las piezas.")
		return
	object.active = true
	recovered.append(token(game.current))
	game.audio.play("chest")
	if remaining_rooms().is_empty():
		var quest: Dictionary = QUESTS[stage]
		game.coins += int(quest.reward)
		stage += 1
		game.progression.grant(game.PROGRESSION.POSTGAME[stage-1])
		if stage == QUESTS.size():
			game.tell("NUEVA ZONA: JARDINES DEL ALBA. Cruza la puerta derecha del Trono. Tu corona abre el acceso.")
		game.check_achievements()
		game.achievement_queue.append("MISION COMPLETA: +%d monedas. Nuevo titulo en el diario." % quest.reward)
		# New targets appear immediately, including when two routes share a room.
		enter_room()
	else:
		game.tell("Objetivo recuperado. Restan %d. Consulta la ruta en el diario." % remaining_rooms().size())
		if game.current in TRIAL_ROOMS:
			game.level.add_object("trial",object.position+Vector2(24,0),"trial")
	game.save_progress()
	game.level.queue_redraw()

func shoot_switch(object: Dictionary) -> void:
	if stage != 3 or object.active or object.get("quest_stage",-1) != stage: return
	if not switches.has(token(game.current)):
		switches.append(token(game.current))
		object.activated = true
		game.audio.play("switch")
		game.dirty = true
		game.level.queue_redraw()

func start_trial() -> void:
	if not trial.is_empty() or guards_alive(): return
	if game.current not in TRIAL_ROOMS and not (game.current == "throne" and game.progression.items.has("meridian_crown")): return
	trial = game.current
	trial_time = 0
	trial_hits = 0
	trial_healed = false
	trial_round = 0
	game.tell("PRUEBA FINAL: tres ecos seguidos sin curas." if trial == "throne" else "ECO: vence sin golpes o en 12 segundos para lograr armas unicas.")
	spawn_trial()

func spawn_trial() -> void:
	var rank := trial_round if trial == "throne" else TRIAL_ROOMS.find(trial)
	spawn(Vector2(game.level.room_size.x*0.68,game.level.floor_y-4),true,false,"trial",480+rank*160,8+rank)
	game.audio.select_track("boss")

func tick(delta: float) -> void:
	if not trial.is_empty(): trial_time += delta

func damaged() -> void:
	if not trial.is_empty(): trial_hits += 1

func healed() -> void:
	if not trial.is_empty(): trial_healed = true

func defeated_enemy(_enemy: Node2D, id: String) -> void:
	if id != "trial":
		if not kills.has(id):
			kills.append(id)
			game.coins += 4 if _enemy.boss else 2
			game.dirty = true
		game.save_progress()
		return
	if trial.is_empty(): return
	if trial == "throne":
		trial_round += 1
		if trial_round < 3:
			# Deferred: never append to the enemy array during its tick iteration.
			game.call_deferred("spawn_trial_wave")
			return
		if not trial_healed: marathon_won = true
		game.coins += 24
		game.tell("Prueba completada sin curas: arma FENIX." if not trial_healed else "Prueba completada. Reintenta sin curarte para obtener FENIX.")
	else:
		game.coins += 8
		if trial_hits == 0 and not clean_trials.has(trial): clean_trials.append(trial)
		if trial_time <= 12 and not speed_trials.has(trial): speed_trials.append(trial)
		game.tell("Eco vencido: %.1fs. Golpes: %d. +8 monedas. Puedes repetir." % [trial_time,trial_hits])
	trial = ""
	game.audio.room_track(game.data.room(game.current),true)
	game.save_progress()

func save_data() -> Dictionary:
	return {"stage":stage,"recovered":recovered,"kills":kills,"switches":switches,"clean_trials":clean_trials,"speed_trials":speed_trials,"marathon_won":marathon_won}

func load_data(saved: Dictionary) -> void:
	stage = clampi(int(saved.get("stage",0)),0,5)
	for field in ["recovered","kills","switches","clean_trials","speed_trials"]:
		if saved.get(field,[]) is Array: set(field,saved.get(field,[]).duplicate())
	marathon_won = bool(saved.get("marathon_won",false))
	trial = ""
