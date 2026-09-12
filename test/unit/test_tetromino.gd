extends GdUnitTestSuite
## Shape data invariants and rotation behaviour of the SRS tables.


func test_every_type_has_four_cells_in_every_rotation() -> void:
	for type in Tetromino.COUNT:
		for rotation in Tetromino.ROTATIONS:
			var cells := Tetromino.cells(type, rotation)
			assert_array(cells).override_failure_message("type %d rotation %d" % [type, rotation]).has_size(4)
			# Cells are distinct and stay inside the bounding box.
			var seen := {}
			for cell in cells:
				assert_bool(seen.has(cell)).override_failure_message("duplicate cell %s in type %d rot %d" % [cell, type, rotation]).is_false()
				seen[cell] = true
				assert_int(cell.x).is_between(0, Tetromino.box_size(type) - 1)
				assert_int(cell.y).is_between(0, Tetromino.box_size(type) - 1)


func test_rotation_index_wraps_after_four_steps() -> void:
	for type in Tetromino.COUNT:
		assert_array(Tetromino.cells(type, 4)).contains_exactly(Tetromino.cells(type, 0))
		assert_array(Tetromino.cells(type, -1)).contains_exactly(Tetromino.cells(type, 3))


func test_o_piece_is_rotation_invariant() -> void:
	var base := Tetromino.cells(Tetromino.Type.O, 0)
	for rotation in Tetromino.ROTATIONS:
		assert_array(Tetromino.cells(Tetromino.Type.O, rotation)).contains_exactly(base)


func test_i_piece_alternates_between_horizontal_and_vertical() -> void:
	var horizontal := Tetromino.cells(Tetromino.Type.I, 0)
	var vertical := Tetromino.cells(Tetromino.Type.I, 1)
	for cell in horizontal:
		assert_int(cell.y).is_equal(horizontal[0].y)
	for cell in vertical:
		assert_int(cell.x).is_equal(vertical[0].x)


func test_cells_returns_a_copy_not_the_shared_table() -> void:
	var first := Tetromino.cells(Tetromino.Type.T, 0)
	first.clear()
	assert_array(Tetromino.cells(Tetromino.Type.T, 0)).has_size(4)


func test_kick_tables_start_with_zero_offset_and_have_five_entries_for_kicking_pieces() -> void:
	for type in Tetromino.COUNT:
		for from_rotation in Tetromino.ROTATIONS:
			for direction in [1, -1]:
				var to_rotation := posmod(from_rotation + direction, Tetromino.ROTATIONS)
				var kicks := Tetromino.kicks(type, from_rotation, to_rotation)
				assert_that(kicks[0]).is_equal(Vector2i.ZERO)
				if type == Tetromino.Type.O:
					assert_array(kicks).has_size(1)
				else:
					assert_array(kicks).has_size(5)


func test_spawn_position_centers_the_bounding_box_at_the_top() -> void:
	var width := GameConfig.BOARD_SIZE.x
	assert_that(Tetromino.spawn_position(Tetromino.Type.T, width)).is_equal(Vector2i(3, GameConfig.SPAWN_ROW))
	assert_that(Tetromino.spawn_position(Tetromino.Type.I, width)).is_equal(Vector2i(3, GameConfig.SPAWN_ROW))
	assert_that(Tetromino.spawn_position(Tetromino.Type.O, width)).is_equal(Vector2i(3, GameConfig.SPAWN_ROW))
