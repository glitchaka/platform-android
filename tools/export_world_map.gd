extends SceneTree

func _initialize() -> void:
	var world = load("res://Scripts/world_data.gd").new()
	var game = load("res://Scripts/main.gd").new()
	var builder = load("res://Scripts/level_builder.gd").new()
	var atlas = load("res://Scripts/world_map.gd").new()
	var rooms: Array = []
	for room in world.rooms:
		builder.build(room,world.exits(room.id))
		var doors: Array = []
		for i in range(builder.exits.size()):
			var door: Dictionary = builder.exits[i]
			var side: String = {"IZQ":"Izquierda","DER":"Derecha","CENTRO":"Centro"}.get(door.side,door.side+" desde la izquierda")
			var port: Vector2i = atlas.map_port(world,room.id,door.to)
			doors.append({"to":door.to,"gate":door.gate,"side":side,"x":door.position.x,"number":door.number,"map_port":[port.x,port.y]})
		rooms.append({"id":room.id,"name":game.room_name(room.id),"zone":room.zone,"rect":[room.rect.position.x,room.rect.position.y,room.rect.size.x,room.rect.size.y],"reward":room.reward,"doors":doors,"lever":builder.objects.any(func(object): return object.kind=="lever")})
	var zones: Dictionary = {}
	for id in world.ZONES:
		zones[id] = {"name":world.ZONES[id][0],"color":"#"+world.ZONES[id][1].to_html(false)}
	var links: Array = []
	for link in world.links:
		var entry: Dictionary = link.duplicate()
		var points: PackedVector2Array = atlas.route(world,link.a,link.b)
		var corners: Array = []
		for i in range(points.size()):
			if i == 0 or i == points.size()-1 or points[i]-points[i-1] != points[i+1]-points[i]:
				corners.append([points[i].x,points[i].y])
		entry["points"] = corners
		links.append(entry)
	DirAccess.make_dir_recursive_absolute("res://Builds/Maps")
	var file := FileAccess.open("res://Builds/Maps/world-map-data.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"rooms":rooms,"links":links,"zones":zones,"version":"0.4.1"},"\t"))
	file.close()
	print("Exported %d rooms and %d real links, including ordered door destinations." % [rooms.size(),world.links.size()])
	builder.free()
	game.free()
	quit()
