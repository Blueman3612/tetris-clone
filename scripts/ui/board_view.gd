extends Control
## Draws the playfield from a TetrisGame: grid, locked blocks, landing ghost, and the active piece.

var game: TetrisGame = null:
	set(value):
		game = value
		queue_redraw()


func _ready() -> void:
	custom_minimum_size = Vector2(GameConfig.BOARD_SIZE) * GameConfig.CELL_SIZE


func _draw() -> void:
	var cell := float(GameConfig.CELL_SIZE)
	var board_px := Vector2(GameConfig.BOARD_SIZE) * cell
	draw_rect(Rect2(Vector2.ZERO, board_px), GameConfig.BOARD_BG_COLOR)
	for x in range(1, GameConfig.BOARD_SIZE.x):
		draw_line(Vector2(x * cell, 0.0), Vector2(x * cell, board_px.y), GameConfig.GRID_LINE_COLOR)
	for y in range(1, GameConfig.BOARD_SIZE.y):
		draw_line(Vector2(0.0, y * cell), Vector2(board_px.x, y * cell), GameConfig.GRID_LINE_COLOR)
	if game == null:
		return
	for y in game.board.height:
		for x in game.board.width:
			var value := game.board.get_cell(Vector2i(x, y))
			if value != Board.EMPTY:
				var color := BlockPainter.color_for_type(Board.type_for_value(value))
				BlockPainter.draw_block(self, Vector2(x, y) * cell, cell, color)
	if game.current == null:
		return
	var piece_color := BlockPainter.color_for_type(game.current.type)
	if GameConfig.GHOST_ENABLED and not game.is_over:
		for ghost_cell in game.ghost_cells():
			BlockPainter.draw_ghost(self, Vector2(ghost_cell) * cell, cell, piece_color)
	for piece_cell in game.current.cells():
		if game.board.is_inside(piece_cell):
			BlockPainter.draw_block(self, Vector2(piece_cell) * cell, cell, piece_color)
