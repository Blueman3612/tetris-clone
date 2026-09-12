extends GdUnitTestSuite
## Collision, locking and line-clear behaviour of the Board grid.

var _board: Board


func before_test() -> void:
	_board = Board.new(10, 20)


func _fill_row(y: int, value: int = 1, skip_x: int = -1) -> void:
	for x in _board.width:
		if x != skip_x:
			_board.set_cell(Vector2i(x, y), value)


func test_new_board_is_empty_with_configured_size() -> void:
	assert_bool(_board.is_empty()).is_true()
	assert_int(_board.width).is_equal(10)
	assert_int(_board.height).is_equal(20)
	assert_int(_board.filled_count()).is_zero()


func test_default_size_comes_from_game_config() -> void:
	var board := Board.new()
	assert_int(board.width).is_equal(GameConfig.BOARD_SIZE.x)
	assert_int(board.height).is_equal(GameConfig.BOARD_SIZE.y)


func test_cells_outside_the_board_are_not_free() -> void:
	assert_bool(_board.is_free(Vector2i(-1, 0))).is_false()
	assert_bool(_board.is_free(Vector2i(10, 0))).is_false()
	assert_bool(_board.is_free(Vector2i(0, -1))).is_false()
	assert_bool(_board.is_free(Vector2i(0, 20))).is_false()
	assert_bool(_board.is_free(Vector2i(0, 0))).is_true()
	assert_bool(_board.is_free(Vector2i(9, 19))).is_true()


func test_fits_rejects_walls_floor_and_occupied_cells() -> void:
	var piece := Piece.new(Tetromino.Type.O, Vector2i(3, 0))
	assert_bool(_board.fits(piece.cells())).is_true()
	# Off the left wall: O occupies box columns 1..2, so x = -2 puts a cell at -1.
	assert_bool(_board.fits(piece.cells_at(Vector2i(-2, 0), 0))).is_false()
	assert_bool(_board.fits(piece.cells_at(Vector2i(-1, 0), 0))).is_true()
	# Off the right wall.
	assert_bool(_board.fits(piece.cells_at(Vector2i(7, 0), 0))).is_true()
	assert_bool(_board.fits(piece.cells_at(Vector2i(8, 0), 0))).is_false()
	# Through the floor.
	assert_bool(_board.fits(piece.cells_at(Vector2i(3, 18), 0))).is_true()
	assert_bool(_board.fits(piece.cells_at(Vector2i(3, 19), 0))).is_false()
	# Onto a locked block.
	_board.set_cell(Vector2i(4, 1), 1)
	assert_bool(_board.fits(piece.cells())).is_false()


func test_lock_writes_the_piece_value_into_every_cell() -> void:
	var piece := Piece.new(Tetromino.Type.T, Vector2i(0, 0))
	_board.lock(piece.cells(), Board.value_for_type(Tetromino.Type.T))
	assert_int(_board.filled_count()).is_equal(4)
	for cell in piece.cells():
		assert_int(_board.get_cell(cell)).is_equal(Board.value_for_type(Tetromino.Type.T))
	assert_int(Board.type_for_value(_board.get_cell(piece.cells()[0]))).is_equal(Tetromino.Type.T)


func test_a_row_missing_one_cell_is_not_full() -> void:
	_fill_row(19, 1, 4)
	assert_bool(_board.is_row_full(19)).is_false()
	assert_array(_board.full_rows()).is_empty()
	_board.set_cell(Vector2i(4, 19), 1)
	assert_bool(_board.is_row_full(19)).is_true()
	assert_array(_board.full_rows()).contains_exactly([19])


func test_clearing_the_bottom_row_shifts_everything_down() -> void:
	_fill_row(19)
	_board.set_cell(Vector2i(2, 18), 5)
	_board.set_cell(Vector2i(7, 17), 6)
	var cleared := _board.clear_full_rows()
	assert_array(cleared).contains_exactly([19])
	assert_int(_board.filled_count()).is_equal(2)
	assert_int(_board.get_cell(Vector2i(2, 19))).is_equal(5)
	assert_int(_board.get_cell(Vector2i(7, 18))).is_equal(6)
	assert_bool(_board.is_row_empty(17)).is_true()


func test_clearing_non_adjacent_rows_preserves_the_gap_rows_in_order() -> void:
	_fill_row(19)
	_fill_row(17)
	_board.set_cell(Vector2i(0, 18), 2)  # sits between the two full rows
	_board.set_cell(Vector2i(9, 16), 3)  # sits above both
	var cleared := _board.clear_full_rows()
	assert_array(cleared).contains_exactly([17, 19])
	assert_int(_board.filled_count()).is_equal(2)
	assert_int(_board.get_cell(Vector2i(0, 19))).is_equal(2)
	assert_int(_board.get_cell(Vector2i(9, 18))).is_equal(3)


func test_clearing_four_rows_at_once_leaves_no_full_rows() -> void:
	for y in range(16, 20):
		_fill_row(y)
	_board.set_cell(Vector2i(5, 15), 4)
	assert_int(_board.clear_full_rows().size()).is_equal(4)
	assert_array(_board.full_rows()).is_empty()
	assert_int(_board.filled_count()).is_equal(1)
	assert_int(_board.get_cell(Vector2i(5, 19))).is_equal(4)


func test_clear_rows_with_empty_list_is_a_no_op() -> void:
	_board.set_cell(Vector2i(1, 1), 1)
	assert_int(_board.clear_rows([])).is_zero()
	assert_int(_board.get_cell(Vector2i(1, 1))).is_equal(1)


@warning_ignore("unused_parameter")
func test_random_fill_then_clear_never_leaves_full_rows_and_conserves_other_cells(
	fuzzer := Fuzzers.rangei(0, 1_000_000), fuzzer_iterations := 50) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = fuzzer.next_value()
	for y in _board.height:
		if rng.randf() < 0.3:
			_fill_row(y, rng.randi_range(1, Tetromino.COUNT))
		else:
			for x in _board.width:
				if rng.randf() < 0.5:
					_board.set_cell(Vector2i(x, y), rng.randi_range(1, Tetromino.COUNT))
	var full := _board.full_rows()
	var before := _board.filled_count()
	var cleared := _board.clear_full_rows()
	assert_int(cleared.size()).is_equal(full.size())
	assert_array(_board.full_rows()).is_empty()
	assert_int(_board.filled_count()).is_equal(before - full.size() * _board.width)
	# Rows are only ever pushed down, so the top `cleared` rows must be empty.
	for y in cleared.size():
		assert_bool(_board.is_row_empty(y)).is_true()
