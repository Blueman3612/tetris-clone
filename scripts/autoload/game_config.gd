extends Node
## Central tunables. Every gameplay, timing, scoring, persistence and UI constant lives here.
## Shape and wall-kick data are rule definitions and live in Tetromino instead.

# -- Board --
const BOARD_SIZE := Vector2i(10, 20)  # playfield columns (x) and rows (y), in cells
const SPAWN_ROW := 0  # row (0 = top) where a new piece's bounding box appears

# -- Timing --
const FRAME_RATE := 60.0  # frames per second the FALL_FRAMES table is expressed in (NES timing)
const FALL_FRAMES: Array[int] = [  # frames per gravity step, indexed by level; last entry repeats beyond
	48, 43, 38, 33, 28, 23, 18, 13, 8, 6,
	5, 5, 5, 4, 4, 4, 3, 3, 3, 2,
	2, 2, 2, 2, 2, 2, 2, 2, 2, 1,
]
const DAS_DELAY := 0.17  # seconds a move key is held before auto-repeat begins
const DAS_REPEAT := 0.05  # seconds between auto-repeat moves while a move key stays held
const SOFT_DROP_INTERVAL := 0.05  # seconds between soft-drop steps while the key stays held
const GAME_OVER_INPUT_DELAY := 0.6  # seconds the game-over buttons stay disabled so a late hard-drop press cannot restart

# -- Scoring --
const LINE_SCORES: Array[int] = [40, 100, 300, 1200]  # base points for 1..4 simultaneous clears, times (level + 1)
const SOFT_DROP_POINTS := 1  # points per cell soft-dropped
const HARD_DROP_POINTS := 2  # points per cell hard-dropped
const LINES_PER_LEVEL := 10  # cleared lines required to advance one level
const STARTING_LEVEL := 0  # level a new game begins at

# -- Persistence --
const HIGH_SCORE_PATH := "user://high_score.cfg"  # ConfigFile holding the persistent local high score
const HIGH_SCORE_SECTION := "scores"  # ConfigFile section name
const HIGH_SCORE_KEY := "high_score"  # ConfigFile key name

# -- Scenes --
const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"  # entry scene
const GAME_SCENE := "res://scenes/game.tscn"  # gameplay scene

# -- Input actions --
const ACTION_MOVE_LEFT := "move_left"  # InputMap action names shared by the game scene and the control guide
const ACTION_MOVE_RIGHT := "move_right"
const ACTION_SOFT_DROP := "soft_drop"
const ACTION_HARD_DROP := "hard_drop"
const ACTION_ROTATE_CW := "rotate_cw"
const ACTION_ROTATE_CCW := "rotate_ccw"
const ACTION_PAUSE := "pause"

# -- Rendering: blocks --
const CELL_SIZE := 32  # pixels per playfield cell
const CELL_INSET := 2  # pixels shaved from each cell edge so blocks read as separate tiles
const CELL_BEVEL_SIZE := 3  # pixels of highlight/shadow edge on each block
const CELL_BEVEL_LIGHTEN := 0.35  # Color.lightened amount for the top-left bevel, 0..1
const CELL_BEVEL_DARKEN := 0.35  # Color.darkened amount for the bottom-right bevel, 0..1
const GHOST_ENABLED := true  # draw the landing preview of the active piece
const GHOST_ALPHA := 0.25  # opacity of the ghost piece, 0..1
const GHOST_OUTLINE_WIDTH := 2.0  # pixels, stroke of the ghost outline
const GRID_LINE_COLOR := Color(1.0, 1.0, 1.0, 0.05)  # playfield grid lines
const BOARD_BG_COLOR := Color("#0b0c14")  # playfield background
const PIECE_COLORS: Array[Color] = [  # indexed by Tetromino.Type: I, O, T, S, Z, J, L
	Color("#3fd8f0"),
	Color("#f7d33d"),
	Color("#b465f5"),
	Color("#5be36a"),
	Color("#f2554f"),
	Color("#4f7bf2"),
	Color("#f59a3c"),
]
const PREVIEW_BOX := 4  # cells per side of the next-piece preview box

# -- UI --
const WINDOW_SIZE := Vector2i(960, 720)  # viewport size in pixels
const BG_COLOR := Color("#12131c")  # scene background
const PANEL_COLOR := Color("#1a1c2a")  # panel fill
const PANEL_BORDER_COLOR := Color("#2f3247")  # panel 1px border
const PANEL_BORDER_WIDTH := 1  # pixels
const PANEL_CORNER_RADIUS := 8  # pixels
const PANEL_MARGIN := 16  # pixels of inner padding on panels
const TEXT_COLOR := Color("#e8e9f0")  # primary text
const MUTED_TEXT_COLOR := Color("#8a8fa8")  # secondary text and headings
const ACCENT_COLOR := Color("#f7c948")  # highlights such as the new-record banner
const TITLE_FONT_SIZE := 84  # pixels, main menu title letters
const HEADING_FONT_SIZE := 30  # pixels, overlay headings
const BODY_FONT_SIZE := 20  # pixels, buttons and values
const SMALL_FONT_SIZE := 14  # pixels, HUD captions and hints
const KEYCAP_FONT_SIZE := 14  # pixels, key labels in the control guide
const KEYCAP_MIN_WIDTH := 34  # pixels, so single-letter keys stay square-ish
const KEYCAP_CORNER_RADIUS := 5  # pixels
const KEYCAP_PADDING := Vector2i(8, 3)  # pixels of horizontal (x) and vertical (y) content margin
const KEYCAP_BG_COLOR := Color("#262a3d")  # keycap fill
const KEYCAP_BORDER_COLOR := Color("#4a5070")  # keycap 1px border
const KEYCAP_SPACING := 6  # pixels between keycaps in one row
const MENU_SPACING := 14  # pixels between stacked menu items
const MENU_BUTTON_MIN_SIZE := Vector2i(220, 44)  # pixels
const HUD_SPACING := 10  # pixels between HUD rows
const SCENE_GAP := 32  # pixels between the playfield and the side panel
const BOARD_FRAME_MARGIN := 8  # pixels of padding around the playfield inside its frame
const SIDE_PANEL_WIDTH := 200  # pixels, fixed so HUD numbers never shift the layout
const OVERLAY_COLOR := Color(0.0, 0.0, 0.0, 0.72)  # dim behind pause and game-over panels
const SCORE_DIGITS := 6  # zero-padded width of displayed scores
