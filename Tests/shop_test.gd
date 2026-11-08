extends SceneTree
var failures := 0
var game: Node2D

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error(label)

func object_of(kind: String) -> Dictionary:
	for object in game.level.objects:
		if object.kind == kind:
			return object
	return {}

func buy(index: int) -> bool:
	game.shop_selection = index
	return game.buy_selected()

func press_key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	# Flush synthetic keyboard events before manually advancing the simulation.
	Input.flush_buffered_events()
	game._physics_process(1.0/60.0)
	event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func fire_at(enemy: Node2D) -> void:
	game.shots.clear()
	game.player.position = enemy.position-Vector2(35,0)
	game.player.facing = 1
	game.attack()
	for i in range(8):
		game.tick_shots(1.0/60.0)

func run() -> void:
	game = load("res://Scenes/main.tscn").instantiate()
	game.save_path = "res://Tests/shop_save.json"
	if FileAccess.file_exists(game.save_path):
		DirAccess.remove_absolute(game.save_path)
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.new_game()
	game.input_block_frames = 0
	game.enter_room("town")
	game.player.position = object_of("merchant").position-Vector2(10,0)
	game.transition_cooldown = 0
	game.coins = 500
	game.defeated = ["bone_lord","royal_spire"]
	game.player.dash = true
	for room in game.data.rooms.slice(0,18):
		if not game.visited.has(room.id): game.visited.append(room.id)
	await press_key(KEY_E)
	check(game.shop_open and game.coins == 500,"E must open the menu without buying")
	var start: Vector2 = game.player.position
	await press_key(KEY_DOWN)
	check(game.shop_selection == 1 and game.coins == 500,"Down must select, never accidentally buy")
	check(game.player.position == start,"Shop must freeze world movement")
	await press_key(KEY_UP)
	await press_key(KEY_E)
	check(game.upgrades.has("power") and game.coins == 445,"Keyboard purchase must buy cannon for 55")
	check(game.player.weapon_damage == 2,"Cannon must configure double damage")
	check(not buy(0) and game.coins == 445,"Permanent upgrades must not charge twice")
	await press_key(KEY_ESCAPE)
	check(not game.shop_open,"Escape must close the menu")
	check(not buy(1) and game.coins == 445,"Closed shop must not accept purchases")
	game.enter_room("nest")
	var boss: Node2D = game.enemies[0]
	fire_at(boss)
	check(boss.hp == boss.max_hp-2,"Upgraded bullet must remove two boss HP")
	# Rapid-fire should be both automatic and effective against hurt cooldowns.
	game.enter_room("town")
	game.use_object(object_of("merchant"))
	check(buy(1) and game.coins == 360,"Rapid mechanism must cost 85")
	check(game.player.rapid_fire,"Rapid purchase must enable the player upgrade")
	game.shop_action("shop_close")
	game.shots.clear()
	game.player.attack_timer = 0
	Input.action_press("attack")
	for frame in range(60):
		game.player.tick(1.0/60.0)
	Input.action_release("attack")
	check(game.shots.size()>=7,"Holding J must fire at least seven times a second")
	game.enter_room("nest")
	boss = game.enemies[0]
	fire_at(boss)
	boss.tick(0.14)
	fire_at(boss)
	check(boss.hp == boss.max_hp-4,"Rapid shots must both damage a boss after its hit flash")
	# Magnet changes real collection reach.
	game.defeated.append("nest")
	game.enter_room("tutorial")
	var coin := object_of("coin")
	game.player.position = coin.position+Vector2(0,-20)
	game.tick_objects()
	check(not coin.active,"Default coin pickup must not reach 20 pixels")
	game.enter_room("town")
	game.use_object(object_of("merchant"))
	check(buy(2) and game.coins == 340,"Magnet must cost 20")
	game.shop_action("shop_close")
	game.enter_room("tutorial")
	coin = object_of("coin")
	game.player.position = coin.position+Vector2(0,-20)
	var balance: int = game.coins
	game.tick_objects()
	check(coin.active and game.coins>balance,"Magnet must actually collect distant coins")
	# Reusable flask: no waste at full health, exactly two hearts, refills at benches.
	game.enter_room("town")
	game.use_object(object_of("merchant"))
	balance = game.coins
	check(buy(3) and game.coins == balance-30,"Flask must cost 30 and be granted full")
	check(game.flask_charges == 1,"New flask must contain one use")
	game.player.health = 1
	check(not game.use_flask() and game.flask_charges == 1,"Paused shop must not consume a flask")
	game.shop_action("shop_close")
	game.player.health = game.player.max_health
	check(not game.use_flask() and game.flask_charges == 1,"Full health must preserve flask charge")
	game.player.health = 1
	check(game.use_flask() and game.player.health == 3 and game.flask_charges == 0,"Flask must heal two hearts and consume its charge")
	game.player.health = 1
	check(not game.use_flask() and game.player.health == 1,"Empty flask must not heal")
	game.use_object(object_of("bench"))
	check(game.flask_charges == 1 and game.player.health == game.player.max_health,"Bench must refill flask and health for free")
	game.player.health = game.player.max_health-1
	await press_key(KEY_F)
	check(game.flask_charges == 0 and game.player.health == game.player.max_health,"F must use flask without overhealing")
	# Save new purchases and empty state, then round-trip through the loader.
	game.save_progress()
	var owned: Array = game.upgrades.duplicate()
	balance = game.coins
	game.upgrades.clear()
	game.flask_charges = 1
	game.apply_upgrades()
	game.load_progress()
	check(game.upgrades == owned and game.coins == balance and game.flask_charges == 0,"Purchases and empty flask must survive reloading")
	check(game.player.weapon_damage == 2 and game.player.rapid_fire,"Reload must apply combat effects")
	# Existing health services retain limits and cannot waste currency.
	game.use_object(object_of("merchant"))
	game.coins = 0
	game.player.max_health = 3
	check(not buy(4) and game.player.max_health == 3,"Insufficient money must not buy health")
	game.coins = 100
	game.player.max_health = 8
	check(not buy(4) and game.coins == 100,"Maximum health must not charge for a heart")
	game.player.health = 8
	check(not buy(5) and game.coins == 100,"Full health must not charge for healing")
	game.player.health = 1
	check(buy(5) and game.player.health == 8 and game.coins == 97,"Healing service must still work")
	game.player.max_health = 5
	check(buy(4) and game.player.max_health == 6 and game.coins == 32,"Heart service must still work")
	game.shop_action("shop_close")
	# Simulate an old save lacking any shop fields, without touching the user's file.
	var file := FileAccess.open(game.save_path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"checkpoint":"town","coins":47,"keys":1,"double_jump":true,"max_health":4}))
	file.close()
	game.load_progress()
	check(game.coins == 47 and game.keys == 1 and game.player.double_jump and game.player.max_health == 4,"Legacy progression must survive")
	check(game.upgrades.is_empty() and game.flask_charges == 0 and game.player.weapon_damage == 1+game.progression.attack_bonus() and not game.player.rapid_fire,"Old saves must not invent purchases")
	game.dirty = false
	DirAccess.remove_absolute(game.save_path)
	print("SHOP: %d failures; keyboard menu, four upgrades, real combat/pickups, flask, prices, limits and save compatibility" % failures)
	quit(1 if failures else 0)
