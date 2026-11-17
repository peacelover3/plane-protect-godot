extends Control
## The menu cover: a plum-to-coral dusk, stars, hills and a lit Beacon.

const NIGHT := Color("241a2b")
const PLUM := Color("6c3c4b")
const CORAL := Color("e08a5b")
const GOLD := Color("f3b45f")
const CREAM := Color("fff2da")
const BERRY := Color("b8484f")
const HILL_BACK := Color("4a2c3d")
const HILL_FRONT := Color("2e1f2c")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return

	# Dusk bands.
	var bands := 28
	for i in bands:
		var t := float(i) / float(bands)
		var color: Color
		if t < 0.52:
			color = NIGHT.lerp(PLUM, t / 0.52)
		elif t < 0.80:
			color = PLUM.lerp(CORAL, (t - 0.52) / 0.28)
		else:
			color = CORAL.lerp(GOLD, (t - 0.80) / 0.20)
		draw_rect(Rect2(0, h * t, w, h / float(bands) + 1.0), color)

	# Stars.
	var rng := RandomNumberGenerator.new()
	rng.seed = 4127
	for i in 76:
		var point := Vector2(rng.randf_range(0.0, w), rng.randf_range(0.0, h * 0.58))
		var radius := rng.randf_range(0.8, 2.2)
		draw_circle(point, radius, Color(CREAM, rng.randf_range(0.25, 0.85)))

	# Moon and its warm halo.
	var moon := Vector2(w * 0.80, h * 0.22)
	for i in 4:
		draw_circle(moon, 92.0 + i * 26.0, Color(GOLD, 0.035))
	draw_circle(moon, 78.0, Color(CREAM, 0.94))
	draw_circle(moon + Vector2(-22, -16), 70.0, Color(CREAM, 0.0))

	# Hills.
	var hill_back := PackedVector2Array([
		Vector2(-80, h * 0.66), Vector2(w * 0.18, h * 0.58), Vector2(w * 0.42, h * 0.67),
		Vector2(w * 0.68, h * 0.59), Vector2(w * 0.92, h * 0.66), Vector2(w + 80, h * 0.61),
		Vector2(w + 80, h + 40), Vector2(-80, h + 40),
	])
	draw_colored_polygon(hill_back, HILL_BACK)
	var hill_front := PackedVector2Array([
		Vector2(-80, h * 0.82), Vector2(w * 0.20, h * 0.73), Vector2(w * 0.48, h * 0.81),
		Vector2(w * 0.74, h * 0.72), Vector2(w + 80, h * 0.80),
		Vector2(w + 80, h + 40), Vector2(-80, h + 40),
	])
	draw_colored_polygon(hill_front, HILL_FRONT)

	_draw_beacon(Vector2(w * 0.815, h * 0.735), h)

	# A few birds.
	for i in 3:
		var origin := Vector2(w * (0.60 + 0.07 * i), h * (0.36 + 0.035 * (i % 2)))
		var wing := 9.0
		draw_arc(origin + Vector2(-wing, 0), wing, -0.9, 0.0, 8, Color(CREAM, 0.55), 2.0)
		draw_arc(origin + Vector2(wing, 0), wing, PI, PI + 0.9, 8, Color(CREAM, 0.55), 2.0)

	# Left scrim so the title reads cleanly over the sky.
	for i in 12:
		var alpha := 0.50 * (1.0 - float(i) / 12.0)
		draw_rect(Rect2(i * (w * 0.58) / 12.0, 0, (w * 0.58) / 12.0 + 1.0, h), Color(0.07, 0.025, 0.06, alpha))


func _draw_beacon(at: Vector2, h: float) -> void:
	var base_y := h * 0.90
	# Halo.
	for i in 5:
		draw_circle(at + Vector2(0, -60), 40.0 + i * 30.0, Color(GOLD, 0.028))
	# Tower.
	var tower := PackedVector2Array([
		at + Vector2(-20, -10), at + Vector2(20, -10),
		at + Vector2(30, base_y - at.y), at + Vector2(-30, base_y - at.y),
	])
	draw_colored_polygon(tower, CREAM)
	# Shaded side.
	var side := PackedVector2Array([
		at + Vector2(2, -10), at + Vector2(20, -10),
		at + Vector2(30, base_y - at.y), at + Vector2(2, base_y - at.y),
	])
	draw_colored_polygon(side, Color(CREAM_DEEP, 0.55))
	# Roof and lantern.
	draw_rect(Rect2(at + Vector2(-26, -34), Vector2(52, 24)), BERRY)
	draw_circle(at + Vector2(0, -52), 20.0, GOLD)
	draw_circle(at + Vector2(0, -52), 12.0, Color(CREAM, 0.95))
	draw_rect(Rect2(at + Vector2(-3, -98), Vector2(6, 46)), BERRY)
	# Window.
	draw_rect(Rect2(at + Vector2(-8, 22), Vector2(16, 22)), Color(INK_LIGHT, 0.8))
	# Base rocks.
	draw_circle(at + Vector2(-34, base_y - at.y - 2), 10.0, Color(GOLD, 0.10))
	draw_circle(at + Vector2(32, base_y - at.y - 4), 14.0, Color(GOLD, 0.08))


const INK_LIGHT := Color("7a5a5f")
