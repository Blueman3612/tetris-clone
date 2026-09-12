extends SceneTree
## Engine-side project builder. Writes project settings through ProjectSettings and produces the
## .tscn files through PackedScene + ResourceSaver, so scene files are engine-serialized, never hand-edited.
##
## Usage (from the project root):
##   Godot --headless --path . -s tools/build_scenes.gd -- settings   # autoloads, input map, main scene
##   Godot --headless --path . -s tools/build_scenes.gd -- scenes     # scenes/main_menu.tscn, scenes/game.tscn
## Run "settings", then --import, then "scenes", then --import again so class and uid caches are current.

const GC := preload("res://scripts/autoload/game_config.gd")

const _AUTOLOADS := [
	["GameConfig", "res://scripts/autoload/game_config.gd"],
	["EventBus", "res://scripts/autoload/event_bus.gd"],
	["HighScoreManager", "res://scripts/autoload/high_score_manager.gd"],
]

const _GDUNIT_PLUGIN := "res://addons/gdUnit4/plugin.cfg"
const _MAIN_MENU_SCRIPT := "res://scripts/ui/main_menu.gd"
const _GAME_SCENE_SCRIPT := "res://scripts/ui/game_scene.gd"
const _BOARD_VIEW_SCRIPT := "res://scripts/ui/board_view.gd"
const _PREVIEW_VIEW_SCRIPT := "res://scripts/ui/preview_view.gd"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var phase := "all" if args.is_empty() else args[0]
	if phase == "settings" or phase == "all":
		_configure_project()
	if phase == "scenes" or phase == "all":
		_build_main_menu()
		_build_game()
	quit()


# -- Project settings --

func _configure_project() -> void:
	ProjectSettings.set_setting("application/run/main_scene", GC.MAIN_MENU_SCENE)
	ProjectSettings.set_setting("display/window/size/viewport_width", GC.WINDOW_SIZE.x)
	ProjectSettings.set_setting("display/window/size/viewport_height", GC.WINDOW_SIZE.y)
	for entry: Array in _AUTOLOADS:
		ProjectSettings.set_setting("autoload/%s" % entry[0], "*%s" % entry[1])
	var actions := {
		GC.ACTION_MOVE_LEFT: [KEY_LEFT, KEY_A],
		GC.ACTION_MOVE_RIGHT: [KEY_RIGHT, KEY_D],
		GC.ACTION_SOFT_DROP: [KEY_DOWN, KEY_S],
		GC.ACTION_HARD_DROP: [KEY_SPACE],
		GC.ACTION_ROTATE_CW: [KEY_UP, KEY_X],
		GC.ACTION_ROTATE_CCW: [KEY_Z],
		GC.ACTION_PAUSE: [KEY_P, KEY_ESCAPE],
	}
	for action: String in actions:
		var events: Array = []
		for key: int in actions[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key as Key
			events.append(event)
		ProjectSettings.set_setting("input/%s" % action, {"deadzone": 0.5, "events": events})
	ProjectSettings.set_setting("editor_plugins/enabled", PackedStringArray([_GDUNIT_PLUGIN]))
	var err := ProjectSettings.save()
	print("[build] project settings saved (error=%d)" % err)


# -- Scenes --

func _build_main_menu() -> void:
	var root := Control.new()
	root.name = "MainMenu"
	root.set_script(load(_MAIN_MENU_SCRIPT))
	_full_rect(root)

	var background := ColorRect.new()
	background.color = GC.BG_COLOR
	_add(root, root, background, "Background")
	_full_rect(background)

	var center := CenterContainer.new()
	_add(root, root, center, "Center")
	_full_rect(center)

	var menu := VBoxContainer.new()
	menu.alignment = BoxContainer.ALIGNMENT_CENTER
	menu.add_theme_constant_override("separation", GC.MENU_SPACING)
	_add(root, center, menu, "Menu")

	var title_box := HBoxContainer.new()
	title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	title_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_add(root, menu, title_box, "TitleBox", true)

	var high_score := _label("HIGH SCORE  000000", GC.BODY_FONT_SIZE, GC.TEXT_COLOR)
	_add(root, menu, high_score, "HighScoreLabel", true)

	_add(root, menu, _button("Play"), "PlayButton", true)
	_add(root, menu, _button("Quit"), "QuitButton", true)

	var controls_panel := _panel(GC.PANEL_MARGIN)
	controls_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_add(root, menu, controls_panel, "ControlsPanel")

	var controls_box := VBoxContainer.new()
	controls_box.add_theme_constant_override("separation", GC.HUD_SPACING)
	_add(root, controls_panel, controls_box, "ControlsBox")

	_add(root, controls_box, _label("CONTROLS", GC.SMALL_FONT_SIZE, GC.MUTED_TEXT_COLOR), "ControlsTitle")

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", GC.PANEL_MARGIN)
	grid.add_theme_constant_override("v_separation", GC.KEYCAP_SPACING)
	_add(root, controls_box, grid, "ControlsGrid", true)

	_save(root, GC.MAIN_MENU_SCENE)


func _build_game() -> void:
	var root := Control.new()
	root.name = "Game"
	root.set_script(load(_GAME_SCENE_SCRIPT))
	_full_rect(root)

	var background := ColorRect.new()
	background.color = GC.BG_COLOR
	_add(root, root, background, "Background")
	_full_rect(background)

	var center := CenterContainer.new()
	_add(root, root, center, "Center")
	_full_rect(center)

	var layout := HBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", GC.SCENE_GAP)
	_add(root, center, layout, "Layout")

	var board_frame := _panel(GC.BOARD_FRAME_MARGIN)
	_add(root, layout, board_frame, "BoardFrame")

	var board_view := Control.new()
	board_view.set_script(load(_BOARD_VIEW_SCRIPT))
	board_view.custom_minimum_size = Vector2(GC.BOARD_SIZE) * GC.CELL_SIZE
	_add(root, board_frame, board_view, "BoardView", true)

	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(GC.SIDE_PANEL_WIDTH, 0.0)
	side.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	side.add_theme_constant_override("separation", GC.HUD_SPACING)
	_add(root, layout, side, "Side")

	_add(root, side, _caption("NEXT"), "NextTitle")
	var preview_frame := _panel(GC.BOARD_FRAME_MARGIN)
	preview_frame.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_add(root, side, preview_frame, "PreviewFrame")
	var preview_view := Control.new()
	preview_view.set_script(load(_PREVIEW_VIEW_SCRIPT))
	preview_view.custom_minimum_size = Vector2.ONE * GC.PREVIEW_BOX * GC.CELL_SIZE
	_add(root, preview_frame, preview_view, "PreviewView", true)

	_add(root, side, _caption("SCORE"), "ScoreTitle")
	_add(root, side, _value("000000"), "ScoreValue", true)
	_add(root, side, _caption("LEVEL"), "LevelTitle")
	_add(root, side, _value("0"), "LevelValue", true)
	_add(root, side, _caption("LINES"), "LinesTitle")
	_add(root, side, _value("0"), "LinesValue", true)
	_add(root, side, _caption("HIGH SCORE"), "HighScoreTitle")
	_add(root, side, _value("000000"), "HighScoreValue", true)
	_add(root, side, _caption("P  pause"), "HintLabel")

	# Pause overlay
	var pause_overlay := _overlay()
	_add(root, root, pause_overlay, "PauseOverlay", true)
	_full_rect(pause_overlay)
	var pause_center := CenterContainer.new()
	_add(root, pause_overlay, pause_center, "PauseCenter")
	_full_rect(pause_center)
	var pause_panel := _panel(GC.PANEL_MARGIN)
	_add(root, pause_center, pause_panel, "PausePanel")
	var pause_box := VBoxContainer.new()
	pause_box.add_theme_constant_override("separation", GC.MENU_SPACING)
	_add(root, pause_panel, pause_box, "PauseBox")
	_add(root, pause_box, _label("PAUSED", GC.HEADING_FONT_SIZE, GC.TEXT_COLOR), "PauseTitle")
	_add(root, pause_box, _button("Resume"), "ResumeButton", true)
	_add(root, pause_box, _button("Main menu"), "PauseMenuButton", true)

	# Game-over overlay
	var over_overlay := _overlay()
	_add(root, root, over_overlay, "GameOverOverlay", true)
	_full_rect(over_overlay)
	var over_center := CenterContainer.new()
	_add(root, over_overlay, over_center, "GameOverCenter")
	_full_rect(over_center)
	var over_panel := _panel(GC.PANEL_MARGIN)
	_add(root, over_center, over_panel, "GameOverPanel")
	var over_box := VBoxContainer.new()
	over_box.add_theme_constant_override("separation", GC.MENU_SPACING)
	_add(root, over_panel, over_box, "GameOverBox")
	_add(root, over_box, _label("GAME OVER", GC.HEADING_FONT_SIZE, GC.TEXT_COLOR), "GameOverTitle")
	_add(root, over_box, _label("SCORE  000000", GC.BODY_FONT_SIZE, GC.TEXT_COLOR), "FinalScoreLabel", true)
	var record := _label("NEW HIGH SCORE", GC.BODY_FONT_SIZE, GC.ACCENT_COLOR)
	record.visible = false
	_add(root, over_box, record, "NewRecordLabel", true)
	_add(root, over_box, _button("Play again"), "RetryButton", true)
	_add(root, over_box, _button("Main menu"), "MenuButton", true)

	var fall_timer := Timer.new()
	fall_timer.one_shot = false
	fall_timer.autostart = false
	_add(root, root, fall_timer, "FallTimer", true)

	_save(root, GC.GAME_SCENE)


# -- Helpers --

func _add(root: Node, parent: Node, node: Node, node_name: String, unique: bool = false) -> Node:
	node.name = node_name
	parent.add_child(node)
	node.owner = root
	if unique:
		node.unique_name_in_owner = true
	return node


func _full_rect(control: Control) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _caption(text: String) -> Label:
	var label := _label(text, GC.SMALL_FONT_SIZE, GC.MUTED_TEXT_COLOR)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return label


func _value(text: String) -> Label:
	var label := _label(text, GC.BODY_FONT_SIZE, GC.TEXT_COLOR)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return label


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(GC.MENU_BUTTON_MIN_SIZE)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", GC.BODY_FONT_SIZE)
	return button


func _panel(margin: int) -> PanelContainer:
	var style := StyleBoxFlat.new()
	style.bg_color = GC.PANEL_COLOR
	style.border_color = GC.PANEL_BORDER_COLOR
	style.set_border_width_all(GC.PANEL_BORDER_WIDTH)
	style.set_corner_radius_all(GC.PANEL_CORNER_RADIUS)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _overlay() -> ColorRect:
	var overlay := ColorRect.new()
	overlay.color = GC.OVERLAY_COLOR
	overlay.visible = false
	return overlay


func _save(root: Node, path: String) -> void:
	var scene := PackedScene.new()
	var pack_err := scene.pack(root)
	if pack_err != OK:
		push_error("[build] pack failed for %s (error=%d)" % [path, pack_err])
	var save_err := ResourceSaver.save(scene, path)
	print("[build] saved %s (error=%d)" % [path, save_err])
	root.free()
