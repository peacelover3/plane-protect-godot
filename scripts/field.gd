extends Node2D
## Static top-down battlefield. Everything is drawn once from a fixed seed so the
## field looks hand-placed and costs nothing per frame.

const SIZE := Vector2(1280, 720)
const OVERSCAN := 48.0

const GRASS_DARK := Color("2a6247")
const GRASS := Color("336f52")
const GRASS_LIGHT := Color("3d7f5d")
const DIRT := Color("5c4a35")
const DIRT_LIGHT := Color("6d5940")
const TREE_DARK := Color("1e4a36")
const TREE := Color("27573f")

var _rng := RandomNumberGenerator.new()
var _clouds: Array[Sprite2D] = []


func _ready() -> void:
	z_index = 0
	_rng.seed = 90210
	queue_redraw()
	_spawn_decor()
	_spawn_clouds()


func _process(delta: float) -> void:
	for cloud in _clouds:
		cloud.position.x += 7.0 * delta
		if cloud.position.x > SIZE.x + 260.0:
			cloud.position.x = -260.0


func _draw() -> void:
	var full := Rect2(-OVERSCAN, -OVERSCAN, SIZE.x + OVERSCAN * 2.0, SIZE.y + OVERSCAN * 2.0)
	draw_rect(full, GRASS_DARK)

	# Soft grass patches.
	for i in 90:
		var center := Vector2(
			_rng.randf_range(-OVERSCAN, SIZE.x + OVERSCAN),
			_rng.randf_range(-OVERSCAN, SIZE.y + OVERSCAN)
		)
		var radius := _rng.randf_range(34.0, 118.0)
		var tint := GRASS if i % 2 == 0 else GRASS_LIGHT
		draw_set_transform(center, _rng.randf_range(-0.4, 0.4), Vector2(1.0, _rng.randf_range(0.45, 0.8)))
		draw_circle(Vector2.ZERO, radius, Color(tint, 0.30))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Trampled ring around the Beacon.
	var beacon: Vector2 = GameState.BEACON_POS
	draw_circle(beacon, 168.0, Color(DIRT, 0.55))
	draw_circle(beacon, 148.0, Color(DIRT_LIGHT, 0.75))
	draw_arc(beacon, 160.0, 0.0, TAU, 64, Color(0.12, 0.09, 0.06, 0.35), 10.0)

	# Marker stones.
	for i in 16:
		var angle := TAU * float(i) / 16.0 + 0.2
		var stone := beacon + Vector2(cos(angle), sin(angle)) * 172.0
		draw_circle(stone, _rng.randf_range(5.0, 9.0), Color("9a927f"))

	# Distant treeline hugging the edges.
	_draw_treeline(Rect2(0, SIZE.y - 90.0, SIZE.x, 140.0), 42)
	_draw_treeline(Rect2(-60, 0, 110, SIZE.y), 16)
	_draw_treeline(Rect2(SIZE.x - 50, 0, 110, SIZE.y), 16)
	_draw_treeline(Rect2(0, -70, SIZE.x, 120), 26)

	# Faint landing markings so the eye has a centre.
	draw_arc(beacon, 214.0, PI * 0.15, PI * 0.85, 48, Color(0.95, 0.85, 0.7, 0.10), 4.0)
	draw_arc(beacon, 214.0, PI * 1.15, PI * 1.85, 48, Color(0.95, 0.85, 0.7, 0.10), 4.0)


func _draw_treeline(band: Rect2, count: int) -> void:
	for i in count:
		var center := Vector2(
			band.position.x + _rng.randf() * band.size.x,
			band.position.y + _rng.randf() * band.size.y
		)
		var radius := _rng.randf_range(22.0, 46.0)
		draw_circle(center + Vector2(4, 6), radius * 1.05, Color(0, 0, 0, 0.18))
		draw_circle(center, radius, TREE_DARK)
		draw_circle(center + Vector2(-6, -8), radius * 0.62, TREE)


func _spawn_decor() -> void:
	var shrub_texture: Texture2D = load("res://assets/art/shrub.svg")
	var rock_texture: Texture2D = load("res://assets/art/rock.svg")
	for i in 46:
		var pos := Vector2(
			_rng.randf_range(70.0, SIZE.x - 70.0),
			_rng.randf_range(110.0, SIZE.y - 60.0)
		)
		if pos.distance_to(GameState.BEACON_POS) < 240.0:
			continue
		var sprite := Sprite2D.new()
		sprite.texture = shrub_texture if i % 3 != 0 else rock_texture
		sprite.position = pos
		var scale_factor := _rng.randf_range(0.65, 1.25)
		sprite.scale = Vector2(scale_factor, scale_factor)
		sprite.z_index = 1
		sprite.modulate = Color(1, 1, 1, 0.9)
		add_child(sprite)


func _spawn_clouds() -> void:
	var texture: Texture2D = load("res://assets/art/cloud.svg")
	for i in 5:
		var cloud := Sprite2D.new()
		cloud.texture = texture
		cloud.position = Vector2(_rng.randf_range(0, SIZE.x), _rng.randf_range(40, SIZE.y - 40))
		cloud.scale = Vector2(_rng.randf_range(2.2, 3.6), _rng.randf_range(1.8, 2.8))
		cloud.modulate = Color(1, 1, 1, _rng.randf_range(0.34, 0.52))
		cloud.z_index = 2
		add_child(cloud)
		_clouds.append(cloud)
