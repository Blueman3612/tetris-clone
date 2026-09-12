class_name Piece
extends RefCounted
## An active tetromino: type, rotation state and bounding-box position on the board.

var type: int
var rotation: int = 0
var position: Vector2i = Vector2i.ZERO


func _init(p_type: int, p_position: Vector2i = Vector2i.ZERO, p_rotation: int = 0) -> void:
	type = p_type
	position = p_position
	rotation = posmod(p_rotation, Tetromino.ROTATIONS)


## Absolute board cells this piece currently occupies.
func cells() -> Array[Vector2i]:
	return cells_at(position, rotation)


## Absolute board cells this piece would occupy at a hypothetical position and rotation.
func cells_at(at_position: Vector2i, at_rotation: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for offset in Tetromino.cells(type, at_rotation):
		out.append(at_position + offset)
	return out


func copy() -> Piece:
	return Piece.new(type, position, rotation)
