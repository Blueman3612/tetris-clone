extends Control
## Gameplay scene controller: owns the TetrisGame, routes input, drives gravity, updates the HUD,
## and relays game events onto EventBus.

@onready var _board_view: Control = %BoardView
@onready var _preview_view: Control = %PreviewView
@onready var _score_value: Label = %ScoreValue
@onready var _level_value: Label = %LevelValue
@onready var _lines_value: Label = %LinesValue
@onready var _high_score_value: Label = %HighScoreValue
@onready var _pause_overlay: Control = %PauseOverlay
@onready var _resume_button: Button = %ResumeButton
@onready var _pause_menu_button: Button = %PauseMenuButton
@onready var _game_over_overlay: Control = %GameOverOverlay
@onready var _final_score_label: Label = %FinalScoreLabel
@onready var _new_record_label: Label = %NewRecordLabel
@onready var _retry_button: Button = %RetryButton
@onready var _menu_button: Button = %MenuButton
@onready var _fall_timer: Timer = %FallTimer

var game: TetrisGame
var paused: bool = false

var _das_direction: int = 0  # -1 left, 1 right, 0 idle
var _das_time: float = 0.0  # seconds the current move key has been held
var _soft_drop_armed: bool = false  # cleared when a soft drop locks a piece, until the key is pressed again
var _soft_drop_time: float = 0.0  # seconds since the last soft-drop step


func _ready() -> void:
	game = TetrisGame.new()
	_board_view.game = game
	game.piece_spawned.connect(_on_game_piece_spawned)
	game.piece_moved.connect(_on_game_piece_moved)
	game.piece_locked.connect(_on_game_piece_locked)
	game.lines_cleared.connect(_on_game_lines_cleared)
	game.score_changed.connect(_on_game_score_changed)
	game.level_changed.connect(_on_game_level_changed)
	game.lines_changed.connect(_on_game_lines_changed)
	game.game_over.connect(_on_game_game_over)
	EventBus.high_score_changed.connect(_on_event_bus_high_score_changed)
	_fall_timer.timeout.connect(_on_fall_timer_timeout)
	_resume_button.pressed.connect(_on_resume_button_pressed)
	_pause_menu_button.pressed.connect(_on_menu_button_pressed)
	_retry_button.pressed.connect(_on_retry_button_pressed)
	_menu_button.pressed.connect(_on_menu_button_pressed)
	_high_score_value.text = _format_score(HighScoreManager.get_high_score())
	start_game()


## Resets the game and HUD and begins a fresh round.
func start_game() -> void:
	_pause_overlay.hide()
	_game_over_overlay.hide()
	_new_record_label.hide()
	paused = false
	_fall_timer.paused = false
	_das_direction = 0
	_soft_drop_armed = false
	game.start()
	EventBus.game_started.emit()


func toggle_pause() -> void:
	if game.is_over:
		return
	paused = not paused
	_fall_timer.paused = paused
	_pause_overlay.visible = paused
	if paused:
		_resume_button.grab_focus()
	EventBus.game_paused.emit(paused)


## Gameplay keys are consumed in _input so they never reach GUI focus navigation while playing.
## While paused or after game over, non-pause keys fall through to the overlay buttons.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed(GameConfig.ACTION_PAUSE):
		toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if paused or game.is_over:
		return
	var consumed := true
	if event.is_action_pressed(GameConfig.ACTION_MOVE_LEFT):
		game.move_left()
		_begin_das(-1)
	elif event.is_action_pressed(GameConfig.ACTION_MOVE_RIGHT):
		game.move_right()
		_begin_das(1)
	elif event.is_action_pressed(GameConfig.ACTION_ROTATE_CW):
		game.rotate_cw()
	elif event.is_action_pressed(GameConfig.ACTION_ROTATE_CCW):
		game.rotate_ccw()
	elif event.is_action_pressed(GameConfig.ACTION_HARD_DROP):
		game.hard_drop()
	elif event.is_action_pressed(GameConfig.ACTION_SOFT_DROP):
		_soft_drop_armed = true
		_soft_drop_time = 0.0
		_soft_drop_step()
	else:
		consumed = false
	if event.is_action_released(GameConfig.ACTION_MOVE_LEFT) and _das_direction < 0:
		_das_direction = 0
	if event.is_action_released(GameConfig.ACTION_MOVE_RIGHT) and _das_direction > 0:
		_das_direction = 0
	if event.is_action_released(GameConfig.ACTION_SOFT_DROP):
		_soft_drop_armed = false
	if consumed:
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if paused or game.is_over:
		return
	_process_das(delta)
	_process_soft_drop(delta)


func _begin_das(direction: int) -> void:
	_das_direction = direction
	_das_time = 0.0


## Delayed auto shift: after DAS_DELAY a held move key repeats every DAS_REPEAT seconds.
func _process_das(delta: float) -> void:
	if _das_direction == 0:
		return
	var action := GameConfig.ACTION_MOVE_LEFT if _das_direction < 0 else GameConfig.ACTION_MOVE_RIGHT
	if not Input.is_action_pressed(action):
		_das_direction = 0
		return
	_das_time += delta
	while _das_time >= GameConfig.DAS_DELAY:
		_das_time -= GameConfig.DAS_REPEAT
		if _das_direction < 0:
			game.move_left()
		else:
			game.move_right()


func _process_soft_drop(delta: float) -> void:
	if not _soft_drop_armed:
		return
	if not Input.is_action_pressed(GameConfig.ACTION_SOFT_DROP):
		_soft_drop_armed = false
		return
	_soft_drop_time += delta
	while _soft_drop_time >= GameConfig.SOFT_DROP_INTERVAL and _soft_drop_armed:
		_soft_drop_time -= GameConfig.SOFT_DROP_INTERVAL
		_soft_drop_step()


func _soft_drop_step() -> void:
	if not game.soft_drop():
		# The piece locked; require a fresh key press before the next piece soft-drops.
		_soft_drop_armed = false


func _format_score(score: int) -> String:
	return str(score).pad_zeros(GameConfig.SCORE_DIGITS)


func _on_fall_timer_timeout() -> void:
	game.tick()


func _on_game_piece_spawned(_piece: Piece) -> void:
	_preview_view.piece_type = game.next_type
	_board_view.queue_redraw()
	_fall_timer.wait_time = game.fall_interval()
	_fall_timer.start()


func _on_game_piece_moved() -> void:
	_board_view.queue_redraw()


func _on_game_piece_locked(_piece: Piece) -> void:
	_board_view.queue_redraw()
	EventBus.piece_locked.emit()


func _on_game_lines_cleared(rows: Array[int]) -> void:
	EventBus.lines_cleared.emit(rows.size())


func _on_game_score_changed(score: int) -> void:
	_score_value.text = _format_score(score)
	if score > HighScoreManager.get_high_score():
		_high_score_value.text = _format_score(score)
	EventBus.score_changed.emit(score)


func _on_game_level_changed(level: int) -> void:
	_level_value.text = str(level)
	_fall_timer.wait_time = game.fall_interval()
	EventBus.level_changed.emit(level)


func _on_game_lines_changed(lines: int) -> void:
	_lines_value.text = str(lines)
	EventBus.lines_changed.emit(lines)


func _on_game_game_over(score: int) -> void:
	_fall_timer.stop()
	_board_view.queue_redraw()
	_final_score_label.text = "SCORE  %s" % _format_score(score)
	_new_record_label.hide()
	# HighScoreManager listens here; it emits high_score_changed when this score is a record.
	EventBus.game_over.emit(score)
	_set_game_over_buttons_enabled(false)
	_game_over_overlay.show()
	get_tree().create_timer(GameConfig.GAME_OVER_INPUT_DELAY).timeout.connect(_on_game_over_delay_timeout, CONNECT_ONE_SHOT)


## Space doubles as hard drop and ui_accept, so the buttons only accept input after a short lockout.
func _on_game_over_delay_timeout() -> void:
	if not game.is_over:
		return
	_set_game_over_buttons_enabled(true)
	_retry_button.grab_focus()


func _set_game_over_buttons_enabled(enabled: bool) -> void:
	_retry_button.disabled = not enabled
	_menu_button.disabled = not enabled


func _on_event_bus_high_score_changed(high_score: int) -> void:
	_high_score_value.text = _format_score(high_score)
	_new_record_label.show()


func _on_resume_button_pressed() -> void:
	toggle_pause()


func _on_retry_button_pressed() -> void:
	start_game()


func _on_menu_button_pressed() -> void:
	get_tree().change_scene_to_file(GameConfig.MAIN_MENU_SCENE)
