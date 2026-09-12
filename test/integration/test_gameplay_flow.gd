extends GdUnitTestSuite
## End-to-end flows through the real scenes with simulated keyboard input.
## The high-score save path is redirected to a scratch file for the whole suite.

const MENU_SCENE := "res://scenes/main_menu.tscn"
const GAME_SCENE := "res://scenes/game.tscn"
const ManagerScript := preload("res://scripts/autoload/high_score_manager.gd")
const GRAVITY_TIMEOUT_MS := 8000
const GRAVITY_TIME_FACTOR := 20.0
const LOCKOUT_TIMEOUT_MS := 8000
const LOCKOUT_TIME_FACTOR := 10.0

var _original_path: String
var _scratch_path: String


func before() -> void:
	_original_path = HighScoreManager.save_path
	_scratch_path = create_temp_dir("flow") + "/high_score.cfg"
	HighScoreManager.save_path = _scratch_path
	HighScoreManager.clear_saved()


func after() -> void:
	HighScoreManager.clear_saved()
	HighScoreManager.save_path = _original_path
	HighScoreManager.load_high_score()


func before_test() -> void:
	HighScoreManager.clear_saved()


func _padded(score: int) -> String:
	return str(score).pad_zeros(GameConfig.SCORE_DIGITS)


func test_main_menu_shows_the_saved_high_score_and_a_control_guide_matching_the_input_map() -> void:
	HighScoreManager.submit_score(4321)
	var runner := scene_runner(MENU_SCENE)
	await runner.await_input_processed()

	var high_score: Label = runner.find_child("HighScoreLabel")
	assert_str(high_score.text).contains(_padded(4321))

	var title: HBoxContainer = runner.find_child("TitleBox")
	assert_int(title.get_child_count()).is_equal("TETRIS".length())

	var grid: GridContainer = runner.find_child("ControlsGrid")
	assert_int(grid.get_child_count()).is_equal(6 * 2)
	var keycaps: Array = []
	var descriptions: Array = []
	for row in grid.get_children():
		if row is HBoxContainer:
			for cap in row.get_children():
				keycaps.append(cap.text)
		elif row is Label:
			descriptions.append(row.text)
	assert_array(keycaps).contains(["←", "→", "↑", "↓", "Space", "Z", "X", "P", "Esc"])
	assert_array(descriptions).contains_exactly(["Move", "Rotate", "Rotate back", "Soft drop", "Hard drop", "Pause"])

	var play: Button = runner.find_child("PlayButton")
	assert_bool(play.has_focus()).is_true()
	assert_bool(play.pressed.is_connected(runner.scene()._on_play_button_pressed)).is_true()


func test_keyboard_moves_rotates_and_pauses_the_active_piece() -> void:
	var runner := scene_runner(GAME_SCENE)
	await runner.await_input_processed()
	var scene: Node = runner.scene()
	var game: TetrisGame = scene.game
	var timer: Timer = runner.find_child("FallTimer")
	timer.stop()  # keep gravity out of a position-exact test

	var x0 := game.current.position.x
	await runner.simulate_key_pressed(KEY_LEFT)
	await runner.await_input_processed()
	assert_int(game.current.position.x).is_equal(x0 - 1)
	await runner.simulate_key_pressed(KEY_RIGHT)
	await runner.await_input_processed()
	assert_int(game.current.position.x).is_equal(x0)

	var rotation0 := game.current.rotation
	await runner.simulate_key_pressed(KEY_UP)
	await runner.await_input_processed()
	assert_int(game.current.rotation).is_equal(posmod(rotation0 + 1, Tetromino.ROTATIONS))
	await runner.simulate_key_pressed(KEY_Z)
	await runner.await_input_processed()
	assert_int(game.current.rotation).is_equal(rotation0)

	var overlay: Control = runner.find_child("PauseOverlay")
	assert_bool(overlay.visible).is_false()
	await runner.simulate_key_pressed(KEY_P)
	await runner.await_input_processed()
	assert_bool(scene.paused).is_true()
	assert_bool(overlay.visible).is_true()
	await runner.simulate_key_pressed(KEY_LEFT)
	await runner.await_input_processed()
	assert_int(game.current.position.x).override_failure_message("input must be ignored while paused").is_equal(x0)
	await runner.simulate_key_pressed(KEY_ESCAPE)
	await runner.await_input_processed()
	assert_bool(scene.paused).is_false()
	assert_bool(overlay.visible).is_false()


func test_soft_drop_key_advances_and_scores() -> void:
	var runner := scene_runner(GAME_SCENE)
	await runner.await_input_processed()
	var scene: Node = runner.scene()
	var game: TetrisGame = scene.game
	var timer: Timer = runner.find_child("FallTimer")
	timer.stop()
	var y0 := game.current.position.y
	await runner.simulate_key_pressed(KEY_DOWN)
	await runner.await_input_processed()
	assert_int(game.current.position.y).is_equal(y0 + 1)
	assert_int(game.score).is_equal(Scoring.soft_drop_points(1))
	var score_label: Label = runner.find_child("ScoreValue")
	assert_str(score_label.text).is_equal(_padded(game.score))


func test_gravity_moves_the_piece_down_over_time() -> void:
	var runner := scene_runner(GAME_SCENE)
	runner.set_time_factor(GRAVITY_TIME_FACTOR)
	await runner.await_input_processed()
	var game: TetrisGame = runner.scene().game
	var y0 := game.current.position.y
	var locks: Array = []
	game.piece_locked.connect(func(piece: Piece) -> void: locks.append(piece))
	var deadline := Time.get_ticks_msec() + GRAVITY_TIMEOUT_MS
	while game.current.position.y == y0 and locks.is_empty() and Time.get_ticks_msec() < deadline:
		await runner.simulate_frames(1)
	assert_bool(game.current.position.y > y0 or not locks.is_empty()).override_failure_message("gravity never advanced the piece").is_true()
	runner.set_time_factor(1.0)


func test_hard_dropping_until_game_over_shows_the_overlay_and_persists_the_high_score() -> void:
	var runner := scene_runner(GAME_SCENE)
	await runner.await_input_processed()
	var scene: Node = runner.scene()
	var game: TetrisGame = scene.game
	var timer: Timer = runner.find_child("FallTimer")
	var overlay: Control = runner.find_child("GameOverOverlay")
	var score_label: Label = runner.find_child("ScoreValue")
	var high_label: Label = runner.find_child("HighScoreValue")
	var game_overs: Array = []
	var bus_listener := func(score: int) -> void: game_overs.append(score)
	EventBus.game_over.connect(bus_listener)

	assert_bool(timer.is_stopped()).is_false()
	assert_bool(overlay.visible).is_false()
	assert_str(high_label.text).is_equal(_padded(0))

	var presses := 0
	while not game.is_over and presses < 300:
		await runner.simulate_key_pressed(KEY_SPACE)
		await runner.await_input_processed()
		presses += 1
	EventBus.game_over.disconnect(bus_listener)

	assert_bool(game.is_over).is_true()
	assert_int(presses).is_between(5, 299)
	assert_array(game_overs).contains_exactly([game.score])
	assert_int(game.score).is_greater(0)
	assert_bool(overlay.visible).is_true()
	assert_bool(timer.is_stopped()).is_true()
	assert_str(score_label.text).is_equal(_padded(game.score))
	assert_str(runner.find_child("FinalScoreLabel").text).contains(_padded(game.score))
	assert_bool(runner.find_child("NewRecordLabel").visible).is_true()
	assert_str(high_label.text).is_equal(_padded(game.score))
	var retry: Button = runner.find_child("RetryButton")
	assert_bool(retry.disabled).override_failure_message("game-over buttons must start locked").is_true()
	assert_bool(retry.has_focus()).is_false()

	# Persisted: the autoload holds it and a fresh loader reads it back from disk.
	assert_int(HighScoreManager.get_high_score()).is_equal(game.score)
	var reloaded: Node = auto_free(ManagerScript.new())
	reloaded.save_path = _scratch_path
	reloaded.load_high_score()
	assert_int(reloaded.get_high_score()).is_equal(game.score)

	# Gameplay input is inert after game over, including the Space key shared with ui_accept.
	var record := game.score
	await runner.simulate_key_pressed(KEY_SPACE)
	await runner.await_input_processed()
	assert_int(game.score).is_equal(record)
	assert_bool(game.is_over).is_true()

	# After the lockout the buttons enable and Play again takes focus.
	runner.set_time_factor(LOCKOUT_TIME_FACTOR)
	var deadline := Time.get_ticks_msec() + LOCKOUT_TIMEOUT_MS
	while retry.disabled and Time.get_ticks_msec() < deadline:
		await runner.simulate_frames(1)
	runner.set_time_factor(1.0)
	assert_bool(retry.disabled).override_failure_message("lockout never lifted").is_false()
	assert_bool(retry.has_focus()).is_true()

	# Enter on the focused button starts a clean round while keeping the record on the HUD.
	await runner.simulate_key_pressed(KEY_ENTER)
	await runner.await_input_processed()
	assert_bool(game.is_over).is_false()
	assert_bool(overlay.visible).is_false()
	assert_bool(game.board.is_empty()).is_true()
	assert_str(score_label.text).is_equal(_padded(0))
	assert_str(high_label.text).is_equal(_padded(record))
	assert_bool(timer.is_stopped()).is_false()
