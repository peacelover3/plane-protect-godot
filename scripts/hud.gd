extends Control
## Mobile-game HUD: a hearts pill, a big score card, a timer and a boss bar.

signal pause_pressed
signal home_requested

var arena: GameArena = null

var _hearts: Array[TextureRect] = []
var _score_card: PanelContainer
var _score_label: Label
var _target_label: Label
var _mode_label: Label
var _progress: ProgressBar
var _timer_label: Label
var _timer_caption: Label
var _boss_card: PanelContainer
var _boss_bar: ProgressBar
var _banner: Label
var _hint: PanelContainer
var _hint_label: Label
var _hint_time := 0.0
var _banner_tween: Tween = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


func bind(game: GameArena) -> void:
	arena = game


func _build() -> void:
	_build_hearts()
	_build_home_button()
	_build_score()
	_build_timer()
	_build_boss()
	_build_banner()
	_build_hint()


func _panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", UIKit.game_panel_box())
	return panel


func _build_hearts() -> void:
	var card := _panel()
	card.set_anchors_preset(Control.PRESET_TOP_LEFT)
	card.offset_left = 20
	card.offset_top = 16
	add_child(card)
	var row := UIKit.hbox(5)
	card.add_child(row)
	for i in 3:
		var icon := UIKit.plane_icon(25, UIKit.GOLD)
		row.add_child(icon)
		_hearts.append(icon)


func _build_home_button() -> void:
	var home_button := UIKit.button("BACK TO HOME", 12, "secondary")
	home_button.custom_minimum_size = Vector2(180, 48)
	home_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	home_button.offset_left = 20
	home_button.offset_top = 78
	home_button.pressed.connect(func() -> void: home_requested.emit())
	add_child(home_button)


func _build_score() -> void:
	_score_card = _panel()
	_score_card.custom_minimum_size = Vector2(350, 0)
	_score_card.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_score_card.offset_left = -175
	_score_card.offset_right = 175
	_score_card.offset_top = 16
	add_child(_score_card)

	var column := UIKit.vbox(4)
	_score_card.add_child(column)
	_mode_label = UIKit.label("", 10, Color(UIKit.PAPER, 0.65), HORIZONTAL_ALIGNMENT_CENTER)
	_mode_label.add_theme_font_override("font", UIKit.font_bold())
	column.add_child(_mode_label)

	var row := UIKit.hbox(8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_score_label = UIKit.label("0", 31, UIKit.PAPER, HORIZONTAL_ALIGNMENT_RIGHT)
	_score_label.add_theme_font_override("font", UIKit.font_display())
	row.add_child(_score_label)
	_target_label = UIKit.label("/ 0", 13, Color(UIKit.PAPER, 0.6))
	_target_label.size_flags_vertical = Control.SIZE_SHRINK_END
	row.add_child(_target_label)
	column.add_child(row)

	_progress = UIKit.progress()
	_progress.custom_minimum_size = Vector2(310, 10)
	column.add_child(_progress)


func _build_timer() -> void:
	var card := _panel()
	card.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	card.offset_left = -212
	card.offset_right = -20
	card.offset_top = 16
	add_child(card)

	var row := UIKit.hbox(10)
	card.add_child(row)
	var timer_box := UIKit.vbox(0)
	timer_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_timer_label = UIKit.label("1:00", 22, UIKit.PAPER, HORIZONTAL_ALIGNMENT_RIGHT)
	_timer_label.add_theme_font_override("font", UIKit.font_display())
	_timer_label.custom_minimum_size = Vector2(72, 0)
	timer_box.add_child(_timer_label)
	_timer_caption = UIKit.label("TIME", 9, Color(UIKit.PAPER, 0.6), HORIZONTAL_ALIGNMENT_RIGHT)
	_timer_caption.add_theme_font_override("font", UIKit.font_bold())
	timer_box.add_child(_timer_caption)
	row.add_child(timer_box)

	var pause_button := UIKit.button("II", 14, "primary")
	pause_button.custom_minimum_size = Vector2(50, 50)
	pause_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pause_button.pressed.connect(func() -> void: pause_pressed.emit())
	row.add_child(pause_button)


func _build_boss() -> void:
	_boss_card = _panel()
	_boss_card.custom_minimum_size = Vector2(380, 0)
	_boss_card.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_boss_card.offset_left = -190
	_boss_card.offset_right = 190
	_boss_card.offset_top = 16
	_boss_card.visible = false
	add_child(_boss_card)

	var column := UIKit.vbox(5)
	_boss_card.add_child(column)
	var name := UIKit.label("KING OF MATHLAND", 11, UIKit.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	name.add_theme_font_override("font", UIKit.font_bold())
	column.add_child(name)
	_boss_bar = UIKit.progress()
	_boss_bar.custom_minimum_size = Vector2(340, 12)
	var fill := StyleBoxFlat.new()
	fill.bg_color = UIKit.CORAL
	fill.set_corner_radius_all(6)
	_boss_bar.add_theme_stylebox_override("fill", fill)
	column.add_child(_boss_bar)


func _build_banner() -> void:
	_banner = UIKit.title("", 34, UIKit.GOLD)
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner.offset_left = -420
	_banner.offset_right = 420
	_banner.offset_top = 102
	_banner.modulate.a = 0.0
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_banner)


func _build_hint() -> void:
	_hint = PanelContainer.new()
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.add_theme_stylebox_override("panel", UIKit.pill_box(Color(UIKit.PAPER, 0.92)))
	_hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.offset_left = -300
	_hint.offset_right = 300
	_hint.offset_top = -76
	_hint.offset_bottom = -42
	_hint.visible = false
	add_child(_hint)

	_hint_label = UIKit.label("", 11, UIKit.INK, HORIZONTAL_ALIGNMENT_CENTER)
	_hint_label.add_theme_font_override("font", UIKit.font_bold())
	_hint.add_child(_hint_label)


func show_banner(text: String, color: Color) -> void:
	if _banner == null:
		return
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	_banner.modulate.a = 1.0
	if _banner_tween != null and _banner_tween.is_valid():
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.tween_interval(1.8)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.45)


func show_hint(text: String, seconds: float = 4.0) -> void:
	_hint_label.text = text.to_upper()
	_hint.visible = true
	_hint.modulate.a = 1.0
	_hint_time = seconds


func clear_hint() -> void:
	_hint_time = 0.0
	_hint.visible = false


func _process(delta: float) -> void:
	if arena == null:
		return

	for i in _hearts.size():
		var filled := i < arena.hearts
		_hearts[i].modulate = UIKit.GOLD if filled else Color(UIKit.PAPER, 0.16)

	var boss_mode := arena.boss_fighting
	var endless := arena.mode == GameArena.MODE_ENDLESS
	_boss_card.visible = boss_mode
	_score_card.visible = not boss_mode

	if boss_mode:
		_boss_bar.value = arena.boss.health_fraction() * 100.0 if arena.boss != null and is_instance_valid(arena.boss) else 0.0
		_timer_label.text = "—"
		_timer_caption.text = "BOSS"
		_timer_label.add_theme_color_override("font_color", UIKit.PAPER)
	elif endless:
		_mode_label.text = "FREE FOR ALL"
		_score_label.text = str(arena.score)
		_target_label.visible = false
		_progress.visible = false
		_timer_label.text = _format_time(arena.time_left)
		_timer_caption.text = "SURVIVED"
		_timer_label.add_theme_color_override("font_color", UIKit.PAPER)
	else:
		_mode_label.text = "LEVEL %d" % arena.level_number
		_score_label.text = str(arena.score)
		_target_label.visible = true
		_target_label.text = "/ %d" % arena.target_score
		_progress.visible = true
		var fraction := 0.0
		if arena.target_score > 0:
			fraction = clampf(float(arena.score) / float(arena.target_score), 0.0, 1.0)
		_progress.value = fraction * 100.0
		_timer_label.text = _format_time(arena.time_left)
		_timer_caption.text = "TIME"
		_timer_label.add_theme_color_override("font_color", UIKit.CORAL if arena.time_left <= 10.0 else UIKit.PAPER)

	if _hint_time > 0.0:
		_hint_time -= delta
		if _hint_time < 0.6:
			_hint.modulate.a = clampf(_hint_time / 0.6, 0.0, 1.0)
		if _hint_time <= 0.0:
			_hint.visible = false


func _format_time(seconds: float) -> String:
	var total := int(ceil(seconds))
	return "%d:%02d" % [total / 60, total % 60]
