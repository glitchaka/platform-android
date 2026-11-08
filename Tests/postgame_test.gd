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
		if object.kind == kind and not object.active: return object
	return {}

func buy(id: String) -> bool:
	for i in range(game.SHOP.ITEMS.size()):
		if game.SHOP.ITEMS[i].id == id:
			game.shop_selection = i
			return game.buy_selected()
	return false

func clear_enemies() -> void:
	for enemy in game.enemies.duplicate():
		if enemy.alive: enemy.hit(10000)

func dummy(pos: Vector2) -> Node2D:
	var enemy = game.ENEMY.new()
	enemy.position = pos
	enemy.hp = 100
	enemy.max_hp = 100
	game.add_child(enemy)
	game.enemies.append(enemy)
	return enemy

func fire(weapon: String, level: int) -> void:
	game.unlock_weapon(weapon)
	game.weapons[weapon].level = level
	game.weapons[weapon].durability = 100
	game.equip_weapon(weapon)
	game.shots.clear()
	game.player.position = Vector2(64,60)
	game.player.facing = 1
	game.attack()

func advance_shots(time := 0.4) -> void:
	for i in range(int(time*120)): game.tick_shots(1.0/120)

func trial_kill() -> void:
	for enemy in game.enemies.duplicate():
		if enemy.alive and enemy.get_meta("post_id","")=="trial": enemy.hit(10000)

func tap(pos: Vector2) -> void:
	for pressed in [true,false]:
		var event := InputEventScreenTouch.new()
		event.index = 0
		event.pressed = pressed
		event.position = root.get_final_transform()*game.touch.get_global_transform_with_canvas()*pos
		Input.parse_input_event(event)
		Input.flush_buffered_events()

func run() -> void:
	game = load("res://Scenes/main.tscn").instantiate()
	game.save_path = "res://Tests/postgame_save.json"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.new_game()
	game.input_block_frames = 0
	check(not game.postgame.active() and object_of("quest").is_empty(),"No postgame before the ending")
	# Every existing save point gets a reachable merchant, with no masked exits.
	var shops := 0
	for room in game.data.rooms:
		if room.reward != "rest": continue
		game.enter_room(room.id)
		var merchant := object_of("merchant")
		var bench := object_of("bench")
		check(not merchant.is_empty() and not bench.is_empty(),"Shop at save point "+room.id)
		check(merchant.position.distance_to(bench.position)>=36,"Independent shop/bench interaction "+room.id)
		for door in game.level.exits:
			game.player.position = door.position
			check(game.nearest_object().is_empty(),"Merchant must not hide exit "+room.id)
		game.coins = 100
		game.player.health = 1
		game.use_object(merchant)
		check(buy("heal") and game.coins==97,"Shop purchases outside town "+room.id)
		shops += 1
	check(shops == 7,"All seven save rooms have shops, including the final zone")
	# Money alone must not bypass weapon or forge progression locks.
	game.enter_room("town")
	game.use_object(object_of("merchant"))
	game.coins = 1000
	check(not buy("shotgun") and not buy("flame") and not buy("forge"),"Weapon/forge progression gates")
	game.defeated.append("nest")
	check(buy("shotgun") and game.equipped_weapon=="shotgun","Shotgun unlock and equip")
	var balance: int = game.coins
	check(not buy("shotgun") and game.coins==balance,"No duplicate weapon charges")
	game.defeated.append("bone_lord")
	check(buy("flame"),"Flamethrower after Huesos")
	check(buy("forge") and game.weapons.flame.level==1,"Per-weapon first upgrade")
	check(game.weapons.pistol.level==0 and not buy("forge"),"No shared level; second upgrade requires royal")
	game.defeated.append("royal_spire")
	check(buy("forge") and not buy("forge"),"Second upgrade allowed; third requires ending")
	game.collected.append("throne")
	check(buy("forge") and not buy("forge"),"Third upgrade cap")
	game.weapons.flame.durability = 0
	game.equipped_title = "smith"
	var repair_item: Dictionary = game.SHOP.ITEMS[-1]
	check(game.shop_price(repair_item)==20,"Repair title discount rounds up")
	check(buy("repair") and game.weapons.flame.durability==480,"Repair restores equipped weapon")
	balance = game.coins
	check(not buy("repair") and game.coins==balance,"Full durability never charges")
	game.shop_action("shop_close")
	game.touch.enabled = true
	tap(Vector2(272,12))
	tap(Vector2(188,35))
	check(game.journal_open and game.journal_tab==3,"Touch opens Arsenal tab")
	game.journal_selection = 1
	tap(Vector2(210,165))
	check(game.equipped_weapon=="shotgun","Touch equips owned weapon")
	tap(Vector2(280,165))
	tap(Vector2(112,12))
	check(game.equipped_weapon=="flame","HUD touch cycles weapon")
	game.use_object(object_of("merchant"))
	game.shop_selection = 0
	tap(Vector2(186,32))
	tap(Vector2(186,32))
	check(game.shop_selection==12,"Touch can page directly to workshop")
	game.shop_action("shop_close")
	game.equipped_title = "none"
	game.weapons.flame.durability = 0
	game.attack()
	check(game.equipped_weapon=="pistol","Broken special weapon falls back to pistol")
	game.weapons.pistol.durability = 0
	game.apply_upgrades()
	game.attack()
	check(not game.shots.is_empty() and game.weapon_stats().damage==1,"Broken pistol retains emergency shot")
	game.use_object(object_of("bench"))
	check(game.weapons.pistol.durability==240,"Benches freely repair pistol")
	# Test real trajectories, pierce order, pellet accumulation, burn and burst delay.
	game.enter_room("town")
	var first := dummy(Vector2(104,59))
	var second := dummy(Vector2(144,59))
	fire("pistol",0)
	check(game.shots.size()==1,"Base pistol emits exactly one bullet")
	advance_shots()
	check(first.hp==99 and second.hp==100,"Base shot stops on first enemy")
	first.hp = 100
	fire("pistol",2)
	advance_shots()
	check(first.hp==97 and second.hp==97,"Level two pistol hits both enemies once")
	first.position = Vector2(88,59)
	first.hp = 100
	fire("shotgun",0)
	check(game.shots.size()==3 and game.shots[0].velocity.y<0 and game.shots[2].velocity.y>0,"Shotgun has three genuine spread trajectories")
	advance_shots()
	check(first.hp==97,"All three pellets damage a close target during same frame")
	first.hp = 100
	fire("flame",0)
	advance_shots(0.2)
	var before: int = first.hp
	first.tick(0.4)
	check(first.burn_time>0 and first.hp<before,"Flames apply actual lingering burn damage")
	fire("tempest",0)
	check(game.shots.size()==3 and game.shots[1].delay>0,"Unique burst is staggered, not shotgun pellets")
	fire("phoenix",3)
	check(game.shots.size()==3 and game.shots[0].burn==5,"Phoenix has three upgraded flame streams")
	fire("needle",3)
	check(game.shots[0].pierce==7 and game.shots[0].damage==12,"Unique lance has distinct damage and penetration")
	# Equip bonuses affect actual movement/cadence/damage/wear, not just labels.
	game.titles.append("ranger")
	game.journal_tab = 4
	game.journal_selection = 1
	game.journal_action("menu_accept")
	check(game.equipped_title=="ranger" and game.player.speed_bonus==1.12,"Equip title applies movement bonus")
	game.equipped_title = "keeper"
	fire("pistol",0)
	check(is_equal_approx(game.weapons.pistol.durability,99.2),"Custodian reduces real wear")
	game.equipped_title = "slayer"
	check(game.weapon_stats().damage==2,"Slayer improves direct damage")
	game.equipped_title = "swift"
	check(is_equal_approx(game.weapon_stats().interval,0.25/1.2),"Swift improves actual fire interval")
	game.equipped_title = "none"
	# Chain: physical objectives, no early future quest, all 52 rooms covered exactly once.
	for id in ["needle","tempest","phoenix"]: game.weapons.erase(id)
	var route: Array = []
	for quest in game.POSTGAME.QUESTS:
		for id in quest.rooms:
			check(not route.has(id) and not game.data.room(id).is_empty(),"Unique valid route room "+id)
			route.append(id)
	check(route.size()==52,"Five-quest route covers all 52 rooms")
	game.enter_room("canopy")
	check(object_of("quest").is_empty(),"Future mission cannot be played early")
	for stage in range(5):
		check(game.postgame.stage==stage,"Sequential mission "+str(stage))
		for id in game.POSTGAME.QUESTS[stage].rooms:
			game.enter_room(id)
			var objective := object_of("quest")
			check(not objective.is_empty(),"Physical quest objective "+id)
			for door in game.level.exits:
				game.player.position = door.position
				check(game.nearest_object().is_empty(),"Postgame objective does not mask exit "+id)
			if game.postgame.guards_alive():
				game.use_object(objective)
				check(not objective.active,"Guard prevents collecting "+id)
			clear_enemies()
			if stage==3:
				game.use_object(objective)
				check(not objective.active,"City mechanism requires a real shot")
				game.player.position = objective.position-Vector2(18,0)
				game.player.facing = 1
				game.shots.clear()
				game.attack()
				advance_shots(0.1)
				check(objective.activated,"Projectile activates city mechanism")
			game.use_object(objective)
			check(objective.active,"Quest interaction records completion "+id)
			balance = game.coins
			game.use_object(objective)
			check(game.coins==balance,"No duplicate mission reward")
			if stage==0 and id=="tutorial":
				game.save_progress()
				game.load_progress()
				game.enter_room(id)
				check(object_of("quest").is_empty() and game.postgame.stage==0,"Partial quest survives reload without duplicating objectives")
			await process_frame
		check(game.postgame.stage==stage+1 and game.achievements.has("post_%d" % (stage+1)),"Mission achievement granted only on completion")
		check(game.titles.has(game.POSTGAME.QUESTS[stage].title),"Mission title unlocked")
	check(game.postgame.recovered.size()==52 and not game.postgame.active(),"Exactly five missions finish")
	# Trials remain retryable. Damage includes shields, healing blocks marathon.
	game.enter_room("nest")
	game.use_object(object_of("trial"))
	game.player.invulnerable_timer = 0
	game.player.shield = true
	game.player.take_damage()
	game.postgame.tick(13)
	trial_kill()
	check(game.postgame.clean_trials.is_empty() and game.postgame.speed_trials.is_empty(),"Shield hit and slow kill cannot earn difficult achievements")
	for id in game.POSTGAME.TRIAL_ROOMS:
		game.enter_room(id)
		game.use_object(object_of("trial"))
		game.postgame.tick(11)
		trial_kill()
	check(game.weapons.has("needle") and game.weapons.has("tempest"),"Three clean/fast trials unlock unique weapons")
	game.enter_room("throne")
	game.use_object(object_of("trial"))
	game.postgame.healed()
	for i in range(3):
		trial_kill()
		await process_frame
	check(not game.postgame.marathon_won and not game.weapons.has("phoenix"),"Using healing prevents marathon unlock")
	# Combat tests temporarily unlocked Phoenix; remove that fixture for award check.
	game.weapons.erase("phoenix")
	game.use_object(object_of("trial"))
	for i in range(3):
		trial_kill()
		await process_frame
	check(game.postgame.marathon_won and game.weapons.has("phoenix") and game.titles.has("immortal"),"All three waves without healing unlock Phoenix and title")
	game.enter_room("nest")
	game.use_object(object_of("trial"))
	game.enter_room("town")
	check(game.postgame.trial.is_empty(),"Leaving abandons active trial")
	game.enter_room("nest")
	game.use_object(object_of("trial"))
	game.player.health = 1
	game.player.shield = false
	game.player.invulnerable_timer = 0
	game.player.take_damage()
	await process_frame
	check(game.postgame.trial.is_empty(),"Death abandons challenge before deferred respawn")
	game.equipped_title = "immortal"
	game.weapons.needle.level = 3
	game.equip_weapon("needle")
	game.weapons.needle.durability = 17.5
	game.save_progress()
	var state: Dictionary = game.postgame.save_data().duplicate(true)
	game.reset_progress()
	game.load_progress()
	check(game.postgame.save_data()==state,"Full quest and challenge state persists")
	check(game.equipped_weapon=="needle" and game.weapons.needle.durability==17.5 and game.weapons.needle.level==3,"Weapon level, wear and selection persist")
	check(game.equipped_title=="immortal" and game.weapon_stats().damage==13+game.progression.attack_bonus(),"Equipped title bonus restored")
	game.reset_progress()
	check(game.postgame.stage==0 and game.postgame.recovered.is_empty() and game.postgame.clean_trials.is_empty() and game.weapons.size()==1 and game.titles==["none"],"New game clears postgame, equipment and challenge progress")
	game.dirty = false
	DirAccess.remove_absolute(game.save_path)
	game.audio.shutdown()
	print("POSTGAME: %d assertions, %d failures; five quests, 52 quest rooms, seven shops, weapons, forge, wear, titles, trials and persistence" % [assertions,failures])
	quit(1 if failures else 0)
