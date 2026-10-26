extends SceneTree

## Phase 2.8 §5: captures the Protagonist's authored states for the manual
## animation review (idle / walk / sprint / dodge / attack combo frames).

const OUT: String = "res://screenshot_phase_2_8_player_%s.png"

var _camera: Camera3D
var _player: PlayerController


func _init() -> void:
	call_deferred("_run")


func _capture(label: String) -> void:
	for _i in range(3):
		await process_frame
	var image: Image = _camera.get_viewport().get_texture().get_image()
	var path: String = OUT % label
	image.save_png(path)
	print("[PLAYER_CAP] %s" % path)


func _frame_player() -> void:
	var p: Vector3 = _player.global_position
	_camera.global_position = p + Vector3(1.9, 1.5, 2.6)
	_camera.look_at(p + Vector3(0.0, 1.0, 0.0), Vector3.UP)
	_camera.current = true


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1152, 648))
	var main: Node3D = (load("res://main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(main)
	await process_frame
	await process_frame
	_player = main.get_node("Player") as PlayerController
	_player.health.is_invulnerable = true
	_camera = Camera3D.new()
	_camera.far = 250.0
	main.add_child(_camera)

	_frame_player()
	for _i in range(6):
		await process_frame
	await _capture("idle")

	Input.action_press("move_forward")
	for _i in range(40):
		await process_frame
	_frame_player()
	await _capture("walk")

	Input.action_press("sprint")
	for _i in range(60):
		await process_frame
	_frame_player()
	await _capture("sprint")

	Input.action_release("sprint")
	Input.action_release("move_forward")
	await process_frame
	Input.action_press("dodge")
	await process_frame
	Input.action_release("dodge")
	for _i in range(12):
		await process_frame
	_frame_player()
	await _capture("dodge")
	for _i in range(40):
		await process_frame

	for hit_index in range(1, 4):
		var event := InputEventAction.new()
		event.action = "attack"
		event.pressed = true
		Input.parse_input_event(event)
		for _i in range(14 * hit_index):
			await process_frame
		_frame_player()
		await _capture("attack%d" % hit_index)
		for _i in range(10):
			await process_frame
		var release := InputEventAction.new()
		release.action = "attack"
		release.pressed = false
		Input.parse_input_event(release)
		for _i in range(12):
			await process_frame
	print("[PLAYER_CAP] protagonist captures complete")
	quit(0)
