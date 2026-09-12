extends GdUnitTestSuite
## 7-bag randomizer guarantees.


@warning_ignore("unused_parameter")
func test_each_bag_of_seven_contains_every_type_exactly_once(
	fuzzer := Fuzzers.rangei(0, 1_000_000), fuzzer_iterations := 25) -> void:
	var bag := PieceBag.new(fuzzer.next_value())
	for bag_index in 4:
		var counts := {}
		for i in Tetromino.COUNT:
			var type := bag.next()
			counts[type] = counts.get(type, 0) + 1
		assert_int(counts.size()).is_equal(Tetromino.COUNT)
		for type in counts:
			assert_int(counts[type]).is_equal(1)


func test_same_seed_produces_the_same_sequence() -> void:
	var a := PieceBag.new(1234)
	var b := PieceBag.new(1234)
	for i in 21:
		assert_int(a.next()).is_equal(b.next())


func test_peek_does_not_consume() -> void:
	var bag := PieceBag.new(7)
	var peeked := bag.peek()
	assert_int(bag.peek()).is_equal(peeked)
	assert_int(bag.next()).is_equal(peeked)


func test_values_are_valid_types() -> void:
	var bag := PieceBag.new(99)
	for i in 70:
		assert_int(bag.next()).is_between(0, Tetromino.COUNT - 1)
