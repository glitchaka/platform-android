extends SceneTree
var game: Node2D
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func object_of(kind: String) -> Dictionary:
	for object in game.level.objects:
		if object.kind == kind:
			return object
	return {}

func clear_enemies() -> void:
	for enemy in game.enemies:
		while enemy.alive:
			enemy.hurt_time = 0
			enemy.hit()

func run() -> void:
	game = load("res://Scenes/main.tscn").instantiate()
	game.save_path = "res://Tests/content_save.json"
	if FileAccess.file_exists(game.save_path):
		DirAccess.remove_absolute(game.save_path)
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.new_game()
	game.input_block_frames = 0
	# The starting challenge has a working gate, not a decorative counter.
	var chest := object_of("chest")
	var lever := object_of("lever")
	game.use_object(chest)
	check(not chest.active,"Tutorial chest must stay locked before its mechanism")
	game.use_object(lever)
	game.use_object(chest)
	check(chest.active and game.coins == 2,"Switch must unlock a paying chest")
	game.use_object(chest)
	check(game.coins == 2,"An opened chest must never pay twice")
	game.use_object(lever)
	var coin := object_of("coin")
	game.player.position = coin.position
	game.tick_objects()
	var balance: int = game.coins
	game.tick_objects()
	check(game.coins == balance,"Coins may only be collected once")
	# A moving projectile must hit the crate and remove it from the world.
	var crate := object_of("crate")
	game.player.position = crate.position-Vector2(20,0)
	game.player.facing = 1
	game.attack()
	for i in range(12):
		game.tick_shots(1.0/60.0)
	check(crate.active and game.coins == balance+1,"Shooting must break a crate and award coins")
	clear_enemies()
	game.enter_room("town")
	var guide := object_of("guide")
	game.use_object(guide)
	check(game.quest_started and game.objective_room() == "nest","Guide must start the Nido quest")
	game.enter_room("nest")
	check(game.enemies.size() == 1 and game.enemies[0].boss,"Nido must contain its guardian")
	var boss: Node2D = game.enemies[0]
	var boss_hp: int = boss.hp
	game.player.position = boss.position-Vector2(45,0)
	game.attack()
	for i in range(14):
		game.tick_shots(1.0/60.0)
	check(boss.hp == boss_hp-game.player.weapon_damage,"Player shots must damage guardians")
	var before: Vector2 = boss.position
	boss.tick(0.3)
	check(boss.position == before,"Guardian must telegraph before charging")
	boss.tick(0.6)
	check(boss.position != before,"Guardian must actually charge after the warning")
	clear_enemies()
	game.enter_room("town")
	balance = game.coins
	game.use_object(object_of("guide"))
	check(game.quest_paid and game.coins == balance+6,"Quest payout must require and reward the guardian kill")
	game.use_object(object_of("guide"))
	check(game.coins == balance+6,"Quest payout must not be farmable")
	var old_health: int = game.player.max_health
	balance = game.coins
	game.use_object(object_of("merchant"))
	game.shop_selection = 4
	game.buy_selected()
	check(game.player.max_health == old_health and game.coins == balance,"Early heart must be locked even after freeing the Nido")
	game.coins = 3
	game.player.health = 1
	game.use_object(object_of("merchant"))
	game.shop_selection = 5
	game.buy_selected()
	check(game.coins == 0 and game.player.health == game.player.max_health,"Healing purchase must charge three coins")
	game.coins = 0
	old_health = game.player.max_health
	game.use_object(object_of("merchant"))
	game.shop_selection = 4
	game.buy_selected()
	check(game.player.max_health == old_health,"Insufficient funds must not purchase an upgrade")
	game.use_object(object_of("bench"))
	check(game.checkpoint == "town","Bench must update checkpoint")
	# Room contents must be supported by terrain and stay inside their geometry.
	for room in game.data.rooms:
		game.enter_room(room.id)
		check(not game.level.objects.is_empty() or room.reward == "boss","Empty room content: "+room.id)
		for door in game.level.exits:
			game.player.position = door.position
			check(game.nearest_object().is_empty(),"An interaction masks an exit in "+room.id)
		for object in game.level.objects:
			check(Rect2(Vector2.ZERO,game.level.room_size).has_point(object.position),"Object outside room: "+room.id)
			var supported := false
			for platform in game.level.platforms:
				if object.position.x>=platform.position.x and object.position.x<=platform.end.x and absf(platform.position.y-object.position.y)<=12:
					supported = true
			check(supported,"Floating interaction: "+object.id)
		await process_frame
	game.enter_room("canopy")
	for object in game.level.objects:
		if object.kind == "lever":
			game.use_object(object)
	game.use_object(object_of("chest"))
	check(game.player.double_jump,"Ability chest must grant double jump")
	game.enter_room("city_spire")
	for object in game.level.objects:
		if object.kind == "lever":
			game.use_object(object)
	game.use_object(object_of("chest"))
	check(game.player.dash,"Ability chest must grant dash")
	for pair in [["bone_lord","bone_return"],["royal_spire","city_end"]]:
		check(not game.can_open("boss:"+pair[0]),"Key room must be guarded")
		game.enter_room(pair[0])
		clear_enemies()
		check(game.can_open("boss:"+pair[0]),"Guardian defeat must unlock key room")
		var drop := object_of("boss_key")
		check(not drop.is_empty(),"Boss must leave a real key")
		game.player.position = drop.position
		game.tick_objects()
		game.enter_room(pair[1])
		for object in game.level.objects:
			if object.kind == "lever":
				game.use_object(object)
		game.use_object(object_of("chest"))
	check(game.keys == 2 and game.can_open("keys"),"Two real boss keys must open the palace")
	game.enter_room("throne")
	for object in game.level.objects:
		if object.kind == "lever":
			game.use_object(object)
	game.use_object(object_of("chest"))
	check(game.collected.has("throne"),"Final chest must complete the objective")
	game.save_progress()
	var saved_coins: int = game.coins
	var saved_objects: Array = game.collected_objects.duplicate()
	game.quest_paid = false
	game.coins = 0
	game.collected_objects.clear()
	game.load_progress()
	check(game.quest_paid and game.coins == saved_coins and game.collected_objects == saved_objects,"Persistent content state must survive reload")
	game.enter_room("tutorial")
	check(object_of("chest").active and object_of("crate").active,"Opened chest and broken crate must remain completed")
	# Opening either overlay must pause simulation, with the whole atlas present.
	game.map_open = true
	var position_before: Vector2 = game.player.position
	game._physics_process(1.0)
	check(game.player.position == position_before,"Atlas must pause movement")
	game.map_open = false
	game.journal_open = true
	game._physics_process(1.0)
	check(game.player.position == position_before,"Journal must pause movement")
	DirAccess.remove_absolute(game.save_path)
	game.dirty = false
	print("CONTENT: %d failures; interactions, shots, quest, shop, 52 populated rooms, keys, ending, persistence and pause" % failures)
	quit(1 if failures else 0)
