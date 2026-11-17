extends Node2D
## The player's plane. Movement is arcade-flavoured: quick acceleration, a little
## drift, and a banked sprite. The arena owns collision and bombing.

const MAX_SPEED := 345.0
const ACCELERATION := 1900.0
const HIT_RADIUS := 32.0
## Offset from the plane's body to the point directly under it.
const SHADOW_OFFSET := Vector2(12.0, 52.0)

var velocity := Vector2.ZERO
var bounds := Rect2(60, 100, 1160, 570)
var invulnerable := 0.0

var _sprite: Sprite2D
var _input := Vector2.ZERO
var _time := 0.0
var _heading := 0.0


func _ready() -> void:
	z_index = 15
	_sprite = Sprite2D.new()
	_sprite.texture = load("res://assets/art/plane.svg")
	_sprite.scale = Vector2(0.55, 0.55)
	add_child(_sprite)


func set_input(direction: Vector2) -> void:
	_input = direction.limit_length(1.0)


func ground_position() -> Vector2:
	return position + SHADOW_OFFSET


func respawn(at: Vector2) -> void:
	position = at
	velocity = Vector2.ZERO
	_input = Vector2.ZERO
	_heading = 0.0
	if _sprite != null:
		_sprite.rotation = 0.0
	invulnerable = maxf(invulnerable, 0.6)


func _physics_process(delta: float) -> void:
	_time += delta
	invulnerable = maxf(0.0, invulnerable - delta)

	var target := _input * MAX_SPEED
	velocity = velocity.move_toward(target, ACCELERATION * delta)
	position += velocity * delta
	position.x = clampf(position.x, bounds.position.x + 30.0, bounds.end.x - 30.0)
	position.y = clampf(position.y, bounds.position.y + 30.0, bounds.end.y - 30.0)

	# The airframe turns to face where it is going, never sliding sideways.
	if velocity.length() > 16.0:
		var target_heading := velocity.angle() + PI * 0.5
		_heading = lerp_angle(_heading, target_heading, minf(1.0, delta * 6.5))
	_sprite.rotation = _heading
	_sprite.position.y = sin(_time * 3.2) * 2.0
	if invulnerable > 0.0:
		_sprite.modulate.a = 0.4 if int(_time * 14.0) % 2 == 0 else 1.0
	else:
		_sprite.modulate.a = 1.0


func _draw() -> void:
	var shadow_alpha := 0.30 if invulnerable <= 0.0 else 0.16
	draw_set_transform(SHADOW_OFFSET, 0.0, Vector2(1.0, 0.52))
	draw_circle(Vector2.ZERO, 62.0, Color(0.02, 0.05, 0.03, shadow_alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
