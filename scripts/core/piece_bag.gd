class_name PieceBag
extends RefCounted
## 7-bag randomizer: every run of seven pieces contains each tetromino exactly once.
## Seedable for deterministic tests.

var _rng := RandomNumberGenerator.new()
var _queue: Array[int] = []


func _init(seed: int = -1) -> void:
	if seed < 0:
		_rng.randomize()
	else:
		_rng.seed = seed


func next() -> int:
	_ensure_filled()
	return _queue.pop_front()


func peek() -> int:
	_ensure_filled()
	return _queue[0]


func _ensure_filled() -> void:
	if _queue.is_empty():
		_refill()


func _refill() -> void:
	var types: Array[int] = []
	for type in Tetromino.COUNT:
		types.append(type)
	# Fisher-Yates with the local RNG; Array.shuffle would use the global one.
	for i in range(types.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var swap := types[i]
		types[i] = types[j]
		types[j] = swap
	_queue.append_array(types)
