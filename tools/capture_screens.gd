extends SceneTree
## Captures PNG screenshots of the main menu and the game scene for visual review.
## Needs a real (non-headless) window because it reads back the rendered viewport.
## Usage: Godot --path . -s tools/capture_screens.gd -- <output_dir>

const GC := preload("res://scripts/autoload/game_config.gd")
const SETTLE_FRAMES := 12  # frames to wait so layout and drawing are complete before reading back
const DEMO_DROPS := 9  # hard drops to stage a partially filled board in the game screenshot
const DEMO_SEED := 7  # deterministic piece sequence for the staged board


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir := args[0] if args.size() > 0 else "user://screens"
	DirAccess.make_dir_recursive_absolute(out_dir)
	# The staged game over would otherwise persist a fake record into the real save file.
	var manager: Node = root.get_node_or_null("HighScoreManager")
	if manager != null:
		manager.save_path = out_dir.path_join("high_score_scratch.cfg")
		manager.clear_saved()
	_run(out_dir)


func _run(out_dir: String) -> void:
	await _capture_scene(GC.MAIN_MENU_SCENE, out_dir.path_join("main_menu.png"), Callable())
	await _capture_scene(GC.GAME_SCENE, out_dir.path_join("game.png"), _stage_game)
	await _capture_scene(GC.GAME_SCENE, out_dir.path_join("game_over.png"), _stage_game_over)
	quit()


func _capture_scene(path: String, out_path: String, stage: Callable) -> void:
	change_scene_to_file(path)
	for i in SETTLE_FRAMES:
		await process_frame
	if stage.is_valid():
		stage.call(current_scene)
	for i in SETTLE_FRAMES:
		await process_frame
	var image := root.get_viewport().get_texture().get_image()
	var err := image.save_png(out_path)
	print("[capture] %s -> %s (error=%d)" % [path, out_path, err])


func _stage_game(scene: Node) -> void:
	var game: TetrisGame = scene.game
	game.bag = PieceBag.new(DEMO_SEED)
	game.start()
	for i in DEMO_DROPS:
		if i % 3 == 0:
			game.move_left()
			game.move_left()
			game.move_left()
		elif i % 3 == 1:
			game.move_right()
			game.move_right()
			game.move_right()
		game.hard_drop()


func _stage_game_over(scene: Node) -> void:
	var game: TetrisGame = scene.game
	while not game.is_over:
		game.hard_drop()
