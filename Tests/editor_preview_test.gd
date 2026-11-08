extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://Scripts/world_data.gd").new()
	for room in world.rooms:
		var scene = load("res://Scenes/Zonas/%s/%s.tscn" % [room.zone,room.id]).instantiate()
		root.add_child(scene)
		await process_frame
		if scene.room_id!=room.id or scene.platforms.is_empty() or scene.position!=Vector2.ZERO:
			failures += 1
			push_error("Room preview is empty or not at origin: "+room.id)
		root.remove_child(scene)
		scene.queue_free()
	var overview = load("res://Scenes/mapa_zonas.tscn").instantiate()
	root.add_child(overview)
	await process_frame
	if overview.map_preview.get_child_count()!=world.rooms.size(): failures += 1
	for section in overview.map_preview.get_children():
		if section.platforms.is_empty() or not Rect2(0,0,1100,650).encloses(Rect2(section.position,section.room_size*section.scale)):
			failures += 1
			push_error("Map room is empty or off screen: "+section.name)
	print("EDITOR PREVIEWS: 55 room scenes at origin and complete overview; %d failures; editor=%s" % [failures,Engine.is_editor_hint()])
	quit(1 if failures else 0)
