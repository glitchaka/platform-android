extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func jump_reaches(player: Node2D, source: Rect2, target: Rect2) -> bool:
	if source.position.y-target.position.y>38:
		return false
	var gap: float = maxf(source.position.x-target.end.x,target.position.x-source.end.x)
	if gap>110:
		return false
	for start in [source.position.x+4,clampf(target.get_center().x,source.position.x+4,source.end.x-4),source.end.x-4]:
		player.position = Vector2(start,source.position.y-4)
		player.velocity = Vector2(0,-220)
		player.grounded = false
		for frame in range(100):
			var distance: float = target.get_center().x-player.position.x
			Input.action_release("move_left")
			Input.action_release("move_right")
			if absf(distance)>2:
				Input.action_press("move_right" if distance>0 else "move_left")
			player.tick(1.0/60.0)
			if player.grounded:
				if absf(player.position.y-(target.position.y-4))<0.1 and player.position.x>=target.position.x-2 and player.position.x<=target.end.x+2:
					Input.action_release("move_left")
					Input.action_release("move_right")
					return true
				break
	Input.action_release("move_left")
	Input.action_release("move_right")
	return false

func run() -> void:
	var game = load("res://Scenes/main.tscn").instantiate()
	game.save_path = "res://Tests/traversal_save.json"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.new_game()
	game.input_block_frames = 0
	game.player.double_jump = false
	game.player.dash = false
	var platforms_checked := 0
	for room in game.data.rooms:
		game.enter_room(room.id)
		var platforms: Array[Rect2] = game.level.platforms
		var reached := [0]
		var pending := [0]
		while not pending.is_empty():
			var index: int = pending.pop_front()
			for i in range(1,platforms.size()):
				if not reached.has(i) and jump_reaches(game.player,platforms[index],platforms[i]):
					reached.append(i)
					pending.append(i)
		for i in range(platforms.size()):
			platforms_checked += 1
			if not reached.has(i):
				failures += 1
				push_error("Unreachable platform "+str(i)+" in "+room.id+" at "+str(platforms[i]))
		await process_frame
	game.dirty = false
	if FileAccess.file_exists(game.save_path):
		DirAccess.remove_absolute(game.save_path)
	print("TRAVERSAL: %d failures; %d platforms across %d rooms checked with actual single-jump physics" % [failures,platforms_checked,game.data.rooms.size()])
	quit(1 if failures else 0)
