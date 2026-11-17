extends Node
## Posts the post-boss note to a Discord webhook.
##
## The URL is never hard-coded in tracked files. Lookup order:
##   1. SKY_WARDEN_WEBHOOK environment variable (desktop development)
##   2. user://discord.cfg  ->  [discord] webhook="https://..."
##   3. res://discord_config.gd (gitignored, copied from the .example file)
##
## If nothing is configured the UI still works and reports that messaging is
## unavailable instead of silently failing.

signal status_changed(state: int, detail: String)

enum Status { IDLE, SENDING, SENT, FAILED }

const MAX_MESSAGE_LENGTH := 1500
const REQUEST_TIMEOUT := 12.0

var status: int = Status.IDLE
var last_detail: String = ""

var _http: HTTPRequest
var _busy: bool = false
var _queue: Array[String] = []


func _ready() -> void:
	# Requests must finish even when the game is paused behind a menu.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_http = HTTPRequest.new()
	_http.timeout = REQUEST_TIMEOUT
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)


func get_webhook_url() -> String:
	var env_url := OS.get_environment("SKY_WARDEN_WEBHOOK").strip_edges()
	if env_url != "":
		return env_url

	var user_config := ConfigFile.new()
	if user_config.load("user://discord.cfg") == OK:
		var configured := str(user_config.get_value("discord", "webhook", "")).strip_edges()
		if configured != "":
			return configured

	var config_path := "res://discord_config.gd"
	if ResourceLoader.exists(config_path):
		var script := load(config_path)
		if script != null:
			var constants: Dictionary = script.get_script_constant_map()
			var url := str(constants.get("WEBHOOK_URL", "")).strip_edges()
			if url != "":
				return url
	return ""


func is_configured() -> bool:
	return get_webhook_url() != ""


## Queue a message. `content` is ordinary text; markdown is fine.
func send_message(content: String) -> bool:
	var text := content.strip_edges()
	if text == "":
		_set_status(Status.FAILED, "Message is empty.")
		return false
	if not is_configured():
		_set_status(Status.FAILED, "No Discord webhook configured.")
		return false
	if text.length() > MAX_MESSAGE_LENGTH:
		text = text.substr(0, MAX_MESSAGE_LENGTH - 1) + "…"
	_queue.append(text)
	_set_status(Status.SENDING, "Sending…")
	_pump()
	return true


## Build and send a structured report. `kind` is shown as the message title.
func send_report(kind: String, fields: Dictionary) -> bool:
	var lines: Array[String] = []
	lines.append("**Sky Warden** — %s" % kind)
	for key in fields.keys():
		var value := str(fields[key]).strip_edges()
		if value != "":
			lines.append("**%s:** %s" % [key, value])
	lines.append("_%s_" % Time.get_datetime_string_from_system(false, true))
	return send_message("\n".join(lines))


func _pump() -> void:
	if _busy or _queue.is_empty():
		return
	var webhook := get_webhook_url()
	if webhook == "":
		_queue.clear()
		_set_status(Status.FAILED, "No Discord webhook configured.")
		return
	var content: String = _queue.pop_front()
	var payload := {
		"content": content,
		"username": "Sky Warden",
		"allowed_mentions": {"parse": []},
	}
	var headers := PackedStringArray(["Content-Type: application/json"])
	var body := JSON.stringify(payload)
	_busy = true
	var err := _http.request(webhook, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		_busy = false
		_set_status(Status.FAILED, "Could not reach Discord (error %d)." % err)
		_queue.clear()


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	_busy = false
	if result != HTTPRequest.RESULT_SUCCESS:
		_queue.clear()
		_set_status(Status.FAILED, "Network error. Check your connection.")
		return
	if response_code >= 200 and response_code < 300:
		_set_status(Status.SENT, "Sent. Thank you!")
		if not _queue.is_empty():
			_pump()
	else:
		_queue.clear()
		if response_code == 401 or response_code == 403 or response_code == 404:
			_set_status(Status.FAILED, "Webhook rejected the message. Check the URL.")
		elif response_code == 429:
			_set_status(Status.FAILED, "Discord is rate limiting. Try again shortly.")
		else:
			_set_status(Status.FAILED, "Discord returned error %d." % response_code)


func _set_status(new_status: int, detail: String) -> void:
	status = new_status
	last_detail = detail
	status_changed.emit(status, detail)
