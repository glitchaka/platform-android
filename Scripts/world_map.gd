extends RefCounted

const PIXEL = preload("res://Scripts/pixel_ui.gd")
const ORIGIN = Vector2(47,34)
const SCALE = 0.51
const OPEN = Color("a8e1cb")
const LOCKED = Color("ff9b78")
var selected := ""
var selection := 0
var overview := false
var grid: AStarGrid2D
var routes: Dictionary = {}

func select_room(id: String) -> void:
	selected = id
	selection = 0

func map_rect(room: Dictionary) -> Rect2:
	# Do not enlarge narrow rooms: that made adjacent rooms overlap in the old atlas.
	return Rect2((ORIGIN+room.rect.position*SCALE).round(),(room.rect.size*SCALE).round())

func portal_row(index: int) -> Rect2:
	return Rect2(7,75+index*12,306,12)

func prepare_routes(world: RefCounted) -> void:
	if grid != null: return
	grid = AStarGrid2D.new()
	grid.region = Rect2i(-2,-2,385,232)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	grid.update()
	for room in world.rooms:
		var rect: Rect2 = room.rect
		for x in range(int(rect.position.x),int(rect.end.x)+1):
			for y in range(int(rect.position.y),int(rect.end.y)+1):
				grid.set_point_solid(Vector2i(x,y))

func map_port(world: RefCounted, from: String, to: String) -> Vector2i:
	var room: Dictionary = world.room(from)
	for door in world.exits(from):
		if door.to == to:
			# Every playable portal is on the floor, in the same left-to-right order.
			return Vector2i(roundi(room.rect.position.x+1+door.fraction*(room.rect.size.x-2)),int(room.rect.end.y))
	return Vector2i(-1,-1)

func route(world: RefCounted, from: String, to: String) -> PackedVector2Array:
	var key := from+":"+to
	if routes.has(key): return routes[key]
	prepare_routes(world)
	var a := map_port(world,from,to)
	var b := map_port(world,to,from)
	var middle := grid.get_id_path(a+Vector2i.DOWN,b+Vector2i.DOWN)
	var result := PackedVector2Array([Vector2(a)])
	for point in middle: result.append(Vector2(point))
	result.append(Vector2(b))
	routes[key] = result
	return result

func action(game: Node2D, input: String) -> void:
	if selected.is_empty(): select_room(game.current)
	match input:
		"move_left","move_right": overview = not overview
		"shop_up","shop_down":
			var step := -1 if input == "shop_up" else 1
			if overview:
				var index := 0
				for i in range(game.data.rooms.size()):
					if game.data.rooms[i].id == selected: index = i
				select_room(game.data.rooms[wrapi(index+step,0,game.data.rooms.size())].id)
			else:
				selection = wrapi(selection+step,0,game.data.exits(selected).size())
		"menu_accept":
			if overview: overview = false
			else: select_room(game.data.exits(selected)[selection].to)
	game.hud.queue_redraw()

func tap(game: Node2D, pos: Vector2) -> void:
	if selected.is_empty(): select_room(game.current)
	if pos.y >= 152:
		if pos.x < 85: overview = not overview
		elif pos.x < 163: select_room(game.objective_room())
		elif pos.x < 241: select_room(game.current)
		else: game.map_open = false
	elif overview:
		var nearest := ""
		var distance := INF
		for room in game.data.rooms:
			var rect := map_rect(room)
			if not rect.grow(2).has_point(pos): continue
			var d := pos.distance_squared_to(rect.get_center())
			if rect.has_point(pos): d -= 1000
			if d < distance:
				nearest = room.id
				distance = d
		if not nearest.is_empty():
			if nearest == selected: overview = false
			select_room(nearest)
	else:
		var doors: Array = game.data.exits(selected)
		for i in range(doors.size()):
			if portal_row(i).has_point(pos):
				if selection == i: select_room(doors[i].to)
				else: selection = i
				break
	game.hud.queue_redraw()

func draw(game: Node2D, canvas: Node2D) -> void:
	if selected.is_empty(): select_room(game.current)
	PIXEL.panel(canvas,Rect2(3,24,314,154),Color("353d48"))
	PIXEL.text(canvas,Vector2(10,29),game.room_name(selected))
	if overview: draw_atlas(game,canvas)
	else: draw_portals(game,canvas)
	game.hud.draw_footer(["PUERTAS" if overview else "ATLAS","META","AQUI","SALIR"],[82,78,78,76])

func draw_portals(game: Node2D, canvas: Node2D) -> void:
	var doors: Array = game.data.exits(selected)
	PIXEL.text(canvas,Vector2(10,43),"IZQUIERDA")
	PIXEL.text(canvas,Vector2(254,43),"DERECHA")
	PIXEL.strip(canvas,Rect2(20,69,280,1),Color("778c8a"))
	for i in range(doors.size()):
		var door: Dictionary = doors[i]
		var locked: bool = not game.door_block_reason(selected,door).is_empty()
		var tint := LOCKED if locked else OPEN
		var x: float = 24+door.fraction*272
		PIXEL.text(canvas,Vector2(x-4,57),str(door.number),tint)
		PIXEL.strip(canvas,Rect2(x,66,1,4),tint)
		var row := portal_row(i)
		if selection == i: PIXEL.strip(canvas,row,Color("4c5a60"))
		PIXEL.text(canvas,row.position+Vector2(2,2),str(door.number),tint)
		PIXEL.text(canvas,row.position+Vector2(18,2),door.side,tint)
		PIXEL.text(canvas,row.position+Vector2(82,2),game.room_name(door.to))
		PIXEL.icon(canvas,"key" if locked else "goal",row.position+Vector2(294,2),tint)
	var requirement: String = game.door_requirement(selected,doors[selection])
	var hint := "ABIERTO. TOCA OTRA VEZ PARA VER." if game.touch.enabled else "E VER DESTINO. A D ATLAS. W S ELEGIR."
	if requirement != "ABIERTO": hint = "FALTA: "+requirement
	PIXEL.text(canvas,Vector2(10,138),hint,LOCKED if requirement != "ABIERTO" else OPEN)

func draw_atlas(game: Node2D, canvas: Node2D) -> void:
	var doors: Array = game.data.exits(selected)
	var destinations: Dictionary = {}
	for door in doors:
		var tint := LOCKED if not game.door_block_reason(selected,door).is_empty() else OPEN
		var points := route(game.data,selected,door.to)
		for i in range(points.size()-1):
			canvas.draw_line((ORIGIN+points[i]*SCALE).round(),(ORIGIN+points[i+1]*SCALE).round(),tint)
		destinations[door.to] = {"number":door.number,"tint":tint}
	var pending: Array = game.postgame.remaining_rooms()
	for room in game.data.rooms:
		var rect := map_rect(room)
		var tint: Color = game.DATA.ZONES[room.zone][1] if game.visited.has(room.id) else Color("737c7c")
		if not game.progression.can_enter(room.id): tint = Color("565655")
		canvas.draw_rect(rect,tint.darkened(0.45))
		canvas.draw_rect(rect,Color.WHITE if room.id == selected else tint,false,1)
		var pos := rect.get_center().round()-Vector2(4,4)
		if destinations.has(room.id):
			PIXEL.shadow_text(canvas,pos,str(destinations[room.id].number),destinations[room.id].tint)
		elif room.id == game.current:
			PIXEL.icon(canvas,"player",pos)
		elif room.id == game.objective_room() or pending.has(room.id):
			PIXEL.icon(canvas,"goal",pos,Color("f5ca73"))
	PIXEL.text(canvas,Vector2(9,47),"SALIDAS")
	PIXEL.text(canvas,Vector2(9,59),"1-%d" % doors.size(),OPEN)
	PIXEL.text(canvas,Vector2(9,124),"%d" % game.visited.size())
	PIXEL.text(canvas,Vector2(9,136),"DE %d" % game.data.rooms.size())
	PIXEL.text(canvas,Vector2(251,47),"TOCA" if game.touch.enabled else "W S")
	PIXEL.text(canvas,Vector2(251,59),"SALA")
