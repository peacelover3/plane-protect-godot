class_name GameArena
extends Node2D
## Runs a single round. The arena owns all gameplay state (score, hearts, timers)
## and builds its world in code so there is nothing fragile to wire in the editor.

signal run_finished(result: Dictionary)
signal hearts_changed(hearts: int)
signal banner(text: String, color: Color)

const MODE_LEVEL := 0
const MODE_BOSS := 1
const MODE_ENDLESS := 2

const BOUNDS := Rect2(60, 100, 1160, 570)
const PLANE_START := Vector2(640, 250)
const BOMB_INTERVAL := 0.34
const START_HEARTS := 3

const PlaneScript := preload("res://scripts/plane.gd")
const BombScript := preload("res://scripts/bomb.gd")
const ExplosionScript := preload("res://scripts/explosion.gd")
const EnemyScript := preload("res://scripts/enemy.gd")
const FireballScript := preload("res://scripts/fireball.gd")
const BossScript := preload("res://scripts/boss.gd")
const FieldScript := preload("res://scripts/field.gd")
const BeaconScript := preload("res://scripts/beacon.gd")
const PopupScript := preload("res://scripts/score_popup.gd")

var mode := MODE_LEVEL
var level_number := 1
var level_title := ""
var running := false
var score := 0
var kills := 0
var hearts := START_HEARTS
var target_score := 0
var time_left := 0.0
var round_time := 0.0
var boss_fighting := false
var plane: Node2D = null
var boss: Node2D = null

var _world: Node2D
var _beacon: Node2D
var _enemy_layer: Node2D
var _plane_layer: Node2D
var _bomb_layer: Node2D
var _projectile_layer: Node2D
var _fx_layer: Node2D
var _enemies: Array[Node2D] = []
var _fireballs: Array[Node2D] = []

var _input_vector := Vector2.ZERO
var _spawn_timer := 0.0
var _flak_timer := 0.0
var _bomb_timer := 0.0
var _invuln_grace := 0.0
var _spawn_interval := 1.2
var _max_alive := 10
var _flak_target := 0
var _speed_mult := 1.0
var _weights: Dictionary = {}
var _endless_time := 0.0
var _shake := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_world = Node2D.new()
	_world.name = "World"
	add_child(_world)

	var field := FieldScript.new()
	field.name = "Field"
	_world.add_child(field)

	_beacon = BeaconScript.new()
	_beacon.name = "Beacon"
	_world.add_child(_beacon)

	_enemy_layer = _make_layer("Enemies")
	_plane_layer = _make_layer("Plane")
	_bomb_layer = _make_layer("Bombs")
	_projectile_layer = _make_layer("Projectiles")
	_fx_layer = _make_layer("Effects")


func _make_layer(layer_name: String) -> Node2D:
	var layer := Node2D.new()
	layer.name = layer_name
	_world.add_child(layer)
	return layer


# --- Round lifecycle --------------------------------------------------------

func start_level(level: int) -> void:
	_clear_run()
	mode = MODE_LEVEL
	level_number = clampi(level, 1, GameState.MAX_LEVEL)
	var data := GameState.level_data(level_number)
	level_title = str(data.get("name", ""))
	target_score = GameState.target_for(level_number)
	round_time = float(data.get("duration", 60.0))
	time_left = round_time
	_spawn_interval = float(data.get("spawn_interval", 1.2)) * GameState.spawn_scale()
	_max_alive = int(data.get("max_alive", 10))
	_flak_target = maxi(0, int(data.get("flak", 0)) + GameState.flak_adjust())
	_speed_mult = float(data.get("speed_mult", 1.0)) * GameState.speed_scale()
	var weights = data.get("weights", {"grunt": 1.0})
	_weights = (weights as Dictionary).duplicate()

	hearts = START_HEARTS
	hearts_changed.emit(hearts)
	_create_plane()
	_spawn_timer = 0.9
	_flak_timer = 5.0
	_bomb_timer = 0.2
	_invuln_grace = 1.2
	running = true
	banner.emit("LEVEL %d" % level_number, UIKit.GOLD)


func start_boss() -> void:
	_clear_run()
	mode = MODE_BOSS
	level_number = GameState.MAX_LEVEL
	level_title = "King of MathLand"
	target_score = 0
	time_left = 0.0
	round_time = 0.0
	_weights = {"grunt": 0.6, "runner": 0.4}
	_speed_mult = 1.15
	_max_alive = 10
	_flak_target = 0

	hearts = START_HEARTS
	hearts_changed.emit(hearts)
	_create_plane()
	_invuln_grace = 2.0
	_bomb_timer = 0.2

	boss = BossScript.new()
	boss.max_hp = GameState.boss_hp()
	boss.hp = boss.max_hp
	_enemy_layer.add_child(boss)
	boss.wants_volley.connect(_on_boss_volley)
	boss.wants_minion.connect(_on_boss_minion)
	boss.defeated.connect(_on_boss_defeated)
	boss.active = true

	boss_fighting = true
	running = true
	banner.emit("THE KING", UIKit.CORAL)
	Sfx.play("boss_roar", 0.02, 2.0)


func start_endless() -> void:
	_clear_run()
	mode = MODE_ENDLESS
	level_number = 0
	level_title = "Free For All"
	target_score = 0
	time_left = 0.0
	round_time = 0.0
	_weights = {"grunt": 0.55, "runner": 0.35, "tank": 0.10}
	_speed_mult = 1.0
	_max_alive = 10
	_flak_target = 1
	_spawn_interval = 1.05
	_endless_time = 0.0

	hearts = START_HEARTS
	hearts_changed.emit(hearts)
	_create_plane()
	_spawn_timer = 0.6
	_flak_timer = 6.0
	_bomb_timer = 0.2
	_invuln_grace = 1.2
	running = true
	banner.emit("FREE FOR ALL", UIKit.GOLD)


func stop_to_idle() -> void:
	_clear_run()


func _clear_run() -> void:
	running = false
	boss_fighting = false
	_world.process_mode = Node.PROCESS_MODE_INHERIT
	for child in _enemy_layer.get_children():
		child.queue_free()
	for child in _plane_layer.get_children():
		child.queue_free()
	for child in _bomb_layer.get_children():
		child.queue_free()
	for child in _projectile_layer.get_children():
		child.queue_free()
	for child in _fx_layer.get_children():
		child.queue_free()
	_enemies.clear()
	_fireballs.clear()
	plane = null
	boss = null
	score = 0
	kills = 0
	hearts = START_HEARTS
	time_left = 0.0
	target_score = 0
	_shake = 0.0
	_bomb_timer = 0.0
	_spawn_timer = 0.0
	_invuln_grace = 0.0
	_input_vector = Vector2.ZERO
	_endless_time = 0.0
	if _world != null:
		_world.position = Vector2.ZERO


func _create_plane() -> void:
	plane = PlaneScript.new()
	plane.bounds = BOUNDS
	_plane_layer.add_child(plane)
	plane.position = PLANE_START
	plane.set_input(Vector2.ZERO)
	plane.invulnerable = 1.2


# --- Per-frame --------------------------------------------------------------

func set_input_vector(direction: Vector2) -> void:
	_input_vector = direction.limit_length(1.0)


func _process(delta: float) -> void:
	if _shake > 0.05:
		_shake = maxf(0.0, _shake - delta * 26.0)
		_world.position = Vector2(_rng.randf_range(-_shake, _shake), _rng.randf_range(-_shake, _shake))
	elif _world.position != Vector2.ZERO:
		_world.position = Vector2.ZERO


func _physics_process(delta: float) -> void:
	if not running:
		return
	_invuln_grace = maxf(0.0, _invuln_grace - delta)

	if plane != null and is_instance_valid(plane):
		plane.set_input(_combined_input())

	_bomb_timer -= delta
	if _bomb_timer <= 0.0 and plane != null and is_instance_valid(plane):
		_bomb_timer = BOMB_INTERVAL
		_drop_bomb()

	if mode == MODE_LEVEL:
		_tick_level(delta)
	elif mode == MODE_ENDLESS:
		_tick_endless(delta)
	else:
		_tick_boss(delta)

	_tick_fireballs()
	_prune()


func _combined_input() -> Vector2:
	var stick := _input_vector
	if stick.length() > 0.12:
		return stick
	var keyboard := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		keyboard.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		keyboard.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		keyboard.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		keyboard.y += 1.0
	return keyboard.normalized()


func _tick_level(delta: float) -> void:
	time_left = maxf(0.0, time_left - delta)
	if time_left <= 0.0:
		end_run(false, "The round timer ran out.")
		return

	_tick_spawning(delta)
	_update_targets()


func _tick_endless(delta: float) -> void:
	_endless_time += delta
	time_left = _endless_time
	var ramp := int(_endless_time / 20.0)
	_spawn_interval = maxf(0.42, 1.05 - float(ramp) * 0.07)
	_max_alive = mini(22, 10 + ramp)
	_speed_mult = 1.0 + float(ramp) * 0.035
	_flak_target = mini(4, 1 + ramp / 2)
	_tick_spawning(delta)
	_update_targets()


func _tick_spawning(delta: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = maxf(0.42, _spawn_interval * _rng.randf_range(0.85, 1.15))
		if _walker_count() < _max_alive:
			_spawn_walker(_pick_type())

	if _flak_target > 0:
		_flak_timer -= delta
		if _flak_timer <= 0.0 and _turret_count() < _flak_target:
			_flak_timer = 7.0
			_spawn_flak()


func _tick_boss(_delta: float) -> void:
	_update_targets()


func _update_targets() -> void:
	for enemy in _enemies:
		if not is_instance_valid(enemy) or not enemy.alive:
			continue
		if enemy.is_turret:
			if plane != null and is_instance_valid(plane):
				enemy.aim_at(plane.position)
		else:
			enemy.set_target(GameState.BEACON_POS)


func _prune() -> void:
	for i in range(_enemies.size() - 1, -1, -1):
		if not is_instance_valid(_enemies[i]):
			_enemies.remove_at(i)
	for i in range(_fireballs.size() - 1, -1, -1):
		if not is_instance_valid(_fireballs[i]):
			_fireballs.remove_at(i)


# --- Spawning ---------------------------------------------------------------

func _spawn_walker(type_id: String) -> void:
	var enemy := EnemyScript.new()
	_enemy_layer.add_child(enemy)
	enemy.setup(type_id, _speed_mult)
	enemy.position = _random_spawn()
	enemy.set_target(GameState.BEACON_POS)
	enemy.reached_beacon.connect(_on_enemy_reached)
	_enemies.append(enemy)
	Sfx.play("spawn", 0.2, -18.0)


func _spawn_flak() -> void:
	var flak := EnemyScript.new()
	_enemy_layer.add_child(flak)
	flak.setup("flak", 1.0)
	flak.position = Vector2(_rng.randf_range(150.0, 1130.0), _rng.randf_range(150.0, 340.0))
	flak.wants_fire.connect(_on_turret_fire)
	_enemies.append(flak)


func _random_spawn() -> Vector2:
	var roll := _rng.randf()
	if roll < 0.55:
		return Vector2(_rng.randf_range(120.0, 1160.0), -80.0)
	if roll < 0.78:
		return Vector2(-80.0, _rng.randf_range(150.0, 600.0))
	return Vector2(1360.0, _rng.randf_range(150.0, 600.0))


func _pick_type() -> String:
	var total := 0.0
	for key in _weights.keys():
		total += float(_weights[key])
	if total <= 0.0:
		return "grunt"
	var roll := _rng.randf() * total
	for key in _weights.keys():
		roll -= float(_weights[key])
		if roll <= 0.0:
			return str(key)
	return "grunt"


func _walker_count() -> int:
	var count := 0
	for enemy in _enemies:
		if is_instance_valid(enemy) and enemy.alive and not enemy.is_turret:
			count += 1
	return count


func _turret_count() -> int:
	var count := 0
	for enemy in _enemies:
		if is_instance_valid(enemy) and enemy.alive and enemy.is_turret:
			count += 1
	return count


# --- Bombing ----------------------------------------------------------------

func _drop_bomb() -> void:
	var bomb := BombScript.new()
	_bomb_layer.add_child(bomb)
	bomb.launch(plane.ground_position(), plane.velocity * 0.16)
	bomb.exploded.connect(_on_bomb_exploded)
	Sfx.play("bomb_drop", 0.18, -12.0)


func _on_bomb_exploded(ground_pos: Vector2, blast_radius: float, damage: int) -> void:
	var blast := ExplosionScript.new()
	blast.setup(blast_radius)
	blast.position = ground_pos
	_fx_layer.add_child(blast)
	Sfx.play("explosion", 0.12, -3.0)
	_shake = maxf(_shake, 6.0)

	for enemy in _enemies.duplicate():
		if not is_instance_valid(enemy) or not enemy.alive:
			continue
		if ground_pos.distance_to(enemy.position) <= blast_radius + enemy.radius * 0.55:
			if enemy.take_damage(damage):
				_kill_enemy(enemy)

	if boss != null and is_instance_valid(boss) and boss.alive:
		if ground_pos.distance_to(boss.position) <= blast_radius + boss.radius:
			boss.take_damage(damage)

	for fireball in _fireballs.duplicate():
		if is_instance_valid(fireball) and ground_pos.distance_to(fireball.position) <= blast_radius + fireball.radius:
			_fireballs.erase(fireball)
			fireball.queue_free()


func _kill_enemy(enemy: Node2D) -> void:
	if not is_instance_valid(enemy):
		return
	score += enemy.score
	kills += 1
	GameState.total_kills += 1
	_spawn_popup(enemy.position, "+%d" % enemy.score)
	var poof := ExplosionScript.new()
	poof.setup(30.0)
	poof.position = enemy.position
	_fx_layer.add_child(poof)
	Sfx.play("kill", 0.2, -9.0)
	_enemies.erase(enemy)
	enemy.queue_free()

	if mode == MODE_LEVEL and score >= target_score:
		end_run(true, "Score target reached.")


func _spawn_popup(at: Vector2, text: String) -> void:
	var popup := PopupScript.new()
	popup.setup(text)
	popup.position = at
	_fx_layer.add_child(popup)


# --- Damage and hearts ------------------------------------------------------

func _on_enemy_reached(enemy: Node2D) -> void:
	if not running:
		return
	if is_instance_valid(enemy):
		var blast := ExplosionScript.new()
		blast.setup(52.0)
		blast.position = enemy.position
		_fx_layer.add_child(blast)
		_enemies.erase(enemy)
		enemy.queue_free()
	_lose_heart("The Beacon took a hit.")


func _on_turret_fire(origin: Vector2, target: Vector2) -> void:
	if not running:
		return
	_spawn_fireball(origin, target, 0.0)


func _spawn_fireball(origin: Vector2, target: Vector2, spread: float) -> void:
	if not running:
		return
	var fireball := FireballScript.new()
	_projectile_layer.add_child(fireball)
	var direction := (target - origin).normalized().rotated(spread)
	fireball.launch(origin, direction, plane, 180.0)
	_fireballs.append(fireball)
	Sfx.play("fireball", 0.1, -6.0)


func _tick_fireballs() -> void:
	if plane == null or not is_instance_valid(plane):
		return
	for fireball in _fireballs.duplicate():
		if not is_instance_valid(fireball):
			continue
		if fireball.position.distance_to(plane.position) <= fireball.radius + plane.HIT_RADIUS:
			_fireballs.erase(fireball)
			fireball.queue_free()
			_lose_heart("Flak hit!")
			if not running:
				return


func _lose_heart(reason: String) -> void:
	if not running or _invuln_grace > 0.0:
		return
	hearts = maxi(0, hearts - 1)
	hearts_changed.emit(hearts)
	if _beacon != null and is_instance_valid(_beacon):
		_beacon.pulse_hit()
	Sfx.play("hit", 0.1, 0.0)
	Sfx.play("life_lost", 0.04, -3.0)
	_shake = maxf(_shake, 14.0)

	if plane != null and is_instance_valid(plane):
		plane.invulnerable = 2.2
		plane.respawn(PLANE_START)
	_invuln_grace = 2.2

	if hearts <= 0:
		end_run(false, reason)
		return

	banner.emit("%s  %d PLANE%s LEFT" % [reason.to_upper(), hearts, "" if hearts == 1 else "S"], UIKit.RED)


# --- Boss -------------------------------------------------------------------

func _on_boss_volley(origin: Vector2, _target: Vector2) -> void:
	if not running:
		return
	var aim: Vector2 = plane.position if plane != null and is_instance_valid(plane) else Vector2(640, 400)
	for spread in [-0.22, 0.0, 0.22]:
		_spawn_fireball(origin, aim, float(spread))
	Sfx.play("boss_roar", 0.05, -12.0)


func _on_boss_minion(origin: Vector2) -> void:
	if not running:
		return
	if _walker_count() >= _max_alive + 4:
		return
	var type_id := "runner" if _rng.randf() < 0.45 else "grunt"
	_spawn_walker(type_id)
	var newest: Node2D = _enemies[_enemies.size() - 1]
	newest.position = Vector2(clampf(origin.x + _rng.randf_range(-60, 60), 120.0, 1160.0), 190.0)


func _on_boss_defeated(at: Vector2) -> void:
	for i in 10:
		var blast := ExplosionScript.new()
		blast.setup(_rng.randf_range(45.0, 100.0))
		blast.position = at + Vector2(_rng.randf_range(-150, 150), _rng.randf_range(-100, 110))
		_fx_layer.add_child(blast)
	_shake = 22.0
	Sfx.play("explosion", 0.0, 2.0)
	Sfx.play("boss_clear", 0.0, -2.0)
	end_run(true, "The King is down.")


# --- Ending ----------------------------------------------------------------

func end_run(won: bool, reason: String) -> void:
	if not running:
		return
	running = false

	var previous_record := GameState.record_for(level_number) if mode == MODE_LEVEL else GameState.endless_best
	var result := {
		"won": won,
		"reason": reason,
		"score": score,
		"kills": kills,
		"level": level_number,
		"level_name": level_title,
		"is_boss": mode == MODE_BOSS,
		"is_endless": mode == MODE_ENDLESS,
		"target": target_score,
		"hearts": hearts,
		"time_left": time_left,
		"round_time": round_time,
		"previous_record": previous_record,
		"new_record": score > previous_record,
		"boss_unlocked": GameState.boss_unlocked,
		"boss_defeated": GameState.boss_defeated,
	}

	if mode == MODE_BOSS:
		if won:
			GameState.mark_boss_defeated()
		result["boss_defeated"] = GameState.boss_defeated
		result["boss_unlocked"] = true
	elif mode == MODE_ENDLESS:
		GameState.record_endless(score)
	else:
		GameState.apply_level_result(level_number, score, won)
	GameState.total_runs += 1
	GameState.save_progress()

	var freeze_delay := 1.0 if (mode == MODE_BOSS and won) else 0.0
	if freeze_delay > 0.0:
		get_tree().create_timer(freeze_delay).timeout.connect(_disable_world)
	else:
		_disable_world()
	run_finished.emit(result)


func _disable_world() -> void:
	if is_instance_valid(_world):
		_world.process_mode = Node.PROCESS_MODE_DISABLED
