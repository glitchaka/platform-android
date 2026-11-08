extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func capture(game: Node2D, file: String) -> void:
	game.camera.force_update_scroll()
	game.hud.queue_redraw()
	game.level.queue_redraw()
	game.touch.queue_redraw()
	game.projectile_renderer.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://Tests/"+file+".png")

func run() -> void:
	if OS.get_cmdline_user_args().has("--icons"):
		await capture_icons()
		return
	var game = load("res://Scenes/main.tscn").instantiate()
	game.save_path = "res://Tests/visual_save.json"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	if OS.get_cmdline_user_args().has("--menus"):
		await capture_menus(game)
		return
	game.new_game()
	game.input_block_frames = 0
	game.player.health = 3
	game.player.max_health = 3
	game.coins = 0
	game.keys = 0
	game.quest_started = false
	game.quest_paid = false
	game.collected.clear()
	game.collected_objects.clear()
	game.visited.clear()
	game.defeated.clear()
	game.message_time = 0
	if OS.get_cmdline_user_args().has("--portal-map"):
		await capture_portal_map(game)
		return
	if OS.get_cmdline_user_args().has("--aurora"):
		await capture_aurora(game)
		return
	if OS.get_cmdline_user_args().has("--controls"):
		await capture_controls(game)
		return
	if OS.get_cmdline_user_args().has("--zones"):
		await capture_zones(game)
		return
	if OS.get_cmdline_user_args().has("--postgame"):
		await capture_postgame(game)
		return
	if OS.get_cmdline_user_args().has("--progression"):
		await capture_progression(game)
		return
	if OS.get_cmdline_user_args().has("--shop"):
		await capture_shop(game)
		return
	for id in ["tutorial","town","nest","central_shaft","bone_gate","city_square","canopy"]:
		game.enter_room(id)
		if id == "town":
			game.player.position.x = 154
			game.nearby = "E: abrir la tienda de mejoras."
		await capture(game,"content_"+id)
	game.enter_room("town")
	game.map_open = true
	await capture(game,"content_atlas")
	game.map_open = false
	game.journal_open = true
	await capture(game,"content_journal")
	game.journal_open = false
	game.enter_room("bone_return")
	game.player.position = game.level.reward_position+Vector2(-12,4)
	game.nearby = "E: abrir cofre."
	await capture(game,"content_key")
	if FileAccess.file_exists(game.save_path):
		DirAccess.remove_absolute(game.save_path)
	game.dirty = false
	quit()

func capture_portal_map(game: Node2D) -> void:
	game.set_process(false)
	game.touch.enabled = true
	game.collected = ["throne"]
	game.postgame.stage = 5
	game.player.double_jump = true
	game.player.dash = true
	game.keys = 2
	for entry in game.PROGRESSION.CAMPAIGN: game.progression.grant(entry,true)
	game.progression.sync_rewards(true)
	for room in game.data.rooms:
		game.visited.append(room.id)
		game.defeated.append(room.id)
	game.achievement_queue.clear()
	game.achievement_timer = 0
	for id in ["reservoir","fungal_stem","well"]:
		game.enter_room(id)
		game.hud.atlas.select_room(id)
		game.hud.atlas.overview = false
		game.map_open = true
		await capture(game,"map_portals_"+id)
		game.hud.atlas.overview = true
		await capture(game,"map_atlas_"+id)
	game.enter_room("reservoir")
	game.player.dash = false
	game.refresh_doors()
	game.hud.atlas.select_room("reservoir")
	game.hud.atlas.selection = 2
	game.hud.atlas.overview = false
	await capture(game,"map_portals_locked")
	game.map_open = false
	game.player.position.x = game.level.room_size.x/2
	game.message_time = 0
	game.nearby = "E: P2. Aguja. Ciudad en Ruinas"
	game.nearby_time = 5
	await capture(game,"map_numbered_portal")
	game.session_active = false
	game.dirty = false
	game.audio.shutdown()
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	quit()

func capture_aurora(game: Node2D) -> void:
	game.set_process(false)
	game.touch.enabled = true
	game.collected = ["throne"]
	game.postgame.stage = 5
	game.player.double_jump = true
	game.player.dash = true
	for entry in game.PROGRESSION.CAMPAIGN: game.progression.grant(entry,true)
	game.progression.sync_rewards(true)
	game.achievement_queue.clear()
	game.achievement_timer = 0
	for id in ["throne","aurora_gate","aurora_garden","aurora_core","moss_depths","deep_west","city_square","reservoir"]:
		game.enter_room(id)
		game.player.position = Vector2(game.level.room_size.x*0.5,game.level.floor_y-4)
		game.message_time = 0
		game.nearby_time = 0
		game.nearby = "E: cruzar al Alba." if id=="throne" else ""
		await capture(game,"aurora_"+id)
	game.journal_open = true
	game.journal_tab = 0
	await capture(game,"aurora_journal")
	game.journal_open = false
	game.map_open = true
	await capture(game,"aurora_map")
	game.session_active = false
	game.dirty = false
	game.audio.shutdown()
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(game.save_path)
	quit()

func capture_controls(game: Node2D) -> void:
	game.set_process(false)
	game.touch.enabled = true
	game.achievement_queue.clear()
	game.achievement_timer = 0
	game.enter_room("tutorial")
	game.message_time = 0
	game.nearby = "E: activar mecanismo."
	game.nearby_time = 0
	await capture(game,"mobile_controls")
	game.player.dash = true
	game.tonics = 3
	await capture(game,"mobile_controls_unlocked")
	game.session_active = false
	game.dirty = false
	game.audio.shutdown()
	if FileAccess.file_exists(game.save_path):
		DirAccess.remove_absolute(game.save_path)
	quit()

func capture_shop(game: Node2D) -> void:
	game.upgrades.clear()
	game.flask_charges = 0
	game.apply_upgrades()
	game.enter_room("town")
	game.coins = 80
	game.player.position = Vector2(154,game.level.floor_y-4)
	for object in game.level.objects:
		if object.kind == "merchant":
			game.use_object(object)
	game.shop_selection = 0
	await capture(game,"shop_catalog")
	game.buy_selected()
	game.shop_selection = 3
	game.shop_message_time = 0
	await capture(game,"shop_flask")
	game.buy_selected()
	await capture(game,"shop_bought")
	game.shop_action("shop_close")
	game.nearby = "E: abrir la tienda de mejoras."
	await capture(game,"shop_hud")
	if FileAccess.file_exists(game.save_path):
		DirAccess.remove_absolute(game.save_path)
	game.dirty = false
	quit()

func capture_zones(game: Node2D) -> void:
	game.set_process(false)
	game.touch.enabled = true
	game.achievement_queue.clear()
	game.achievement_timer = 0
	game.enter_room("tutorial")
	game.player.position = game.level.exits[0].position-Vector2(12,0)
	game.tell(game.progression.block_reason("town"))
	game.nearby = "E: Pueblo. BLOQUEADO."
	await capture(game,"zones_locked_door")
	for object in game.level.objects:
		if object.kind=="lever": game.use_object(object)
	for object in game.level.objects:
		if object.kind=="chest": game.use_object(object)
	game.journal_open = true
	game.journal_tab = 5
	game.journal_selection = 0
	await capture(game,"zones_first_item")
	game.journal_open = false
	game.enter_room("town","tutorial")
	game.quest_started = true
	game.defeated.append("nest")
	for object in game.level.objects:
		if object.kind=="guide": game.use_object(object)
	game.journal_open = true
	game.journal_tab = 0
	await capture(game,"zones_campaign_route")
	game.journal_open = false
	game.map_open = true
	game.visited = game.data.rooms.map(func(room): return room.id)
	await capture(game,"zones_campaign_map")
	game.map_open = false
	for entry in game.PROGRESSION.CAMPAIGN: game.progression.grant(entry,true)
	game.player.double_jump = true
	game.player.dash = true
	game.collected = ["throne"]
	game.enter_room("town")
	game.journal_open = true
	game.journal_tab = 0
	game.journal_selection = 0
	await capture(game,"zones_postgame_route")
	game.postgame.stage = 1
	game.progression.sync_rewards(true)
	game.journal_tab = 5
	game.journal_selection = 5
	await capture(game,"zones_postgame_item")
	game.journal_open = false
	game.map_open = true
	await capture(game,"zones_postgame_map")
	game.dirty = false
	DirAccess.remove_absolute(game.save_path)
	game.audio.shutdown()
	quit()

func capture_postgame(game: Node2D) -> void:
	game.set_process(false)
	game.achievement_queue.clear()
	game.achievement_timer = 0
	game.touch.enabled = true
	game.defeated = ["nest","bone_lord","royal_spire"]
	game.collected = ["throne"]
	game.coins = 315
	game.player.double_jump = true
	game.player.dash = true
	game.player.max_health = 6
	game.player.health = 6
	game.unlock_weapon("shotgun")
	game.unlock_weapon("flame")
	game.weapons.shotgun.level = 2
	game.weapons.shotgun.durability = 56
	game.equip_weapon("shotgun")
	game.enter_room("spore_hall")
	game.message_time = 0
	game.player.position.x = 98
	await capture(game,"postgame_save_shop")
	game.journal_open = true
	game.journal_tab = 0
	await capture(game,"postgame_route")
	game.journal_tab = 1
	game.journal_selection = 17
	await capture(game,"postgame_achievement")
	game.journal_tab = 3
	game.journal_selection = 1
	await capture(game,"postgame_arsenal")
	game.postgame.stage = 5
	game.check_achievements(true)
	game.journal_tab = 4
	game.journal_selection = 3
	game.journal_action("menu_accept")
	await capture(game,"postgame_titles")
	game.journal_open = false
	for object in game.level.objects:
		if object.kind == "merchant": game.use_object(object)
	game.shop_selection = 14
	game.shop_message_time = 0
	await capture(game,"postgame_forge")
	game.shop_open = false
	game.postgame.stage = 3
	game.enter_room("city_square")
	game.player.position.x = 128
	game.message_time = 0
	await capture(game,"postgame_mechanism")
	game.postgame.stage = 0
	game.enter_room("town")
	game.player.position = Vector2(128,game.level.floor_y-24)
	game.player.facing = 1
	game.message_time = 0
	for id in ["shotgun","flame","needle","tempest","phoenix"]:
		game.unlock_weapon(id)
		game.weapons[id].level = 3
		game.equip_weapon(id)
		game.shots.clear()
		game.attack()
		if id in ["flame","phoenix"]:
			for frame in range(12):
				game.tick_shots(1.0/60)
				if frame%3 == 0: game.attack()
		else:
			game.tick_shots(0.18)
		game.projectile_renderer.queue_redraw()
		await capture(game,"postgame_shots_"+id)
	game.postgame.stage = 5
	game.enter_room("throne")
	for object in game.level.objects:
		if object.kind == "trial": game.use_object(object)
	game.message_time = 0
	await capture(game,"postgame_trial")
	game.dirty = false
	DirAccess.remove_absolute(game.save_path)
	game.audio.shutdown()
	quit()

func capture_menus(game: Node2D) -> void:
	if FileAccess.file_exists(game.save_path):
		DirAccess.remove_absolute(game.save_path)
	game.show_title()
	await capture(game,"menu_title")
	game.menu_selection = 1
	await capture(game,"menu_no_save")
	game.new_game()
	game.enter_room("town")
	game.player.position = Vector2(154,game.level.floor_y-4)
	game.checkpoint = "town"
	game.coins = 42
	game.open_pause()
	await capture(game,"menu_pause")
	game.menu_selection = 1
	await capture(game,"menu_return")
	game.return_to_title()
	await capture(game,"menu_load")
	game.menu_selection = 0
	await capture(game,"menu_replace")
	game.session_active = false
	game.dirty = false
	if FileAccess.file_exists(game.save_path):
		DirAccess.remove_absolute(game.save_path)
	quit()

func capture_progression(game: Node2D) -> void:
	game.touch.enabled = true
	game.enter_room("town")
	game.player.position = Vector2(154,game.level.floor_y-4)
	game.nearby = "E: abrir la tienda de mejoras."
	game.nearby_time = 1.6
	await capture(game,"mobile_town")
	game.nearby_time = 0
	game.message_time = 0
	game.achievement_timer = 0
	await capture(game,"mobile_town_clear")
	for object in game.level.objects:
		if object.kind == "merchant": game.use_object(object)
	game.shop_selection = 4
	await capture(game,"mobile_shop_locked")
	game.shop_action("shop_close")
	game.enter_room("bone_lord")
	game.player.position = Vector2(game.level.room_size.x*0.52,game.level.floor_y-4)
	game.nearby = "Vence al Principe de Huesos."
	game.nearby_time = 1.6
	await capture(game,"mobile_boss_before")
	for enemy in game.enemies:
		enemy.hit(100)
	game.message_time = 0
	game.achievement_timer = 0
	game.achievement_queue.clear()
	game.nearby_time = 0
	await capture(game,"mobile_boss_drop")
	game.journal_open = true
	game.journal_tab = 1
	game.journal_selection = 4
	await capture(game,"mobile_achievements")
	game.journal_tab = 2
	game.journal_selection = 3
	game.journal_action("menu_accept")
	await capture(game,"mobile_wardrobe")
	game.journal_open = false
	game.player.double_jump = true
	game.player.dash = true
	game.tonics = 3
	game.message_time = 0
	game.nearby = ""
	game.enter_room("canopy")
	game.nearby = "E: abrir cofre."
	game.touch.press_finger(1,Vector2(54,136))
	await capture(game,"mobile_hongos")
	game.touch.release_all()
	game.open_pause()
	await capture(game,"mobile_pause")
	game.session_active = false
	game.audio.shutdown()
	game.dirty = false
	DirAccess.remove_absolute(game.save_path)
	quit()

func capture_icons() -> void:
	DirAccess.make_dir_recursive_absolute("res://Resource/Icons")
	for mode in ["main","foreground","background"]:
		var viewport := SubViewport.new()
		viewport.size = Vector2i(192,192) if mode == "main" else Vector2i(432,432)
		viewport.transparent_bg = true
		viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var icon = load("res://tools/launcher_icon.gd").new()
		icon.mode = mode
		viewport.add_child(icon)
		await process_frame
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("res://Resource/Icons/"+mode+".png")
		viewport.queue_free()
	quit()
