extends GdUnitTestSuite
## Rules of play: movement, rotation with wall kicks, dropping, locking, clearing, scoring, levels, game over.

const SEED := 42

var _game: TetrisGame
var _locked: Array = []
var _cleared: Array = []
var _over: Array = []
var _levels: Array = []


func before_test() -> void:
	_locked = []
	_cleared = []
	_over = []
	_levels = []
	_game = TetrisGame.new(SEED)
	_game.piece_locked.connect(func(piece: Piece) -> void: _locked.append(piece))
	_game.lines_cleared.connect(func(rows: Array[int]) -> void: _cleared.append(rows))
	_game.game_over.connect(func(score: int) -> void: _over.append(score))
	_game.level_changed.connect(func(level: int) -> void: _levels.append(level))
	_game.start()


## Replaces the active piece so a test can stage an exact situation.
func _place(type: int, position: Vector2i, rotation: int = 0) -> void:
	_game.current = Piece.new(type, position, rotation)
	assert_bool(_game.board.fits(_game.current.cells())).override_failure_message("staged piece must fit").is_true()


func _fill_row_except(y: int, open_columns: Array) -> void:
	for x in _game.board.width:
		if not open_columns.has(x):
			_game.board.set_cell(Vector2i(x, y), Board.value_for_type(Tetromino.Type.O))


func test_start_spawns_a_piece_at_the_top_and_resets_counters() -> void:
	assert_object(_game.current).is_not_null()
	assert_int(_game.current.position.y).is_equal(GameConfig.SPAWN_ROW)
	assert_int(_game.next_type).is_between(0, Tetromino.COUNT - 1)
	assert_int(_game.score).is_zero()
	assert_int(_game.lines).is_zero()
	assert_int(_game.level).is_equal(GameConfig.STARTING_LEVEL)
	assert_bool(_game.is_over).is_false()
	assert_bool(_game.board.is_empty()).is_true()


func test_start_again_resets_a_finished_game() -> void:
	while not _game.is_over:
		_game.hard_drop()
	_game.start()
	assert_bool(_game.is_over).is_false()
	assert_bool(_game.board.is_empty()).is_true()
	assert_int(_game.score).is_zero()
	assert_object(_game.current).is_not_null()


func test_horizontal_moves_shift_one_column_and_stop_at_the_walls() -> void:
	_place(Tetromino.Type.T, Vector2i(3, 5))
	var moves := 0
	while _game.move_left():
		moves += 1
		assert_int(_game.current.position.x).is_equal(3 - moves)
	var min_x := 99
	for cell in _game.current.cells():
		min_x = mini(min_x, cell.x)
	assert_int(min_x).is_zero()
	assert_bool(_game.move_left()).is_false()
	while _game.move_right():
		pass
	var max_x := -1
	for cell in _game.current.cells():
		max_x = maxi(max_x, cell.x)
	assert_int(max_x).is_equal(_game.board.width - 1)


func test_rotation_cycles_through_four_states_and_stays_valid() -> void:
	_place(Tetromino.Type.T, Vector2i(3, 5))
	for expected in [1, 2, 3, 0]:
		assert_bool(_game.rotate_cw()).is_true()
		assert_int(_game.current.rotation).is_equal(expected)
		assert_bool(_game.board.fits(_game.current.cells())).is_true()
	for expected in [3, 2, 1, 0]:
		assert_bool(_game.rotate_ccw()).is_true()
		assert_int(_game.current.rotation).is_equal(expected)


func test_t_piece_kicks_off_the_left_wall() -> void:
	# Vertical T hugging the left wall: box at x = -1 puts its stem in column 0.
	_place(Tetromino.Type.T, Vector2i(-1, 5), 1)
	assert_bool(_game.rotate_cw()).is_true()
	assert_int(_game.current.rotation).is_equal(2)
	assert_that(_game.current.position).is_equal(Vector2i(0, 5))


func test_i_piece_kicks_two_columns_off_the_left_wall() -> void:
	# Vertical I in column 0 (box x = -2, cells at box column 2).
	_place(Tetromino.Type.I, Vector2i(-2, 5), 1)
	assert_bool(_game.rotate_cw()).is_true()
	assert_int(_game.current.rotation).is_equal(2)
	assert_that(_game.current.position).is_equal(Vector2i(0, 5))
	var min_x := 99
	for cell in _game.current.cells():
		min_x = mini(min_x, cell.x)
	assert_int(min_x).is_zero()


func test_rotation_fails_when_every_kick_is_blocked() -> void:
	_place(Tetromino.Type.T, Vector2i(3, 5))
	var keep := _game.current.cells()
	for y in range(2, 10):
		for x in _game.board.width:
			var cell := Vector2i(x, y)
			if not keep.has(cell):
				_game.board.set_cell(cell, 1)
	assert_bool(_game.rotate_cw()).is_false()
	assert_bool(_game.rotate_ccw()).is_false()
	assert_int(_game.current.rotation).is_zero()
	assert_that(_game.current.position).is_equal(Vector2i(3, 5))


func test_soft_drop_moves_down_one_row_and_scores() -> void:
	_place(Tetromino.Type.O, Vector2i(3, 0))
	var score_before := _game.score
	assert_bool(_game.soft_drop()).is_true()
	assert_int(_game.current.position.y).is_equal(1)
	assert_int(_game.score).is_equal(score_before + Scoring.soft_drop_points(1))
	assert_array(_locked).is_empty()


func test_soft_drop_on_a_landed_piece_locks_it() -> void:
	_place(Tetromino.Type.O, Vector2i(3, 18))
	assert_bool(_game.soft_drop()).is_false()
	assert_array(_locked).has_size(1)
	assert_int(_game.board.filled_count()).is_equal(4)
	assert_int(_game.board.get_cell(Vector2i(4, 19))).is_equal(Board.value_for_type(Tetromino.Type.O))
	assert_object(_game.current).is_not_null()
	assert_int(_game.current.position.y).is_equal(GameConfig.SPAWN_ROW)


func test_hard_drop_lands_locks_and_scores_the_distance() -> void:
	_place(Tetromino.Type.T, Vector2i(3, 0))
	var ghost := _game.ghost_cells()
	var distance := _game.hard_drop()
	assert_int(distance).is_equal(18)
	assert_int(_game.score).is_equal(Scoring.hard_drop_points(18))
	assert_array(_locked).has_size(1)
	assert_array(_locked[0].cells()).contains_exactly_in_any_order(ghost)
	for cell in ghost:
		assert_int(_game.board.get_cell(cell)).is_equal(Board.value_for_type(Tetromino.Type.T))
	assert_int(_game.current.position.y).is_equal(GameConfig.SPAWN_ROW)


func test_tick_moves_down_then_locks_at_the_floor() -> void:
	_place(Tetromino.Type.O, Vector2i(3, 17))
	_game.tick()
	assert_int(_game.current.position.y).is_equal(18)
	assert_array(_locked).is_empty()
	_game.tick()
	assert_array(_locked).has_size(1)
	assert_int(_game.board.filled_count()).is_equal(4)


func test_next_piece_becomes_current_after_a_lock() -> void:
	var upcoming := _game.next_type
	_game.hard_drop()
	assert_int(_game.current.type).is_equal(upcoming)
	assert_int(_game.next_type).is_between(0, Tetromino.COUNT - 1)


func test_completing_a_row_clears_it_scores_and_shifts_the_rest_down() -> void:
	_fill_row_except(19, [4, 5])
	_place(Tetromino.Type.O, Vector2i(3, 18))
	_game.hard_drop()
	assert_array(_cleared).has_size(1)
	assert_array(_cleared[0]).contains_exactly([19])
	assert_int(_game.lines).is_equal(1)
	assert_int(_game.score).is_equal(Scoring.line_clear_points(1, 0))
	# The O's upper row dropped into the cleared row; nothing else remains.
	assert_int(_game.board.filled_count()).is_equal(2)
	assert_int(_game.board.get_cell(Vector2i(4, 19))).is_equal(Board.value_for_type(Tetromino.Type.O))
	assert_int(_game.board.get_cell(Vector2i(5, 19))).is_equal(Board.value_for_type(Tetromino.Type.O))
	assert_array(_game.board.full_rows()).is_empty()


func test_vertical_i_clears_four_rows_for_a_tetris() -> void:
	for y in range(16, 20):
		_fill_row_except(y, [0])
	_place(Tetromino.Type.I, Vector2i(-2, 16), 1)
	_game.hard_drop()
	assert_array(_cleared).has_size(1)
	assert_array(_cleared[0]).contains_exactly([16, 17, 18, 19])
	assert_int(_game.lines).is_equal(4)
	assert_int(_game.score).is_equal(Scoring.line_clear_points(4, 0))
	assert_bool(_game.board.is_empty()).is_true()


func test_level_rises_after_lines_per_level_and_gravity_speeds_up() -> void:
	var slow := _game.fall_interval()
	for i in GameConfig.LINES_PER_LEVEL:
		_game.board.clear()
		_fill_row_except(19, [0])
		_place(Tetromino.Type.I, Vector2i(-2, 16), 1)
		_game.hard_drop()
	assert_int(_game.lines).is_equal(GameConfig.LINES_PER_LEVEL)
	assert_int(_game.level).is_equal(GameConfig.STARTING_LEVEL + 1)
	assert_array(_levels).contains_exactly([GameConfig.STARTING_LEVEL, GameConfig.STARTING_LEVEL + 1])
	assert_float(_game.fall_interval()).is_less(slow)
	# Every clear happened while still on the starting level.
	assert_int(_game.score).is_equal(GameConfig.LINES_PER_LEVEL * Scoring.line_clear_points(1, GameConfig.STARTING_LEVEL))


func test_hard_dropping_forever_ends_the_game_exactly_once_and_freezes_input() -> void:
	var drops := 0
	while not _game.is_over and drops < 300:
		_game.hard_drop()
		drops += 1
	assert_bool(_game.is_over).is_true()
	assert_array(_over).has_size(1)
	assert_int(_over[0]).is_equal(_game.score)
	var locks := _locked.size()
	var score := _game.score
	assert_int(_game.hard_drop()).is_zero()
	assert_bool(_game.move_left()).is_false()
	assert_bool(_game.rotate_cw()).is_false()
	assert_bool(_game.soft_drop()).is_false()
	_game.tick()
	assert_int(_locked.size()).is_equal(locks)
	assert_int(_game.score).is_equal(score)
	assert_array(_over).has_size(1)


@warning_ignore("unused_parameter")
func test_random_play_preserves_invariants(fuzzer := Fuzzers.rangei(0, 1_000_000), fuzzer_iterations := 20) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = fuzzer.next_value()
	var game := TetrisGame.new(rng.randi())
	var locks: Array = []
	game.piece_locked.connect(func(piece: Piece) -> void: locks.append(piece))
	game.start()
	var last_score := 0
	var last_lines := 0
	for step in 600:
		if game.is_over:
			break
		match rng.randi_range(0, 6):
			0: game.move_left()
			1: game.move_right()
			2: game.rotate_cw()
			3: game.rotate_ccw()
			4: game.soft_drop()
			5: game.hard_drop()
			6: game.tick()
		if not game.is_over:
			assert_bool(game.board.fits(game.current.cells())).override_failure_message("active piece overlaps or leaves the board").is_true()
		assert_array(game.board.full_rows()).override_failure_message("full rows must be cleared immediately").is_empty()
		assert_int(game.score).is_greater_equal(last_score)
		assert_int(game.lines).is_greater_equal(last_lines)
		assert_int(game.level).is_equal(Scoring.level_for_lines(game.lines, game.starting_level))
		assert_int(game.board.filled_count()).is_equal(locks.size() * 4 - game.lines * game.board.width)
		last_score = game.score
		last_lines = game.lines
