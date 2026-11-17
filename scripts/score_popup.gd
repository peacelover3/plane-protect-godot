extends Node2D
## Small floating "+30" that drifts up and fades out.

var _label: Label
var _life := 0.85
var _age := 0.0


func setup(text: String, color: Color = Color("ffe9a8")) -> void:
	z_index = 35
	_label = Label.new()
	_label.text = text
	_label.add_theme_font_override("font", UIKit.font_bold())
	_label.add_theme_font_size_override("font_size", 24)
	_label.add_theme_color_override("font_color", color)
	_label.add_theme_constant_override("outline_size", 6)
	_label.add_theme_color_override("font_outline_color", UIKit.INK)
	_label.position = Vector2(-24, -18)
	add_child(_label)


func _process(delta: float) -> void:
	_age += delta
	position.y -= 46.0 * delta
	if _label != null:
		_label.modulate.a = clampf(1.0 - _age / _life, 0.0, 1.0)
		_label.scale = Vector2.ONE * (1.0 + _age * 0.15)
	if _age >= _life:
		queue_free()
