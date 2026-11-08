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
		if object.kind == kind: return object
	return {}

func use_door(to: String) -> void:
	var destination := Vector2.ZERO
	for door in game.level.exits:
		if door.to == to: destination = door.position
	check(destination != Vector2.ZERO,"Physical door exists: "+to)
	game.player.position = destination
	game.transition_cooldown = 0
	game.input_block_frames = 0
	Input.action_press("interact")
	game._physics_process(1.0/60)
	Input.action_release("interact")
	await process_frame

func run() -> void:
	game = load("res://Scenes/main.tscn").instantiate()
	game.save_path = "res://Tests/final_zone_save.json"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.new_game()
	game.enter_room("throne")
	await use_door("aurora_gate")
	check(game.current=="throne" and game.message.contains("cinco"),"New game cannot enter final zone and gets the quest requirement")
	game.collected = ["throne"]
	game.player.double_jump = true
	game.player.dash = true
	for entry in game.PROGRESSION.CAMPAIGN: game.progression.grant(entry,true)
	for stage in range(5):
		game.postgame.stage = stage
		game.progression.sync_rewards(true)
		check(not game.progression.can_enter("aurora_gate") and not game.can_open("postgame"),"Final zone is locked during mission "+str(stage+1))
	game.postgame.stage = 5
	game.progression.sync_rewards(true)
	game.refresh_doors()
	check(game.objective_room()=="aurora_gate" and game.objective_text().contains("puerta derecha"),"Completed quests point to the new entrance in map and journal")
	await use_door("aurora_gate")
	check(game.current=="aurora_gate","Real interaction enters the newly unlocked zone")
	check(not object_of("bench").is_empty() and not object_of("merchant").is_empty(),"Entrance contains rest and shop")
	game.use_object(object_of("bench"))
	check(game.checkpoint=="aurora_gate","New zone can be used as checkpoint")
	await use_door("aurora_garden")
	check(game.current=="aurora_garden" and game.level.terrain_style=="Bosque","Garden route uses the new forest atlas")
	await use_door("aurora_core")
	check(game.current=="aurora_core" and game.level.terrain_style=="Escarcha","Sanctuary route uses the new frost atlas")
	var chest := object_of("chest")
	game.use_object(chest)
	check(not chest.active,"Sanctuary chest is sealed while guardian lives")
	for enemy in game.enemies.duplicate(): enemy.hit(10000)
	check(game.defeated.has("aurora_core") and game.message.contains("Alba"),"Guardian defeat clears the new room and gives the correct message")
	var before: int = game.coins
	game.use_object(chest)
	game.use_object(chest)
	check(game.coins==before+60 and game.objective_text().contains("completados"),"Sanctuary pays 60 coins once and completes the route")
	game.save_progress()
	game.reset_progress()
	game.load_progress()
	check(game.checkpoint=="aurora_gate" and game.progression.can_enter("aurora_core"),"Saved checkpoint and final access survive reload")
	game.enter_room("aurora_core")
	check(game.enemies.is_empty() and object_of("chest").active,"Guardian and chest stay completed after reload")
	await use_door("aurora_garden")
	await use_door("aurora_gate")
	await use_door("throne")
	check(game.current=="throne","All new doors allow returning to the campaign")
	# Existing fully completed saves acquire the new access without replaying quests.
	var legacy := {"version":4,"checkpoint":"town","coins":77,"collected":["throne"],"postgame":{"stage":5}}
	var file := FileAccess.open(game.save_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	game.reset_progress()
	game.load_progress()
	check(game.coins==77 and game.progression.final_zone_unlocked(),"Existing completed save unlocks the new area without resetting progress")
	game.new_game()
	check(not game.progression.final_zone_unlocked(),"New game relocks the area")
	game.session_active = false
	game.dirty = false
	game.audio.shutdown()
	DirAccess.remove_absolute(game.save_path)
	print("FINAL ZONE: %d assertions, %d failures; gates, actual doors, shops, guardian, reward, persistence and migration" % [assertions,failures])
	quit(1 if failures else 0)
