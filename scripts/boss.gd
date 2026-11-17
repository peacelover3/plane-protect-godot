extends Node2D
## The King of MathLand. It hovers out of bombing reach... almost, lobs fireball
## volleys, and keeps dropping minions on the Beacon. Damage it with bombs.

signal wants_volley(origin: Vector2, target: Vector2)
signal wants_minion(origin: Vector2)
signal defeated(at: Vector2)

const HOVER_Y := 248.0

var max_hp := 70
var hp := 70
var radius := 128.0
var active := false
var alive := true

var _sprite: Sprite2D
var _crown: Sprite2D
var _time := 0.0
var _flash := 0.0
var _entering := true
var _volley_timer := 2.4
var _minion_timer := 2.0


func _ready() -> void:
	z_index = 14
	position = Vector2(GameState.BEACON_POS.x, -300.0)
	_sprite = Sprite2D.new()
	_sprite.texture = load("res://assets/art/boss.svg")
	_sprite.scale = Vector2(0.62, 0.62)
	add_child(_sprite)

	_crown = Sprite2D.new()
	_crown.texture = load("res://assets/art/crown.svg")
	_crown.position = Vector2(0, -148)
	_crown.scale = Vector2(0.46, 0.46)
	add_child(_crown)


func take_damage(amount: int) -> bool:
	if not alive:
		return false
	hp -= amount
	_flash = 1.0
	if hp <= 0:
		hp = 0
		alive = false
		active = false
		defeated.emit(position)
		queue_free()
		return true
	return false


func health_fraction() -> float:
	return clampf(float(hp) / float(max_hp), 0.0, 1.0)


func is_enraged() -> bool:
	return health_fraction() < 0.4


func _physics_process(delta: float) -> void:
	if not active or not alive:
		return
	_time += delta
	_flash = maxf(0.0, _flash - delta * 4.0)

	if _entering:
		position.y = move_toward(position.y, HOVER_Y, 240.0 * delta)
		if absf(position.y - HOVER_Y) < 0.5:
			_entering = false
			_volley_timer = 1.6
			_minion_timer = 1.4
	else:
		var rage := 1.6 if is_enraged() else 1.0
		position.x = GameState.BEACON_POS.x + sin(_time * 0.48) * 330.0
		position.y = HOVER_Y + sin(_time * 0.9) * 16.0

		_volley_timer -= delta * rage
		if _volley_timer <= 0.0:
			_volley_timer = 2.9
			wants_volley.emit(position + Vector2(0, 96), Vector2.ZERO)

		_minion_timer -= delta * rage
		if _minion_timer <= 0.0:
			_minion_timer = 2.6
			wants_minion.emit(position + Vector2(randf_range(-80, 80), 110))

	if _sprite != null:
		_sprite.modulate = Color.WHITE.lerp(Color(1.0, 0.4, 0.4), _flash * 0.9)
		_sprite.position.y = sin(_time * 2.0) * 4.0
	if _crown != null:
		_crown.position.y = -148.0 + sin(_time * 2.0 + 0.4) * 5.0
		_crown.rotation = sin(_time * 1.3) * 0.04
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2(18, 34), 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, 170.0, Color(0.02, 0.04, 0.03, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var pulse := 0.5 + sin(_time * 3.0) * 0.5
	var glow_color := Color(1.0, 0.3, 0.25, 0.10 + pulse * 0.06)
	if is_enraged():
		glow_color = Color(1.0, 0.35, 0.2, 0.16 + pulse * 0.10)
	draw_circle(Vector2.ZERO, 150.0, glow_color)
	draw_arc(Vector2.ZERO, 190.0, 0.0, TAU, 64, Color(1.0, 0.35, 0.3, 0.18 + pulse * 0.1), 3.0)
