extends GdUnitTestSuite
## Score, level and gravity formulas.


@warning_ignore("unused_parameter")
func test_line_clear_points_follow_the_nes_table(
	lines: int, level: int, expected: int,
	test_parameters := [
		[1, 0, 40], [2, 0, 100], [3, 0, 300], [4, 0, 1200],
		[1, 1, 80], [4, 9, 12000], [0, 5, 0], [-2, 3, 0],
	]) -> void:
	assert_int(Scoring.line_clear_points(lines, level)).is_equal(expected)


func test_more_than_four_lines_scores_as_four() -> void:
	assert_int(Scoring.line_clear_points(5, 0)).is_equal(Scoring.line_clear_points(4, 0))


func test_drop_points_scale_with_distance() -> void:
	assert_int(Scoring.soft_drop_points(1)).is_equal(GameConfig.SOFT_DROP_POINTS)
	assert_int(Scoring.hard_drop_points(10)).is_equal(10 * GameConfig.HARD_DROP_POINTS)
	assert_int(Scoring.soft_drop_points(-3)).is_zero()
	assert_int(Scoring.hard_drop_points(0)).is_zero()


func test_level_advances_every_lines_per_level() -> void:
	var per := GameConfig.LINES_PER_LEVEL
	assert_int(Scoring.level_for_lines(0, 0)).is_equal(0)
	assert_int(Scoring.level_for_lines(per - 1, 0)).is_equal(0)
	assert_int(Scoring.level_for_lines(per, 0)).is_equal(1)
	assert_int(Scoring.level_for_lines(per * 3 + 2, 0)).is_equal(3)
	assert_int(Scoring.level_for_lines(per, 5)).is_equal(6)


func test_fall_interval_decreases_with_level_and_clamps() -> void:
	var last_index := GameConfig.FALL_FRAMES.size() - 1
	for level in last_index:
		assert_float(Scoring.fall_interval(level + 1)).is_less_equal(Scoring.fall_interval(level))
	assert_float(Scoring.fall_interval(0)).is_equal(GameConfig.FALL_FRAMES[0] / GameConfig.FRAME_RATE)
	assert_float(Scoring.fall_interval(last_index + 50)).is_equal(Scoring.fall_interval(last_index))
	assert_float(Scoring.fall_interval(-5)).is_equal(Scoring.fall_interval(0))


@warning_ignore("unused_parameter")
func test_points_are_monotonic_in_level_and_lines(fuzzer := Fuzzers.rangei(0, 40), fuzzer_iterations := 60) -> void:
	var level: int = fuzzer.next_value()
	var previous := 0
	for lines in range(1, 5):
		var points := Scoring.line_clear_points(lines, level)
		assert_int(points).is_greater(previous)
		assert_int(Scoring.line_clear_points(lines, level + 1)).is_greater(points)
		previous = points
