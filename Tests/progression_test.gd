extends SceneTree
var game: Node2D
var failures := 0
var assertions := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	assertions += 1
	if not value:
		failures += 1
		push_error(label)

func object_of(kind: String) -> Dictionary:
	for object in game.level.objects:
		if object.kind == kind:
			return object
	return {}

func kill_boss() -> void:
	var boss: Node2D = game.enemies[0]
	while boss.alive:
		boss.hurt_time = 0
		boss.hit()

func buy(id: String) -> bool:
	for i in range(game.SHOP.ITEMS.size()):
		if game.SHOP.ITEMS[i].id == id:
			game.shop_selection = i
			return game.buy_selected()
	return false

func tap(index: int, pos: Vector2, pressed := true) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = root.get_final_transform()*game.touch.get_global_transform_with_canvas()*pos
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func drag(index: int, pos: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = root.get_final_transform()*game.touch.get_global_transform_with_canvas()*pos
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func run() -> void:
	game = load("res://Scenes/main.tscn").instantiate()
	game.save_path = "res://Tests/progression_save.json"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.touch.enabled = true
	check(game.audio.current_track == "title","Title music must play on the initial menu")
	tap(0,Vector2(160,70))
	tap(0,Vector2(160,70),false)
	check(game.session_active and game.current == "tutorial","Touch New Game must start a session")
	game.input_block_frames = 0
	# Collect every available early coin, including crates, quest-independent chests and enemy.
	for id in ["tutorial","town"]:
		game.enter_room(id)
		for enemy in game.enemies:
			enemy.hit(100)
		for object in game.level.objects:
			if object.kind == "lever": game.use_object(object)
		for object in game.level.objects:
			if object.kind == "coin":
				game.player.position = object.position
				game.tick_objects()
			elif object.kind == "chest": game.use_object(object)
			elif object.kind == "crate":
				game.player.position = object.position-Vector2(18,0)
				game.player.facing = 1
				game.attack()
				for i in range(8): game.tick_shots(1.0/60)
	check(game.coins <= 14,"Tutorial and town must not fund early combat upgrades")
	print("EARLY ECONOMY: all tutorial and town sources = %d coins" % game.coins)
	game.use_object(object_of("merchant"))
	game.coins = 999
	check(not buy("heart") and not buy("rapid") and not buy("power"),"Money alone must not bypass progression locks")
	game.shop_action("shop_close")
	# Music continues within a world and changes for a new world or boss.
	game.enter_room("spore_hall")
	var changes: int = game.audio.transitions
	game.enter_room("moss_gate")
	check(game.audio.transitions == changes and game.audio.current_track == "fungus","Same-world music must not restart between rooms")
	game.enter_room("nest")
	check(game.audio.current_track == "nest","Nido must have its own music")
	kill_boss()
	check(game.achievements.has("nest") and game.cosmetics.has("amber"),"Nido victory must award an achievement and free appearance")
	# Both guardians drop keys on the floor. Chests never consume/require the palace keys.
	for id in ["bone_lord","royal_spire"]:
		game.enter_room(id)
		var chest := object_of("chest")
		check(not chest.is_empty(),"Guardian arena must contain a visible chest")
		game.use_object(chest)
		check(not chest.active,"Guardian seals the chest before defeat")
		kill_boss()
		check(not object_of("boss_key").is_empty(),"Dying guardian must leave a visible physical key")
		game.use_object(chest)
		check(chest.active,"Chest opens after victory with zero key requirements")
		game.checkpoint = "town"
		game.save_progress()
		game.return_to_title()
		game.continue_game()
		game.enter_room(id)
		var drop := object_of("boss_key")
		check(not drop.is_empty() and not drop.active,"Uncollected key survives save, title, load and room re-entry")
		check(game.enemies.is_empty(),"Defeated guardian must stay defeated")
		game.player.position = drop.position
		game.tick_objects()
		var count: int = game.keys
		game.tick_objects()
		game.enter_room(id)
		check(game.keys == count and object_of("boss_key").is_empty(),"Collected key must never duplicate on revisit")
	check(game.keys == 2 and game.can_open("keys"),"Two boss drops must open the palace")
	check(game.achievements.has("keys"),"Collecting both keys must award the achievement")
	# Late economy, repeatable supplies, shield, costumes and persistence.
	for room in game.data.rooms.slice(0,18):
		if not game.visited.has(room.id): game.visited.append(room.id)
	game.player.dash = true
	game.enter_room("town")
	game.use_object(object_of("merchant"))
	game.coins = 500
	check(buy("heart") and game.coins == 435,"First late heart costs 65")
	check(buy("heart") and game.coins == 335,"Second late heart costs 100")
	check(not buy("heart") and game.coins == 335,"Only two shop hearts can be purchased")
	check(buy("rapid") and game.coins == 250,"Late rapid fire costs 85")
	check(buy("tonic") and buy("tonic") and buy("tonic") and not buy("tonic"),"Tonic inventory must enforce its capacity")
	check(buy("satchel") and buy("tonic") and buy("tonic") and not buy("tonic"),"Satchel must expand inventory to five")
	check(buy("guard"),"Late guardian amulet can be purchased")
	check(buy("ember") and game.equipped_style == "ember" and game.player.trail_enabled,"Shop costume equips original sprite tint and dash trail")
	game.shop_action("shop_close")
	game.player.health = 1
	check(game.use_flask() and game.tonics == 4 and game.player.health == 3,"Tonic fallback must consume exactly one item and heal two")
	game.player.invulnerable_timer = 0
	game.player.take_damage()
	check(game.player.health == 3 and not game.player.shield,"Amulet absorbs exactly one hit")
	game.use_object(object_of("bench"))
	check(game.player.shield,"Resting recharges the amulet")
	game.save_progress()
	game.reset_progress()
	game.load_progress()
	check(game.keys == 2 and game.heart_purchases == 2 and game.tonics == 4,"New progression fields survive reload")
	check(game.equipped_style == "ember" and game.achievements.has("nest"),"Cosmetics and achievements persist")
	# A legacy cleared guardian with a missing key recovers the drop, not a dead end.
	var file := FileAccess.open(game.save_path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"checkpoint":"town","defeated":["bone_lord"],"keys":0,"coins":31}))
	file.close()
	game.load_progress()
	game.begin_session()
	game.enter_room("bone_lord")
	check(not object_of("boss_key").is_empty() and game.coins == 31,"Legacy broken saves recover a key without resetting coins")
	# Genuine multi-finger events: movement + jump + attack together, release and pause.
	game.enter_room("town")
	game.input_block_frames = 0
	game.player.grounded = true
	var before: Vector2 = game.player.position
	tap(1,Vector2(54,136))
	tap(2,Vector2(296,151))
	tap(3,Vector2(300,110))
	game._physics_process(1.0/60)
	check(game.player.position.x > before.x and game.player.velocity.y < 0 and game.shots.size() > 0,"Three simultaneous touches must move, jump and shoot")
	tap(2,Vector2(296,151),false)
	check(Input.is_action_pressed("move_right") and not Input.is_action_pressed("jump"),"Releasing one finger must preserve the other fingers")
	drag(1,Vector2(34,136))
	check(not Input.is_action_pressed("move_right") and game.touch.stick_id == 1,"Joystick dead zone must stop movement without losing the finger")
	drag(1,Vector2(14,136))
	check(Input.is_action_pressed("move_left") and not Input.is_action_pressed("move_right"),"Joystick can cross its dead zone and move left with the same touch")
	tap(4,Vector2(300,11))
	check(game.menu_state == "pause" and not Input.is_action_pressed("move_right") and not Input.is_action_pressed("attack"),"Pause must release all held touch controls")
	tap(4,Vector2(300,11),false)
	tap(5,Vector2(160,70))
	tap(5,Vector2(160,70),false)
	check(game.menu_state.is_empty(),"Touch pause menu must resume")
	game.input_block_frames = 0
	game.enter_room("town")
	game.player.position = object_of("merchant").position
	game.transition_cooldown = 0
	game._physics_process(1.0/60)
	tap(7,Vector2(246,142))
	game._physics_process(1.0/60)
	tap(7,Vector2(246,142),false)
	check(game.shop_open,"USAR must open the nearby merchant")
	game.player.health = 1
	game.coins = 12
	tap(8,Vector2(145,108))
	tap(8,Vector2(145,108),false)
	tap(9,Vector2(188,165))
	tap(9,Vector2(188,165),false)
	check(game.coins == 9 and game.player.health == game.player.max_health,"Touch selection and COMPRAR must buy a healing service")
	tap(10,Vector2(280,165))
	tap(10,Vector2(280,165),false)
	tap(11,Vector2(272,11))
	tap(11,Vector2(272,11),false)
	tap(12,Vector2(154,35))
	tap(12,Vector2(154,35),false)
	check(game.journal_open and game.journal_tab == 2,"Touch diary and wardrobe tabs must open")
	game.cosmetics.append("ember")
	game.journal_selection = 6
	tap(13,Vector2(209,165))
	tap(13,Vector2(209,165),false)
	check(game.equipped_style == "ember","Touch ELEGIR must equip the selected owned aspect")
	tap(14,Vector2(286,165))
	tap(14,Vector2(286,165),false)
	check(not game.journal_open,"Touch SALIR must close the wardrobe")
	game.touch.press_finger(6,Vector2(54,136))
	game._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(game.menu_state == "pause" and game.audio.suspended and game.touch.fingers.is_empty(),"Android backgrounding saves, pauses sound and releases touches")
	game._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check(not game.audio.suspended,"Android foregrounding restores the audio driver")
	game.resume_game()
	game.input_block_frames = 0
	game.player.position = Vector2(70,game.level.floor_y-4)
	game.message_time = 0
	game.nearby_time = 0
	game.tell("Prueba breve de un aviso.")
	check(game.message_time <= 2.8,"Notices must stay brief")
	for frame in range(180):
		game._physics_process(1.0/60)
	check(game.message_time == 0,"Notices must fully disappear after three seconds")
	game.audio.shutdown()
	game.session_active = false
	game.dirty = false
	game.set_process(false)
	game.audio.set_process(false)
	await create_timer(0.15).timeout
	DirAccess.remove_absolute(game.save_path)
	print("PROGRESSION: %d assertions, %d failures; economy, boss drops, chests, migration, audio, achievements, cosmetics, supplies, multitouch and Android lifecycle" % [assertions,failures])
	quit(1 if failures else 0)
