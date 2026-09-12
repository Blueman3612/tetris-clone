# Tetris (Godot 4.8, GDScript)

Classic Tetris clone: main menu with control guide, SRS pieces with wall kicks, 7-bag randomizer,
NES gravity and scoring, persistent local high score. Load the `godot` skill for any work here.

## Layout

- `scripts/autoload/` — autoload singletons, in load order:
  `game_config.gd` (every tunable; consts, grouped by `# -- Section --`),
  `event_bus.gd` (cross-cutting signals), `high_score_manager.gd` (ConfigFile persistence at `user://high_score.cfg`).
- `scripts/core/` — pure rules, no nodes: `tetromino.gd` (SRS shape + kick tables; rule data, not tunables),
  `piece.gd`, `board.gd` (grid, collision, line clears), `piece_bag.gd` (seedable 7-bag), `scoring.gd`, `tetris_game.gd` (orchestrator, local signals).
- `scripts/ui/` — scene scripts: `main_menu.gd`, `game_scene.gd` (input, DAS, gravity timer, HUD, relays to EventBus),
  `board_view.gd`, `preview_view.gd`, `block_painter.gd`.
- `scenes/` — `main_menu.tscn`, `game.tscn`. Generated, never hand-edited (see below).
- `tools/build_scenes.gd` — engine-side builder for project settings and scenes. `tools/test.sh` — headless test runner.
- `test/unit/`, `test/integration/` — GdUnit4 suites. `docs/` — README screenshot, `.gdignore`d so Godot never imports it.
- `runs/` — autonomous run logs, gitignored and local only.

## Scenes are generated

`.tscn` files are produced by the engine, not edited as text. To change scene structure, edit
`tools/build_scenes.gd` and rebuild:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s tools/build_scenes.gd -- scenes && /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --import
```

Project settings (autoloads, input map, main scene, window size) come from the `settings` phase of the same script.
Dynamic UI (title letters, control-guide keycaps) is built at runtime from `GameConfig` and the `InputMap`.

## Conventions specific to this project

- Nodes referenced from scripts use unique names (`%Name`); the builder sets `unique_name_in_owner`.
- `TetrisGame` emits local signals; `game_scene.gd` relays to `EventBus`. `HighScoreManager` listens to `EventBus.game_over`.
- Tests that touch persistence set `HighScoreManager.save_path` (or a fresh manager instance) to a `create_temp_dir()` path.
- Locking is classic: gravity or soft drop failing to move the piece locks it. No hold piece. Ghost piece on.
- Gameplay keys are consumed in `_input` (marked handled) so arrows never drive GUI focus mid-game; while paused
  or after game over they fall through to the overlay buttons. GdUnit4's scene runner also calls
  `_unhandled_input` directly, which would double-apply input; do not move key handling back there.
- Game-over buttons stay disabled for `GameConfig.GAME_OVER_INPUT_DELAY` so a late Space (hard drop and
  `ui_accept`) cannot restart the round.

## Testing

```bash
tools/test.sh
```

Equivalent to `godot --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a test` with
`GODOT_BIN` defaulting to the macOS app bundle. Reports land in `reports/` (gitignored).
Integration suite drives the real scenes through the GdUnit4 scene runner.

## Screenshots

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path . -s tools/capture_screens.gd -- /tmp/tetris-screens
```

Opens a real window briefly and writes `main_menu.png`, `game.png`, `game_over.png`. Redirects the high-score
save to the output dir so the staged game over never touches the real save.

## Run

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path .
```
