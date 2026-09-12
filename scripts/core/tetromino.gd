class_name Tetromino
extends RefCounted
## Tetromino rule data: Super Rotation System shapes and wall-kick tables.
## Cells are Vector2i offsets from the top-left of each piece's bounding box, y grows downward.

enum Type { I, O, T, S, Z, J, L }

const COUNT := 7
const ROTATIONS := 4

const _BOX_SIZES := {
	Type.I: 4, Type.O: 4, Type.T: 3, Type.S: 3, Type.Z: 3, Type.J: 3, Type.L: 3,
}

const _SHAPES := {
	Type.I: [
		[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)],
		[Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2), Vector2i(2, 3)],
		[Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2)],
		[Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3)],
	],
	Type.O: [
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1)],
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1)],
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1)],
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1)],
	],
	Type.T: [
		[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
		[Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)],
		[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)],
		[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2)],
	],
	Type.S: [
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)],
		[Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2)],
		[Vector2i(1, 1), Vector2i(2, 1), Vector2i(0, 2), Vector2i(1, 2)],
		[Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2)],
	],
	Type.Z: [
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)],
		[Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)],
		[Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)],
		[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2)],
	],
	Type.J: [
		[Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(1, 2)],
		[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(2, 2)],
		[Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2)],
	],
	Type.L: [
		[Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
		[Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)],
		[Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(0, 2)],
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2)],
	],
}

# SRS wall kicks keyed by Vector2i(from_rotation, to_rotation), converted to y-down coordinates.
const _KICKS_JLSTZ := {
	Vector2i(0, 1): [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, 2), Vector2i(-1, 2)],
	Vector2i(1, 0): [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, -2), Vector2i(1, -2)],
	Vector2i(1, 2): [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, -2), Vector2i(1, -2)],
	Vector2i(2, 1): [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, 2), Vector2i(-1, 2)],
	Vector2i(2, 3): [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, 2), Vector2i(1, 2)],
	Vector2i(3, 2): [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, -2), Vector2i(-1, -2)],
	Vector2i(3, 0): [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, -2), Vector2i(-1, -2)],
	Vector2i(0, 3): [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, 2), Vector2i(1, 2)],
}

const _KICKS_I := {
	Vector2i(0, 1): [Vector2i(0, 0), Vector2i(-2, 0), Vector2i(1, 0), Vector2i(-2, 1), Vector2i(1, -2)],
	Vector2i(1, 0): [Vector2i(0, 0), Vector2i(2, 0), Vector2i(-1, 0), Vector2i(2, -1), Vector2i(-1, 2)],
	Vector2i(1, 2): [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(2, 0), Vector2i(-1, -2), Vector2i(2, 1)],
	Vector2i(2, 1): [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-2, 0), Vector2i(1, 2), Vector2i(-2, -1)],
	Vector2i(2, 3): [Vector2i(0, 0), Vector2i(2, 0), Vector2i(-1, 0), Vector2i(2, -1), Vector2i(-1, 2)],
	Vector2i(3, 2): [Vector2i(0, 0), Vector2i(-2, 0), Vector2i(1, 0), Vector2i(-2, 1), Vector2i(1, -2)],
	Vector2i(3, 0): [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-2, 0), Vector2i(1, 2), Vector2i(-2, -1)],
	Vector2i(0, 3): [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(2, 0), Vector2i(-1, -2), Vector2i(2, 1)],
}

const _KICKS_O := {
	Vector2i(0, 1): [Vector2i(0, 0)], Vector2i(1, 0): [Vector2i(0, 0)],
	Vector2i(1, 2): [Vector2i(0, 0)], Vector2i(2, 1): [Vector2i(0, 0)],
	Vector2i(2, 3): [Vector2i(0, 0)], Vector2i(3, 2): [Vector2i(0, 0)],
	Vector2i(3, 0): [Vector2i(0, 0)], Vector2i(0, 3): [Vector2i(0, 0)],
}


## Relative cell offsets of a piece type in the given rotation state (0..3, wraps).
static func cells(type: int, rotation: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	out.assign(_SHAPES[type][posmod(rotation, ROTATIONS)])
	return out


## Side length of the square bounding box the shape is defined in.
static func box_size(type: int) -> int:
	return _BOX_SIZES[type]


## Wall-kick offsets to try, in order, when rotating from one state to another.
static func kicks(type: int, from_rotation: int, to_rotation: int) -> Array[Vector2i]:
	var key := Vector2i(posmod(from_rotation, ROTATIONS), posmod(to_rotation, ROTATIONS))
	var table: Dictionary = _KICKS_I if type == Type.I else (_KICKS_O if type == Type.O else _KICKS_JLSTZ)
	var out: Array[Vector2i] = []
	out.assign(table[key])
	return out


## Bounding-box position that centers a freshly spawned piece at the top of a board.
static func spawn_position(type: int, board_width: int) -> Vector2i:
	@warning_ignore("integer_division")
	return Vector2i((board_width - box_size(type)) / 2, GameConfig.SPAWN_ROW)
