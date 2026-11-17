extends Node2D
## Flak fireball. It leans toward the plane but is slow enough to dodge, which is
## the point: get greedy and it will catch you.

var velocity := Vector2.ZERO
var speed := 180.0
var life := 5.5
var radius := 16.0
var homing := 0.9
var target: Node2D = null

var _time := 0.0
var _sprite: Sprite2D
var _trail: Array[Vector2] = []


func _ready() -> void:
	z_index = 22
	_sprite = Sprite2D.new()
	_sprite.texture = load("res://assets/art/fireball.svg")
	_sprite.scale = Vector2(0.62, 0.62)
	add_child(_sprite)


func launch(from: Vector2, direction: Vector2, target_node: Node2D, speed_value: float = 205.0) -> void:
	position = from
	speed = speed_value
	velocity = direction.normalized() * speed
	target = target_node


func _physics_process(delta: float) -> void:
	_time += delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return

	if target != null and is_instance_valid(target):
		var desired := (target.position - position).normalized() * speed
		velocity = velocity.lerp(desired, clampf(homing * delta, 0.0, 1.0)).normalized() * speed
	position += velocity * delta

	_trail.push_front(position)
	if _trail.size() > 7:
		_trail.pop_back()

	if _sprite != null:
		_sprite.rotation += delta * 6.0
		_sprite.scale = Vector2.ONE * (0.62 + sin(_time * 18.0) * 0.05)
	queue_redraw()


func _draw() -> void:
	for i in _trail.size():
		var alpha := (1.0 - float(i) / float(_trail.size())) * 0.30
		draw_circle(_trail[i] - position, radius * (0.35 + 0.05 * i), Color(1.0, 0.48, 0.16, alpha))
	draw_circle(Vector2.ZERO, radius * 1.9, Color(1.0, 0.45, 0.15, 0.13))
