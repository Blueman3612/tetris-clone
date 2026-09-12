extends Node
## Persists the local high score in a ConfigFile and records it on game over.
## save_path is overridable so tests can point it at a scratch file.

var save_path: String = GameConfig.HIGH_SCORE_PATH

var _high_score: int = 0


func _ready() -> void:
	load_high_score()
	EventBus.game_over.connect(_on_event_bus_game_over)


func get_high_score() -> int:
	return _high_score


## Records score if it beats the stored high score. Returns true when a new record was saved.
func submit_score(score: int) -> bool:
	if score <= _high_score:
		return false
	_high_score = score
	save_high_score()
	EventBus.high_score_changed.emit(_high_score)
	return true


## Reads the high score from save_path. Missing or corrupt files load as 0.
func load_high_score() -> void:
	_high_score = 0
	var config := ConfigFile.new()
	if config.load(save_path) != OK:
		return
	var value: Variant = config.get_value(GameConfig.HIGH_SCORE_SECTION, GameConfig.HIGH_SCORE_KEY, 0)
	if value is int or value is float:
		_high_score = maxi(int(value), 0)


func save_high_score() -> void:
	var config := ConfigFile.new()
	config.set_value(GameConfig.HIGH_SCORE_SECTION, GameConfig.HIGH_SCORE_KEY, _high_score)
	var err := config.save(save_path)
	if err != OK:
		push_warning("HighScoreManager: could not save %s (error %d)" % [save_path, err])


## Clears the in-memory value and removes the save file. Used by tests.
func clear_saved() -> void:
	_high_score = 0
	var absolute := ProjectSettings.globalize_path(save_path)
	if FileAccess.file_exists(absolute):
		DirAccess.remove_absolute(absolute)


func _on_event_bus_game_over(score: int) -> void:
	submit_score(score)
