class_name BlockPainter
extends RefCounted
## Shared tile drawing for the playfield and the next-piece preview.


static func color_for_type(type: int) -> Color:
	return GameConfig.PIECE_COLORS[type]


## Draws one beveled block whose cell occupies the square at origin with the given side length.
static func draw_block(canvas: CanvasItem, origin: Vector2, size: float, color: Color) -> void:
	var rect := _inset_rect(origin, size)
	canvas.draw_rect(rect, color)
	var bevel := float(GameConfig.CELL_BEVEL_SIZE)
	var light := color.lightened(GameConfig.CELL_BEVEL_LIGHTEN)
	var dark := color.darkened(GameConfig.CELL_BEVEL_DARKEN)
	canvas.draw_rect(Rect2(rect.position, Vector2(rect.size.x, bevel)), light)
	canvas.draw_rect(Rect2(rect.position, Vector2(bevel, rect.size.y)), light)
	canvas.draw_rect(Rect2(rect.position + Vector2(0.0, rect.size.y - bevel), Vector2(rect.size.x, bevel)), dark)
	canvas.draw_rect(Rect2(rect.position + Vector2(rect.size.x - bevel, 0.0), Vector2(bevel, rect.size.y)), dark)


## Draws the translucent outline used for the landing preview.
static func draw_ghost(canvas: CanvasItem, origin: Vector2, size: float, color: Color) -> void:
	var ghost := Color(color, GameConfig.GHOST_ALPHA)
	canvas.draw_rect(_inset_rect(origin, size), ghost, false, GameConfig.GHOST_OUTLINE_WIDTH)


static func _inset_rect(origin: Vector2, size: float) -> Rect2:
	var inset := float(GameConfig.CELL_INSET)
	return Rect2(origin + Vector2(inset, inset), Vector2(size - inset * 2.0, size - inset * 2.0))
