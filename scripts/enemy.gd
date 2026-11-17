extends Node2D
## Ground units. Walkers converge on the Beacon; flak turrets hold position and
## fire homing fireballs at the plane.

signal reached_beacon(enemy: Node2D)
signal wants_fire(origin: Vector2, target: Vector2)

const DATA := {
	"grunt": {
		"texture": "res://assets/art/enemy_grunt.svg", "hp": 1, "speed": 50.0,
		"score": 10, "radius": 28.0, "scale": 0.68,
	},
	"runner": {
		"texture": "res://assets/art/enemy_runner.svg", "hp": 1, "speed": 88.0,
		"score": 15, "radius": 24.0, "scale": 0.58,
	},
	"tank": {
		"texture": "res://assets/art/enemy_tank.svg", "hp": 2, "speed": 31.0,
		"score": 30, "radius": 44.0, "scale": 0.78,
	},
	"flak": {
		"texture": "res://assets/art/flak.svg", "hp": 2, "speed": 0.0,
		"score": 40, "radius": 36.0, "scale": 0.80,
	},
}

var type_id := "grunt"
var hp := 1
var max_hp := 1
var speed := 50.0
var score := 10
var radius := 28.0
var is_turret := false
var alive := true

var _sprite: Sprite2D
var _target := Vector2.ZERO
var _aim := Vector2.ZERO
var _time := 0.0
var _flash := 0.0
var _fire_cooldown := 0.0
var _seed := 0.0


func setup(enemy_type: String, speed_multiplier: float = 1.0) -> void:
	type_id = enemy_type if DATA.has(enemy_type) else "grunt"
	var data: Dictionary = DATA[type_id]
	hp = int(data["hp"])
	max_hp = hp
	speed = float(data["speed"]) * speed_multiplier
	score = int(data["score"])
	radius = float(data["radius"])
	is_turret = type_id == "flak"
	_seed = randf() * TAU
	_fire_cooldown = randf_range(1.6, 3.2)
	z_index = 10

	_sprite = Sprite2D.new()
	_sprite.texture = load(str(data["texture"]))
	var s := float(data["scale"])
	_sprite.scale = Vector2(s, s)
	add_child(_sprite)


func set_target(point: Vector2) -> void:
	_target = point


func aim_at(point: Vector2) -> void:
	_aim = point


func take_damage(amount: int) -> bool:
	if not alive:
		return false
	hp -= amount
	_flash = 1.0
	if hp <= 0:
		alive = false
		return true
	return false


func _physics_process(delta: float) -> void:
	if not alive:
		return
	_time += delta
	_flash = maxf(0.0, _flash - delta * 5.0)
	if _sprite != null:
		_sprite.modulate = Color.WHITE.lerp(Color(1.0, 0.45, 0.45), _flash)

	if is_turret:
		_fire_cooldown -= delta
		if _sprite != null and _aim != Vector2.ZERO:
			var desired := (_aim - position).angle() + PI * 0.5
			_sprite.rotation = lerp_angle(_sprite.rotation, desired, minf(1.0, delta * 6.0))
		if _fire_cooldown <= 0.0 and _aim != Vector2.ZERO:
			_fire_cooldown = randf_range(3.8, 5.0)
			wants_fire.emit(position, _aim)
		queue_redraw()
		return

	var to_target := _target - position
	if to_target.length() > 0.001:
		var direction := to_target.normalized()
		# Small lateral weave keeps the approach from looking robotic.
		var weave := direction.orthogonal() * sin(_time * 2.2 + _seed) * 0.18
		position += (direction + weave).normalized() * speed * delta
		if _sprite != null:
			var face := direction.angle() + PI * 0.5
			_sprite.rotation = lerp_angle(_sprite.rotation, face, minf(1.0, delta * 5.0))
			_sprite.position.y = sin(_time * (9.0 if type_id == "runner" else 6.0) + _seed) * 1.8

	if position.distance_to(_target) <= 108.0:
		alive = false
		reached_beacon.emit(self)
	queue_redraw()


func _draw() -> void:
	# Ground shadow.
	draw_set_transform(Vector2(4, 8), 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, radius * 1.05, Color(0.02, 0.04, 0.03, 0.28))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if max_hp > 1:
		var width := radius * 1.7
		var top := -radius - 16.0
		draw_rect(Rect2(-width * 0.5 - 2, top - 2, width + 4, 10), Color(0.05, 0.07, 0.11, 0.75))
		draw_rect(Rect2(-width * 0.5, top, width * (float(hp) / float(max_hp)), 6), Color("ffab3d"))
