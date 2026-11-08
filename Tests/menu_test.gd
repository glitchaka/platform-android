extends SceneTree
var game: Node2D
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error(label)

func press_key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	game._physics_process(1.0/60.0)
	event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = false
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await process_frame

func settle_input() -> void:
	for i in range(2):
		game._physics_process(1.0/60.0)

func run_exit_case(mode: String) -> void:
	var path := "res://Tests/menu_exit_"+mode+".json"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var previous := ""
	if mode == "existing":
		previous = JSON.stringify({"checkpoint":"town","coins":89})
		var file := FileAccess.open(path,FileAccess.WRITE)
		file.store_string(previous)
		file.close()
	var output: Array = []
	var code := OS.execute(OS.get_executable_path(),["--headless","--path",ProjectSettings.globalize_path("res://"),"--log-file",ProjectSettings.globalize_path("res://Tests/menu-exit-"+mode+".log"),"--script","res://Tests/menu_exit_probe.gd","--quit-after","120","--",mode],output,true)
	check(code == 0,"Process must close: "+mode+" "+str(output))
	if mode == "title":
		check(not FileAccess.file_exists(path),"Unused title exit must not create a save")
	elif mode == "existing":
		check(FileAccess.get_file_as_string(path) == previous,"Title exit must not overwrite a saved game")
	else:
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		check(parsed is Dictionary and parsed.coins == 37 and parsed.checkpoint == "town" and parsed.double_jump,"Exit must save before closing: "+mode)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

func run() -> void:
	game = load("res://Scenes/main.tscn").instantiate()
	game.save_path = "res://Tests/menu_save.json"
	if FileAccess.file_exists(game.save_path):
		DirAccess.remove_absolute(game.save_path)
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	check(game.menu_state == "title" and not game.session_active,"Startup must show title")
	check(not game.get_node("World").visible and not game.save_available,"Missing save disables Load and hides world")
	check(not FileAccess.file_exists(game.save_path),"Startup must not create a save")
	await press_key(KEY_DOWN)
	await press_key(KEY_ENTER)
	check(game.menu_state == "title" and not game.session_active,"Unavailable Load must stay at title")
	check(not FileAccess.file_exists(game.save_path),"Unavailable Load must not write a save")
	await press_key(KEY_UP)
	await press_key(KEY_SPACE)
	check(game.session_active and game.menu_state == "" and game.current == "tutorial","New Game starts tutorial")
	check(FileAccess.file_exists(game.save_path),"New Game saves immediately")
	settle_input()
	check(game.player.grounded and is_zero_approx(game.player.velocity.y),"Space selection must not leak a jump")
	game.enter_room("nest")
	game.coins = 47
	game.keys = 2
	game.boss_keys = ["bone_lord","royal_spire"]
	game.checkpoint = "town"
	game.collected = ["canopy","bone_return"]
	game.collected_objects = ["tutorial:lever","tutorial:chest"]
	game.defeated = ["tutorial"]
	game.quest_started = true
	game.quest_paid = true
	game.upgrades = ["power","rapid","flask"]
	game.flask_charges = 0
	game.player.double_jump = true
	game.player.dash = true
	game.player.max_health = 5
	game.player.health = 2
	game.apply_upgrades()
	game.attack()
	await press_key(KEY_ESCAPE)
	check(game.menu_state == "pause","Escape opens pause")
	var pos: Vector2 = game.player.position
	var enemy_pos: Vector2 = game.enemies[0].position
	var enemy_time: float = game.enemies[0].time
	var shot_pos: Vector2 = game.shots[0].position
	var health: int = game.player.health
	for i in range(60):
		game._physics_process(1.0/60.0)
	await press_key(KEY_F)
	await press_key(KEY_J)
	check(game.player.position == pos and game.enemies[0].position == enemy_pos and game.enemies[0].time == enemy_time,"Pause freezes player and guardian")
	check(game.shots.size() == 1 and game.shots[0].position == shot_pos,"Pause freezes shots and suppresses fire")
	check(game.player.health == health and game.flask_charges == 0,"Pause suppresses items and damage")
	check(game.player.sprite.speed_scale == 0,"Pause freezes animation")
	await press_key(KEY_ESCAPE)
	check(game.menu_state == "" and game.player.sprite.speed_scale == 1,"Escape resumes session")
	settle_input()
	await press_key(KEY_ESCAPE)
	await press_key(KEY_DOWN)
	await press_key(KEY_ENTER)
	check(game.menu_state == "title" and not game.session_active and game.save_available,"Return must save and show title")
	var saved: Dictionary = game.read_progress()
	check(saved.coins == 47 and saved.keys == 2 and saved.upgrades.size() == 3,"Return preserves progress")
	var saved_text := FileAccess.get_file_as_string(game.save_path)
	game._physics_process(30)
	check(FileAccess.get_file_as_string(game.save_path) == saved_text,"Title must not autosave over progress")
	await press_key(KEY_ENTER)
	check(game.session_active and game.current == "town" and game.coins == 47,"Load resumes at saved rest")
	check(game.player.double_jump and game.player.dash and game.player.weapon_damage == 2+game.progression.attack_bonus() and game.player.rapid_fire,"Load restores progression and purchases")
	check(game.flask_charges == 0 and game.player.max_health == 5,"Load restores empty flask and health upgrades")
	settle_input()
	for object in game.level.objects:
		if object.kind == "merchant":
			game.use_object(object)
	await press_key(KEY_ESCAPE)
	check(not game.shop_open and game.menu_state == "","Escape closes shop before pause")
	game.map_open = true
	await press_key(KEY_ESCAPE)
	check(not game.map_open and game.menu_state == "","Escape closes atlas before pause")
	game.journal_open = true
	await press_key(KEY_ESCAPE)
	check(not game.journal_open and game.menu_state == "","Escape closes journal before pause")
	game.open_pause()
	var real_path: String = game.save_path
	game.save_path = "res://Tests/missing-save-directory/no-save.json"
	check(not game.return_to_title() and game.session_active and game.menu_state == "pause","Failed save keeps session open")
	check(not game.quit_game() and game.session_active,"Failed save blocks quitting")
	game.save_path = real_path
	game.return_to_title()
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = game.hud.get_global_transform_with_canvas()*game.hud.menu_button_rect(0).get_center()
	game._unhandled_input(click)
	check(game.session_active and game.current == "tutorial" and game.checkpoint == "tutorial","Mouse New Game restarts tutorial")
	check(game.coins == 0 and game.keys == 0 and game.player.max_health == 3 and game.player.health == 3,"New Game clears currency and health upgrades")
	check(not game.player.double_jump and not game.player.dash and game.upgrades.is_empty() and game.flask_charges == 0,"New Game clears abilities and purchases")
	check(game.collected.is_empty() and game.collected_objects.is_empty() and game.defeated.is_empty() and game.visited == ["tutorial"],"New Game resets world completion")
	check(not game.quest_started and not game.quest_paid and game.player.weapon_damage == 1 and not game.player.rapid_fire,"New Game resets quests and combat")
	saved = game.read_progress()
	check(saved.coins == 0 and saved.keys == 0 and saved.collected.is_empty() and saved.upgrades.is_empty(),"Fresh save replaces progress on disk")
	game.return_to_title()
	var file := FileAccess.open(game.save_path,FileAccess.WRITE)
	file.store_string("{broken save")
	file.close()
	game.show_title()
	check(not game.save_available,"Corrupt save disables Load")
	check(not game.continue_game() and game.menu_state == "title","Corrupt save cannot start session")
	check(FileAccess.get_file_as_string(game.save_path) == "{broken save","Rejected load must not modify file")
	file = FileAccess.open(game.save_path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"checkpoint":"town","visited":42}))
	file.close()
	check(game.read_progress().is_empty(),"Malformed save arrays must not crash")
	game.dirty = false
	DirAccess.remove_absolute(game.save_path)
	for mode in ["title","existing","pause","window"]:
		run_exit_case(mode)
	print("MENUS: %d failures; title, keyboard/mouse, reset, load, pause, save failures, actual exits and overlay priority" % failures)
	quit(1 if failures else 0)
