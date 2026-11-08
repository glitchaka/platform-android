extends SceneTree
var game: Node2D
var failures := 0
var assertions := 0
var transitions: Array = []

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	assertions += 1
	if not value:
		failures += 1
		push_error(label)

func press_door(door: Dictionary) -> void:
	game.player.position = door.position
	game.player.velocity = Vector2.ZERO
	game.transition_cooldown = 0
	game.input_block_frames = 0
	Input.action_press("interact")
	game._physics_process(1.0/60)
	Input.action_release("interact")
	await process_frame

func check_lock(from: String, to: String, expected: String) -> void:
	game.enter_room(from)
	for door in game.level.exits:
		if door.to != to: continue
		check(door.locked,"Physical portal is locked: "+from+" -> "+to)
		check(game.door_requirement(from,door) == expected,"Atlas reports the actual requirement: "+expected)
		await press_door(door)
		check(game.current == from,"Blocked actual transition: "+from+" -> "+to)
		return
	check(false,"Missing locked test portal: "+to)

func unlock_all() -> void:
	game.collected = ["throne"]
	game.postgame.stage = 5
	game.player.double_jump = true
	game.player.dash = true
	game.keys = 2
	for entry in game.PROGRESSION.CAMPAIGN: game.progression.grant(entry,true)
	game.progression.sync_rewards(true)
	game.defeated.clear()
	for room in game.data.rooms: game.defeated.append(room.id)

func run() -> void:
	game = load("res://Scenes/main.tscn").instantiate()
	game.save_path = "res://Tests/portal_map_save.json"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.set_process(false)
	game.new_game()
	await check_lock("tutorial","town","MEDALLA DEL SENDERO")
	unlock_all()
	game.player.dash = false
	await check_lock("reservoir","deep_city","IMPULSO")
	game.player.dash = true
	game.player.double_jump = false
	await check_lock("fungal_stem","buried_path","DOBLE SALTO")
	game.player.double_jump = true
	game.keys = 1
	await check_lock("moss_gate","palace_hall","DOS LLAVES")
	game.keys = 2
	game.defeated.erase("bone_lord")
	await check_lock("ossuary","bone_return","VENCER AL GUARDIAN")
	await check_lock("bone_lord","rib_hall","VENCER AL GUARDIAN")
	game.defeated.append("bone_lord")
	game.postgame.stage = 4
	await check_lock("throne","aurora_gate","CORONA DEL MERIDIANO")
	unlock_all()
	var atlas = game.hud.atlas
	for room in game.data.rooms:
		var expected: Array = game.data.exits(room.id)
		check(expected.size() <= 5,"Portal list fits on screen: "+room.id)
		for i in range(expected.size()):
			game.enter_room(room.id)
			var door: Dictionary = game.level.exits[i]
			var old_x: float = game.level.room_size.x-20 if room.id == "tutorial" else 20+i*(game.level.room_size.x-40)/maxi(expected.size()-1,1)
			check(is_equal_approx(door.position.x,old_x),"Preserved physical portal slot: "+room.id+" P"+str(i+1))
			check(door.to == expected[i].to and door.number == i+1,"Atlas number and destination match physical portal")
			check(not door.locked and game.door_requirement(room.id,door) == "ABIERTO","Map and physical portal both open")
			await press_door(door)
			var arrived: bool = game.current == door.to
			check(arrived,"Actual transition: "+room.id+" P"+str(i+1)+" -> "+door.to)
			if arrived:
				var reverse: Dictionary = {}
				for back in game.level.exits:
					if back.to == room.id: reverse = back
				check(not reverse.is_empty(),"Reciprocal physical portal exists")
				var spawn: Vector2 = reverse.position+Vector2(18 if reverse.position.x<game.level.room_size.x/2 else -18,0)
				check(game.player.position.is_equal_approx(spawn),"Arrival is at the correct return portal")
				transitions.append({"from":room.id,"portal":door.number,"side":door.side,"to":game.current,"return_portal":reverse.number})
			var points: PackedVector2Array = atlas.route(game.data,room.id,door.to)
			check(points.size()>2,"Atlas corridor exists: "+room.id+" -> "+door.to)
			var clear := true
			for j in range(1,points.size()-1):
				if atlas.grid.is_point_solid(Vector2i(points[j])): clear = false
			check(clear,"Atlas corridor avoids all unrelated rooms")
	check(transitions.size() == 130,"All 65 links were crossed in both directions")
	for i in range(game.data.rooms.size()):
		var rect: Rect2 = atlas.map_rect(game.data.rooms[i])
		for j in range(i+1,game.data.rooms.size()):
			check(not rect.intersects(atlas.map_rect(game.data.rooms[j])),"Atlas room rectangles do not overlap")
	game.enter_room("reservoir")
	game.map_open = true
	atlas.select_room(game.current)
	atlas.overview = false
	game.touch.overlay_tap(atlas.portal_row(1).get_center())
	check(atlas.selection == 1 and atlas.selected == "reservoir","Touch selects the center portal for inspection")
	game.touch.overlay_tap(atlas.portal_row(1).get_center())
	check(atlas.selected == "city_spire" and game.current == "reservoir","Touch inspects the destination without moving the player")
	game.touch.overlay_tap(Vector2(200,164))
	check(atlas.selected == "reservoir","AQUI returns the map to the player")
	atlas.action(game,"move_left")
	check(atlas.overview,"Keyboard switches to atlas")
	atlas.action(game,"menu_accept")
	check(not atlas.overview,"Keyboard opens the portal list")
	game.touch.overlay_tap(Vector2(280,164))
	check(not game.map_open,"Map exit works on touch")
	var report := FileAccess.open("res://Tests/portal-map-audit.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"assertions":assertions,"failures":failures,"rooms":55,"links":65,"transitions":transitions},"\t"))
	report.close()
	game.session_active = false
	game.dirty = false
	game.audio.shutdown()
	DirAccess.remove_absolute(game.save_path)
	print("PORTAL MAP: %d assertions, %d failures; %d actual directed transitions" % [assertions,failures,transitions.size()])
	quit(1 if failures else 0)
