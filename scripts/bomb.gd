extends Node2D
## A bomb drops from the plane toward the point on the ground below it. The node
## itself sits on the ground position (so the shadow is stable) and the sprite is
## offset upward by the current altitude.

signal exploded(ground_pos: Vector2, blast_radius: float, damage: int)

const START_ALTITUDE := 122.0
const FALL_SPEED := 470.0

var blast_radius := 76.0
var damage := 1
var drift := Vector2.ZERO

var _altitude := START_ALTITUDE
var _sprite: Sprite2D


func _ready() -> void:
	z_index = 20
	_sprite = Sprite2D.new()
	_sprite.texture = load("res://assets/art/bomb.svg")
	_sprite.scale = Vector2(0.55, 0.55)
	add_child(_sprite)
	_update_visual()


func launch(ground: Vector2, drift_velocity: Vector2) -> void:
	position = ground
	drift = drift_velocity


func _physics_process(delta: float) -> void:
	_altitude -= FALL_SPEED * delta
	position += drift * delta
	drift = drift.lerp(Vector2.ZERO, minf(1.0, delta * 3.5))
	_update_visual()
	queue_redraw()
	if _altitude <= 0.0:
		exploded.emit(position, blast_radius, damage)
		queue_free()


func _update_visual() -> void:
	if _sprite == null:
		return
	var ratio: float = clampf(_altitude / START_ALTITUDE, 0.0, 1.0)
	_sprite.position = Vector2(0, -_altitude * 0.78)
	_sprite.scale = Vector2.ONE * lerpf(1.0, 0.62, ratio)
	_sprite.rotation = sin(_altitude * 0.08) * 0.14


func _draw() -> void:
	var ratio: float = clampf(_altitude / START_ALTITUDE, 0.0, 1.0)
	var shadow_radius := lerpf(26.0, 12.0, ratio)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, shadow_radius, Color(0.02, 0.04, 0.03, lerpf(0.42, 0.16, ratio)))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Aiming pip so the drop point is always readable.
	draw_arc(Vector2.ZERO, blast_radius * 0.55, 0.0, TAU, 24, Color(1.0, 0.68, 0.24, 0.30 * (1.0 - ratio)), 2.0)
