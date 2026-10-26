class_name AudioFeedbackManager
extends Node

## Audio feedback manager providing event hooks for combat sound effects.
## Gracefully handles missing audio files without throwing runtime errors.

signal sound_played(event_name: String, stream_assigned: bool)

@export_group("Katana Audio Streams")
@export var stream_katana_hit_1: AudioStream = null
@export var stream_katana_hit_2: AudioStream = null
@export var stream_katana_hit_3: AudioStream = null

@export_group("Combat Reaction Audio Streams")
@export var stream_guard_block: AudioStream = null
@export var stream_guard_break: AudioStream = null
@export var stream_stagger: AudioStream = null
@export var stream_enemy_death: AudioStream = null
@export var stream_player_hurt: AudioStream = null

var _audio_player: AudioStreamPlayer = null


func _ready() -> void:
	_resolve_player()


func _resolve_player() -> void:
	if _audio_player == null:
		_audio_player = get_node_or_null("AudioStreamPlayer") as AudioStreamPlayer
	if _audio_player == null:
		_audio_player = AudioStreamPlayer.new()
		_audio_player.name = "AudioStreamPlayer"
		add_child(_audio_player)


func play_hit(combo_index: int) -> bool:
	_resolve_player()
	var stream: AudioStream = null
	match combo_index:
		1: stream = stream_katana_hit_1
		2: stream = stream_katana_hit_2
		3: stream = stream_katana_hit_3
		_: stream = stream_katana_hit_1

	return _try_play_stream("katana_hit_%d" % combo_index, stream)


func play_guard_block() -> bool:
	_resolve_player()
	return _try_play_stream("guard_block", stream_guard_block)


func play_guard_break() -> bool:
	_resolve_player()
	return _try_play_stream("guard_break", stream_guard_break)


func play_stagger() -> bool:
	_resolve_player()
	return _try_play_stream("stagger", stream_stagger)


func play_enemy_death() -> bool:
	_resolve_player()
	return _try_play_stream("enemy_death", stream_enemy_death)


func play_player_hurt() -> bool:
	_resolve_player()
	return _try_play_stream("player_hurt", stream_player_hurt)


func has_stream_for(event_name: String) -> bool:
	match event_name:
		"katana_hit_1": return stream_katana_hit_1 != null
		"katana_hit_2": return stream_katana_hit_2 != null
		"katana_hit_3": return stream_katana_hit_3 != null
		"guard_block": return stream_guard_block != null
		"guard_break": return stream_guard_break != null
		"stagger": return stream_stagger != null
		"enemy_death": return stream_enemy_death != null
		"player_hurt": return stream_player_hurt != null
		_: return false


func get_missing_streams() -> Array[String]:
	var missing: Array[String] = []
	var events := [
		"katana_hit_1", "katana_hit_2", "katana_hit_3",
		"guard_block", "guard_break", "stagger", "enemy_death", "player_hurt"
	]
	for ev in events:
		if not has_stream_for(ev):
			missing.append(ev)
	return missing


func _try_play_stream(event_name: String, stream: AudioStream) -> bool:
	if stream != null and _audio_player != null:
		_audio_player.stream = stream
		_audio_player.play()
		sound_played.emit(event_name, true)
		return true
	sound_played.emit(event_name, false)
	return false
