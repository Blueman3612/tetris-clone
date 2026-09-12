class_name Scoring
extends RefCounted
## Score, level and gravity formulas. Stateless; all constants come from GameConfig.


## Points for clearing lines_cleared rows at once on the given level.
static func line_clear_points(lines_cleared: int, level: int) -> int:
	if lines_cleared <= 0:
		return 0
	var index := clampi(lines_cleared, 1, GameConfig.LINE_SCORES.size()) - 1
	return GameConfig.LINE_SCORES[index] * (level + 1)


static func soft_drop_points(cells_dropped: int) -> int:
	return maxi(cells_dropped, 0) * GameConfig.SOFT_DROP_POINTS


static func hard_drop_points(cells_dropped: int) -> int:
	return maxi(cells_dropped, 0) * GameConfig.HARD_DROP_POINTS


## Level reached after clearing total_lines from a game that began at starting_level.
static func level_for_lines(total_lines: int, starting_level: int = GameConfig.STARTING_LEVEL) -> int:
	@warning_ignore("integer_division")
	return starting_level + maxi(total_lines, 0) / GameConfig.LINES_PER_LEVEL


## Seconds between gravity steps at the given level.
static func fall_interval(level: int) -> float:
	var index := clampi(level, 0, GameConfig.FALL_FRAMES.size() - 1)
	return GameConfig.FALL_FRAMES[index] / GameConfig.FRAME_RATE
