extends Control
## Floating thumbstick. Touching anywhere inside this control spawns the stick
## under your thumb, so the player never has to look for a fixed pad.

signal direction_changed(direction: Vector2)

const BASE_RADIUS := 76.0
const KNOB_RADIUS := 30.0
const DEAD_ZONE := 0.14

var _active := false
var _center := Vector2.ZERO
var _knob := Vector2.ZERO
var _direction := Vector2.ZERO
var _touch_index := -1
var _idle_time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)
	queue_redraw()


func reset() -> void:
	_active = false
	_touch_index = -1
	_direction = Vector2.ZERO
	_knob = Vector2.ZERO
	direction_changed.emit(Vector2.ZERO)
	queue_redraw()


func _process(delta: float) -> void:
	if not _active:
		_idle_time += delta
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _touch_index == -1:
			_touch_index = touch.index
			_begin(touch.position)
			accept_event()
		elif not touch.pressed and touch.index == _touch_index:
			_touch_index = -1
			_end()
			accept_event()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _touch_index:
			_update(drag.position)
			accept_event()
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			if mouse.pressed and not _active:
				_begin(mouse.position)
				accept_event()
			elif not mouse.pressed and _active:
				_end()
				accept_event()
	elif event is InputEventMouseMotion and _active:
		_update((event as InputEventMouseMotion).position)


func _begin(point: Vector2) -> void:
	_active = true
	_center = point
	_knob = point
	_direction = Vector2.ZERO
	direction_changed.emit(Vector2.ZERO)
	queue_redraw()


func _update(point: Vector2) -> void:
	var offset := point - _center
	if offset.length() > BASE_RADIUS:
		offset = offset.normalized() * BASE_RADIUS
	var raw := offset / BASE_RADIUS
	_direction = Vector2.ZERO if raw.length() < DEAD_ZONE else raw
	direction_changed.emit(_direction)
	queue_redraw()


func _end() -> void:
	_active = false
	_knob = _center
	_direction = Vector2.ZERO
	direction_changed.emit(Vector2.ZERO)
	queue_redraw()


func _draw() -> void:
	if _active:
		_draw_stick(_center, 1.0)
	else:
		var idle_center := Vector2(150.0, size.y - 150.0)
		var fade: float = 0.45 + sin(_idle_time * 2.0) * 0.08
		_draw_stick(idle_center, fade * 0.7)


func _draw_stick(center: Vector2, strength: float) -> void:
	var paper := UIKit.PAPER
	var ink := UIKit.INK
	draw_circle(center + Vector2(2, 3), BASE_RADIUS, Color(0, 0, 0, 0.14 * strength))
	draw_arc(center, BASE_RADIUS, 0.0, TAU, 64, Color(paper, 0.60 * strength), 2.0)
	draw_circle(center, 3.0, Color(paper, 0.45 * strength))

	var knob_center := center + _direction * BASE_RADIUS
	draw_circle(knob_center, KNOB_RADIUS, Color(paper, 0.92 * strength))
	draw_arc(knob_center, KNOB_RADIUS, 0.0, TAU, 48, Color(ink, 0.45 * strength), 2.0)
	draw_circle(knob_center, 4.0, Color(UIKit.GOLD, 0.95 * strength))
