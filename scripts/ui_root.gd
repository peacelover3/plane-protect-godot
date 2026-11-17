extends Control
## Sits inside the UI CanvasLayer with PROCESS_MODE_ALWAYS so the escape/back
## action still reaches the game while the tree is paused.

signal back_requested


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		back_requested.emit()
		get_viewport().set_input_as_handled()
