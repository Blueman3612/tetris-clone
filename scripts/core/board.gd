class_name Board
extends RefCounted
## The locked-block grid. Stores a value per cell: EMPTY or (piece type + 1) so colors survive locking.
## Pure data with collision and line-clear logic; no rendering.

const EMPTY := 0

var width: int
var height: int

var _cells: PackedInt32Array


func _init(p_width: int = GameConfig.BOARD_SIZE.x, p_height: int = GameConfig.BOARD_SIZE.y) -> void:
	width = p_width
	height = p_height
	clear()


static func value_for_type(type: int) -> int:
	return type + 1


static func type_for_value(value: int) -> int:
	return value - 1


func clear() -> void:
	_cells = PackedInt32Array()
	_cells.resize(width * height)
	_cells.fill(EMPTY)


func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < width and cell.y >= 0 and cell.y < height


func get_cell(cell: Vector2i) -> int:
	assert(is_inside(cell), "Board.get_cell out of bounds: %s" % cell)
	return _cells[cell.y * width + cell.x]


func set_cell(cell: Vector2i, value: int) -> void:
	assert(is_inside(cell), "Board.set_cell out of bounds: %s" % cell)
	_cells[cell.y * width + cell.x] = value


## True when the cell is on the board and unoccupied.
func is_free(cell: Vector2i) -> bool:
	return is_inside(cell) and get_cell(cell) == EMPTY


## True when every cell is free: the collision test for placing a piece.
func fits(cells: Array[Vector2i]) -> bool:
	for cell in cells:
		if not is_free(cell):
			return false
	return true


func lock(cells: Array[Vector2i], value: int) -> void:
	for cell in cells:
		set_cell(cell, value)


func is_row_full(y: int) -> bool:
	for x in width:
		if get_cell(Vector2i(x, y)) == EMPTY:
			return false
	return true


func is_row_empty(y: int) -> bool:
	for x in width:
		if get_cell(Vector2i(x, y)) != EMPTY:
			return false
	return true


## Indices of every completely filled row, top to bottom.
func full_rows() -> Array[int]:
	var rows: Array[int] = []
	for y in height:
		if is_row_full(y):
			rows.append(y)
	return rows


## Removes the given rows and shifts everything above them down. Returns the count removed.
func clear_rows(rows: Array[int]) -> int:
	if rows.is_empty():
		return 0
	var remaining := PackedInt32Array()
	remaining.resize(width * height)
	remaining.fill(EMPTY)
	var write_y := height - 1
	for read_y in range(height - 1, -1, -1):
		if rows.has(read_y):
			continue
		for x in width:
			remaining[write_y * width + x] = _cells[read_y * width + x]
		write_y -= 1
	_cells = remaining
	return rows.size()


## Clears every full row. Returns the row indices that were removed.
func clear_full_rows() -> Array[int]:
	var rows := full_rows()
	clear_rows(rows)
	return rows


func is_empty() -> bool:
	for value in _cells:
		if value != EMPTY:
			return false
	return true


func filled_count() -> int:
	var count := 0
	for value in _cells:
		if value != EMPTY:
			count += 1
	return count


## Values of one row, left to right. Handy for assertions.
func row_values(y: int) -> Array[int]:
	var out: Array[int] = []
	for x in width:
		out.append(get_cell(Vector2i(x, y)))
	return out
