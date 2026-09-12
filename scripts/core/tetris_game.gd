class_name TetrisGame
extends RefCounted
## Pure Tetris rules: no nodes, no rendering, no timers.
## Drive it with move/rotate/drop/tick calls and observe state or signals.
## Locking is classic: a piece locks the moment gravity or a soft drop fails to move it down.

signal piece_spawned(piece: Piece)
signal piece_moved
signal piece_locked(piece: Piece)
signal lines_cleared(rows: Array[int])
signal score_changed(score: int)
signal level_changed(level: int)
signal lines_changed(lines: int)
signal game_over(score: int)

var board: Board
var bag: PieceBag
var current: Piece = null
var next_type: int = -1
var score: int = 0
var level: int = GameConfig.STARTING_LEVEL
var lines: int = 0
var is_over: bool = false
var starting_level: int = GameConfig.STARTING_LEVEL


## seed < 0 randomizes; any other seed makes the piece sequence deterministic.
func _init(seed: int = -1, p_starting_level: int = GameConfig.STARTING_LEVEL) -> void:
	board = Board.new()
	bag = PieceBag.new(seed)
	starting_level = p_starting_level
	level = starting_level


## Resets all state and spawns the first piece.
func start() -> void:
	board.clear()
	current = null
	score = 0
	lines = 0
	level = starting_level
	is_over = false
	next_type = bag.next()
	score_changed.emit(score)
	level_changed.emit(level)
	lines_changed.emit(lines)
	_spawn_next()


func move_left() -> bool:
	return _try_move(Vector2i(-1, 0))


func move_right() -> bool:
	return _try_move(Vector2i(1, 0))


func rotate_cw() -> bool:
	return _try_rotate(1)


func rotate_ccw() -> bool:
	return _try_rotate(-1)


## Moves the active piece down one row, scoring it. Locks the piece if it cannot move.
## Returns true when the piece moved.
func soft_drop() -> bool:
	if not _can_act():
		return false
	if _try_move(Vector2i(0, 1)):
		_add_score(Scoring.soft_drop_points(1))
		return true
	_lock_current()
	return false


## Drops the active piece straight to its landing row and locks it. Returns rows travelled.
func hard_drop() -> int:
	if not _can_act():
		return 0
	var distance := drop_distance()
	current.position.y += distance
	if distance > 0:
		piece_moved.emit()
	_add_score(Scoring.hard_drop_points(distance))
	_lock_current()
	return distance


## One gravity step. Locks the piece when it can no longer fall.
func tick() -> void:
	if not _can_act():
		return
	if not _try_move(Vector2i(0, 1)):
		_lock_current()


## Rows the active piece can still fall before landing.
func drop_distance() -> int:
	if current == null:
		return 0
	var distance := 0
	while board.fits(current.cells_at(current.position + Vector2i(0, distance + 1), current.rotation)):
		distance += 1
	return distance


## Cells the active piece would occupy after landing. Empty when there is no active piece.
func ghost_cells() -> Array[Vector2i]:
	if current == null:
		return []
	return current.cells_at(current.position + Vector2i(0, drop_distance()), current.rotation)


func fall_interval() -> float:
	return Scoring.fall_interval(level)


func _can_act() -> bool:
	return current != null and not is_over


func _try_move(delta: Vector2i) -> bool:
	if not _can_act():
		return false
	var target := current.position + delta
	if not board.fits(current.cells_at(target, current.rotation)):
		return false
	current.position = target
	piece_moved.emit()
	return true


func _try_rotate(direction: int) -> bool:
	if not _can_act():
		return false
	var to_rotation := posmod(current.rotation + direction, Tetromino.ROTATIONS)
	for kick in Tetromino.kicks(current.type, current.rotation, to_rotation):
		var target := current.position + kick
		if board.fits(current.cells_at(target, to_rotation)):
			current.position = target
			current.rotation = to_rotation
			piece_moved.emit()
			return true
	return false


func _lock_current() -> void:
	var locked := current
	board.lock(locked.cells(), Board.value_for_type(locked.type))
	current = null
	piece_locked.emit(locked)
	var rows := board.clear_full_rows()
	if not rows.is_empty():
		lines += rows.size()
		_add_score(Scoring.line_clear_points(rows.size(), level))
		lines_cleared.emit(rows)
		lines_changed.emit(lines)
		var new_level := Scoring.level_for_lines(lines, starting_level)
		if new_level != level:
			level = new_level
			level_changed.emit(level)
	_spawn_next()


func _spawn_next() -> void:
	var piece := Piece.new(next_type, Tetromino.spawn_position(next_type, board.width))
	next_type = bag.next()
	current = piece
	if not board.fits(piece.cells()):
		# Keep the blocked piece as current so the view can draw the overlap, then end the game.
		is_over = true
		game_over.emit(score)
		return
	piece_spawned.emit(piece)


func _add_score(points: int) -> void:
	if points <= 0:
		return
	score += points
	score_changed.emit(score)
