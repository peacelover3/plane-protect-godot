class_name UIKit
extends RefCounted
## Mobile-game look: deep dusk, warm paper, gold chunky buttons, thick ink
## borders and a heavy display face. Less text, bigger taps.

const INK := Color("1d2947")
const INK_DEEP := Color("131b31")
const INK_SOFT := Color("64708c")
const PAPER := Color("fff7e6")
const PAPER_DEEP := Color("f6e3bf")
const GOLD := Color("ffc94a")
const GOLD_LIGHT := Color("ffdc7a")
const GOLD_DARK := Color("d99c1e")
const CORAL := Color("f26b5b")
const RED := Color("e03e3e")
const TEAL := Color("3fc7b4")
const SAGE := Color("76c27c")
const DUSK_TOP := Color("1b2b52")
const DUSK_BOTTOM := Color("8f4a5e")

# Legacy names.
const CREAM := PAPER
const ORANGE := GOLD
const MUTED := INK_SOFT
const SCREEN_DIM := Color(0.05, 0.07, 0.14, 0.62)
const NAVY := INK
const NIGHT := INK_DEEP
const PANEL := PAPER
const PANEL_EDGE := INK
const FIELD := Color("3c5c47")

static var _font_cache: Dictionary = {}


static func font_regular() -> Font:
	if not _font_cache.has("regular"):
		var font := SystemFont.new()
		font.font_names = PackedStringArray(["Segoe UI", "Roboto", "Noto Sans", "DejaVu Sans", "sans-serif"])
		font.font_weight = 600
		_font_cache["regular"] = font
	return _font_cache["regular"]


static func font_bold() -> Font:
	if not _font_cache.has("bold"):
		var font := SystemFont.new()
		font.font_names = PackedStringArray(["Segoe UI", "Roboto", "Noto Sans", "DejaVu Sans", "sans-serif"])
		font.font_weight = 800
		_font_cache["bold"] = font
	return _font_cache["bold"]


static func font_display() -> Font:
	if not _font_cache.has("display"):
		var font := SystemFont.new()
		font.font_names = PackedStringArray(["Arial Rounded MT Bold", "Segoe UI Black", "Roboto", "Noto Sans", "DejaVu Sans", "sans-serif"])
		font.font_weight = 900
		_font_cache["display"] = font
	return _font_cache["display"]


static func font_serif() -> Font:
	if not _font_cache.has("serif"):
		var font := SystemFont.new()
		font.font_names = PackedStringArray(["Georgia", "Noto Serif", "DejaVu Serif", "serif"])
		font.font_weight = 800
		_font_cache["serif"] = font
	return _font_cache["serif"]


static func font_serif_italic() -> Font:
	if not _font_cache.has("serif_italic"):
		var font := SystemFont.new()
		font.font_names = PackedStringArray(["Georgia", "Noto Serif", "DejaVu Serif", "serif"])
		font.font_weight = 400
		font.font_italic = true
		_font_cache["serif_italic"] = font
	return _font_cache["serif_italic"]


static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = font_regular()
	theme.default_font_size = 17

	theme.set_color("font_color", "Label", INK)

	theme.set_stylebox("normal", "Button", button_box("secondary", false))
	theme.set_stylebox("hover", "Button", button_box("secondary", true))
	theme.set_stylebox("pressed", "Button", button_box("secondary_pressed", false))
	theme.set_stylebox("disabled", "Button", button_box("disabled", false))
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	theme.set_color("font_color", "Button", INK)
	theme.set_color("font_hover_color", "Button", INK)
	theme.set_color("font_pressed_color", "Button", INK)
	theme.set_color("font_disabled_color", "Button", Color(INK, 0.35))
	theme.set_font("font", "Button", font_display())
	theme.set_font_size("font_size", "Button", 18)

	theme.set_stylebox("panel", "PanelContainer", card_box())
	theme.set_stylebox("panel", "Panel", card_box())

	theme.set_stylebox("normal", "LineEdit", input_box(false))
	theme.set_stylebox("focus", "LineEdit", input_box(true))
	theme.set_color("font_color", "LineEdit", INK)
	theme.set_color("font_placeholder_color", "LineEdit", Color(INK_SOFT, 0.7))
	theme.set_color("caret_color", "LineEdit", CORAL)
	theme.set_stylebox("normal", "TextEdit", input_box(false))
	theme.set_stylebox("focus", "TextEdit", input_box(true))
	theme.set_color("font_color", "TextEdit", INK)
	theme.set_color("font_placeholder_color", "TextEdit", Color(INK_SOFT, 0.7))
	theme.set_color("caret_color", "TextEdit", CORAL)

	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(INK, 0.30)
	bar_bg.set_corner_radius_all(6)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = GOLD
	bar_fill.set_corner_radius_all(6)
	theme.set_stylebox("background", "ProgressBar", bar_bg)
	theme.set_stylebox("fill", "ProgressBar", bar_fill)

	return theme


# --- Boxes ------------------------------------------------------------------

static func button_box(kind: String, hover: bool = false) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.set_corner_radius_all(18)
	box.border_color = INK
	match kind:
		"primary":
			box.bg_color = GOLD_LIGHT if hover else GOLD
			box.set_border_width_all(3)
			box.border_width_bottom = 7
		"primary_pressed":
			box.bg_color = GOLD_DARK
			box.set_border_width_all(3)
			box.border_width_bottom = 3
		"secondary":
			box.bg_color = PAPER_DEEP if hover else PAPER
			box.set_border_width_all(3)
			box.border_width_bottom = 6
		"secondary_pressed":
			box.bg_color = Color("e6cf9f")
			box.set_border_width_all(3)
			box.border_width_bottom = 3
		"coral":
			box.bg_color = Color("ff8576") if hover else CORAL
			box.set_border_width_all(3)
			box.border_width_bottom = 7
		"coral_pressed":
			box.bg_color = Color("d9564a")
			box.set_border_width_all(3)
			box.border_width_bottom = 3
		"ghost":
			box.bg_color = Color(PAPER, 0.10) if hover else Color(0, 0, 0, 0)
			box.set_border_width_all(0)
		"disabled":
			box.bg_color = Color(PAPER, 0.35)
			box.set_border_width_all(3)
			box.border_color = Color(INK, 0.20)
	box.content_margin_left = 24
	box.content_margin_right = 24
	box.content_margin_top = 13
	box.content_margin_bottom = 13
	return box


static func card_box(margin: int = 36) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = PAPER
	box.border_color = INK
	box.set_border_width_all(4)
	box.set_corner_radius_all(26)
	box.content_margin_left = margin
	box.content_margin_right = margin
	box.content_margin_top = margin
	box.content_margin_bottom = margin
	box.shadow_color = Color(0.03, 0.05, 0.12, 0.40)
	box.shadow_size = 10
	box.shadow_offset = Vector2(0, 10)
	return box


static func input_box(focused: bool) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("fdf9ee")
	box.border_color = GOLD if focused else Color(INK, 0.28)
	box.set_border_width_all(3)
	box.set_corner_radius_all(14)
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	return box


static func game_panel_box(alpha: float = 0.78) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(INK_DEEP, alpha)
	box.border_color = Color(PAPER, 0.14)
	box.set_border_width_all(2)
	box.set_corner_radius_all(18)
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box


static func pill_box(bg: Color = PAPER) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = INK
	box.set_border_width_all(3)
	box.set_corner_radius_all(22)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 5
	box.content_margin_bottom = 5
	return box


# --- Text -------------------------------------------------------------------

static func label(text: String, size: int = 17, color: Color = INK, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	node.horizontal_alignment = align
	return node


static func title(text: String, size: int = 48, color: Color = GOLD, align: int = HORIZONTAL_ALIGNMENT_CENTER, outlined: bool = true) -> Label:
	var node := label(text, size, color, align)
	node.add_theme_font_override("font", font_display())
	if outlined:
		node.add_theme_constant_override("outline_size", maxi(6, int(size * 0.13)))
		node.add_theme_color_override("font_outline_color", INK)
		node.add_theme_constant_override("shadow_offset_x", 0)
		node.add_theme_constant_override("shadow_offset_y", maxi(3, int(size * 0.06)))
		node.add_theme_constant_override("shadow_outline_size", 2)
		node.add_theme_color_override("font_shadow_color", Color(0.03, 0.05, 0.12, 0.55))
	else:
		node.add_theme_constant_override("outline_size", 0)
	return node


static func body(text: String, size: int = 15, color: Color = INK_SOFT, align: int = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var node := label(text, size, color, align)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_constant_override("line_spacing", 4)
	return node


static func note_text(text: String, size: int = 34) -> Label:
	var node := label(text, size, INK, HORIZONTAL_ALIGNMENT_LEFT)
	node.add_theme_font_override("font", font_serif())
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_constant_override("line_spacing", 8)
	return node


static func small(text: String, color: Color = INK_SOFT) -> Label:
	var node := label(text.to_upper(), 11, color)
	node.add_theme_font_override("font", font_bold())
	return node


static func star_row(filled: int, total: int = 3, size: int = 34) -> HBoxContainer:
	var row := hbox(6)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in total:
		var on := i < filled
		var star := label("★", size, GOLD if on else Color(INK, 0.16), HORIZONTAL_ALIGNMENT_CENTER)
		if on:
			star.add_theme_constant_override("outline_size", 4)
			star.add_theme_color_override("font_outline_color", INK)
		row.add_child(star)
	return row


# --- Controls ---------------------------------------------------------------

static func button(text: String, size: int = 20, kind: String = "secondary") -> Button:
	var node := Button.new()
	node.text = text
	node.focus_mode = Control.FOCUS_NONE
	node.custom_minimum_size = Vector2(0, 68)
	node.add_theme_font_override("font", font_display())
	node.add_theme_font_size_override("font_size", size)
	apply_kind(node, kind)
	node.pressed.connect(func() -> void: Sfx.play("ui"))
	return node


static func apply_kind(node: Button, kind: String) -> void:
	node.add_theme_stylebox_override("normal", button_box(kind))
	node.add_theme_stylebox_override("hover", button_box(kind, true))
	var pressed_kind := kind + "_pressed"
	if kind == "primary" or kind == "secondary" or kind == "coral":
		node.add_theme_stylebox_override("pressed", button_box(pressed_kind))
	elif kind == "ghost":
		node.add_theme_stylebox_override("pressed", button_box("ghost"))
	var text_color := PAPER if kind == "coral" else INK
	if kind == "ghost":
		text_color = Color(PAPER, 0.8)
	node.add_theme_color_override("font_color", text_color)
	node.add_theme_color_override("font_hover_color", text_color)
	node.add_theme_color_override("font_pressed_color", text_color)


static func ghost(text: String, size: int = 15) -> Button:
	var node := button(text, size, "ghost")
	node.custom_minimum_size = Vector2(0, 44)
	return node


static func panel(min_width: int = 0) -> PanelContainer:
	var node := PanelContainer.new()
	if min_width > 0:
		node.custom_minimum_size = Vector2(min_width, 0)
	return node


static func vbox(separation: int = 12) -> VBoxContainer:
	var node := VBoxContainer.new()
	node.add_theme_constant_override("separation", separation)
	return node


static func hbox(separation: int = 12) -> HBoxContainer:
	var node := HBoxContainer.new()
	node.add_theme_constant_override("separation", separation)
	return node


static func spacer(height: int = 12) -> Control:
	var node := Control.new()
	node.custom_minimum_size = Vector2(0, height)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


static func full_rect(node: Control) -> Control:
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	node.offset_left = 0
	node.offset_top = 0
	node.offset_right = 0
	node.offset_bottom = 0
	return node


static func dim_background(alpha: float = 0.55) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = Color(0.03, 0.05, 0.12, alpha)
	full_rect(rect)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


static func progress() -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 12)
	bar.max_value = 100.0
	return bar


static func line_edit(placeholder: String) -> LineEdit:
	var node := LineEdit.new()
	node.placeholder_text = placeholder
	node.custom_minimum_size = Vector2(0, 52)
	return node


static func text_area(placeholder: String, min_height: int = 110) -> TextEdit:
	var node := TextEdit.new()
	node.placeholder_text = placeholder
	node.custom_minimum_size = Vector2(0, min_height)
	node.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	return node


# --- Backdrops --------------------------------------------------------------

static func dusk_backdrop(root: Control) -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.07, 0.11, 0.24, 0.94))
	gradient.set_color(1, Color(0.36, 0.16, 0.22, 0.18))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 8
	texture.height = 256
	texture.fill_from = Vector2(0, 0)
	texture.fill_to = Vector2(0, 1)
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	full_rect(rect)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(rect)


static func story_backdrop(root: Control) -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, DUSK_TOP)
	gradient.set_color(1, DUSK_BOTTOM)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 8
	texture.height = 256
	texture.fill_from = Vector2(0, 0)
	texture.fill_to = Vector2(0, 1)
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	full_rect(rect)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(rect)

	var glow := Gradient.new()
	glow.set_color(0, Color(1.0, 0.78, 0.45, 0.30))
	glow.set_color(1, Color(1.0, 0.78, 0.45, 0.0))
	var glow_texture := GradientTexture2D.new()
	glow_texture.gradient = glow
	glow_texture.width = 256
	glow_texture.height = 256
	glow_texture.fill = GradientTexture2D.FILL_RADIAL
	glow_texture.fill_from = Vector2(0.5, 0.5)
	glow_texture.fill_to = Vector2(1.0, 1.0)
	var glow_rect := TextureRect.new()
	glow_rect.texture = glow_texture
	glow_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow_rect.stretch_mode = TextureRect.STRETCH_SCALE
	full_rect(glow_rect)
	glow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(glow_rect)


static func screen_root() -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	return root


## Dim veil + centred paper card.
static func centered_card(root: Control, min_width: int = 600) -> VBoxContainer:
	root.add_child(dim_background())
	var center := CenterContainer.new()
	full_rect(center)
	root.add_child(center)
	var box := panel(min_width)
	center.add_child(box)
	var column := vbox(16)
	box.add_child(column)
	return column


# --- Icons ------------------------------------------------------------------

static func plane_icon(size: int = 34, tint: Color = PAPER) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = load("res://assets/art/plane.svg")
	rect.custom_minimum_size = Vector2(size, size)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.modulate = tint
	return rect


static func crown_icon(size: int = 80, tint: Color = Color.WHITE) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = load("res://assets/art/crown.svg")
	rect.custom_minimum_size = Vector2(size, size)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.modulate = tint
	return rect
