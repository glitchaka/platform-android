extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var mode: String = OS.get_cmdline_user_args()[0]
	var game = load("res://Scenes/main.tscn").instantiate()
	game.save_path = "res://Tests/menu_exit_"+mode+".json"
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	if mode in ["pause","window"]:
		game.new_game()
		game.enter_room("town")
		game.checkpoint = "town"
		game.coins = 37
		game.player.double_jump = true
		if mode == "pause":
			game.open_pause()
			game.menu_selection = 2
			game.menu_action("menu_accept")
		else:
			game._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	else:
		game.menu_selection = 2
		game.menu_action("menu_accept")
	await create_timer(0.5).timeout
	push_error("Quit did not close the engine: "+mode)
	quit(1)
