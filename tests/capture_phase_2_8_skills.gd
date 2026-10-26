extends SceneTree

## Phase 2.8 production skill evidence capture (windowed run, 1152x648).
## Captures each of the four skills mid-effect, lock-on reticle, checkpoint
## interaction, and a compass yaw pair — all in the real main.tscn.

const OUT: String = "res://screenshot_phase_2_8_%s.png"

var _main: Node3D
var _camera: Camera3D
var _player: PlayerController
var _soldier: SoldierEnemy
var _skills: Node
var _skill_index: int = 0


func _init() -> void:
	call_deferred("_run")


func _release_all() -> void:
	for action: String in ["move_forward", "move_back", "move_left", "move_right", "sprint", "jump", "dodge", "guard", "attack", "lock_on", "skill_next", "skill_cast", "target_next", "target_prev", "interact"]:
		Input.action_release(action)


func _presscast(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	var event_release := InputEventAction.new()
	event_release.action = action
	event_release.pressed = false
	Input.parse_input_event(event_release)


func _combat_framing() -> void:
	# Camera behind player, looking over the shoulder at the soldier.
	var shoulder: Vector3 = _player.global_position
	_camera.global_position = shoulder + Vector3(-1.3, 1.05, 5.2)
	_camera.look_at(_soldier.global_position + Vector3(0.0, 0.9, 0.0), Vector3.UP)
	_camera.current = true


func _position_combat(distance: float = 2.2) -> void:
	_soldier.set_physics_process(false)
	_soldier._change_state(SoldierEnemy.State.IDLE)
	_soldier.global_position = _player.global_position + Vector3(0.0, 0.0, -distance)
	_player.velocity = Vector3.ZERO
	_combat_framing()


func _capture(label: String) -> void:
	for _i in range(3):
		await process_frame
	var image: Image = _camera.get_viewport().get_texture().get_image()
	var path: String = OUT % label
	image.save_png(path)
	print("[CAPTURE] %s %s" % [path, str(image.get_size())])


func _reset_skill_state() -> void:
	_skills.set("_cooldowns", [0.0, 0.0, 0.0, 0.0])
	_player.stamina.reset_stamina()


func _select_skill(index: int) -> void:
	var current: int = _skills.selected_index
	var presses: int = (index - current + _skills.skills.size()) % _skills.skills.size()
	for i in range(presses):
		await _presscast("skill_next")
	await process_frame
	print("[SKILL] selected=%s index=%d" % [str(_skills.get_selected_skill().display_name), _skills.selected_index])


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1152, 648))
	_main = (load("res://main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(_main)
	await process_frame
	await process_frame
	_player = _main.get_node("Player") as PlayerController
	_soldier = _main.get_node("SoldierEnemy") as SoldierEnemy
	_skills = _player.get_node("PlayerSkillComponent") as Node
	_camera = Camera3D.new()
	_camera.far = 250.0
	_main.add_child(_camera)
	_player.health.is_invulnerable = true
	_release_all()
	_position_combat()
	for _i in range(20):
		await process_frame

	# --- Lock-on reticle ---
	await _presscast("lock_on")
	for _i in range(8):
		await process_frame
	_combat_framing()
	await _capture("lockon_reticle")

	# --- Compass yaw pair: 0 and 90 degree camera rotations ---
	var lock_on: Node = _player.lock_on
	if lock_on.is_locked_on:
		lock_on.unlock()
	var camera_rig: Node3D = _player.get_node_or_null("CameraPivot")
	if camera_rig != null:
		camera_rig.rotation.y = 0.0
	for _i in range(10):
		await process_frame
	var hud_compass: Node = _main.get_node("CombatHUD").compass
	var heading_north: float = hud_compass.get_heading_degrees()
	await _capture("compass_north")
	if camera_rig != null:
		camera_rig.rotation.y = deg_to_rad(90.0)
	for _i in range(10):
		await process_frame
	var heading_east: float = hud_compass.get_heading_degrees()
	await _capture("compass_east")
	print("[SKILL] compass yaw pair: %.1f -> %.1f deg" % [heading_north, heading_east])

	# --- Four skills, one capture each mid-effect ---
	var cast_labels: Array[String] = ["skill1_aether_crescent", "skill2_rift_step", "skill3_shatterpoint_thrust", "skill4_aether_wave"]
	var effect_delay: Array[int] = [14, 10, 16, 14]
	for index in range(4):
		_position_combat(maxf(2.0, 2.0 + float(index) * 0.3))
		_reset_skill_state()
		await _select_skill(index)
		for _i in range(10):
			await process_frame
		_combat_framing()
		await _presscast("skill_cast")
		for _i in range(effect_delay[index]):
			await process_frame
		await _capture(cast_labels[index])
		for _i in range(30):
			await process_frame

	# --- Checkpoint F interaction visual ---
	_release_all()
	var checkpoint: Node3D = _main.get_node_or_null("LanternCheckpoint") as Node3D
	_player.global_position = checkpoint.global_position + Vector3(0.0, 0.2, 1.4)
	_player.velocity = Vector3.ZERO
	for _i in range(25):
		await process_frame
	await _presscast("interact")
	for _i in range(10):
		await process_frame
	_camera.global_position = checkpoint.global_position + Vector3(2.2, 1.6, 3.4)
	_camera.look_at(checkpoint.global_position + Vector3(0.0, 1.0, 0.0), Vector3.UP)
	await _capture("checkpoint_interact")
	print("[SKILL] capture session complete")
	quit(0)
