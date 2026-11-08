extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://Scenes/main.tscn").instantiate()
	# This preview never reads or writes the player's campaign save.
	game.save_path = "res://Tests/aurora_preview_save.json"
	root.add_child(game)
	game.new_game()
	game.collected = ["throne"]
	game.postgame.stage = 5
	game.player.double_jump = true
	game.player.dash = true
	game.boss_keys = ["bone_lord","royal_spire"]
	game.keys = 2
	game.quest_started = true
	game.quest_paid = true
	game.defeated = ["nest","bone_lord","royal_spire"]
	for entry in game.PROGRESSION.CAMPAIGN: game.progression.grant(entry,true)
	game.progression.sync_rewards(true)
	game.checkpoint = "aurora_gate"
	game.coins = 120
	game.enter_room("throne")
	game.player.position = Vector2(game.level.room_size.x-58,game.level.floor_y-4)
	game.achievement_queue.clear()
	game.achievement_timer = 0
	game.tell("VISTA DE PRUEBA: puerta derecha al Alba. Guardado separado.")
