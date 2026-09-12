extends Control
## Draws the upcoming piece centered in a fixed square box.

var piece_type: int = -1:
	set(value):
		piece_type = value
		queue_redraw()


func _ready() -> void:
	custom_minimum_size = Vector2.ONE * GameConfig.PREVIEW_BOX * GameConfig.CELL_SIZE


func _draw() -> void:
	var cell := float(GameConfig.CELL_SIZE)
	draw_rect(Rect2(Vector2.ZERO, custom_minimum_size), GameConfig.BOARD_BG_COLOR)
	if piece_type < 0:
		return
	var cells := Tetromino.cells(piece_type, 0)
	var min_cell := cells[0]
	var max_cell := cells[0]
	for c in cells:
		min_cell = Vector2i(mini(min_cell.x, c.x), mini(min_cell.y, c.y))
		max_cell = Vector2i(maxi(max_cell.x, c.x), maxi(max_cell.y, c.y))
	var shape_px := Vector2(max_cell - min_cell + Vector2i.ONE) * cell
	var origin := (custom_minimum_size - shape_px) * 0.5 - Vector2(min_cell) * cell
	var color := BlockPainter.color_for_type(piece_type)
	for c in cells:
		BlockPainter.draw_block(self, origin + Vector2(c) * cell, cell, color)
