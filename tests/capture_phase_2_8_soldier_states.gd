extends SceneTree

## Phase 2.8: close-up captures of the production Soldier's UAL retargeted
## states (idle / walk / sprint / attack mid-window) for manual inspection.

const OUT: String = "res://screenshot_phase_2_8_soldier_%s.png"

var _main: Node3D
var _camera: Camera3D
var _soldier: SoldierEnemy


func _init() -> void:
	call_deferred("_run")


func _capture(label: String) -> void:
	for _i in range(3):
		await process_frame
	var image: Image = _camera.get_viewport().get_texture().get_image()
	var path: String = OUT % label
	image.save_png(path)
	print("[CAPTURE] %s" % path)


func _frame_soldier() -> void:
	var soldier_pos: Vector3 = _soldier.global_position
	_camera.global_position = soldier_pos + Vector3(1.6, 1.35, 2.1)
	_camera.look_at(soldier_pos + Vector3(0.0, 0.9, 0.0), Vector3.UP)
	_camera.current = true


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1152, 648))
	_main = (load("res://main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(_main)
	await process_frame
	await process_frame
	_soldier = _main.get_node("SoldierEnemy") as SoldierEnemy
	_soldier.set_physics_process(false)
	_soldier.global_position = Vector3(8.0, 0.0, 6.0)
	_camera = Camera3D.new()
	_camera.far = 250.0
	_main.add_child(_camera)
	var _player: PlayerController = _main.get_node("Player") as PlayerController
	_player.global_position = Vector3(30.0, 0.0, 30.0) # out of frame: disambiguates soldier vs player
	await process_frame
	await process_frame
	var ap: AnimationPlayer = _soldier.anim_player
	_soldier.global_position = Vector3(0.0, 0.0, -4.0)
	await process_frame

	for state_name: String in ["idle", "walk", "sprint", "telegraph"]:
		ap.play("soldier_ual/" + state_name)
		await process_frame
		var clip: Animation = ap.get_animation("soldier_ual/" + state_name)
		ap.seek(clip.length * 0.25, true) # pin a definite pose, avoid transition blends
		for _i in range(4):
			await process_frame
		_frame_soldier()
		await _capture(state_name)

	ap.play("soldier_ual/attack")
	for _i in range(22):
		await process_frame
	_frame_soldier()
	await _capture("attack_mid")
	ap.play("soldier_ual/hit")
	for _i in range(14):
		await process_frame
	_frame_soldier()
	await _capture("hit")
	ap.play("soldier_ual/death")
	for _i in range(30):
		await process_frame
	_frame_soldier()
	await _capture("death")
	print("[CAPTURE] soldier retarget captures complete")
	quit(0)
