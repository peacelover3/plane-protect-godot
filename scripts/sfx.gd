extends Node
## Tiny procedural sound engine.
##
## Every effect is synthesised into a 16-bit mono AudioStreamWAV at boot, so the
## project ships with no audio files and no licensing baggage. A small pool of
## players is reused round-robin to keep rapid explosions from cutting each other
## off.

const RATE := 22050
const POOL_SIZE := 14

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0


func _ready() -> void:
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_players.append(player)
	_build_streams()


func play(sound_name: String, pitch_jitter: float = 0.05, volume_db: float = 0.0) -> void:
	if GameState.muted or GameState.sfx_volume <= 0.001:
		return
	var stream: AudioStreamWAV = _streams.get(sound_name)
	if stream == null or _players.is_empty():
		return
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stream = stream
	player.pitch_scale = clampf(1.0 + randf_range(-pitch_jitter, pitch_jitter), 0.4, 2.2)
	player.volume_db = volume_db + linear_to_db(maxf(GameState.sfx_volume, 0.001))
	player.play()


func stop_all() -> void:
	for player in _players:
		player.stop()


# --- Synthesis --------------------------------------------------------------

func _build_streams() -> void:
	_streams["bomb_drop"] = _to_wav(_whistle())
	_streams["explosion"] = _to_wav(_explosion())
	_streams["fireball"] = _to_wav(_fireball())
	_streams["hit"] = _to_wav(_hit())
	_streams["kill"] = _to_wav(_kill())
	_streams["level_clear"] = _to_wav(_arpeggio([523.25, 659.25, 783.99, 1046.5], 0.13, 0.30))
	_streams["boss_clear"] = _to_wav(_arpeggio([392.0, 523.25, 659.25, 783.99, 1046.5, 1318.5], 0.16, 0.34))
	_streams["ui"] = _to_wav(_ui_click())
	_streams["life_lost"] = _to_wav(_life_lost())
	_streams["boss_roar"] = _to_wav(_boss_roar())
	_streams["spawn"] = _to_wav(_spawn_blip())


func _to_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		var v: float = clampf(samples[i], -1.0, 1.0)
		bytes.encode_s16(i * 2, int(round(v * 32000.0)))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	return stream


func _silence(seconds: float) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(int(seconds * RATE))
	samples.fill(0.0)
	return samples


func _whistle() -> PackedFloat32Array:
	var dur := 0.18
	var out := _silence(dur)
	var phase := 0.0
	for i in out.size():
		var t := float(i) / RATE
		var progress := t / dur
		var freq := lerpf(1050.0, 420.0, progress)
		phase += TAU * freq / RATE
		out[i] = sin(phase) * 0.12 * (1.0 - progress * 0.6)
	return out


func _explosion() -> PackedFloat32Array:
	var dur := 0.62
	var out := _silence(dur)
	var lowpass := 0.0
	var phase := 0.0
	for i in out.size():
		var t := float(i) / RATE
		var env: float = exp(-t * 6.0)
		lowpass = lowpass * 0.82 + randf_range(-1.0, 1.0) * 0.18
		var freq := lerpf(95.0, 38.0, minf(t / dur, 1.0))
		phase += TAU * freq / RATE
		var body := sin(phase) * exp(-t * 4.0)
		out[i] = clampf(lowpass * 2.2 * env + body * 0.55, -1.0, 1.0)
	return out


func _fireball() -> PackedFloat32Array:
	var dur := 0.34
	var out := _silence(dur)
	var phase := 0.0
	for i in out.size():
		var t := float(i) / RATE
		var progress := t / dur
		var freq := lerpf(300.0, 90.0, progress)
		phase += TAU * freq / RATE
		var saw := fmod(phase, TAU) / PI - 1.0
		var noise := randf_range(-1.0, 1.0) * 0.35
		out[i] = (saw * 0.22 + noise * 0.10) * (1.0 - progress) * 0.9
	return out


func _hit() -> PackedFloat32Array:
	var dur := 0.30
	var out := _silence(dur)
	var phase := 0.0
	for i in out.size():
		var t := float(i) / RATE
		var progress := t / dur
		var freq := lerpf(340.0, 70.0, progress)
		phase += TAU * freq / RATE
		var square: float = 1.0 if sin(phase) >= 0.0 else -1.0
		out[i] = square * 0.16 * (1.0 - progress) + randf_range(-1.0, 1.0) * 0.06 * (1.0 - progress)
	return out


func _kill() -> PackedFloat32Array:
	var dur := 0.12
	var out := _silence(dur)
	var phase := 0.0
	for i in out.size():
		var t := float(i) / RATE
		var progress := t / dur
		phase += TAU * lerpf(560.0, 940.0, progress) / RATE
		out[i] = sin(phase) * 0.14 * (1.0 - progress)
	return out


func _ui_click() -> PackedFloat32Array:
	var dur := 0.05
	var out := _silence(dur)
	for i in out.size():
		var t := float(i) / RATE
		out[i] = sin(TAU * 1100.0 * t) * 0.10 * (1.0 - t / dur)
	return out


func _life_lost() -> PackedFloat32Array:
	var dur := 0.55
	var out := _silence(dur)
	var phase := 0.0
	for i in out.size():
		var t := float(i) / RATE
		var progress := t / dur
		var freq := 520.0 if progress < 0.5 else 330.0
		phase += TAU * freq / RATE
		var env: float = (1.0 - fmod(progress * 2.0, 1.0)) * 0.8
		out[i] = (sin(phase) * 0.16 + sin(phase * 2.0) * 0.05) * env
	return out


func _boss_roar() -> PackedFloat32Array:
	var dur := 1.1
	var out := _silence(dur)
	var lowpass := 0.0
	var phase := 0.0
	for i in out.size():
		var t := float(i) / RATE
		var progress := t / dur
		var env: float = minf(progress * 8.0, 1.0) * exp(-progress * 2.2)
		lowpass = lowpass * 0.94 + randf_range(-1.0, 1.0) * 0.06
		phase += TAU * lerpf(72.0, 44.0, progress) / RATE
		out[i] = (lowpass * 3.0 + sin(phase) * 0.5) * env
	return out


func _spawn_blip() -> PackedFloat32Array:
	var dur := 0.09
	var out := _silence(dur)
	for i in out.size():
		var t := float(i) / RATE
		out[i] = sin(TAU * lerpf(180.0, 260.0, t / dur) * t) * 0.07 * (1.0 - t / dur)
	return out


func _arpeggio(freqs: Array, note_len: float, gain: float) -> PackedFloat32Array:
	var dur := note_len * freqs.size() + 0.25
	var out := _silence(dur)
	for note_index in freqs.size():
		var freq: float = freqs[note_index]
		var start := int(note_index * note_len * RATE)
		var note_samples := int((note_len + 0.22) * RATE)
		var phase := 0.0
		for k in note_samples:
			var idx := start + k
			if idx >= out.size():
				break
			var t := float(k) / RATE
			phase += TAU * freq / RATE
			var env: float = exp(-t * 7.0)
			var tone := sin(phase) * 0.7 + sin(phase * 2.0) * 0.18
			out[idx] += tone * gain * env
	return out
