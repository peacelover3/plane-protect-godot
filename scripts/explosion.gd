extends Node2D
## Pure visual explosion. Damage is resolved by the arena at the moment of the
## blast so the effects can take their time.

var blast_radius := 68.0
var _time := 0.0
var _duration := 0.55
var _sparks: Array[Dictionary] = []


func setup(radius: float) -> void:
	blast_radius = radius
	z_index = 30
	var rng := RandomNumberGenerator.new()
	rng.seed = randi()
	for i in 14:
		var angle := rng.randf_range(0.0, TAU)
		_sparks.append({
			"dir": Vector2(cos(angle), sin(angle)),
			"speed": rng.randf_range(0.6, 1.5),
			"size": rng.randf_range(3.0, 8.0),
		})


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if _time >= _duration:
		queue_free()


func _draw() -> void:
	var progress: float = clampf(_time / _duration, 0.0, 1.0)
	var ease_out := 1.0 - pow(1.0 - progress, 2.2)

	# Shockwave ring.
	var ring_radius := lerpf(10.0, blast_radius * 1.25, ease_out)
	draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 40, Color(1.0, 0.72, 0.34, (1.0 - progress) * 0.85), lerpf(8.0, 1.0, progress))

	# Fireball core.
	var core_radius := lerpf(blast_radius * 0.85, blast_radius * 0.35, progress)
	draw_circle(Vector2.ZERO, core_radius, Color(1.0, 0.55, 0.16, (1.0 - progress) * 0.55))
	draw_circle(Vector2.ZERO, core_radius * 0.55, Color(1.0, 0.88, 0.55, (1.0 - progress) * 0.75))

	# Sparks.
	for spark in _sparks:
		var dir: Vector2 = spark["dir"]
		var travel: float = blast_radius * 1.15 * float(spark["speed"]) * ease_out
		var pos := dir * travel
		var alpha: float = (1.0 - progress) * 0.9
		draw_circle(pos, float(spark["size"]) * (1.0 - progress * 0.6), Color(1.0, 0.82, 0.42, alpha))

	# Smoke puffs that rise and fade.
	for i in 4:
		var angle := float(i) * TAU / 4.0 + 0.5
		var offset := Vector2(cos(angle), sin(angle) - 0.4) * blast_radius * 0.55 * ease_out
		draw_circle(offset, lerpf(6.0, 26.0, progress), Color(0.24, 0.22, 0.24, (1.0 - progress) * 0.20))
