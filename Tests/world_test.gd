extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://Scenes/main.tscn").instantiate()
	game.save_path = "res://Tests/test_save.json"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.new_game()
	game.input_block_frames = 0
	var tiles: Image = game.level.tiles.get_image()
	assert(tiles.get_pixel(0,520).a == 1.0,"Platform surface must be visible")
	assert(tiles.get_pixel(1,522).a == 0.0,"Do not reveal hidden RGB around platform edges")
	assert(tiles.get_pixel(115,656).a == 0.0,"Tree silhouette must retain its original alpha")
	assert(tiles.get_pixel(300,0).a == 0.0,"Empty atlas background must stay transparent")
	assert(game.player.sprite.sprite_frames.get_frame_texture("idle",0).get_size() == Vector2(8,8),"Do not combine facing-direction rows")
	assert(game.data.rooms.size() == 55)
	var reached := ["tutorial"]
	var pending := ["tutorial"]
	while not pending.is_empty():
		var id: String = pending.pop_front()
		for door in game.data.exits(id):
			assert(not game.data.room(door.to).is_empty())
			if not reached.has(door.to):
				reached.append(door.to)
				pending.append(door.to)
	assert(reached.size() == game.data.rooms.size(),"Disconnected map")
	for room in game.data.rooms:
		game.enter_room(room.id)
		assert(game.level.platforms.size()>1)
		assert(game.level.exits.size()>0)
		for rect in game.level.platforms:
			assert(Rect2(Vector2.ZERO,game.level.room_size).encloses(rect),"Terrain outside room: " + room.id)
		assert(Rect2(Vector2.ZERO,game.level.room_size).has_point(game.level.reward_position),"Reward outside room: " + room.id)
		for enemy in game.enemies:
			assert(enemy.position.x >= 4 and enemy.position.x <= game.level.room_size.x-4,"Enemy outside room: " + room.id)
			assert(enemy.patrol_min < enemy.patrol_max,"Invalid patrol: " + room.id)
		for i in range(12):
			game.player.tick(1.0/60.0)
		assert(game.player.grounded,"Spawn must stand on terrain: " + room.id)
		await process_frame
	game.player.double_jump = false
	game.player.dash = false
	game.keys = 0
	assert(not game.can_open("double_jump"))
	assert(not game.can_open("dash"))
	assert(not game.can_open("keys"))
	game.player.double_jump = true
	game.player.dash = true
	game.keys = 2
	game.boss_keys = ["bone_lord","royal_spire"]
	assert(game.can_open("double_jump") and game.can_open("dash") and game.can_open("keys"))
	game.defeated.clear()
	assert(not game.can_open("boss:bone_lord"))
	game.defeated.append("bone_lord")
	assert(game.can_open("boss:bone_lord"))
	game.collected_objects.append("tutorial:chest")
	game.checkpoint = "town"
	game.save_progress()
	game.keys = 0
	game.player.dash = false
	game.checkpoint = "tutorial"
	game.load_progress()
	assert(game.keys == 2 and game.player.dash and game.checkpoint == "town")
	DirAccess.remove_absolute(game.save_path)
	game.enter_room("tutorial")
	game.player.position = game.level.platforms[1].position + Vector2(16,-6)
	game.player.velocity = Vector2(0,100)
	for i in range(15):
		game.player.tick(1.0/60.0)
	assert(is_equal_approx(game.player.position.y,game.level.platforms[1].position.y-4),"Platform landing mismatch")
	game.enter_room("town")
	game.hud.queue_redraw()
	await process_frame
	await process_frame
	if DisplayServer.get_name() != "headless":
		game.message_time = 0
		game.nearby = ""
		game.player.double_jump = false
		game.player.dash = false
		for id in ["tutorial","town","west_tower","central_shaft","moss_gate","bone_gate","city_square"]:
			game.enter_room(id)
			game.hud.queue_redraw()
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://Tests/"+id+".png")
		game.visited = reached
		game.map_open = true
		game.hud.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://Tests/atlas.png")
	print("PASS: original sprite alpha and native frames; 55 connected rooms, bounded terrain/rewards/enemies, valid spawns, ability/boss gates, save round-trip, platform landing")
	quit()
