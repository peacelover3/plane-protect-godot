extends Node
## Application shell: mobile menu, settings, record notes, boss and Free For All.

const GameArenaScript := preload("res://scripts/game.gd")
const HudScript := preload("res://scripts/hud.gd")
const JoystickScript := preload("res://scripts/joystick.gd")
const UIRootScript := preload("res://scripts/ui_root.gd")

var arena: GameArena
var hud: Control
var joystick: Control
var ui_root: Control

var screens: Array[Control] = []
var menu_screen: Control
var note_screen: Control
var settings_screen: Control
var pause_screen: Control
var result_screen: Control
var boss_intro_screen: Control
var ending_screen: Control

var _menu_level_label: Label
var _menu_best_label: Label
var _menu_play_button: Button
var _menu_secondary_button: Button
var _menu_stars: Array[Label] = []
var _menu_plane: TextureRect
var _menu_time := 0.0

var _settings_from: Control = null
var _difficulty_row: HBoxContainer
var _sound_button: Button
var _reset_button: Button
var _reset_armed := false

var _pause_level_label: Label
var _pause_restart_button: Button

var _note_eyebrow: Label
var _note_text: Label
var _note_continue: Button
var _note_next: Callable

var _result_box: VBoxContainer
var _last_result: Dictionary = {}

var _ending_form: VBoxContainer
var _ending_area: TextEdit
var _ending_status: Label
var _ending_send: Button


func _ready() -> void:
	arena = GameArenaScript.new()
	arena.name = "Arena"
	add_child(arena)
	arena.run_finished.connect(_on_run_finished)

	var layer := CanvasLayer.new()
	layer.name = "UI"
	add_child(layer)

	ui_root = UIRootScript.new()
	ui_root.name = "UIRoot"
	ui_root.theme = UIKit.make_theme()
	UIKit.full_rect(ui_root)
	ui_root.back_requested.connect(_on_back_requested)
	layer.add_child(ui_root)

	hud = HudScript.new()
	hud.name = "HUD"
	UIKit.full_rect(hud)
	hud.bind(arena)
	hud.visible = false
	hud.pause_pressed.connect(_on_pause_pressed)
	hud.home_requested.connect(_go_menu)
	ui_root.add_child(hud)
	arena.banner.connect(func(text: String, color: Color) -> void: hud.show_banner(text, color))

	joystick = JoystickScript.new()
	joystick.name = "Joystick"
	joystick.anchor_left = 0.0
	joystick.anchor_top = 0.28
	joystick.anchor_right = 0.68
	joystick.anchor_bottom = 1.0
	joystick.offset_left = 0
	joystick.offset_top = 0
	joystick.offset_right = 0
	joystick.offset_bottom = 0
	joystick.visible = false
	joystick.direction_changed.connect(func(direction: Vector2) -> void: arena.set_input_vector(direction))
	ui_root.add_child(joystick)

	Discord.status_changed.connect(_on_discord_status)

	_build_menu()
	_build_note()
	_build_settings()
	_build_pause()
	_build_result()
	_build_boss_intro()
	_build_ending()

	_refresh_menu()
	_show_screen(menu_screen)


func _process(delta: float) -> void:
	_menu_time += delta
	if _menu_plane != null and is_instance_valid(_menu_plane):
		_menu_plane.rotation = -0.14 + sin(_menu_time * 1.6) * 0.04


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if arena != null and arena.running and not get_tree().paused:
			_on_pause_pressed()


# --- Screen plumbing --------------------------------------------------------

func _make_screen() -> Control:
	var screen := Control.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_STOP
	screen.visible = false
	ui_root.add_child(screen)
	screens.append(screen)
	return screen


func _show_screen(target: Control) -> void:
	for screen in screens:
		screen.visible = screen == target


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


# --- Menu -------------------------------------------------------------------

func _build_menu() -> void:
	menu_screen = _make_screen()
	UIKit.dusk_backdrop(menu_screen)

	var margin := MarginContainer.new()
	UIKit.full_rect(margin)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_bottom", 24)
	menu_screen.add_child(margin)

	var layout := UIKit.vbox(0)
	margin.add_child(layout)

	var top := UIKit.hbox(12)
	var level_pill := PanelContainer.new()
	level_pill.add_theme_stylebox_override("panel", UIKit.pill_box())
	level_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_level_label = UIKit.label("LEVEL 1 / 4", 13, UIKit.INK)
	level_pill.add_child(_menu_level_label)
	top.add_child(level_pill)
	var top_grow := Control.new()
	top_grow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_grow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(top_grow)
	var settings_button := UIKit.button("SETTINGS", 13, "secondary")
	settings_button.custom_minimum_size = Vector2(148, 46)
	settings_button.pressed.connect(func() -> void: _open_settings(menu_screen))
	top.add_child(settings_button)
	layout.add_child(top)

	var top_space := Control.new()
	top_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(top_space)

	var center := UIKit.vbox(12)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(UIKit.title("SKY WARDEN", 78))
	center.add_child(UIKit.small("PROTECT THE BEACON", Color(UIKit.PAPER, 0.88)))
	center.add_child(UIKit.small("MADE FOR ARIBA", UIKit.GOLD_LIGHT))

	_menu_plane = TextureRect.new()
	_menu_plane.texture = load("res://assets/art/plane.svg")
	_menu_plane.custom_minimum_size = Vector2(120, 120)
	_menu_plane.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_menu_plane.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_menu_plane.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_menu_plane.pivot_offset = Vector2(60, 60)
	center.add_child(_menu_plane)

	_menu_play_button = UIKit.button("PLAY LEVEL 1", 28, "primary")
	_menu_play_button.custom_minimum_size = Vector2(460, 86)
	_menu_play_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_menu_play_button.pressed.connect(_on_primary_pressed)
	center.add_child(_menu_play_button)

	_menu_secondary_button = UIKit.button("REPLAY LEVEL 4", 16, "secondary")
	_menu_secondary_button.custom_minimum_size = Vector2(460, 58)
	_menu_secondary_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_menu_secondary_button.pressed.connect(_on_secondary_pressed)
	center.add_child(_menu_secondary_button)

	var stars := UIKit.hbox(6)
	stars.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in GameState.MAX_LEVEL:
		var star := UIKit.label("★", 28, Color(UIKit.PAPER, 0.30), HORIZONTAL_ALIGNMENT_CENTER)
		stars.add_child(star)
		_menu_stars.append(star)
	center.add_child(stars)

	_menu_best_label = UIKit.label("", 12, Color(UIKit.PAPER, 0.75), HORIZONTAL_ALIGNMENT_CENTER)
	center.add_child(_menu_best_label)
	layout.add_child(center)

	var bottom_space := Control.new()
	bottom_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bottom_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(bottom_space)


func _refresh_menu() -> void:
	var cleared := GameState.cleared_count()
	for i in _menu_stars.size():
		var filled := i < cleared
		_menu_stars[i].add_theme_color_override("font_color", UIKit.GOLD if filled else Color(UIKit.PAPER, 0.30))
		_menu_stars[i].add_theme_constant_override("outline_size", 4 if filled else 0)
		_menu_stars[i].add_theme_color_override("font_outline_color", UIKit.INK)

	_menu_level_label.text = "FREE FOR ALL" if GameState.boss_defeated else "LEVEL %d / %d" % [GameState.next_level(), GameState.MAX_LEVEL]

	if GameState.boss_unlocked and not GameState.boss_defeated:
		_menu_play_button.text = "FIGHT THE KING"
		_menu_secondary_button.visible = true
		_menu_secondary_button.text = "REPLAY LEVEL 4"
	elif GameState.boss_defeated:
		_menu_play_button.text = "FREE FOR ALL"
		_menu_secondary_button.visible = true
		_menu_secondary_button.text = "REMATCH THE KING"
	else:
		_menu_play_button.text = "PLAY LEVEL %d" % GameState.next_level()
		_menu_secondary_button.visible = false

	if GameState.boss_defeated:
		_menu_best_label.text = ("BEST %d" % GameState.endless_best) if GameState.endless_best > 0 else ""
	elif GameState.boss_unlocked:
		_menu_best_label.text = "THE KING IS ANGRY"
	else:
		var best := GameState.record_for(GameState.next_level())
		_menu_best_label.text = ("BEST %d" % best) if best > 0 else ("TARGET %d" % GameState.target_for(GameState.next_level()))


func _on_primary_pressed() -> void:
	if GameState.boss_defeated:
		_start_endless()
	elif GameState.boss_unlocked:
		_show_boss_intro()
	else:
		_start_level(GameState.next_level())


func _on_secondary_pressed() -> void:
	if GameState.boss_defeated:
		_show_boss_intro()
	else:
		_start_level(GameState.MAX_LEVEL)


# --- Settings ---------------------------------------------------------------

func _build_settings() -> void:
	settings_screen = _make_screen()
	var column := UIKit.centered_card(settings_screen, 560)
	column.add_child(UIKit.title("SETTINGS", 42, UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(UIKit.small("DIFFICULTY", UIKit.INK_SOFT))
	_difficulty_row = UIKit.hbox(10)
	column.add_child(_difficulty_row)
	column.add_child(UIKit.spacer(4))

	var sound_row := UIKit.hbox(12)
	var sound_label := UIKit.label("SOUND", 16, UIKit.INK)
	sound_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sound_row.add_child(sound_label)
	_sound_button = UIKit.button("ON", 15, "secondary")
	_sound_button.custom_minimum_size = Vector2(120, 52)
	_sound_button.pressed.connect(_toggle_sound)
	sound_row.add_child(_sound_button)
	column.add_child(sound_row)

	column.add_child(UIKit.spacer(4))
	_reset_button = UIKit.button("RESET ALL DATA", 15, "coral")
	_reset_button.custom_minimum_size = Vector2(0, 56)
	_reset_button.pressed.connect(_on_reset_pressed)
	column.add_child(_reset_button)

	var back := UIKit.button("BACK", 18, "primary")
	back.custom_minimum_size = Vector2(0, 60)
	back.pressed.connect(_close_settings)
	column.add_child(back)


func _open_settings(from: Control) -> void:
	_settings_from = from
	_reset_armed = false
	_refresh_settings()
	_show_screen(settings_screen)


func _close_settings() -> void:
	if _settings_from != null and is_instance_valid(_settings_from):
		_show_screen(_settings_from)
	else:
		_show_screen(menu_screen)
	_refresh_menu()


func _refresh_settings() -> void:
	if _difficulty_row == null:
		return
	_clear_children(_difficulty_row)
	for i in GameState.DIFFICULTY_NAMES.size():
		var kind := "primary" if i == GameState.difficulty else "secondary"
		var button := UIKit.button(GameState.DIFFICULTY_NAMES[i].to_upper(), 14, kind)
		button.custom_minimum_size = Vector2(0, 52)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_difficulty_pressed.bind(i))
		_difficulty_row.add_child(button)
	_sound_button.text = "ON" if not GameState.muted else "OFF"
	_reset_button.text = "TAP AGAIN TO ERASE" if _reset_armed else "RESET ALL DATA"


func _on_difficulty_pressed(value: int) -> void:
	GameState.set_difficulty(value)
	_refresh_settings()
	_refresh_menu()
	Sfx.play("ui")


func _toggle_sound() -> void:
	GameState.muted = not GameState.muted
	GameState.save_progress()
	_refresh_settings()
	if not GameState.muted:
		Sfx.play("ui")


func _on_reset_pressed() -> void:
	if not _reset_armed:
		_reset_armed = true
		_refresh_settings()
		return
	_reset_armed = false
	GameState.reset_progress()
	_refresh_settings()
	_refresh_menu()
	_reset_button.text = "CLEARED"
	Sfx.play("ui")
	await get_tree().create_timer(1.6).timeout
	if is_instance_valid(_reset_button):
		_refresh_settings()


# --- Notes ------------------------------------------------------------------

func _build_note() -> void:
	note_screen = _make_screen()
	UIKit.story_backdrop(note_screen)

	var center := CenterContainer.new()
	UIKit.full_rect(center)
	note_screen.add_child(center)
	var card := UIKit.panel(880)
	center.add_child(card)

	var column := UIKit.vbox(18)
	card.add_child(column)
	_note_eyebrow = UIKit.small("NOTE", UIKit.GOLD_DARK)
	column.add_child(_note_eyebrow)
	_note_text = UIKit.note_text("", 34)
	column.add_child(_note_text)
	_note_continue = UIKit.button("CONTINUE", 20, "primary")
	_note_continue.custom_minimum_size = Vector2(0, 66)
	_note_continue.pressed.connect(_on_note_continue)
	column.add_child(_note_continue)


func _present_note(text: String, label: String, next: Callable) -> void:
	_note_eyebrow.text = label.to_upper()
	_note_text.text = text
	_note_text.add_theme_font_size_override("font_size", 34 if text.length() < 320 else 27)
	_note_next = next
	_show_screen(note_screen)


func _on_note_continue() -> void:
	if not _note_next.is_valid():
		return
	var next := _note_next
	_note_next = Callable()
	next.call()


# --- Playing ----------------------------------------------------------------

func _start_level(level: int) -> void:
	get_tree().paused = false
	arena.start_level(level)
	_hide_screens()
	hud.visible = true
	joystick.visible = true
	joystick.reset()
	hud.show_hint("DRAG TO FLY  ·  BOMBS DROP", 4.0)


func _start_boss() -> void:
	get_tree().paused = false
	arena.start_boss()
	_hide_screens()
	hud.visible = true
	joystick.visible = true
	joystick.reset()
	hud.show_hint("BOMB THE KING  ·  DODGE THE VOLLEYS", 4.0)


func _start_endless() -> void:
	get_tree().paused = false
	arena.start_endless()
	_hide_screens()
	hud.visible = true
	joystick.visible = true
	joystick.reset()
	hud.show_hint("SURVIVE AS LONG AS YOU CAN", 4.0)


func _show_boss_intro() -> void:
	_show_screen(boss_intro_screen)


func _go_menu() -> void:
	get_tree().paused = false
	arena.stop_to_idle()
	hud.visible = false
	joystick.visible = false
	hud.clear_hint()
	_refresh_menu()
	_show_screen(menu_screen)


func _hide_screens() -> void:
	_show_screen(null)


# --- Pause ------------------------------------------------------------------

func _build_pause() -> void:
	pause_screen = _make_screen()
	var column := UIKit.centered_card(pause_screen, 460)
	column.add_child(UIKit.title("PAUSED", 44, UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	_pause_level_label = UIKit.body("", 14, UIKit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	column.add_child(_pause_level_label)

	var resume := UIKit.button("RESUME", 20, "primary")
	resume.pressed.connect(_resume_game)
	column.add_child(resume)

	_pause_restart_button = UIKit.button("RESTART", 16, "secondary")
	_pause_restart_button.pressed.connect(_on_pause_restart)
	column.add_child(_pause_restart_button)

	var settings := UIKit.button("SETTINGS", 16, "secondary")
	settings.pressed.connect(func() -> void: _open_settings(pause_screen))
	column.add_child(settings)

	var quit := UIKit.ghost("BACK TO HOME", 14)
	quit.pressed.connect(_go_menu)
	column.add_child(quit)


func _refresh_pause() -> void:
	_pause_restart_button.text = "RESTART KING" if arena.boss_fighting else "RESTART"
	if arena.mode == GameArena.MODE_ENDLESS:
		_pause_level_label.text = "FREE FOR ALL  ·  %d POINTS" % arena.score
	elif arena.boss_fighting:
		_pause_level_label.text = "THE KING"
	else:
		_pause_level_label.text = "LEVEL %d  ·  %d / %d" % [arena.level_number, arena.score, arena.target_score]


func _on_pause_restart() -> void:
	if arena.boss_fighting:
		_start_boss()
	elif arena.mode == GameArena.MODE_ENDLESS:
		_start_endless()
	else:
		_start_level(arena.level_number)


func _on_pause_pressed() -> void:
	if not arena.running or pause_screen.visible:
		return
	joystick.reset()
	joystick.visible = false
	_refresh_pause()
	get_tree().paused = true
	_show_screen(pause_screen)


func _resume_game() -> void:
	get_tree().paused = false
	_hide_screens()
	if arena.running:
		joystick.visible = true
		hud.visible = true


# --- Results ----------------------------------------------------------------

func _build_result() -> void:
	result_screen = _make_screen()
	_result_box = UIKit.centered_card(result_screen, 560)


func _on_run_finished(result: Dictionary) -> void:
	_last_result = result
	joystick.reset()
	joystick.visible = false
	hud.clear_hint()

	if result.get("is_boss", false) and result.get("won", false):
		await get_tree().create_timer(1.4).timeout
		_present_note(Lore.AFTER_BOSS, "THE LAST NOTE", func() -> void: _show_ending(result))
		return

	var level := int(result.get("level", 1))
	if bool(result.get("won", false)) and not bool(result.get("is_boss", false)) and not bool(result.get("is_endless", false)):
		var note := Lore.level_note(level)
		if note != "":
			_present_note(note, "NOTE %d" % level, func() -> void: _show_result(result))
			return

	_show_result(result)


func _show_result(result: Dictionary) -> void:
	_clear_children(_result_box)
	var won: bool = bool(result.get("won", false))
	var boss_mode: bool = bool(result.get("is_boss", false))
	var endless: bool = bool(result.get("is_endless", false))
	var level: int = int(result.get("level", 1))
	var score: int = int(result.get("score", 0))

	var heading := "SHOT DOWN"
	var color := UIKit.CORAL
	if endless:
		heading = "RUN OVER"
	elif won:
		heading = "LEVEL CLEAR!" if not boss_mode else "KING DOWN!"
		color = UIKit.GOLD

	if not endless:
		var filled := 0
		if won:
			filled = clampi(int(result.get("hearts", 0)), 1, 3)
		_result_box.add_child(UIKit.star_row(filled, 3, 34))

	_result_box.add_child(UIKit.title(heading, 46, color))
	_result_box.add_child(UIKit.title(str(score), 70, UIKit.INK, HORIZONTAL_ALIGNMENT_CENTER, false))
	_result_box.add_child(UIKit.small("POINTS", UIKit.INK_SOFT))

	var best := 0
	if endless:
		best = GameState.endless_best
	elif not boss_mode:
		best = GameState.record_for(level)
	if best > 0:
		_result_box.add_child(UIKit.label("BEST %d" % best, 13, UIKit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER))

	var primary: Button
	if endless:
		primary = UIKit.button("PLAY AGAIN", 20, "primary")
		primary.pressed.connect(_start_endless)
	elif boss_mode:
		primary = UIKit.button("TRY AGAIN", 20, "primary")
		primary.pressed.connect(_start_boss)
	elif won and level < GameState.MAX_LEVEL:
		primary = UIKit.button("NEXT LEVEL", 20, "primary")
		primary.pressed.connect(func() -> void: _start_level(level + 1))
	elif won and level >= GameState.MAX_LEVEL:
		primary = UIKit.button("FIGHT THE KING", 20, "primary")
		primary.pressed.connect(_show_boss_intro)
	else:
		primary = UIKit.button("TRY AGAIN", 20, "primary")
		primary.pressed.connect(func() -> void: _start_level(level))
	_result_box.add_child(primary)

	var menu_button := UIKit.ghost("BACK TO HOME", 13)
	menu_button.pressed.connect(_go_menu)
	_result_box.add_child(menu_button)

	_show_screen(result_screen)


# --- Boss intro -------------------------------------------------------------

func _build_boss_intro() -> void:
	boss_intro_screen = _make_screen()
	var column := UIKit.centered_card(boss_intro_screen, 600)
	column.add_child(UIKit.crown_icon(84))
	column.add_child(UIKit.title("KING OF MATHLAND", 36, UIKit.CORAL))
	column.add_child(UIKit.small("THE FINAL BATTLE", UIKit.INK_SOFT))
	var begin := UIKit.button("FIGHT", 24, "primary")
	begin.pressed.connect(_start_boss)
	column.add_child(begin)
	var not_yet := UIKit.ghost("BACK TO HOME", 13)
	not_yet.pressed.connect(_go_menu)
	column.add_child(not_yet)


# --- Ending -----------------------------------------------------------------

func _build_ending() -> void:
	ending_screen = _make_screen()
	var column := UIKit.centered_card(ending_screen, 640)
	column.add_child(UIKit.crown_icon(64))
	column.add_child(UIKit.title("YOU WIN!", 54, UIKit.GOLD))
	column.add_child(UIKit.small("THE KING IS DOWN", UIKit.INK_SOFT))

	_ending_form = UIKit.vbox(12)
	column.add_child(_ending_form)
	_ending_area = UIKit.text_area("Leave a note for the dev…", 96)
	_ending_form.add_child(_ending_area)

	var send_row := UIKit.hbox(12)
	_ending_status = UIKit.label("", 12, UIKit.INK_SOFT)
	_ending_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ending_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	send_row.add_child(_ending_status)
	_ending_send = UIKit.button("SEND", 16, "primary")
	_ending_send.custom_minimum_size = Vector2(140, 54)
	_ending_send.pressed.connect(_send_ending_note)
	send_row.add_child(_ending_send)
	_ending_form.add_child(send_row)

	var buttons := UIKit.hbox(10)
	var endless_button := UIKit.button("FREE FOR ALL", 14, "secondary")
	endless_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	endless_button.pressed.connect(_start_endless)
	buttons.add_child(endless_button)
	var rematch := UIKit.button("REMATCH", 14, "secondary")
	rematch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rematch.pressed.connect(_start_boss)
	buttons.add_child(rematch)
	column.add_child(buttons)

	var menu_button := UIKit.ghost("BACK TO HOME", 13)
	menu_button.pressed.connect(_go_menu)
	column.add_child(menu_button)


func _show_ending(_result: Dictionary) -> void:
	_ending_form.visible = not GameState.note_sent
	_ending_status.text = ""
	_ending_send.disabled = false
	_ending_send.text = "SEND"
	if not Discord.is_configured():
		_ending_status.text = "Discord is not connected."
	_show_screen(ending_screen)


func _send_ending_note() -> void:
	var message := _ending_area.text.strip_edges()
	if message.length() < 3:
		_ending_status.text = "Write a few words first."
		_ending_status.add_theme_color_override("font_color", UIKit.RED)
		return
	var fields := {
		"After the King": "The King of MathLand defeated",
		"Message": message,
	}
	_ending_status.add_theme_color_override("font_color", UIKit.INK_SOFT)
	if Discord.send_report("Post-boss thoughts", fields):
		_ending_send.disabled = true
		_ending_send.text = "SENDING…"
		_ending_status.text = "Sending…"
	else:
		_ending_status.text = Discord.last_detail
		_ending_status.add_theme_color_override("font_color", UIKit.RED)


func _on_discord_status(state: int, detail: String) -> void:
	if _ending_status == null or not is_instance_valid(_ending_status):
		return
	_ending_status.text = detail
	if state == Discord.Status.SENT:
		_ending_status.add_theme_color_override("font_color", UIKit.SAGE)
		_ending_send.text = "SENT"
		GameState.note_sent = true
		GameState.save_progress()
	elif state == Discord.Status.FAILED:
		_ending_status.add_theme_color_override("font_color", UIKit.RED)
		_ending_send.disabled = false
		_ending_send.text = "SEND"
	else:
		_ending_status.add_theme_color_override("font_color", UIKit.INK_SOFT)


# --- Back handling ----------------------------------------------------------

func _on_back_requested() -> void:
	if settings_screen.visible:
		_close_settings()
	elif note_screen.visible:
		_on_note_continue()
	elif pause_screen.visible:
		_resume_game()
	elif boss_intro_screen.visible:
		_show_screen(menu_screen)
	elif ending_screen.visible:
		_go_menu()
	elif result_screen.visible:
		_go_menu()
	elif arena.running:
		_on_pause_pressed()
