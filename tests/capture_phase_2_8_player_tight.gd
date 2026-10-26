extends SceneTree

## Phase 2.8 §5 follow-up: tight-timing captures of the Protagonist's dodge
## roll and first combo swing, with animation-state logging per frame.

const OUT: String = "res://screenshot_phase_2_8_player_%s.png"

var _camera: Camera3D
var _player: PlayerController


func _init() -> void:
	call_deferred("_run")


func _log_state(label: String) -> void:
	var ap: AnimationPlayer = _player.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var state: String = "%s | is_attacking=%s is_dodging=%s anim=%s@%.2f" % [
		label, str(_player.is_attacking), str(_player.is_dodging),
		str(ap.current_animation if ap != null else "<none>"),
		(ap.current_animation_position if ap != null and ap.current_animation != "" else 0.0),
	]
	print("[PLAYER_CAP] %s" % state)


func _capture_at(label: String, frames: int) -> void:
	for _i in range(frames):
		await process_frame
	_frame_player()
	_log_state(label)
	var image: Image = _camera.get_viewport().get_texture().get_image()
	var path: String = OUT % label
	image.save_png(path)
	print("[PLAYER_CAP] %s" % path)


func _frame_player() -> void:
	var p: Vector3 = _player.global_position
	_camera.global_position = p + Vector3(1.2, 1.3, -2.3)
	_camera.look_at(p + Vector3(0.0, 1.0, 0.0), Vector3.UP)
	_camera.current = true


func _run() -> void:
	print("[PLAYER_CAP] tight run start")
	var main: Node3D = (load("res://main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(main)
	await process_frame
	await process_frame
	_player = main.get_node("Player") as PlayerController
	_player.health.is_invulnerable = true
	_camera = Camera3D.new()
	_camera.far = 250.0
	main.add_child(_camera)

	Input.action_release("move_forward")
	await process_frame
	var dodge_input := InputEventAction.new()
	dodge_input.action = "dodge"
	dodge_input.pressed = true
	Input.parse_input_event(dodge_input)
	await process_frame
	var dodge_release := InputEventAction.new()
	dodge_release.action = "dodge"
	dodge_release.pressed = false
	Input.parse_input_event(dodge_release)
	await _capture_at("dodge_mid", 4)
	for _i in range(50):
		await process_frame

	var event := InputEventAction.new()
	event.action = "attack"
	event.pressed = true
	Input.parse_input_event(event)
	await _capture_at("attack1_mid", 8)
	var release := InputEventAction.new()
	release.action = "attack"
	release.pressed = false
	Input.parse_input_event(release)
	for _i in range(50):
		await process_frame
	print("[PLAYER_CAP] tight captures complete")
	quit(0)
