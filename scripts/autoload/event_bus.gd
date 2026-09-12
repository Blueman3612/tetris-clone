extends Node
## Cross-cutting signals. Emitted by the game scene, consumed by the HUD and managers.

signal game_started
signal score_changed(score: int)
signal level_changed(level: int)
signal lines_changed(lines: int)
signal lines_cleared(count: int)
signal piece_locked
signal game_over(score: int)
signal game_paused(paused: bool)
signal high_score_changed(score: int)
