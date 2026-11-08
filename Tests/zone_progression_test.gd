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
		if object.kind==kind and not object.active: return object
	return {}

func clear_enemies() -> void:
	for enemy in game.enemies.duplicate():
		if enemy.alive: enemy.hit(10000)

func open_chest() -> void:
	for object in game.level.objects:
		if object.kind=="lever" and not object.active: game.use_object(object)
	game.use_object(object_of("chest"))

func reached(start := "town") -> Array:
	var seen: Array = [start]
	var queue: Array = [start]
	while not queue.is_empty():
		var id: String = queue.pop_front()
		for door in game.data.exits(id):
			if not seen.has(door.to) and game.progression.can_enter(door.to) and game.can_open(door.gate):
				seen.append(door.to)
				queue.append(door.to)
	return seen

func interact_door(to: String) -> void:
	for door in game.level.exits:
		if door.to!=to: continue
		game.player.position = door.position
		game.transition_cooldown = 0
		game.input_block_frames = 0
		Input.action_press("interact")
		game._physics_process(1.0/60)
		Input.action_release("interact")
		await process_frame
		return
	check(false,"Missing test door to "+to)

func tap(pos: Vector2) -> void:
	for pressed in [true,false]:
		var event := InputEventScreenTouch.new()
		event.index = 0
		event.position = root.get_final_transform()*game.touch.get_global_transform_with_canvas()*pos
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()

func check_locked_zones(max_rank: int) -> void:
	var accessible := reached("tutorial" if max_rank==0 else "town")
	for room in game.data.rooms:
		if game.progression.region_rank(room.id)>max_rank:
			check(not accessible.has(room.id),"No alternate entrance to "+room.id)

func check_combat(rank: int, room: String) -> void:
	var stats: Dictionary = game.progression.enemy_stats(room,false,false)
	check(game.weapon_stats().damage==rank+1,"Quest item grants expected weapon damage")
	check(game.player.armor==rank,"Quest item grants permanent defense")
	check(int(ceil(stats.hp/float(game.weapon_stats().damage)))==3,"Next-zone regular enemy takes three basic hits")
	game.player.health = 3
	game.player.invulnerable_timer = 0
	game.player.shield = false
	game.player.take_damage(stats.damage)
	check(game.player.health==2,"Item defense reduces next-zone contact damage to one heart")
	game.player.health = 3
	game.player.invulnerable_timer = 0
	game.player.armor = 0
	if stats.damage<3:
		game.player.take_damage(stats.damage)
		check(game.player.health==3-stats.damage,"Defense changes actual damage, not just display")
	game.player.health = 3
	game.player.invulnerable_timer = 0
	game.apply_upgrades()

func run() -> void:
	game = load("res://Scenes/main.tscn").instantiate()
	game.save_path = "res://Tests/zone_progression_save.json"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.new_game()
	game.input_block_frames = 0
	check_locked_zones(0)
	await interact_door("town")
	check(game.current=="tutorial" and game.message.contains("MEDALLA"),"Real input blocks town and explains item")
	open_chest()
	check(game.progression.items==["path_medal"],"Tutorial quest grants its item")
	game.touch.enabled = true
	tap(Vector2(272,12))
	tap(Vector2(290,35))
	check(game.journal_open and game.journal_tab==5,"Touch opens the quest item inventory")
	tap(Vector2(120,165))
	check(game.journal_selection==1,"Item list supports touch navigation")
	var item_count: int = game.progression.items.size()
	tap(Vector2(210,165))
	check(game.progression.items.size()==item_count,"Passive item screen cannot grant locked rewards")
	tap(Vector2(282,165))
	await interact_door("town")
	check(game.current=="town","Earned item opens the real door")
	check_combat(1,"well")
	check_locked_zones(1)
	game.use_object(object_of("guide"))
	game.enter_room("nest")
	clear_enemies()
	check(not game.progression.can_enter("moss_gate"),"Killing Nido alone does not skip quest hand-in")
	game.enter_room("town")
	game.use_object(object_of("guide"))
	check(game.progression.items.has("nest_amulet"),"Nido quest grants amulet on hand-in")
	check_combat(2,"moss_gate")
	check_locked_zones(2)
	game.enter_room("canopy")
	open_chest()
	check(game.progression.items.has("living_sprout") and game.player.double_jump,"Hongos quest gives stats plus existing ability")
	check_combat(3,"bone_gate")
	check_locked_zones(3)
	game.enter_room("bone_lord")
	clear_enemies()
	check(not game.progression.can_enter("city_gate"),"Must physically collect boss key before accessing Ruinas")
	game.player.position = object_of("boss_key").position
	game.tick_objects()
	check(game.progression.items.has("bone_key"),"Physical boss item grants stats and next-world access")
	check_combat(4,"city_gate")
	check_locked_zones(4)
	game.enter_room("royal_spire")
	clear_enemies()
	game.player.position = object_of("boss_key").position
	game.tick_objects()
	check(not game.progression.can_enter("palace_hall"),"Ruinas quest also requires the impulse objective")
	game.enter_room("city_spire")
	open_chest()
	check_combat(5,"palace_hall")
	check(reached().size()==52,"All campaign rooms reachable after earned items and abilities")
	var before: int = game.weapon_stats().damage
	game.progression.sync_rewards()
	game.progression.sync_rewards()
	check(game.weapon_stats().damage==before and game.progression.items.size()==5,"Repeating reward checks never stacks stats")
	game.weapons.pistol.durability = 0
	game.apply_upgrades()
	check(game.weapon_stats().damage==6 and game.player.armor==5,"Broken weapons retain permanent quest stats")
	game.enter_room("throne")
	open_chest()
	check(game.current=="town" and game.checkpoint=="town","Ending starts expedition at an accessible hub")
	check_locked_zones(1)
	for stage in range(5):
		var reachable := reached()
		for id in game.POSTGAME.QUESTS[stage].rooms:
			check(reachable.has(id),"Current quest target remains reachable: "+id)
		for room in game.data.rooms:
			if game.progression.region_rank(room.id)>stage+1:
				check(not reachable.has(room.id),"Future postgame world blocked through every route: "+room.id)
		var old_attack: int = game.progression.attack_bonus()
		var old_armor: int = game.player.armor
		for id in game.POSTGAME.QUESTS[stage].rooms:
			game.enter_room(id)
			var object := object_of("quest")
			clear_enemies()
			if stage==3: game.postgame.shoot_switch(object)
			game.use_object(object)
			await process_frame
		check(game.progression.items.has(game.PROGRESSION.POSTGAME[stage].id),"Every postgame quest grants its unique item")
		check(game.progression.attack_bonus()==old_attack+2 and game.player.armor==old_armor+1,"Postgame reward improves real attack and defense")
		if stage<4:
			var guardian: Dictionary = game.progression.guardian_stats(stage+1,false)
			check(int(ceil(guardian.hp/float(game.weapon_stats().damage)))==5,"Next expedition is balanced for the previous quest item, even with emergency pistol")
	check(game.progression.items.size()==10 and reached().size()==55,"Five postgame items reopen every world and unlock the three Alba rooms")
	game.enter_room("throne")
	game.use_object(object_of("trial"))
	check(game.postgame.trial=="throne","Final quest item grants entry to the final trial")
	var saved_items: Array = game.progression.items.duplicate()
	var saved_attack: int = game.weapon_stats().damage
	game.checkpoint = "palace_gate"
	game.save_progress()
	game.reset_progress()
	game.load_progress()
	check(game.progression.items==saved_items and game.weapon_stats().damage==saved_attack and game.player.armor==10,"Items, real stats and access survive load")
	check(game.checkpoint=="palace_gate","Unlocked late checkpoint remains valid")
	# A previous release's completed save receives earned bonuses without trapping the player.
	var legacy := {"version":3,"checkpoint":"palace_gate","coins":77,"collected":["throne"],"double_jump":true,"dash":true,"boss_keys":["bone_lord","royal_spire"],"postgame":{"stage":1}}
	var file := FileAccess.open(game.save_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	game.reset_progress()
	game.load_progress()
	check(game.progression.items.size()==6 and game.progression.attack_bonus()==7 and game.player.armor==6,"Legacy completed quests recover earned items and stats")
	check(game.coins==77 and game.checkpoint=="town" and game.progression.can_enter("moss_gate") and not game.progression.can_enter("bone_gate"),"Migration retains money and places player outside a locked checkpoint")
	game.new_game()
	check(game.progression.items.is_empty() and game.weapon_stats().damage==1 and game.player.armor==0 and not game.progression.can_enter("town"),"New Game resets all quest items, stats and access")
	game.dirty = false
	DirAccess.remove_absolute(game.save_path)
	game.audio.shutdown()
	print("ZONE PROGRESSION: %d assertions, %d failures; campaign/postgame items, actual combat, full-graph access, real door input, migration and reset" % [assertions,failures])
	quit(1 if failures else 0)
