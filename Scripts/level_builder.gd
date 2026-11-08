@tool
extends Node2D
const ATLAS = preload("res://Scripts/sprite_atlas.gd")
const PIXEL = preload("res://Scripts/pixel_ui.gd")
const WORLD = preload("res://Scripts/world_data.gd")
const NEW_TILES = preload("res://Scripts/terrain_tiles.gd")
var tiles: Texture2D = preload("res://Resource/Tiles.png")
var platforms: Array[Rect2] = []
var platforms_visual: Array[Rect2] = []
var decorations: Array[Vector2] = []
var exits: Array[Dictionary] = []
var objects: Array[Dictionary] = []
var enemy_spawns: Array[Dictionary] = []
var room_size := Vector2(384,192)
var reward_position := Vector2.ZERO
var rest_position := Vector2.ZERO
var floor_y := 152.0
var palette: Dictionary = ATLAS.TERRAIN.slate
var zone_color := Color.WHITE
var variant := 0
var room_id := ""
var is_town := false
var terrain_style := "Original"
var map_preview: Node2D

@export_group("Vista de zonas")
@export var show_complete_map := false:
	set(value):
		show_complete_map = value
		if is_inside_tree() and Engine.is_editor_hint():
			rebuild_preview()
@export_enum("Segun zona", "Original", "Musgo", "Roca", "Ladrillo", "Brasa", "Bosque", "Escarcha", "Caverna") var preview_tileset := "Segun zona":
	set(value):
		preview_tileset = value
		if is_inside_tree() and Engine.is_editor_hint():
			rebuild_preview()
@export_tool_button("Actualizar vista", "Reload") var update_preview = rebuild_preview

func _validate_property(property: Dictionary) -> void:
	if property.name == "preview_room":
		property.hint = PROPERTY_HINT_ENUM
		property.hint_string = ",".join(WORLD.new().rooms.map(func(entry): return entry.id))
@export var preview_room := "tutorial":
	set(value):
		preview_room = value
		if is_inside_tree() and Engine.is_editor_hint():
			rebuild_preview()

func _ready() -> void:
	if Engine.is_editor_hint() or get_parent() == get_tree().root:
		rebuild_preview()

func rebuild_preview() -> void:
	var world = WORLD.new()
	if is_instance_valid(map_preview):
		remove_child(map_preview)
		map_preview.queue_free()
		map_preview = null
	if show_complete_map:
		map_preview = Node2D.new()
		map_preview.name = "MapaCompleto"
		add_child(map_preview)
		for entry in world.rooms:
			var section = get_script().new()
			section.show_complete_map = false
			section.preview_room = entry.id
			section.preview_tileset = preview_tileset
			section.name = entry.id
			# Fit the geographic overview next to the editor origin, rather than
			# placing the starting rooms more than 5,000 pixels off screen.
			section.position = (entry.rect.position-Vector2(7,8))*3.0
			map_preview.add_child(section)
			section.build(entry,world.exits(entry.id))
			section.scale = entry.rect.size*3.0/section.room_size
		queue_redraw()
		return
	var room: Dictionary = world.room(preview_room)
	build(world.room("tutorial") if room.is_empty() else room,world.exits(preview_room))
	queue_redraw()

func build(data: Dictionary, doors: Array[Dictionary]) -> void:
	room_id = data.id
	terrain_style = data.get("tileset","Original")
	if Engine.is_editor_hint() and preview_tileset != "Segun zona":
		terrain_style = preview_tileset
	var map_rect: Rect2 = data.rect
	room_size = Vector2(clampf(map_rect.size.x*12,320,768),clampf(map_rect.size.y*10,192,688))
	if room_id == "town":
		room_size = Vector2(640,224)
	elif room_id == "tutorial":
		room_size = Vector2(384,192)
	elif data.zone == "aurora":
		room_size = {"aurora_gate":Vector2(448,224),"aurora_garden":Vector2(640,288),"aurora_core":Vector2(480,256)}[room_id]
	palette = ATLAS.TERRAIN[ATLAS.ZONE_TERRAIN[data.zone]]
	zone_color = WORLD.ZONES[data.zone][1]
	variant = absi(room_id.hash())%3
	is_town = data.zone == "town"
	floor_y = room_size.y-40
	platforms.clear()
	platforms_visual.clear()
	decorations.clear()
	objects.clear()
	enemy_spawns.clear()
	exits = doors.duplicate(true)
	add_platform(Rect2(0,floor_y,room_size.x,40))
	if is_town:
		# Low market roofs, a loft with treasure, and a separate route towards the well.
		for x in [64,136,208,352,448,544]:
			add_platform(Rect2(x,floor_y-32,56,16))
		add_platform(Rect2(280,floor_y-64,56,16))
		add_platform(Rect2(360,floor_y-96,64,16))
		reward_position = Vector2(388,floor_y-100)
	elif room_id == "tutorial":
		add_platform(Rect2(80,floor_y-32,64,16))
		add_platform(Rect2(144,floor_y-64,64,16))
		add_platform(Rect2(232,floor_y-64,64,16))
		reward_position = Vector2(264,floor_y-68)
	elif data.zone == "aurora":
		# A rising garden path and broad terraces, all sharing the real collision rectangles.
		for x in range(64,int(room_size.x)-80,112):
			add_platform(Rect2(x,floor_y-32,80,16))
		for x in range(120,int(room_size.x)-120,112):
			add_platform(Rect2(x,floor_y-64,64,16))
		if room_id == "aurora_garden":
			add_platform(Rect2(232,floor_y-96,80,16))
			add_platform(Rect2(288,floor_y-128,64,16))
			reward_position = Vector2(320,floor_y-132)
		else:
			reward_position = platforms[-1].position+Vector2(32,-4)
	else:
		var steps := int((floor_y-40)/32)
		for i in range(steps):
			var x := 64.0+float((i+variant)%3)*48.0
			add_platform(Rect2(x,floor_y-32-i*32,64,16))
		reward_position = platforms[-1].position+Vector2(32,-4)
		for x in range(280,int(room_size.x)-56,96):
			add_platform(Rect2(x,floor_y-32,64,16))
			if (x/96)%2 == 0:
				add_platform(Rect2(x-32,floor_y-64,56,16))
	for door in exits:
		door["position"] = Vector2(20+door.fraction*(room_size.x-40),floor_y-4)
	rest_position = Vector2(224 if is_town else room_size.x/2,floor_y-4)
	# Keep the rest interaction away from door triggers, including odd exit counts.
	if data.reward == "rest":
		for offset in [0,-32,32,-64,64]:
			var candidate := Vector2(clampf(rest_position.x+offset,48,room_size.x-48),floor_y-4)
			var clear := true
			for door in exits:
				if candidate.distance_to(door.position)<30:
					clear = false
			if clear:
				rest_position = candidate
				break
	for x in range(42,int(room_size.x)-24,48):
		decorations.append(Vector2(x,floor_y))
	build_content(data)
	queue_redraw()

func add_platform(rect: Rect2) -> void:
	platforms.append(rect)
	platforms_visual.append(rect)

func add_object(kind: String, pos: Vector2, suffix: String, reward := "") -> void:
	objects.append({"kind":kind,"position":pos,"id":room_id+":"+suffix,"reward":reward,"active":false})

func build_content(data: Dictionary) -> void:
	if data.reward == "rest":
		add_object("bench",rest_position,"bench")
		if not is_town:
			for x in range(48,int(room_size.x)-40,24):
				var candidate := Vector2(x,floor_y-4)
				if candidate.distance_to(rest_position)<40: continue
				var clear := true
				for door in exits:
					if candidate.distance_to(door.position)<30: clear = false
				if clear:
					add_object("merchant",candidate,"merchant")
					break
	if is_town:
		add_object("guide",Vector2(92,floor_y-4),"guide")
		add_object("merchant",Vector2(164,floor_y-4),"merchant")
		add_object("sign",Vector2(292,floor_y-4),"sign")
		add_object("chest",reward_position,"chest","cache")
	elif room_id == "tutorial":
		add_object("sign",Vector2(62,floor_y-4),"sign")
		add_object("lever",Vector2(112,floor_y-4),"lever")
		add_object("chest",reward_position,"chest","cache")
		add_enemy(Vector2(312,floor_y-4),240,340,"crawler")
	elif data.reward not in ["rest","boss"]:
		add_object("chest",reward_position,"chest",data.reward if data.reward != "" else "cache")
		if variant == 1:
			add_object("lever",platforms[1].position+Vector2(24,-4),"lever")
	if data.reward == "boss":
		# Visible on arrival; sealed only by this room's guardian, never by keys.
		add_object("chest",Vector2(room_size.x*0.72,floor_y-4),"chest","boss_cache")
		add_enemy(Vector2(room_size.x*0.62,floor_y-4),72,room_size.x-32,"boss")
	elif data.zone not in ["tutorial","town"] and data.reward != "rest":
		for x in range(152,int(room_size.x)-32,128):
			add_enemy(Vector2(x,floor_y-4),x-36,minf(x+44,room_size.x-32),"crawler")
		for i in range(2,platforms.size(),3):
			var ledge := platforms[i]
			add_enemy(ledge.position+Vector2(32,-16),ledge.position.x,ledge.end.x,"flyer")
	# At most three loose coins per room. IDs remain compatible with old saves.
	var placed := 0
	for i in range(1,platforms.size()):
		var platform := platforms[i]
		var pos := platform.position+Vector2(16,-10)
		if placed < (2 if room_id in ["tutorial","town"] else 3) and pos.distance_to(reward_position)>18:
			add_object("coin",pos,"coin%d_0" % i)
			placed += 1
	for x in range(128,int(room_size.x)-40,144):
		if is_town and x<280:
			continue
		add_object("crate",Vector2(x,floor_y-4),"crate%d" % x)

func add_enemy(pos: Vector2, left: float, right: float, kind: String) -> void:
	enemy_spawns.append({"position":pos,"left":left,"right":right,"kind":kind})

func piece(source: Rect2i, destination: Vector2, tint := Color.WHITE) -> void:
	draw_texture_rect_region(tiles,Rect2(destination,source.size),Rect2(source),tint)

func draw_terrain(rect: Rect2) -> void:
	if NEW_TILES.TEXTURES.has(terrain_style):
		NEW_TILES.platform(self,rect,terrain_style)
		return
	var surface: Rect2i = palette.surface
	piece(palette.left,rect.position)
	for x in range(8,int(rect.size.x)-8,8):
		piece(Rect2i(surface.position+Vector2i(((x/8-1)%11)*8,0),Vector2i(8,8)),rect.position+Vector2(x,0))
	piece(palette.right,rect.position+Vector2(rect.size.x-8,0))
	# Hanging roots from the actual terrain sheet give long ledges structure.
	for x in range(24,int(rect.size.x)-16,48):
		piece(palette.rock,rect.position+Vector2(x,8),Color("929b96"))

func _draw() -> void:
	if is_instance_valid(map_preview):
		return
	var new_terrain := NEW_TILES.TEXTURES.has(terrain_style)
	if new_terrain:
		NEW_TILES.background(self,room_size,floor_y,terrain_style)
	else:
		draw_rect(Rect2(Vector2.ZERO,room_size),Color("1d2122"))
	# Native trees in the background, in layered silhouettes, follow each traversable floor.
	for ledge in platforms_visual:
		if new_terrain: break
		for x in range(int(ledge.position.x)+8,int(ledge.end.x)-16,56):
			piece(palette.tree,Vector2(x,ledge.position.y-palette.tree.size.y),Color("5b6561"))
	for point in decorations:
		if new_terrain: break
		draw_decoration(palette.tree,point)
	for ledge in platforms_visual:
		if new_terrain:
			var root := Vector2(ledge.end.x-24,ledge.position.y)
			var clear := true
			for door in exits:
				if root.distance_to(door.position)<32: clear = false
			if clear: NEW_TILES.decoration(self,root,terrain_style,int(ledge.position.x)/8)
		else:
			draw_decoration(palette.plant,Vector2(ledge.end.x-24,ledge.position.y))
		draw_terrain(ledge)
	if is_town:
		for x in [72,144,216]:
			piece(Rect2i(0,768,8,16),Vector2(x,floor_y-16))
			piece(Rect2i(8,768,8,16),Vector2(x+32,floor_y-16))
			for item in range(3):
				piece(Rect2i(item*8,752,8,8),Vector2(x+8+item*8,floor_y-16))
	for door in exits:
		var pos: Vector2 = door.position
		var origin := pos-Vector2(12,28)
		for y in range(0,32,8):
			piece(Rect2i(palette.rock.position+Vector2i(0,8),Vector2i(8,8)),origin+Vector2(0,y))
			piece(Rect2i(palette.rock.position+Vector2i(0,8),Vector2i(8,8)),origin+Vector2(16,y))
		piece(Rect2i(palette.rock.position+Vector2i(0,8),Vector2i(8,8)),origin+Vector2(8,0))
		var marker: String = {"keys":"key","double_jump":"jump","dash":"dash"}.get(door.gate,"enemy" if str(door.gate).begins_with("boss:") else "goal")
		if door.get("locked",false): marker = "key"
		if door.gate == "postgame" and door.to == "aurora_gate":
			PIXEL.shadow_text(self,pos-Vector2(16,46),"ALBA",Color("ff9b78") if door.get("locked",false) else Color("87d7c3"))
		PIXEL.icon(self,marker,origin+Vector2(8,-10),Color("ff9b78") if door.get("locked",false) else Color.WHITE)
		PIXEL.shadow_text(self,origin+Vector2(8,12),str(door.number))
	for object in objects:
		draw_object(object)

func draw_object(object: Dictionary) -> void:
	var pos: Vector2 = object.position.round()
	var active: bool = object.active
	match object.kind:
		"coin":
			if not active:
				draw_texture_rect_region(preload("res://Resource/Collectables.png"),Rect2(pos-Vector2(4,4),Vector2(8,8)),Rect2(8,0,8,8))
		"chest":
			piece(Rect2i(8 if active else 16,792,8,8),pos-Vector2(4,4),Color("656965") if active else Color.WHITE)
			if not active:
				if object.reward in ATLAS.COLLECTABLES:
					draw_texture_rect_region(preload("res://Resource/Collectables.png"),Rect2(pos-Vector2(4,18),Vector2(8,8)),Rect2(ATLAS.COLLECTABLES[object.reward]))
				else:
					PIXEL.icon(self,"goal",pos-Vector2(4,18))
		"boss_key":
			if not active:
				PIXEL.panel(self,Rect2(pos-Vector2(7,7),Vector2(14,14)),Color("aa9864"))
				PIXEL.icon(self,"key",pos-Vector2(4,4))
				PIXEL.text(self,pos-Vector2(4,19),"!")
		"crate":
			if not active:
				piece(Rect2i(0,792,8,8),pos-Vector2(4,4))
		"lever":
			piece(Rect2i(8 if active else 0,768,8,16),pos-Vector2(4,12))
			PIXEL.icon(self,"goal",pos-Vector2(4,23),Color("99d6ae") if active else Color.WHITE)
		"guide","merchant":
			draw_texture_rect_region(preload("res://Resource/Player.png"),Rect2(pos-Vector2(4,4),Vector2(8,8)),Rect2(0,64,8,8),Color("a1e2dc") if object.kind == "guide" else Color("e6bc92"))
			PIXEL.icon(self,"goal" if object.kind == "guide" else "coin",pos-Vector2(4,19))
		"bench":
			for x in [-8,0,8]:
				piece(Rect2i(0,784,8,8),pos+Vector2(x-4,-4))
			PIXEL.icon(self,"save",pos-Vector2(4,19))
		"sign":
			piece(Rect2i(48,800,8,8),pos-Vector2(4,4))
			PIXEL.icon(self,"map",pos-Vector2(4,16))
		"quest":
			if active: return
			var is_switch: bool = object.get("quest_stage",0)==3
			piece(Rect2i(8 if object.get("activated",false) else 0,768,8,16) if is_switch else Rect2i(0,792,8,8),pos-Vector2(4,12 if is_switch else 4),Color("8ee8ff") if is_switch else Color("f9dd96"))
			PIXEL.icon(self,"goal",pos-Vector2(4,23),Color("8ee8ff") if is_switch else Color("f9dd96"))
			PIXEL.text(self,pos-Vector2(4,34),str(int(object.get("quest_stage",0))+1))
		"trial":
			piece(Rect2i(48,800,8,8),pos-Vector2(4,4),Color("c6acff"))
			PIXEL.icon(self,"enemy",pos-Vector2(4,20),Color("c6acff"))

func draw_decoration(source: Rect2i, root_position: Vector2) -> void:
	var plant := Rect2(root_position-Vector2(0,source.size.y),source.size)
	if not Rect2(Vector2.ZERO,room_size).encloses(plant):
		return
	for other in platforms_visual:
		if other.intersects(plant):
			return
	for door in exits:
		if Rect2(door.position-Vector2(12,28),Vector2(24,32)).intersects(plant):
			return
	piece(source,plant.position)
