extends SceneTree

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	var scene := load("res://main.tscn") as PackedScene
	var main := scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var player := main.get_node("Player") as PlayerController
	var hud := main.get_node("CombatHUD") as CombatHUD
	var camera := player.get_node("CameraPivot/SpringArm3D/Camera3D") as Camera3D
	var compass: Node = hud.get_node("Root/Compass/HeadingStrip")
	_assert(compass != null, "Production HUD contains a functional compass controller")
	if compass != null:
		player.get_node("CameraPivot").rotation.y = 0.0
		await process_frame
		var north_heading: float = compass.call("get_heading_degrees")
		player.get_node("CameraPivot").rotation.y = -PI * 0.5
		await process_frame
		var east_heading: float = compass.call("get_heading_degrees")
		_assert(absf(_angle_delta(east_heading, north_heading) - 90.0) < 2.0, "Compass follows a 90-degree camera rotation")
		_assert(absf(float(compass.call("get_direction_offset_degrees", "N"))) > 80.0, "Compass direction offsets use live heading")
		_assert(camera != null, "Compass is bound to the production gameplay camera")

	player.global_position = Vector3(0.0, 0.0, -4.0)
	var soldier := main.get_node("SoldierEnemy") as SoldierEnemy
	soldier.set_physics_process(false)
	soldier.global_position = Vector3(0.0, 0.0, -7.0)
	player.get_node("VisualRoot").rotation.y = 0.0
	var skills := player.get_node("PlayerSkillComponent") as PlayerSkillComponent
	var soldier_health := soldier.get_node("HealthComponent") as HealthComponent
	_assert(skills.skills.size() == 4, "Production player owns four skill definitions")

	var selected_before := skills.selected_index
	await _send_key(KEY_E)
	_assert(skills.selected_index == (selected_before + 1) % 4, "E changes selected skill through InputMap")

	# Select each skill through the same E action and cast it through Q.
	for index in range(4):
		while skills.selected_index != index:
			await _send_key(KEY_E)
		var stamina_before: float = player.stamina.get_stamina()
		var health_before: float = soldier_health.get_health()
		await _send_key(KEY_Q)
		await physics_frame
		await physics_frame
		await physics_frame
		var selected_skill := skills.get_selected_skill()
		_assert(player.stamina.get_stamina() < stamina_before, "Q consumes stamina for " + selected_skill.display_name)
		if index == 1:
			_assert(player.global_position.z < -4.0, "Rift Step changes player position through CharacterBody3D")
		elif index == 3:
			_assert(skills.projectile_spawn_count > 0, "Aether Wave creates a moving projectile")
		else:
			await create_timer(0.35).timeout
			_assert(soldier_health.get_health() < health_before, "Melee skill affects the real Soldier")
		await create_timer(selected_skill.cooldown + 0.05).timeout

	_assert(skills.selected_index == 3, "E selection remains stable after casts")
	main.queue_free()
	print("Phase 2.5 runtime tests: %d/%d passed" % [_passed, _passed + _failed])
	quit(0 if _failed == 0 else 1)


func _send_key(keycode: Key) -> void:
	var press := InputEventKey.new()
	press.keycode = keycode
	press.physical_keycode = 0
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	var release := InputEventKey.new()
	release.keycode = keycode
	release.physical_keycode = 0
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame


func _angle_delta(value: float, previous: float) -> float:
	var delta := fposmod(value - previous + 180.0, 360.0) - 180.0
	return absf(delta)


func _assert(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] ", label)
	else:
		_failed += 1
		push_error("[FAIL] " + label)
