extends Node2D
## The building the player protects. Purely visual + feedback; the lives live in
## the arena controller.

const ARRIVAL_RADIUS := 105.0

var _sprite: Sprite2D
var _time := 0.0
var _hit_flash := 0.0
var _rings: Array[float] = []


func _ready() -> void:
	position = GameState.BEACON_POS
	z_index = 5
	_sprite = Sprite2D.new()
	_sprite.texture = load("res://assets/art/beacon.svg")
	_sprite.scale = Vector2(0.95, 0.95)
	add_child(_sprite)


func _process(delta: float) -> void:
	_time += delta
	_hit_flash = maxf(0.0, _hit_flash - delta * 2.2)
	for i in range(_rings.size() - 1, -1, -1):
		_rings[i] += delta
		if _rings[i] > 0.7:
			_rings.remove_at(i)
	if _sprite != null:
		var bob := 1.0 + sin(_time * 1.8) * 0.008
		_sprite.scale = Vector2(0.95, 0.95) * bob
		_sprite.modulate = Color.WHITE.lerp(Color(1.0, 0.55, 0.55), _hit_flash * 0.8)
	queue_redraw()


func pulse_hit() -> void:
	_hit_flash = 1.0
	_rings.append(0.0)


func _draw() -> void:
	# Warm core glow.
	var glow := 0.10 + sin(_time * 2.0) * 0.025 + _hit_flash * 0.25
	var glow_color := Color(1.0, 0.67, 0.24, glow)
	draw_circle(Vector2.ZERO, 118.0, glow_color)
	draw_circle(Vector2.ZERO, 82.0, Color(1.0, 0.75, 0.35, glow * 0.8))

	for age in _rings:
		var progress: float = clampf(age / 0.7, 0.0, 1.0)
		var radius := lerpf(110.0, 210.0, progress)
		var alpha := (1.0 - progress) * 0.7
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(1.0, 0.4, 0.35, alpha), 6.0)
