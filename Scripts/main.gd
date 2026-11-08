extends Node2D
const DATA = preload("res://Scripts/world_data.gd")
const PLAYER = preload("res://Scripts/player.gd")
const ENEMY = preload("res://Scripts/enemy.gd")
const PIXEL = preload("res://Scripts/pixel_ui.gd")
const SHOP = preload("res://Scripts/shop_catalog.gd")
const MILESTONES = preload("res://Scripts/milestones.gd")
const AUDIO = preload("res://Scripts/game_audio.gd")
const TOUCH = preload("res://Scripts/touch_controls.gd")
const ARSENAL = preload("res://Scripts/arsenal.gd")
const POSTGAME = preload("res://Scripts/postgame.gd")
const PROGRESSION = preload("res://Scripts/zone_progression.gd")
var progression = PROGRESSION.new()
var weapons: Dictionary = ARSENAL.fresh()
var equipped_weapon := "pistol"
var titles: Array = ["none"]
var equipped_title := "none"
var postgame = POSTGAME.new()
const KEY_BOSSES = {"bone_lord":"Huesos","royal_spire":"Ruinas"}
var audio: Node
var touch: Node2D
var defeated_enemies: Array = []
var boss_keys: Array = []
var achievements: Array = []
var cosmetics: Array = ["classic"]
var equipped_style := "classic"
var heart_purchases := 0
var tonics := 0
var journal_tab := 0
var journal_selection := 0
var achievement_queue: Array[String] = []
var achievement_notice := ""
var achievement_timer := 0.0
var data = DATA.new()
var player: Node2D
var camera: Camera2D
var level: Node2D
var hud: Node2D
var projectile_renderer: Node2D
var enemies: Array[Node2D] = []
var shots: Array[Dictionary] = []
var current := "tutorial"
var checkpoint := "tutorial"
var visited: Array = []
var collected: Array = []
var collected_objects: Array = []
var defeated: Array = []
var keys := 0
var coins := 0
var quest_started := false
var quest_paid := false
var map_open := false
var journal_open := false
var shop_open := false
var shop_selection := 0
var shop_message := ""
var shop_message_time := 0.0
var upgrades: Array = []
var flask_charges := 0
var message := "A D mover. ESPACIO saltar. J disparar. E usar objetos."
var message_time := 7.0
var nearby := ""
var nearby_last := ""
var nearby_time := 0.0
var transition_cooldown := 0.0
var save_path := "user://meridian_save.json"
var dirty := false
var autosave_timer := 0.0
var menu_state := "title"
var menu_selection := 0
var menu_message := ""
var save_available := false
var session_active := false
var input_block_frames := 0
var quitting := false

func _ready() -> void:
	postgame.game = self
	progression.game = self
	get_tree().auto_accept_quit = false
	register_controls()
	level = get_node("World/Environment/LevelBuilder")
	hud = get_node("Interface/HUD")
	hud.game = self
	audio = AUDIO.new()
	add_child(audio)
	touch = TOUCH.new()
	touch.game = self
	get_node("Interface").add_child(touch)
	player = PLAYER.new()
	get_node("World/Actors").add_child(player)
	player.attack_hit.connect(attack)
	player.health_changed.connect(health_changed)
	player.sound_requested.connect(player_sound)
	player.damage_received.connect(postgame.damaged)
	projectile_renderer = preload("res://Scripts/projectile_renderer.gd").new()
	projectile_renderer.game = self
	projectile_renderer.z_index = 5
	get_node("World/Actors").add_child(projectile_renderer)
	camera = Camera2D.new()
	camera.position_smoothing_enabled = false
	player.add_child(camera)
	show_title()

func register_controls() -> void:
	var controls := {"move_left":[KEY_A,KEY_LEFT],"move_right":[KEY_D,KEY_RIGHT],"jump":[KEY_SPACE,KEY_W,KEY_UP],"attack":[KEY_J],"interact":[KEY_E,KEY_DOWN],"map":[KEY_M,KEY_TAB],"journal":[KEY_Q],"dash":[KEY_SHIFT,KEY_K],"flask":[KEY_F],"shop_up":[KEY_W,KEY_UP],"shop_down":[KEY_S,KEY_DOWN],"shop_buy":[KEY_E,KEY_ENTER],"shop_close":[KEY_ESCAPE]}
	for action in controls:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for code in controls[action]:
			var event := InputEventKey.new()
			event.physical_keycode = code
			if not InputMap.action_has_event(action,event):
				InputMap.action_add_event(action,event)
	var menu_controls := {"weapon_next":[KEY_R],"menu_up":[KEY_W,KEY_UP],"menu_down":[KEY_S,KEY_DOWN],"menu_accept":[KEY_E,KEY_ENTER,KEY_SPACE],"pause":[KEY_ESCAPE],"mute":[KEY_V]}
	for action in menu_controls:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for code in menu_controls[action]:
			var event := InputEventKey.new()
			event.physical_keycode = code
			if not InputMap.action_has_event(action,event):
				InputMap.action_add_event(action,event)

func show_title() -> void:
	touch.release_all()
	audio.select_track("title")
	menu_state = "title"
	session_active = false
	map_open = false
	journal_open = false
	shop_open = false
	shots.clear()
	get_node("World").visible = false
	player.sprite.speed_scale = 0
	save_available = not read_progress().is_empty()
	menu_selection = 1 if save_available else 0
	menu_message = "" if save_available or not FileAccess.file_exists(save_path) else "Guardado no valido. Inicia nuevo juego."
	hud.queue_redraw()
	queue_redraw()

func reset_progress() -> void:
	progression.items.clear()
	weapons = ARSENAL.fresh()
	equipped_weapon = "pistol"
	titles = ["none"]
	equipped_title = "none"
	postgame.load_data({})
	dirty = false
	current = "tutorial"
	checkpoint = "tutorial"
	visited.clear()
	collected.clear()
	collected_objects.clear()
	defeated.clear()
	upgrades.clear()
	defeated_enemies.clear()
	boss_keys.clear()
	achievements.clear()
	cosmetics = ["classic"]
	equipped_style = "classic"
	heart_purchases = 0
	tonics = 0
	journal_tab = 0
	journal_selection = 0
	achievement_queue.clear()
	achievement_notice = ""
	achievement_timer = 0
	player.shield = false
	player.trail.clear()
	shots.clear()
	keys = 0
	coins = 0
	flask_charges = 0
	quest_started = false
	quest_paid = false
	map_open = false
	journal_open = false
	shop_open = false
	shop_selection = 0
	shop_message = ""
	shop_message_time = 0
	autosave_timer = 0
	nearby = ""
	nearby_last = ""
	nearby_time = 0
	message = "Palanca izquierda: mover. Salto y tiro: botones de la derecha." if touch.enabled else "A D mover. ESPACIO saltar. J disparar. E usar. ESC menu."
	message_time = 2.8
	player.health = 3
	player.max_health = 3
	player.double_jump = false
	player.dash = false
	player.jumps = 0
	player.velocity = Vector2.ZERO
	player.facing = 1
	player.attack_timer = 0
	player.muzzle_timer = 0
	player.invulnerable_timer = 0
	player.dash_timer = 0
	player.dash_cooldown = 0
	player.sprite.visible = true
	player.sprite.play("idle")
	apply_upgrades()

func begin_session() -> void:
	session_active = true
	menu_state = ""
	menu_message = ""
	get_node("World").visible = true
	player.sprite.speed_scale = 1
	input_block_frames = 2
	enter_room(checkpoint)

func new_game() -> bool:
	reset_progress()
	begin_session()
	# Intentionally replace the previous slot, with no backup or carry-over.
	if not save_progress():
		tell("No se pudo guardar. Revisa el acceso al archivo de partida.")
		return false
	return true

func continue_game() -> bool:
	if read_progress().is_empty():
		save_available = false
		menu_message = "No hay una partida valida para cargar."
		hud.queue_redraw()
		return false
	reset_progress()
	if not load_progress():
		menu_message = "No se pudo cargar la partida."
		return false
	begin_session()
	tell("Partida cargada en el ultimo descanso. II abre el menu." if touch.enabled else "Partida cargada en el ultimo descanso. ESC abre el menu.")
	return true

func open_pause() -> void:
	if not session_active:
		return
	menu_state = "pause"
	touch.release_all()
	menu_selection = 0
	menu_message = ""
	player.sprite.speed_scale = 0
	hud.queue_redraw()

func resume_game() -> void:
	menu_state = ""
	player.sprite.speed_scale = 1
	input_block_frames = 2
	hud.queue_redraw()

func return_to_title() -> bool:
	if session_active and not save_progress():
		menu_message = "No se pudo guardar. La partida sigue abierta."
		return false
	show_title()
	return true

func quit_game() -> bool:
	if quitting:
		return true
	if session_active and not save_progress():
		open_pause()
		menu_message = "No se pudo guardar. La partida sigue abierta."
		return false
	quitting = true
	touch.release_all()
	audio.shutdown()
	# Let the audio thread release queued streams before the engine exits.
	get_tree().create_timer(0.12).timeout.connect(get_tree().quit)
	return true

func menu_action(action: String) -> void:
	if menu_state.is_empty():
		return
	audio.play("menu" if action in ["menu_up","menu_down"] else "accept")
	match action:
		"menu_up","menu_down":
			menu_selection = wrapi(menu_selection+(-1 if action == "menu_up" else 1),0,3)
			menu_message = ""
		"pause":
			if menu_state == "pause":
				resume_game()
		"menu_accept":
			if menu_state == "title":
				match menu_selection:
					0: new_game()
					1: continue_game()
					2: quit_game()
			else:
				match menu_selection:
					0: resume_game()
					1: return_to_title()
					2: quit_game()
	hud.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(hud):
		return
	var is_click: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	var is_touch: bool = event is InputEventScreenTouch and event.pressed
	if not is_click and not is_touch and not event is InputEventMouseMotion:
		return
	var local_pos: Vector2 = hud.get_global_transform_with_canvas().affine_inverse()*event.position
	if (is_click or is_touch) and (menu_state.is_empty() or Rect2(270,28,26,22).has_point(local_pos)):
		if touch.overlay_tap(local_pos):
			get_viewport().set_input_as_handled()
		return
	if menu_state.is_empty():
		return
	for i in range(3):
		if hud.menu_button_rect(i).has_point(local_pos):
			menu_selection = i
			menu_message = ""
			if is_click or is_touch:
				menu_action("menu_accept")
			hud.queue_redraw()
			get_viewport().set_input_as_handled()
			return

func enter_room(id: String, from: String = "") -> void:
	if not from.is_empty() and not progression.can_enter(id):
		tell(progression.block_reason(id))
		return
	touch.release_all()
	player.trail.clear()
	shop_open = false
	if dirty:
		save_progress()
	current = id
	if not visited.has(id):
		visited.append(id)
		dirty = true
	for enemy in enemies:
		enemy.queue_free()
	enemies.clear()
	shots.clear()
	nearby = ""
	var room: Dictionary = data.room(id)
	audio.room_track(room,defeated.has(id))
	level.build(room,data.exits(id))
	refresh_doors()
	for object in level.objects:
		object.active = collected_objects.has(object.id) or (object.kind == "chest" and collected.has(id))
	player.configure(level.platforms)
	player.bounds = level.room_size
	player.position = Vector2(36,level.floor_y-4)
	for door in level.exits:
		if door.to == from:
			player.position = door.position+Vector2(18 if door.position.x < level.room_size.x/2 else -18,0)
	player.velocity = Vector2.ZERO
	player.grounded = true
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(level.room_size.x)
	camera.limit_bottom = int(level.room_size.y)
	camera.reset_smoothing()
	camera.force_update_scroll()
	transition_cooldown = 0.4
	if not defeated.has(id):
		for index in range(level.enemy_spawns.size()):
			var spawn: Dictionary = level.enemy_spawns[index]
			var enemy_id := id+":enemy%d" % index
			if defeated_enemies.has(enemy_id):
				continue
			var enemy = ENEMY.new()
			enemy.kind = spawn.kind
			enemy.boss = spawn.kind == "boss"
			var combat: Dictionary = progression.enemy_stats(id,enemy.boss,spawn.kind=="flyer")
			enemy.hp = combat.hp
			enemy.contact_damage = combat.damage
			enemy.max_hp = enemy.hp
			enemy.position = spawn.position
			enemy.patrol_min = spawn.left
			enemy.patrol_max = spawn.right
			enemy.configure(player)
			enemy.touched_player.connect(player.take_damage.bind(enemy.contact_damage))
			enemy.defeated.connect(enemy_defeated.bind(enemy,enemy_id))
			get_node("World/Actors").add_child(enemy)
			enemies.append(enemy)
	if defeated.has(id):
		spawn_boss_key(Vector2(level.room_size.x*0.62,level.floor_y-4))
	postgame.enter_room()
	check_achievements()
	hud.queue_redraw()
	level.queue_redraw()
	queue_redraw()

func _physics_process(delta: float) -> void:
	if quitting:
		return
	if Input.is_action_just_pressed("mute"):
		audio.muted = not audio.muted
		if session_active:
			save_progress()
	if not menu_state.is_empty():
		for action in ["pause","menu_up","menu_down","menu_accept"]:
			if Input.is_action_just_pressed(action):
				menu_action(action)
				break
		hud.queue_redraw()
		return
	if input_block_frames > 0:
		input_block_frames -= 1
		return
	if shop_open:
		shop_message_time = maxf(0,shop_message_time-delta)
		for action in ["shop_close","shop_up","shop_down","shop_buy"]:
			if Input.is_action_just_pressed(action):
				shop_action(action)
				break
		hud.queue_redraw()
		return
	if Input.is_action_just_pressed("pause"):
		if map_open or journal_open:
			map_open = false
			journal_open = false
			hud.queue_redraw()
		else:
			open_pause()
		return
	if Input.is_action_just_pressed("map"):
		map_open = not map_open
		journal_open = false
		if map_open: hud.atlas.select_room(current)
	if Input.is_action_just_pressed("journal"):
		journal_open = not journal_open
		map_open = false
	hud.queue_redraw()
	if map_open or journal_open:
		touch.release_all()
		if map_open:
			for action in ["move_left","move_right","shop_up","shop_down","menu_accept"]:
				if Input.is_action_just_pressed(action):
					hud.atlas.action(self,action)
					break
		if journal_open:
			for action in ["move_left","move_right","shop_up","shop_down","menu_accept"]:
				if Input.is_action_just_pressed(action):
					journal_action(action)
					break
		return
	message_time = maxf(0,message_time-delta)
	nearby_time = maxf(0,nearby_time-delta)
	transition_cooldown = maxf(0,transition_cooldown-delta)
	autosave_timer += delta
	if dirty and autosave_timer > 1.0:
		save_progress()
	if Input.is_action_just_pressed("weapon_next"):
		cycle_weapon()
	player.tick(delta)
	postgame.tick(delta)
	if Input.is_action_just_pressed("flask"):
		use_flask()
	for enemy in enemies:
		enemy.tick(delta)
	tick_shots(delta)
	tick_objects()
	nearby = ""
	var focus: Dictionary = nearest_object()
	if not focus.is_empty():
		nearby = object_prompt(focus)
		if Input.is_action_just_pressed("interact") and transition_cooldown <= 0:
			use_object(focus)
	else:
		for door in level.exits:
			if player.position.distance_to(door.position)<18:
				var dest: Dictionary = data.room(door.to)
				nearby = "E: P%d. %s. %s" % [door.number,room_name(door.to),DATA.ZONES[dest.zone][0]]
				if door.get("locked",false): nearby += ". BLOQUEADO."
				if Input.is_action_just_pressed("interact") and transition_cooldown<=0:
					var blocked := door_block_reason(current,door)
					if not blocked.is_empty():
						tell(blocked)
						audio.play("error")
					else:
						enter_room(door.to,current)
						audio.play("door")
						return
	if nearby != nearby_last:
		nearby_last = nearby
		nearby_time = 1.6 if not nearby.is_empty() else 0.0
	if player.position.y > level.room_size.y+24:
		player.take_damage()
		enter_room(checkpoint)
	level.queue_redraw()
	queue_redraw()

func room_name(id: String) -> String:
	return {
		"tutorial":"Sendero","town":"Pueblo","well":"Pozo","nest":"Nido",
		"shrine":"Santuario","central_shaft":"Pozo central","upper_gallery":"Galeria alta",
		"west_tower":"Torre oeste","east_tower":"Torre este","east_shaft":"Pozo este",
		"west_road":"Camino oeste","heart_room":"Camara vital","lower_gallery":"Galeria baja",
		"bone_road":"Paso de Huesos","fungal_road":"Camino de Hongos","junction":"Cruce",
		"lower_tower":"Torre baja","fungal_drop":"Descenso","deep_well":"Pozo profundo",
		"caverns":"Cavernas","east_bridge":"Puente este","east_lift":"Torre del este",
		"moss_gate":"Puerta del musgo","spore_hall":"Refugio","fungal_stem":"Tallo",
		"canopy":"Copa","roots":"Raices","moss_depths":"Gruta","root_shaft":"Pozo de raices",
		"fungal_exit":"Paso del sur","buried_path":"Senda enterrada","deep_west":"Abismo oeste",
		"bone_gate":"Puerta de Huesos","ossuary":"Osario","rib_hall":"Costillar",
		"bone_crown":"Corona","bone_lord":"Principe de Huesos","bone_return":"Tesoro de Huesos",
		"city_gate":"Puerta de Ciudad","reservoir":"Deposito","city_spire":"Aguja",
		"city_square":"Plaza","east_spire":"Aguja este","archive":"Archivo",
		"royal_spire":"Aguja real","city_end":"Tesoro de Ruinas","deep_city":"Ciudad profunda",
		"palace_gate":"Entrada del Palacio","palace_stairs":"Escalinata",
		"palace_hall":"Salon","palace_tower":"Torre blanca","throne":"Trono",
		"aurora_gate":"Umbral del Alba","aurora_garden":"Jardin del Alba","aurora_core":"Santuario del Alba"
	}.get(id,id.replace("_"," "))

func can_open(gate: String) -> bool:
	if gate == "postgame":
		return progression.final_zone_unlocked()
	if gate.begins_with("boss:"):
		return defeated.has(gate.trim_prefix("boss:"))
	return gate == "" or (gate == "double_jump" and player.double_jump) or (gate == "dash" and player.dash) or (gate == "keys" and keys>=2)

func refresh_doors() -> void:
	if not is_instance_valid(level): return
	for door in level.exits:
		door["locked"] = not door_block_reason(current,door).is_empty()
	level.queue_redraw()

func door_block_reason(from: String, door: Dictionary) -> String:
	if not progression.can_enter(door.to): return progression.block_reason(door.to)
	if not can_open(door.gate):
		return "Necesitas " + {"double_jump":"doble salto.","dash":"impulso.","keys":"las llaves de Huesos y Ruinas.","postgame":"completar las cinco misiones."}.get(door.gate,"vencer al guardian.")
	if data.room(from).reward == "boss" and not defeated.has(from):
		return "Vence al guardian para abrir las salidas."
	return ""

func door_requirement(from: String, door: Dictionary) -> String:
	if not progression.can_enter(door.to): return progression.required_item(door.to).get("name","")
	if not can_open(door.gate): return {"double_jump":"DOBLE SALTO","dash":"IMPULSO","keys":"DOS LLAVES","postgame":"CINCO MISIONES"}.get(door.gate,"VENCER AL GUARDIAN")
	if data.room(from).reward == "boss" and not defeated.has(from): return "VENCER AL GUARDIAN"
	return "ABIERTO"

func objective_room() -> String:
	if progression.final_zone_unlocked():
		return "aurora_core" if visited.has("aurora_gate") else "aurora_gate"
	if postgame.active():
		var remaining: Array = postgame.remaining_rooms()
		return remaining[mini(journal_selection,remaining.size()-1)] if not remaining.is_empty() else "throne"
	if not progression.items.has("path_medal"): return "tutorial"
	if not quest_started:
		return "town"
	if not defeated.has("nest"):
		return "nest"
	if not quest_paid:
		return "town"
	if not player.double_jump:
		return "canopy"
	if not boss_keys.has("bone_lord"):
		return "bone_lord"
	if not player.dash:
		return "city_spire"
	if not boss_keys.has("royal_spire"):
		return "royal_spire"
	return "throne"

func objective_text() -> String:
	if collected.has("throne"):
		if postgame.active(): return postgame.objective()
		if collected_objects.has("aurora_core:chest"):
			return "Jardines del Alba completados. Puedes explorar y repetir la prueba del Trono."
		return "Nueva zona: JARDINES DEL ALBA. Cruza la puerta derecha del Trono. Hay un descanso, un jardin y un guardian con cofre."
	return {
		"tutorial":"Activa la palanca y abre el cofre del Sendero. Su medalla mejora tu combate y abre el Pueblo.",
		"town":"Vuelve al guia por tu paga y el amuleto que abre Hongos." if quest_started else "Busca al guia del Pueblo. Q: encargos.",
		"nest":"Libera el Nido. Ve del Pueblo al Pozo y luego al este.",
		"canopy":"Busca el doble salto en la Copa de Hongos.",
		"bone_lord":"Vence al Principe de Huesos. Recoge la llave que deja al morir.",
		"city_spire":"Busca el impulso en la Aguja de Ciudad.",
		"royal_spire":"Vence al guardian real. Recoge la llave que deja al morir.",
		"throne":"Usa las dos llaves en Hongos para entrar al Palacio Blanco."
	}.get(objective_room(),"")

func nearest_object() -> Dictionary:
	var result: Dictionary = {}
	var closest := 18.0
	for object in level.objects:
		if object.kind in ["coin","crate","boss_key"] or (object.active and object.kind in ["chest","lever","quest"]):
			continue
		var distance: float = player.position.distance_to(object.position)
		if distance < closest:
			result = object
			closest = distance
	return result

func object_prompt(object: Dictionary) -> String:
	match object.kind:
		"quest": return "E: recoger semillas." if postgame.stage==1 else "E: recuperar objetivo de la mision."
		"trial": return "E: prueba final sin curas." if current=="throne" else "E: repetir desafio del eco."
		"guide": return "E: hablar con el guia del Pueblo."
		"merchant": return "E: abrir la tienda de mejoras."
		"bench": return "E: descansar, curar y guardar."
		"lever": return "E: activar el mecanismo del cofre."
		"chest": return "Vence al guardian para abrir el cofre." if object.reward == "boss_cache" and not defeated.has(current) else "E: abrir cofre."
		"sign": return "E: leer el cartel."
	return ""

func use_object(object: Dictionary) -> void:
	if object.kind in ["quest","trial"]:
		postgame.use_object(object)
		return
	if object.active and object.kind in ["chest","lever"]:
		return
	match object.kind:
		"guide":
			if not quest_started:
				quest_started = true
				tell("Libera el Nido, al este del Pozo. Te pagare 6 monedas.")
			elif defeated.has("nest") and not quest_paid:
				quest_paid = true
				coins += 6
				audio.play("buy")
				tell("Toma 6 monedas. La tienda tiene nuevas mejoras y un aspecto.")
			else:
				tell(objective_text())
		"merchant":
			shop_open = true
			touch.release_all()
			audio.play("accept")
			map_open = false
			journal_open = false
			shop_message_time = 0
			player.velocity = Vector2.ZERO
			hud.queue_redraw()
		"bench":
			postgame.healed()
			checkpoint = current
			weapons.pistol.durability = ARSENAL.weapon("pistol").capacity
			apply_upgrades()
			player.health = player.max_health
			player.shield = upgrades.has("guard")
			audio.play("heal")
			flask_charges = 1 if upgrades.has("flask") else 0
			tell("Guardado. Salud, frasco y pistola restaurados. Tienda junto al banco.")
		"lever":
			activate_object(object)
			audio.play("switch")
			tell("Mecanismo activado. El cofre ya puede abrirse.")
		"chest":
			for other in level.objects:
				if other.kind == "lever" and not other.active:
					tell("Activa el mecanismo de esta sala para abrir el cofre.")
					return
			if data.room(current).reward == "boss" and not defeated.has(current):
				tell("Este cofre se abre al vencer al guardian. No necesita llaves.")
				audio.play("error")
				return
			activate_object(object)
			audio.play("chest")
			if object.reward in ["heart","double_jump","dash","key","ending","coin"]:
				collect(object.reward)
			else:
				var value := 60 if current == "aurora_core" else 12 if object.reward == "boss_cache" else 2 if current in ["tutorial","town"] else 4
				coins += value
				tell("Jardines del Alba completados: +60 monedas. Puedes volver al Trono." if current == "aurora_core" else "Cofre abierto: +%d monedas." % value)
		"sign":
			if current == "tutorial":
				tell("TIRO rompe cajas. Activa el mecanismo y abre el cofre con USAR." if touch.enabled else "J dispara y rompe cajas. Activa el mecanismo y abre el cofre con E.")
			else:
				tell("Guia, tienda y descanso en el Pueblo. La salida este lleva al Pozo.")
	save_progress()
	level.queue_redraw()

func shop_action(action: String) -> void:
	if not shop_open:
		return
	audio.play("menu" if action in ["shop_up","shop_down"] else "accept")
	match action:
		"shop_close":
			shop_open = false
			transition_cooldown = 0.2
		"shop_up","shop_down":
			shop_selection = wrapi(shop_selection+(-1 if action == "shop_up" else 1),0,SHOP.ITEMS.size())
			shop_message_time = 0
		"shop_buy":
			buy_selected()
	hud.queue_redraw()

func shop_unavailable(item: Dictionary) -> String:
	if item.id in ["shotgun","flame"] and weapons.has(item.id):
		return "Arma adquirida. Equipala en Diario, Armas."
	if item.id == "repair":
		return "El arma equipada ya esta reparada." if weapons[equipped_weapon].durability >= ARSENAL.weapon(equipped_weapon).capacity else ""
	if item.id == "forge":
		var level_now: int = weapons[equipped_weapon].level
		if level_now >= 3: return "Arma al nivel maximo."
		if level_now == 0 and not defeated.has("bone_lord"): return "Mejora 1: vence al Principe de Huesos."
		if level_now == 1 and not defeated.has("royal_spire"): return "Mejora 2: vence al guardian real."
		if level_now == 2 and not collected.has("throne"): return "Mejora 3: restaura el Meridiano."
		return ""
	if upgrades.has(item.id) or cosmetics.has(item.id):
		return "Ya lo tienes. Los aspectos se eligen en Q, Vestuario."
	if item.id == "heart" and (heart_purchases >= 2 or player.max_health >= 8):
		return "Ya compraste ambos corazones extra."
	if item.id == "heal" and player.health >= player.max_health:
		return "Tu salud ya esta completa."
	if item.id == "tonic" and tonics >= tonic_capacity():
		return "Bolsa llena. Capacidad: %d tonicos." % tonic_capacity()
	match item.get("gate",""):
		"nest":
			if not defeated.has("nest"):
				return "Bloqueado: libera primero el Nido."
		"bone":
			if not defeated.has("bone_lord"):
				return "Bloqueado: vence al Principe de Huesos."
		"explorer":
			if not defeated.has("bone_lord") or visited.size() < 18:
				return "Requiere vencer a Huesos y 18 salas. Exploradas: %d." % visited.size()
		"royal":
			if not defeated.has("royal_spire") or not player.dash:
				return "Requiere vencer al guardian real y encontrar el impulso."
		"ending":
			if not collected.has("throne"):
				return "Bloqueado: restaura el Meridiano."
	return ""

func shop_price(item: Dictionary) -> int:
	if item.id == "forge": return [30,60,100,0][int(weapons[equipped_weapon].level)]
	if item.id == "repair":
		var entry: Dictionary = ARSENAL.weapon(equipped_weapon)
		return maxi(1,int(ceil(entry.repair*(1.0-weapons[equipped_weapon].durability/float(entry.capacity))*(0.75 if equipped_title=="smith" else 1.0))))
	return 65+heart_purchases*35 if item.id == "heart" else int(item.price)

func shop_description(item: Dictionary) -> String:
	if item.id == "forge":
		var next_level: int = mini(3,weapons[equipped_weapon].level+1)
		var stats := ARSENAL.stats(equipped_weapon,next_level)
		return "%s N%d\nDANO %d ALCANCE %d BALAS %d\nCADENCIA %.1f-S PENETRA %d" % [ARSENAL.weapon(equipped_weapon).name,next_level,stats.damage,stats.range,stats.pellets*stats.burst,1.0/stats.interval,stats.pierce]
	if item.id == "repair": return "Repara %s al 100. Durabilidad: %d. La pistola se repara gratis al descansar." % [ARSENAL.weapon(equipped_weapon).name,durability_percent()]
	return item.description

func tonic_capacity() -> int:
	return 5 if upgrades.has("satchel") else 3

func buy_selected() -> bool:
	if not shop_open or data.room(current).reward != "rest":
		return false
	var item: Dictionary = SHOP.ITEMS[shop_selection]
	shop_message_time = 4
	shop_message = shop_unavailable(item)
	if not shop_message.is_empty():
		audio.play("error")
		return false
	var price := shop_price(item)
	if coins < price:
		shop_message = "Te faltan %d monedas para esta compra." % (price-coins)
		audio.play("error")
		return false
	coins -= price
	match item.id:
		"shotgun","flame":
			unlock_weapon(item.id)
			equipped_weapon = item.id
		"forge":
			weapons[equipped_weapon].level += 1
			weapons[equipped_weapon].durability = ARSENAL.weapon(equipped_weapon).capacity
		"repair":
			weapons[equipped_weapon].durability = ARSENAL.weapon(equipped_weapon).capacity
		"heart":
			postgame.healed()
			heart_purchases += 1
			player.max_health += 1
			player.health = player.max_health
		"heal":
			postgame.healed()
			player.health = player.max_health
		"tonic":
			tonics += 1
		"ember","storm","starlight":
			cosmetics.append(item.id)
			equipped_style = item.id
		_:
			upgrades.append(item.id)
			if item.id == "flask":
				flask_charges = 1
			if item.id == "guard":
				player.shield = true
	apply_upgrades()
	audio.play("buy")
	shop_message = "Comprado: " + item.name + "."
	save_progress()
	hud.queue_redraw()
	return true

func apply_upgrades() -> void:
	var stats := weapon_stats()
	player.weapon_damage = stats.damage
	player.rapid_fire = stats.automatic or upgrades.has("rapid")
	player.fire_interval = stats.interval
	player.speed_bonus = 1.12 if equipped_title == "ranger" else 1.0
	player.armor = progression.armor_bonus()
	var style := MILESTONES.style(equipped_style)
	player.sprite.modulate = style.tint
	player.trail_enabled = style.trail

func unlock_weapon(id: String) -> void:
	if not weapons.has(id):
		weapons[id] = {"level":0,"durability":float(ARSENAL.weapon(id).capacity)}

func weapon_stats(id := "") -> Dictionary:
	if id.is_empty(): id = equipped_weapon
	var stats := ARSENAL.stats(id,int(weapons[id].level))
	stats.damage += (1 if upgrades.has("power") else 0)+(1 if equipped_title in ["slayer","immortal"] else 0)
	stats.interval /= (2.0 if upgrades.has("rapid") else 1.0)*(1.2 if equipped_title=="swift" else 1.12 if equipped_title=="sovereign" else 1.0)
	stats.range *= 1.2 if equipped_title=="untouched" else 1.1 if equipped_title=="sovereign" else 1.0
	if id == "pistol" and weapons.pistol.durability <= 0:
		stats.merge({"damage":1,"interval":0.55,"pierce":0,"range":130.0},true)
	# Relic strength survives weapon swaps, broken weapons, titles and loading.
	stats.damage += progression.attack_bonus()
	if stats.burn>0: stats.burn += progression.attack_bonus()/2
	return stats

func durability_percent() -> int:
	return int(ceil(100.0*weapons[equipped_weapon].durability/ARSENAL.weapon(equipped_weapon).capacity))

func equip_weapon(id: String) -> void:
	if not weapons.has(id): return
	equipped_weapon = id
	apply_upgrades()
	save_progress()

func cycle_weapon() -> void:
	var owned: Array = weapons.keys()
	equip_weapon(owned[(owned.find(equipped_weapon)+1)%owned.size()])
	tell(ARSENAL.weapon(equipped_weapon).name+". Durabilidad: %d." % durability_percent())

func use_flask() -> bool:
	if not menu_state.is_empty() or map_open or journal_open or shop_open:
		return false
	if player.health >= player.max_health:
		tell("Salud completa. Conservas tus curaciones.")
		return false
	if flask_charges <= 0 and tonics <= 0:
		tell("Sin curaciones. Descansa para recargar o compra tonicos junto a cualquier descanso.")
		audio.play("error")
		return false
	postgame.healed()
	player.health = mini(player.health+2,player.max_health)
	if flask_charges > 0:
		flask_charges -= 1
		tell("Frasco usado: +2 corazones. Recarga al descansar.")
	else:
		tonics -= 1
		tell("Tonico usado: +2 corazones. Quedan %d." % tonics)
	audio.play("heal")
	save_progress()
	return true

func activate_object(object: Dictionary) -> void:
	object.active = true
	if not collected_objects.has(object.id):
		collected_objects.append(object.id)
	dirty = true

func tick_objects() -> void:
	var radius := 26.0 if upgrades.has("magnet") else 9.0
	for object in level.objects:
		if object.kind == "coin" and not object.active and player.position.distance_to(object.position)<radius:
			activate_object(object)
			coins += 1
			audio.play("coin")
		elif object.kind == "boss_key" and not object.active and player.position.distance_to(object.position)<12:
			activate_object(object)
			if not boss_keys.has(current):
				boss_keys.append(current)
			keys = boss_keys.size()
			audio.play("key")
			tell("Llave de %s recogida. %d de 2 para la puerta del Palacio." % [KEY_BOSSES[current],keys])
			save_progress()

func collect(kind: String) -> void:
	if collected.has(current):
		return
	collected.append(current)
	match kind:
		"double_jump":
			player.double_jump = true
			tell("DOBLE SALTO. Pulsa salto otra vez en el aire.")
		"dash":
			player.dash = true
			tell("IMPULSO. SHIFT o K. Explora las profundidades.")
		"key":
			keys += 1
			tell("Llave de " + ("Huesos" if current == "bone_return" else "Ruinas") + ". Abre el Palacio con ambas llaves.")
		"heart":
			player.max_health = mini(player.max_health+1,8)
			player.health = player.max_health
			tell("Vitalidad aumentada. Salud restaurada.")
		"coin":
			coins += 8
			tell("Tesoro: +8 monedas.")
		"ending":
			checkpoint = "town"
			enter_room("town")
			tell("MERIDIANO RESTAURADO. La expedicion comienza en el Pueblo. Cada mision abre un mundo.")
	save_progress()

func attack() -> void:
	if weapons[equipped_weapon].durability <= 0 and equipped_weapon != "pistol":
		equip_weapon("pistol")
		tell("Arma agotada. Equipada pistola. Repara en cualquier tienda.")
		return
	var stats := weapon_stats()
	audio.play("shoot" if equipped_weapon=="pistol" else equipped_weapon)
	for burst in range(stats.burst):
		for pellet in range(stats.pellets):
			var angle: float = lerpf(-stats.spread,stats.spread,float(pellet)/maxi(1,stats.pellets-1)) if stats.pellets>1 else 0.0
			var velocity := Vector2(player.facing,0).rotated(angle)*float(stats.speed)
			shots.append({"position":player.position+Vector2(player.facing*6,-1),"velocity":velocity,"range":stats.range,"damage":stats.damage,"pierce":stats.pierce,"burn":stats.burn,"radius":stats.radius,"kind":stats.kind,"color":ARSENAL.weapon(equipped_weapon).color,"hits":[],"delay":burst*0.055})
	var wear := 0.8 if equipped_title=="keeper" else 0.85 if equipped_title=="immortal" else 1.0
	var previous: float = weapons[equipped_weapon].durability
	weapons[equipped_weapon].durability = maxf(0,previous-wear)
	if previous>0 and weapons[equipped_weapon].durability==0:
		tell("Arma agotada. Repara en la tienda. La pistola conserva un disparo de emergencia.")
	apply_upgrades()
	dirty = true

func player_sound(id: String) -> void:
	audio.play(id)
	if id == "shield":
		dirty = true

func tick_shots(delta: float) -> void:
	for i in range(shots.size()-1,-1,-1):
		var shot := shots[i]
		var step_time := delta
		if shot.delay > 0:
			step_time = maxf(0,delta-shot.delay)
			shot.delay -= delta
			if step_time == 0: continue
		var old: Vector2 = shot.position
		var travel: float = minf(shot.range,shot.velocity.length()*step_time)
		shot.position += shot.velocity.normalized()*travel
		shot.range -= travel
		var used := false
		var candidates := enemies.duplicate()
		candidates.sort_custom(func(a,b): return old.distance_squared_to(a.position)<old.distance_squared_to(b.position))
		for enemy in candidates:
			var enemy_center: Vector2 = enemy.position+Vector2(0,-4 if enemy.boss else 0)
			var closest := Geometry2D.get_closest_point_to_segment(enemy_center,old,shot.position)
			if enemy.alive and not shot.hits.has(enemy.get_instance_id()) and closest.distance_to(enemy_center)<(9 if enemy.boss else 5)+shot.radius:
				shot.hits.append(enemy.get_instance_id())
				if shot.burn > 0: enemy.ignite(int(shot.burn))
				enemy.hit(int(shot.damage))
				audio.play("hit")
				shot.pierce -= 1
				if shot.pierce < 0:
					used = true
					break
		if not used:
			for object in level.objects:
				if object.active or object.kind not in ["crate","lever","quest"]:
					continue
				if object.kind == "quest" and postgame.stage != 3: continue
				if Geometry2D.get_closest_point_to_segment(object.position,old,shot.position).distance_to(object.position)<6+shot.radius:
					if object.kind == "quest":
						postgame.shoot_switch(object)
						continue
					activate_object(object)
					if object.kind == "crate":
						coins += 1
						audio.play("crate")
					else:
						audio.play("switch")
						tell("Mecanismo activado. Busca el cofre.")
					used = true
					break
		if used or shot.range<=0:
			shots.remove_at(i)
	queue_redraw()

func spawn_trial_wave() -> void:
	if not postgame.trial.is_empty(): postgame.spawn_trial()

func enemy_defeated(enemy: Node2D, enemy_id: String) -> void:
	if defeated_enemies.has(enemy_id):
		return
	defeated_enemies.append(enemy_id)
	# Each enemy pays only once, including if you leave before clearing its room.
	coins += 1 if not enemy.boss else 0
	dirty = true
	for other in enemies:
		if other.alive and not other.has_meta("post_id"):
			check_achievements()
			return
	if not defeated.has(current):
		defeated.append(current)
		refresh_doors()
		if data.room(current).reward == "boss":
			spawn_boss_key(Vector2(enemy.position.x,level.floor_y-4))
			audio.play("boss_down")
			audio.room_track(data.room(current),true)
			tell("Guardian del Alba vencido. Abre el cofre del santuario." if current == "aurora_core" else "Guardian vencido. Recoge su llave y abre el cofre." if KEY_BOSSES.has(current) else "Nido liberado. Abre el cofre y vuelve al guia del Pueblo.")
		save_progress()

func spawn_boss_key(pos: Vector2) -> void:
	if not KEY_BOSSES.has(current) or boss_keys.has(current):
		return
	for object in level.objects:
		if object.kind == "boss_key":
			return
	level.add_object("boss_key",Vector2(clampf(pos.x,48,level.room_size.x-48),level.floor_y-4),"boss_key","key")
	level.queue_redraw()

func health_changed(value: int) -> void:
	audio.play("death" if value <= 0 else "hurt")
	if value<=0:
		postgame.trial = ""
		player.health = player.max_health
		flask_charges = 1 if upgrades.has("flask") else 0
		player.shield = upgrades.has("guard")
		dirty = true
		player.invulnerable_timer = 1.5
		call_deferred("enter_room",checkpoint)
		tell("Has vuelto al ultimo descanso.")
	else:
		player.velocity.y = -100
		player.velocity.x = -player.facing*70

func tell(text: String) -> void:
	message = text
	message_time = clampf(1.1+text.length()*0.018,1.5,2.8)

func check_achievements(quiet := false) -> void:
	for entry in MILESTONES.ACHIEVEMENTS:
		if achievements.has(entry.id) or MILESTONES.progress(self,entry.id) < entry.target:
			continue
		achievements.append(entry.id)
		dirty = true
		var notice: String = "LOGRO: "+entry.name
		if not entry.cosmetic.is_empty() and not cosmetics.has(entry.cosmetic):
			cosmetics.append(entry.cosmetic)
			notice += ". NUEVO ASPECTO EN Q."
		if entry.has("weapon"):
			unlock_weapon(entry.weapon)
			notice += ". ARMA UNICA EN DIARIO."
		if entry.has("title") and not titles.has(entry.title):
			titles.append(entry.title)
		if not quiet:
			achievement_queue.append(notice)

func journal_action(action: String) -> void:
	match action:
		"move_left","move_right":
			journal_tab = wrapi(journal_tab+(-1 if action == "move_left" else 1),0,6)
			journal_selection = 0
		"shop_up","shop_down":
			var count: int = maxi(1,postgame.remaining_rooms().size()) if journal_tab==0 else journal_entries().size()
			journal_selection = wrapi(journal_selection+(-1 if action == "shop_up" else 1),0,count)
		"menu_accept":
			if journal_tab == 0 and postgame.active():
				journal_open = false
				map_open = true
				hud.atlas.select_room(objective_room())
			if journal_tab == 3:
				equip_weapon(ARSENAL.WEAPONS[journal_selection].id)
			elif journal_tab == 4:
				var title_id: String = ARSENAL.TITLES[journal_selection].id
				if titles.has(title_id):
					equipped_title = title_id
					apply_upgrades()
					save_progress()
			if journal_tab == 2:
				var style: Dictionary = MILESTONES.STYLES[journal_selection]
				if cosmetics.has(style.id):
					equipped_style = style.id
					apply_upgrades()
					save_progress()
				else:
					audio.play("error")
					return
	audio.play("menu")
	hud.queue_redraw()

func journal_entries() -> Array:
	if journal_tab==5: return progression.entries()
	return MILESTONES.ACHIEVEMENTS if journal_tab==1 else MILESTONES.STYLES if journal_tab==2 else ARSENAL.WEAPONS if journal_tab==3 else ARSENAL.TITLES

func collection_page_size() -> int:
	return 3 if journal_tab==5 else 4

func collection_row_y() -> int:
	return 66 if journal_tab==5 else 51

func _process(delta: float) -> void:
	if quitting or not is_instance_valid(audio):
		return
	audio.ducked = menu_state == "pause" or map_open or journal_open or shop_open
	if session_active and menu_state.is_empty() and not map_open and not journal_open and not shop_open:
		if message_time <= 0:
			achievement_timer = maxf(0,achievement_timer-delta)
		if message_time <= 0 and achievement_timer == 0 and not achievement_queue.is_empty():
			achievement_notice = achievement_queue.pop_front()
			achievement_timer = 2.8
			audio.play("achievement")
	hud.queue_redraw()
	touch.queue_redraw()
	projectile_renderer.queue_redraw()

func save_progress() -> bool:
	if not session_active:
		return false
	progression.sync_rewards()
	check_achievements()
	var file := FileAccess.open(save_path,FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"version":4,"quest_items":progression.items,"weapons":weapons,"equipped_weapon":equipped_weapon,"titles":titles,"equipped_title":equipped_title,"postgame":postgame.save_data(),"checkpoint":checkpoint,"visited":visited,"collected":collected,"collected_objects":collected_objects,"defeated":defeated,"keys":keys,"coins":coins,"double_jump":player.double_jump,"dash":player.dash,"max_health":player.max_health,"quest_started":quest_started,"quest_paid":quest_paid,"upgrades":upgrades,"flask_charges":flask_charges,"defeated_enemies":defeated_enemies,"boss_keys":boss_keys,"achievements":achievements,"cosmetics":cosmetics,"equipped_style":equipped_style,"heart_purchases":heart_purchases,"tonics":tonics,"shield":player.shield,"muted":audio.muted}))
		file.flush()
		if file.get_error() != OK:
			return false
		dirty = false
		autosave_timer = 0
		return true
	return false

func read_progress() -> Dictionary:
	if not FileAccess.file_exists(save_path):
		return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(save_path)) != OK:
		return {}
	var parsed = parser.data
	if not parsed is Dictionary:
		return {}
	if data.room(str(parsed.get("checkpoint",""))).is_empty():
		return {}
	for field in ["visited","collected","collected_objects","defeated","upgrades","defeated_enemies","boss_keys","achievements","cosmetics"]:
		if not parsed.get(field,[]) is Array:
			return {}
	return parsed

func load_progress() -> bool:
	var parsed := read_progress()
	if parsed.is_empty():
		return false
	checkpoint = str(parsed.checkpoint)
	visited = parsed.get("visited",[])
	collected = parsed.get("collected",[])
	collected_objects = parsed.get("collected_objects",[])
	defeated = parsed.get("defeated",[])
	keys = int(parsed.get("keys",0))
	coins = int(parsed.get("coins",0))
	quest_started = bool(parsed.get("quest_started",false))
	quest_paid = bool(parsed.get("quest_paid",false))
	player.double_jump = bool(parsed.get("double_jump",false))
	player.dash = bool(parsed.get("dash",false))
	player.max_health = clampi(int(parsed.get("max_health",3)),3,8)
	player.health = player.max_health
	upgrades.clear()
	var saved_upgrades = parsed.get("upgrades",[])
	if saved_upgrades is Array:
		for id in SHOP.PERMANENT:
			if saved_upgrades.has(id):
				upgrades.append(id)
	flask_charges = clampi(int(parsed.get("flask_charges",1)),0,1) if upgrades.has("flask") else 0
	defeated_enemies = parsed.get("defeated_enemies",[])
	boss_keys = []
	for boss in KEY_BOSSES:
		if parsed.get("boss_keys",[]).has(boss):
			boss_keys.append(boss)
	# Old saves awarded keys in treasure rooms; retain them without duplicating drops.
	if int(parsed.get("version",1)) < 2:
		for pair in [["bone_return","bone_lord"],["city_end","royal_spire"]]:
			if collected.has(pair[0]) or keys >= 2:
				if not boss_keys.has(pair[1]):
					boss_keys.append(pair[1])
		# Very early saves stored just a count. Preserve that count as well.
		if keys == 1 and boss_keys.is_empty():
			boss_keys.append("royal_spire" if defeated.has("royal_spire") and not defeated.has("bone_lord") else "bone_lord")
	keys = boss_keys.size()
	achievements = parsed.get("achievements",[])
	cosmetics = parsed.get("cosmetics",["classic"])
	if not cosmetics.has("classic"):
		cosmetics.append("classic")
	equipped_style = str(parsed.get("equipped_style","classic"))
	if not cosmetics.has(equipped_style):
		equipped_style = "classic"
	heart_purchases = clampi(int(parsed.get("heart_purchases",0)),0,2)
	tonics = clampi(int(parsed.get("tonics",0)),0,tonic_capacity())
	player.shield = bool(parsed.get("shield",false)) and upgrades.has("guard")
	audio.muted = bool(parsed.get("muted",false))
	weapons = ARSENAL.restore(parsed.get("weapons",{}) if parsed.get("weapons",{}) is Dictionary else {})
	equipped_weapon = str(parsed.get("equipped_weapon","pistol"))
	if not weapons.has(equipped_weapon): equipped_weapon = "pistol"
	titles = ["none"]
	for entry in ARSENAL.TITLES:
		if parsed.get("titles",[]) is Array and parsed.get("titles",[]).has(entry.id) and not titles.has(entry.id): titles.append(entry.id)
	equipped_title = str(parsed.get("equipped_title","none"))
	if not titles.has(equipped_title): equipped_title = "none"
	postgame.load_data(parsed.get("postgame",{}) if parsed.get("postgame",{}) is Dictionary else {})
	progression.restore(parsed.get("quest_items",[]) if parsed.get("quest_items",[]) is Array else [],int(parsed.get("version",1))<4)
	if not progression.can_enter(checkpoint):
		checkpoint = "town" if progression.can_enter("town") else "tutorial"
	check_achievements(true)
	apply_upgrades()
	return true

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and player:
		quit_game()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST and player:
		if shop_open:
			shop_action("shop_close")
		elif map_open or journal_open:
			map_open = false
			journal_open = false
		elif menu_state == "pause":
			resume_game()
		elif session_active:
			open_pause()
	elif what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT] and is_instance_valid(touch):
		touch.release_all()
		if session_active:
			open_pause()
			save_progress()
		audio.suspended = true
	elif what in [NOTIFICATION_APPLICATION_RESUMED,NOTIFICATION_APPLICATION_FOCUS_IN] and is_instance_valid(audio):
		audio.suspended = false

func draw_shots(canvas: Node2D) -> void:
	for shot in shots:
		if shot.delay>0: continue
		var heading: Vector2 = shot.velocity.normalized()
		var length := 14.0 if shot.kind=="lance" else 8.0 if shot.kind=="flame" else 6.0
		for index in range(3):
			var tint: Color = shot.color
			tint.a = 0.8-index*0.22
			var size := 5.0-index if shot.kind=="flame" else 3.0-index*0.5
			canvas.draw_texture_rect_region(PIXEL.TEXTURE,Rect2(shot.position-heading*length*index/2-Vector2.ONE*size/2,Vector2.ONE*size),Rect2(99,19,2,2),tint)
		canvas.draw_texture_rect_region(PIXEL.TEXTURE,Rect2(shot.position-Vector2(2,2),Vector2(4,4)),Rect2(99,19,2,2),Color.WHITE)
