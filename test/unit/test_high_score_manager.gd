extends GdUnitTestSuite
## Persistence of the local high score, exercised on fresh manager instances at a scratch path
## so the real user:// save is never touched.

const ManagerScript := preload("res://scripts/autoload/high_score_manager.gd")

var _path: String


func before_test() -> void:
	_path = create_temp_dir("high_score") + "/high_score.cfg"
	if FileAccess.file_exists(_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_path))


func _manager() -> Node:
	var manager: Node = auto_free(ManagerScript.new())
	manager.save_path = _path
	return manager


func test_missing_file_loads_as_zero() -> void:
	var manager := _manager()
	manager.load_high_score()
	assert_int(manager.get_high_score()).is_zero()


func test_submitted_record_survives_a_fresh_load() -> void:
	var manager := _manager()
	assert_bool(manager.submit_score(1500)).is_true()
	assert_bool(FileAccess.file_exists(_path)).is_true()
	var reloaded := _manager()
	reloaded.load_high_score()
	assert_int(reloaded.get_high_score()).is_equal(1500)


func test_lower_or_equal_scores_do_not_overwrite_the_record() -> void:
	var manager := _manager()
	manager.submit_score(1000)
	assert_bool(manager.submit_score(999)).is_false()
	assert_bool(manager.submit_score(1000)).is_false()
	assert_bool(manager.submit_score(0)).is_false()
	var reloaded := _manager()
	reloaded.load_high_score()
	assert_int(reloaded.get_high_score()).is_equal(1000)


func test_corrupt_or_wrong_typed_files_load_as_zero() -> void:
	var garbage := FileAccess.open(_path, FileAccess.WRITE)
	garbage.store_string("this is not a config file [[[")
	garbage.close()
	var manager := _manager()
	manager.load_high_score()
	assert_int(manager.get_high_score()).is_zero()

	var config := ConfigFile.new()
	config.set_value(GameConfig.HIGH_SCORE_SECTION, GameConfig.HIGH_SCORE_KEY, "not a number")
	config.save(_path)
	manager.load_high_score()
	assert_int(manager.get_high_score()).is_zero()

	config.set_value(GameConfig.HIGH_SCORE_SECTION, GameConfig.HIGH_SCORE_KEY, -50)
	config.save(_path)
	manager.load_high_score()
	assert_int(manager.get_high_score()).is_zero()


func test_high_score_changed_fires_only_for_new_records() -> void:
	var emitted: Array = []
	var listener := func(score: int) -> void: emitted.append(score)
	EventBus.high_score_changed.connect(listener)
	var manager := _manager()
	manager.submit_score(10)
	manager.submit_score(5)
	manager.submit_score(20)
	EventBus.high_score_changed.disconnect(listener)
	assert_array(emitted).contains_exactly([10, 20])


func test_clear_saved_removes_the_file_and_resets() -> void:
	var manager := _manager()
	manager.submit_score(77)
	manager.clear_saved()
	assert_bool(FileAccess.file_exists(_path)).is_false()
	assert_int(manager.get_high_score()).is_zero()
	var reloaded := _manager()
	reloaded.load_high_score()
	assert_int(reloaded.get_high_score()).is_zero()


@warning_ignore("unused_parameter")
func test_stored_value_always_equals_the_running_maximum(fuzzer := Fuzzers.rangei(0, 1_000_000), fuzzer_iterations := 20) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = fuzzer.next_value()
	var manager := _manager()
	var running_max := 0
	for i in 25:
		var score := rng.randi_range(0, 100000)
		var was_record: bool = manager.submit_score(score)
		assert_bool(was_record).is_equal(score > running_max)
		running_max = maxi(running_max, score)
		assert_int(manager.get_high_score()).is_equal(running_max)
	var reloaded := _manager()
	reloaded.load_high_score()
	assert_int(reloaded.get_high_score()).is_equal(running_max)
