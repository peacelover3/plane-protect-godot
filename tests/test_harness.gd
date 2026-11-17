extends Node
## Headless end-to-end check. Run with:
##   godot --headless --fixed-fps 60 res://tests/test_harness.tscn

var _failures: Array[String] = []
var _main: Node


func _ready() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		print("FAIL: ", message)
		_failures.append(message)


func _run() -> void:
	var save_path := "user://sky_warden_save.cfg"
	var had_save := FileAccess.file_exists(save_path)
	var backup := FileAccess.get_file_as_bytes(save_path) if had_save else PackedByteArray()
	GameState.reset_progress()

	var packed: PackedScene = load("res://scenes/main.tscn")
	_main = packed.instantiate()
	add_child(_main)
	await get_tree().process_frame
	await get_tree().process_frame

	var arena = _main.arena
	_check(_main.menu_screen.visible, "menu is visible at boot")
	_check(arena != null, "arena exists")
	_check(load("res://assets/art/plane.svg").get_size().x > 0.0, "SVG art imported as textures")
	_check(GameState.MAX_LEVEL == 4 and GameState.LEVELS.size() == 4, "there are four records")
	_check(load("res://assets/art/crown.svg").get_size().x > 0.0, "crown art imported")

	var menu_layout: Control = _main.menu_screen.get_child(1)
	var menu_min: Vector2 = menu_layout.get_child(0).get_combined_minimum_size()
	print("INFO: menu content min = ", menu_min)
	_check(menu_min.y <= 670.0, "menu content fits the screen")

	# --- Difficulty ---
	GameState.set_difficulty(GameState.Difficulty.EASY)
	var easy_target := GameState.target_for(1)
	GameState.set_difficulty(GameState.Difficulty.HARD)
	var hard_target := GameState.target_for(1)
	_check(easy_target < hard_target, "difficulty changes level targets")
	GameState.set_difficulty(GameState.Difficulty.EASY)
	_check(GameState.boss_hp() == 50, "easy mode lowers the King's health")

	# --- Level 1: fly, bomb, note, result ---
	_main._start_level(1)
	await get_tree().physics_frame
	_check(arena.running, "level 1 starts")
	_check(_main.hud.visible, "HUD is visible while playing")
	_check(arena.hearts == 3, "starts with three planes")
	_check(arena.target_score == easy_target, "level uses the difficulty target")

	arena.set_input_vector(Vector2.RIGHT)
	for i in 24:
		await get_tree().physics_frame
	_check(arena.plane._sprite.rotation > 0.5, "plane turns toward its travel direction")
	arena.set_input_vector(Vector2.ZERO)

	for i in 1800:
		_steer_over_nearest_enemy(arena)
		await get_tree().physics_frame
		if not arena.running:
			break

	if arena.running:
		arena.score = maxi(0, arena.target_score - 10)
		arena._spawn_walker("grunt")
		await get_tree().physics_frame
		var enemy = arena._enemies[arena._enemies.size() - 1]
		enemy.position = Vector2(640, 340)
		arena.plane.position = enemy.position - Vector2(12, 52)
		arena.plane.velocity = Vector2.ZERO
		arena.set_input_vector(Vector2.ZERO)
		for i in 180:
			await get_tree().physics_frame
			if not arena.running:
				break
	_check(not arena.running, "a level finishes")

	await get_tree().process_frame
	_check(_main.note_screen.visible, "clearing a level opens the note page")
	_check(_has_text(_main.note_screen, Lore.level_note(1)), "the level 1 note is shown")
	_main._on_note_continue()
	await get_tree().process_frame
	_check(_main.result_screen.visible, "result follows the note")
	_check(GameState.unlocked_level >= 2, "clearing level 1 unlocks level 2")

	# --- Pause, resume, a fireball hit ---
	_main._start_level(2)
	await get_tree().physics_frame
	_check(arena.running and arena.level_number == 2, "level 2 starts")
	_main._on_pause_pressed()
	await get_tree().process_frame
	_check(get_tree().paused and _main.pause_screen.visible, "pause works")
	_main._resume_game()
	await get_tree().process_frame
	_check(not get_tree().paused, "resume works")

	for i in 85:
		await get_tree().physics_frame
	var hearts_before: int = arena.hearts
	arena._spawn_fireball(arena.plane.position, arena.plane.position, 0.0)
	for i in 10:
		await get_tree().physics_frame
	_check(arena.hearts == hearts_before - 1, "a fireball costs a plane")

	# --- Settings ---
	_main._go_menu()
	await get_tree().process_frame
	_main._open_settings(_main.menu_screen)
	await get_tree().process_frame
	_check(_main.settings_screen.visible, "settings opens")
	_check(_main._difficulty_row.get_child_count() == 3, "settings has three difficulties")
	var silent_before: bool = GameState.muted
	_main._toggle_sound()
	_check(GameState.muted != silent_before, "settings toggles sound")
	_main._toggle_sound()
	_main._on_difficulty_pressed(GameState.Difficulty.NORMAL)
	_check(GameState.difficulty == GameState.Difficulty.NORMAL, "settings changes difficulty")
	_main._close_settings()
	await get_tree().process_frame

	# --- Boss ---
	GameState.set_difficulty(GameState.Difficulty.EASY)
	_main._start_boss()
	await get_tree().physics_frame
	_check(arena.running and arena.boss_fighting, "boss fight starts")
	_check(arena.boss != null and arena.boss.max_hp == 50, "boss uses difficulty health")
	var boss_hp_before: int = arena.boss.hp

	for i in 1900:
		_fly_over_boss(arena)
		await get_tree().physics_frame
		if not arena.running:
			break

	_check(not arena.running, "boss fight reaches a conclusion")
	_check(arena.boss == null or arena.boss.hp < boss_hp_before, "bombs damage the boss")

	if not arena.running:
		for i in 150:
			await get_tree().process_frame
		if GameState.boss_defeated:
			_check(_main.note_screen.visible, "beating the boss opens the last note")
			_check(_has_text(_main.note_screen, Lore.AFTER_BOSS), "after-boss note text is shown")
			_main._on_note_continue()
			await get_tree().process_frame
			_check(_main.ending_screen.visible, "ending follows the last note")
		else:
			_check(_main.result_screen.visible, "boss loss shows the result")

	# --- Free For All ---
	_main._start_endless()
	await get_tree().physics_frame
	_check(arena.running and arena.mode == GameArena.MODE_ENDLESS, "free for all starts")
	_check(arena.target_score == 0, "free for all has no score target")
	for i in 180:
		_fly_over_nearest_enemy(arena)
		await get_tree().physics_frame
	_check(arena.time_left > 0.0, "free for all runs without a timer")
	var endless_score: int = arena.score
	arena.end_run(false, "Test end.")
	await get_tree().process_frame
	_check(_main.result_screen.visible and bool(_main._last_result.get("is_endless", false)), "free for all ends on a result")
	_check(GameState.endless_best >= endless_score, "free for all best is saved")

	# --- Layout ---
	var ending_layout: Vector2 = await _show_and_measure(_main.ending_screen, "ending")
	_check(ending_layout.y <= 720.0 and ending_layout.x <= 1280.0, "ending card fits")
	var settings_layout: Vector2 = await _show_and_measure(_main.settings_screen, "settings")
	_check(settings_layout.y <= 720.0 and settings_layout.x <= 1280.0, "settings card fits")
	var pause_layout: Vector2 = await _show_and_measure(_main.pause_screen, "pause")
	_check(pause_layout.y <= 720.0 and pause_layout.x <= 1280.0, "pause card fits")
	var boss_layout: Vector2 = await _show_and_measure(_main.boss_intro_screen, "boss intro")
	_check(boss_layout.y <= 720.0 and boss_layout.x <= 1280.0, "boss intro card fits")

	_main._show_result({
		"won": true, "is_boss": false, "is_endless": false, "level": 4,
		"score": 450, "target": 450, "kills": 40, "hearts": 3,
		"time_left": 5.0, "previous_record": 300, "new_record": true,
	})
	await get_tree().process_frame
	var result_layout: Vector2 = await _show_and_measure(_main.result_screen, "result")
	_check(result_layout.y <= 720.0 and result_layout.x <= 1280.0, "result card fits")

	_main._present_note(Lore.AFTER_BOSS, "Test", func() -> void: pass)
	for i in 3:
		await get_tree().process_frame
	print("INFO: long note text size = ", _main._note_text.size)
	_check(_main._note_text.size.y <= 470.0, "longest note fits its page")

	# --- Reset all data ---
	_main._open_settings(_main.menu_screen)
	await get_tree().process_frame
	_main._on_reset_pressed()
	_main._on_reset_pressed()
	await get_tree().process_frame
	_check(GameState.unlocked_level == 1 and GameState.record_for(1) == 0, "reset wipes progress")
	_check(GameState.endless_best == 0, "reset wipes the endless best")
	_check(GameState.difficulty == GameState.Difficulty.NORMAL, "reset restores normal difficulty")

	# --- Persistence ---
	GameState.save_progress()
	GameState.load_progress()
	_check(GameState.unlocked_level == 1, "progress survives a save/load round trip")
	var webhook := Discord.get_webhook_url()
	_check(webhook == "" or webhook.begins_with("https://discord.com/api/webhooks/"), "discord lookup is safe")

	await get_tree().process_frame
	if had_save:
		var file := FileAccess.open(save_path, FileAccess.WRITE)
		if file != null:
			file.store_buffer(backup)
	elif FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))

	print("----")
	if _failures.is_empty():
		print("ALL CHECKS PASSED")
		get_tree().quit(0)
	else:
		print("%d CHECK(S) FAILED" % _failures.size())
		for failure in _failures:
			print("  - ", failure)
		get_tree().quit(1)


func _show_and_measure(screen: Control, label: String) -> Vector2:
	_main._show_screen(screen)
	await get_tree().process_frame
	await get_tree().process_frame
	var card: Control = screen.get_child(1).get_child(0)
	print("INFO: %s card size = %s" % [label, card.size])
	return card.size


func _has_text(node: Node, text: String) -> bool:
	if text != "" and node is Label and (node as Label).text.contains(text):
		return true
	for child in node.get_children():
		if _has_text(child, text):
			return true
	return false


func _steer_over_nearest_enemy(arena) -> void:
	if arena.plane == null or not is_instance_valid(arena.plane):
		return
	var best = null
	var best_distance := INF
	for enemy in arena._enemies:
		if not is_instance_valid(enemy) or not enemy.alive or enemy.is_turret:
			continue
		var distance: float = enemy.position.distance_to(arena.plane.position)
		if distance < best_distance:
			best_distance = distance
			best = enemy
	if best == null:
		arena.set_input_vector(Vector2.ZERO)
		return
	var target: Vector2 = best.position - Vector2(12, 52)
	var to_target: Vector2 = target - arena.plane.position
	arena.set_input_vector(to_target.normalized() if to_target.length() > 14.0 else Vector2.ZERO)


func _fly_over_boss(arena) -> void:
	if arena.boss == null or not is_instance_valid(arena.boss) or arena.plane == null:
		return
	var target: Vector2 = arena.boss.position - Vector2(12, 52)
	var to_target: Vector2 = target - arena.plane.position
	arena.set_input_vector(to_target.normalized() if to_target.length() > 14.0 else Vector2.ZERO)


func _fly_over_nearest_enemy(arena) -> void:
	_steer_over_nearest_enemy(arena)
