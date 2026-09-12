extends Control
## Main menu: piece-colored title, persistent high score, Play/Quit, and a control guide
## generated from the live InputMap so it always matches the real bindings.

const TITLE_TEXT := "TETRIS"
const _KEY_DISPLAY_NAMES := {"Left": "←", "Right": "→", "Up": "↑", "Down": "↓", "Escape": "Esc"}

@onready var _title_box: HBoxContainer = %TitleBox
@onready var _high_score_label: Label = %HighScoreLabel
@onready var _play_button: Button = %PlayButton
@onready var _quit_button: Button = %QuitButton
@onready var _controls_grid: GridContainer = %ControlsGrid


func _ready() -> void:
	_build_title()
	_high_score_label.text = "HIGH SCORE  %s" % str(HighScoreManager.get_high_score()).pad_zeros(GameConfig.SCORE_DIGITS)
	_build_control_guide()
	_play_button.pressed.connect(_on_play_button_pressed)
	_quit_button.pressed.connect(_on_quit_button_pressed)
	_play_button.grab_focus()


func _build_title() -> void:
	for i in TITLE_TEXT.length():
		var letter := Label.new()
		letter.text = TITLE_TEXT[i]
		letter.add_theme_font_size_override("font_size", GameConfig.TITLE_FONT_SIZE)
		letter.add_theme_color_override("font_color", GameConfig.PIECE_COLORS[i % GameConfig.PIECE_COLORS.size()])
		_title_box.add_child(letter)


func _build_control_guide() -> void:
	var rows := [
		["Move", [GameConfig.ACTION_MOVE_LEFT, GameConfig.ACTION_MOVE_RIGHT]],
		["Rotate", [GameConfig.ACTION_ROTATE_CW]],
		["Rotate back", [GameConfig.ACTION_ROTATE_CCW]],
		["Soft drop", [GameConfig.ACTION_SOFT_DROP]],
		["Hard drop", [GameConfig.ACTION_HARD_DROP]],
		["Pause", [GameConfig.ACTION_PAUSE]],
	]
	for row in rows:
		var keys := HBoxContainer.new()
		keys.add_theme_constant_override("separation", GameConfig.KEYCAP_SPACING)
		for action in row[1]:
			for key_name in _key_names_for_action(action):
				keys.add_child(_make_keycap(key_name))
		_controls_grid.add_child(keys)
		var description := Label.new()
		description.text = row[0]
		description.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		description.add_theme_font_size_override("font_size", GameConfig.SMALL_FONT_SIZE)
		description.add_theme_color_override("font_color", GameConfig.MUTED_TEXT_COLOR)
		_controls_grid.add_child(description)


func _key_names_for_action(action: String) -> Array[String]:
	var names: Array[String] = []
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key: InputEventKey = event
			var keycode := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
			var key_name := OS.get_keycode_string(keycode)
			names.append(_KEY_DISPLAY_NAMES.get(key_name, key_name))
	return names


func _make_keycap(text: String) -> Label:
	var cap := Label.new()
	cap.text = text
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cap.custom_minimum_size = Vector2(GameConfig.KEYCAP_MIN_WIDTH, 0.0)
	cap.add_theme_font_size_override("font_size", GameConfig.KEYCAP_FONT_SIZE)
	cap.add_theme_color_override("font_color", GameConfig.TEXT_COLOR)
	var style := StyleBoxFlat.new()
	style.bg_color = GameConfig.KEYCAP_BG_COLOR
	style.border_color = GameConfig.KEYCAP_BORDER_COLOR
	style.set_border_width_all(GameConfig.PANEL_BORDER_WIDTH)
	style.set_corner_radius_all(GameConfig.KEYCAP_CORNER_RADIUS)
	style.content_margin_left = GameConfig.KEYCAP_PADDING.x
	style.content_margin_right = GameConfig.KEYCAP_PADDING.x
	style.content_margin_top = GameConfig.KEYCAP_PADDING.y
	style.content_margin_bottom = GameConfig.KEYCAP_PADDING.y
	cap.add_theme_stylebox_override("normal", style)
	return cap


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file(GameConfig.GAME_SCENE)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
