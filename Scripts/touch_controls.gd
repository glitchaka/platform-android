extends Node2D

const PIXEL = preload("res://Scripts/pixel_ui.gd")
const STICK_CENTER = Vector2(34,136)
const STICK_AREA = Rect2(0,96,96,84)
const BUTTONS = [
	{"action":"flask","center":Vector2(222,164),"radius":10,"hit":16,"icon":"heart","size":16},
	{"action":"interact","center":Vector2(246,142),"radius":10,"hit":15,"icon":"goal","size":16},
	{"action":"dash","center":Vector2(246,105),"radius":11,"hit":16,"icon":"dash","size":16},
	{"action":"attack","center":Vector2(300,110),"radius":12,"hit":17,"icon":"power","size":16},
	{"action":"jump","center":Vector2(296,151),"radius":20,"hit":23,"icon":"jump","size":24}
]
var game: Node
var enabled := false
var fingers: Dictionary = {}
var stick_id := -99
var stick_point := STICK_CENTER

func _ready() -> void:
	enabled = OS.has_feature("android") or DisplayServer.is_touchscreen_available() or OS.get_cmdline_user_args().has("--touch")
	var icon_material := ShaderMaterial.new()
	icon_material.shader = preload("res://Scripts/touch_icons.gdshader")
	material = icon_material

func gameplay() -> bool:
	return game.session_active and game.menu_state.is_empty() and not game.shop_open and not game.map_open and not game.journal_open

func button_enabled(action: String) -> bool:
	if action == "dash":
		return game.player.dash
	if action == "flask":
		return game.flask_charges > 0 or game.tonics > 0
	if action == "interact":
		return not game.nearby.is_empty()
	return true

func release_finger(index: int) -> void:
	if index == stick_id:
		stick_id = -99
		stick_point = STICK_CENTER
	if not fingers.has(index):
		return
	var action: String = fingers[index]
	fingers.erase(index)
	if not fingers.values().has(action):
		Input.action_release(action)

func release_all() -> void:
	for index in fingers.keys():
		release_finger(index)
	stick_id = -99
	stick_point = STICK_CENTER

func action_at(pos: Vector2) -> String:
	for button in BUTTONS:
		if pos.distance_to(button.center) <= button.hit and button_enabled(button.action):
			return button.action
	return ""

func press_finger(index: int, pos: Vector2) -> void:
	release_finger(index)
	if STICK_AREA.has_point(pos) and stick_id == -99:
		stick_id = index
		update_stick(pos)
		return
	var action := action_at(pos)
	if not action.is_empty():
		fingers[index] = action
		Input.action_press(action)

func update_stick(pos: Vector2) -> void:
	var offset := (pos-STICK_CENTER).limit_length(20)
	stick_point = STICK_CENTER+offset
	var index := stick_id
	var old: String = fingers.get(index,"")
	var next := "" if absf(offset.x)<5 else "move_left" if offset.x<0 else "move_right"
	if old != next:
		fingers.erase(index)
		if not old.is_empty() and not fingers.values().has(old):
			Input.action_release(old)
	if not next.is_empty():
		fingers[index] = next
		Input.action_press(next,minf(absf(offset.x)/15.0,1.0))

func _input(event: InputEvent) -> void:
	if not enabled or not is_instance_valid(game.player):
		return
	if event is InputEventScreenTouch:
		var pos: Vector2 = get_global_transform_with_canvas().affine_inverse()*event.position
		if not event.pressed or event.canceled:
			release_finger(event.index)
		elif overlay_tap(pos):
			release_all()
		elif gameplay():
			press_finger(event.index,pos)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and (fingers.has(event.index) or event.index == stick_id):
		var pos: Vector2 = get_global_transform_with_canvas().affine_inverse()*event.position
		if event.index == stick_id:
			update_stick(pos)
			get_viewport().set_input_as_handled()
			return
		var old: String = fingers[event.index]
		var next := action_at(pos)
		if next != old:
			release_finger(event.index)
			# Sliding the direction pad is supported; action buttons need a new press.
			if gameplay() and old in ["move_left","move_right"] and next in ["move_left","move_right"]:
				press_finger(event.index,pos)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and stick_id == -1:
		update_stick(get_global_transform_with_canvas().affine_inverse()*event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# Desktop preview (--touch) also accepts a mouse without duplicating real touches.
		var pos: Vector2 = get_global_transform_with_canvas().affine_inverse()*event.position
		if not event.pressed:
			release_finger(-1)
		elif not overlay_tap(pos) and gameplay():
			press_finger(-1,pos)
		get_viewport().set_input_as_handled()

func overlay_tap(pos: Vector2) -> bool:
	if not game.menu_state.is_empty():
		if Rect2(270,28,26,22).has_point(pos):
			game.audio.muted = not game.audio.muted
			if game.session_active:
				game.save_progress()
			return true
		for i in range(3):
			if game.hud.menu_button_rect(i).has_point(pos):
				game.menu_selection = i
				game.menu_action("menu_accept")
		return true
	if Rect2(290,0,30,24).has_point(pos):
		if game.shop_open:
			game.shop_action("shop_close")
		elif game.map_open or game.journal_open:
			game.map_open = false
			game.journal_open = false
		else:
			game.open_pause()
		return true
	if Rect2(236,0,26,24).has_point(pos):
		game.map_open = not game.map_open
		if game.map_open: game.hud.atlas.select_room(game.current)
		game.journal_open = false
		game.shop_open = false
		return true
	if Rect2(263,0,26,24).has_point(pos):
		game.journal_open = not game.journal_open
		game.map_open = false
		game.shop_open = false
		return true
	if game.shop_open:
		if Rect2(164,25,64,18).has_point(pos):
			game.shop_selection = ((game.shop_selection/6+1)*6)%game.SHOP.ITEMS.size()
			game.shop_message_time = 0
			return true
		if pos.y >= 151:
			if pos.x < 70: game.shop_action("shop_up")
			elif pos.x < 140: game.shop_action("shop_down")
			elif pos.x < 244: game.shop_action("shop_buy")
			else: game.shop_action("shop_close")
		elif pos.y >= 44 and pos.y < 116:
			game.shop_selection = (game.shop_selection/6)*6 + int((pos.y-44)/12)
			game.shop_selection = mini(game.shop_selection,game.SHOP.ITEMS.size()-1)
			game.shop_message_time = 0
		return true
	if game.journal_open:
		if pos.y >= 27 and pos.y < 47:
			game.journal_tab = clampi(int((pos.x-4)/52),0,5)
			game.journal_selection = 0
		elif pos.y >= 152:
			if pos.x < 80: game.journal_action("shop_up")
			elif pos.x < 160: game.journal_action("shop_down")
			elif pos.x < 256: game.journal_action("menu_accept")
			else: game.journal_open = false
		elif pos.y >= game.collection_row_y()-1 and pos.y < game.collection_row_y()+game.collection_page_size()*12-1 and game.journal_tab > 0:
			var count: int = game.journal_entries().size()
			var page: int = game.collection_page_size()
			game.journal_selection = mini((game.journal_selection/page)*page+int((pos.y-game.collection_row_y()+1)/12),count-1)
		return true
	if game.map_open:
		game.hud.atlas.tap(game,pos)
		return true
	if Rect2(80,0,85,31).has_point(pos):
		game.cycle_weapon()
		return true
	return game.map_open

func _draw() -> void:
	if not enabled or not is_instance_valid(game.player) or not gameplay():
		return
	var stick_held := stick_id != -99
	PIXEL.ring(self,STICK_CENTER,28,Color(0.69,0.91,0.78,0.40 if stick_held else 0.22),0.015)
	PIXEL.ring(self,stick_point.round(),8,Color(0.94,1,0.97,0.7 if stick_held else 0.35),0.36 if stick_held else 0.19)
	for button in BUTTONS:
		var usable := button_enabled(button.action)
		if not usable:
			continue
		var held: bool = fingers.values().has(button.action)
		var primary: bool = button.action == "jump"
		var outline := Color(0.58,0.93,0.71,0.9 if held else 0.54) if primary else Color(0.88,0.98,0.92,0.85 if held else 0.42)
		PIXEL.ring(self,button.center,button.radius,outline,0.12 if held else 0.025)
		if primary:
			PIXEL.ring(self,button.center,button.radius+2,Color(0.58,0.93,0.71,0.35 if held else 0.12),0)
		PIXEL.icon_scaled(self,button.icon,button.center,button.size,Color(0.95,1,0.97,1.0 if held else 0.86))
		if button.action == "flask":
			PIXEL.shadow_text(self,button.center+Vector2(8,6),str(game.flask_charges+game.tonics),Color(1,1,1,0.8))
