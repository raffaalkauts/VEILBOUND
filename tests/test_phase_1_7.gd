extends SceneTree

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0


func _init() -> void:
	print("==================================================")
	print("VEILBOUND Phase 1.7 Automated Test Suite")
	print("Testing Combat Polish, VFX, Camera & Audio Hooks")
	print("==================================================")

	call_deferred("_run_all_tests")


func _assert_test(test_name: String, condition: bool, details: String = "") -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("  [PASS] Test %d: %s" % [total_tests, test_name])
	else:
		failed_tests += 1
		print("  [FAIL] Test %d: %s - %s" % [total_tests, test_name, details])


func _setup_env() -> Dictionary:
	var main_scene: PackedScene = load("res://main.tscn")
	var main: Node3D = main_scene.instantiate() as Node3D
	root.add_child(main)

	var player: PlayerController = main.get_node_or_null("Player") as PlayerController
	var soldier: SoldierEnemy = main.get_node_or_null("SoldierEnemy") as SoldierEnemy
	var hud: CombatHUD = main.get_node_or_null("CombatHUD") as CombatHUD
	var dummy_center: LockOnTarget = main.get_node_or_null("Dummy_Center") as LockOnTarget
	var dummy_left: LockOnTarget = main.get_node_or_null("Dummy_Left") as LockOnTarget

	for _i in range(5):
		await physics_frame

	return {
		"main": main,
		"player": player,
		"soldier": soldier,
		"hud": hud,
		"dummy_center": dummy_center,
		"dummy_left": dummy_left
	}


func _cleanup_env(env: Dictionary) -> void:
	if env.has("main") and is_instance_valid(env["main"]):
		env["main"].queue_free()
	await process_frame
	await process_frame


func _run_all_tests() -> void:
	# --- COMBAT FEEDBACK TESTS (1 to 7) ---
	await _test_1_valid_hit_triggers_impact_feedback_once()
	await _test_2_missed_attack_does_not_trigger_feedback()
	await _test_3_blocked_hit_triggers_block_feedback()
	await _test_4_guard_break_produces_distinct_event_and_feedback()
	await _test_5_stagger_produces_feedback_without_modifying_poise()
	await _test_6_death_cleans_up_visual_effects_safely()
	await _test_7_repeated_effects_do_not_accumulate_transform_offsets()

	# --- CAMERA FEEDBACK TESTS (8 to 10) ---
	await _test_8_camera_feedback_returns_to_baseline()
	await _test_9_camera_feedback_does_not_rotate_player_collider()
	await _test_10_camera_orbit_and_lock_on_remain_functional()

	# --- ENEMY HEALTH UI TESTS (11 to 13) ---
	await _test_11_enemy_health_ui_reflects_health_changes()
	await _test_12_target_switching_reconnects_health_ui_correctly()
	await _test_13_dead_or_removed_targets_do_not_leave_stale_health_bars()

	# --- AUDIO & REGRESSION TESTS (14 to 16) ---
	await _test_14_missing_audio_assets_do_not_cause_runtime_errors()
	await _test_15_existing_combat_systems_remain_operational()
	await _test_16_existing_navigation_and_collision_remain_unchanged()

	print("==================================================")
	print("Results: Total=%d | Passed=%d | Failed=%d" % [total_tests, passed_tests, failed_tests])
	print("==================================================")

	if failed_tests > 0:
		print("FAILED: Some Phase 1.7 tests failed!")
		quit(1)
	else:
		print("SUCCESS: All Phase 1.7 tests passed!")
		quit(0)


# -----------------------------------------------------------------------------
# TEST 1: A valid melee hit triggers impact feedback exactly once
# -----------------------------------------------------------------------------
func _test_1_valid_hit_triggers_impact_feedback_once() -> void:
	var env: Dictionary = await _setup_env()
	var player: PlayerController = env["player"]
	var dummy: LockOnTarget = env["dummy_center"]

	# Position player facing dummy at 1.2m
	player.global_position = Vector3(0, 0.1, -0.8)
	dummy.global_position = Vector3(0, 0.1, -2.0)
	player.visual_root.rotation.y = 0.0 # Facing forward towards -Z

	var feedback_events: Array[String] = []
	player.feedback_coordinator.feedback_triggered.connect(func(ev: String, _d: Dictionary):
		feedback_events.append(ev)
	)

	# Execute light attack 1
	player.melee_attack.try_attack()
	player.melee_attack._physics_process(0.18) # Advance to ACTIVE frame

	var hit_count: int = feedback_events.count("hit_confirmed")
	var ok: bool = hit_count == 1
	_assert_test("Valid melee hit triggers impact feedback exactly once", ok, "hits=%d, events=%s" % [hit_count, feedback_events])
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 2: An attack that misses does not trigger hit-confirmation effects
# -----------------------------------------------------------------------------
func _test_2_missed_attack_does_not_trigger_feedback() -> void:
	var env: Dictionary = await _setup_env()
	var player: PlayerController = env["player"]
	var dummy: LockOnTarget = env["dummy_center"]

	# Place player in empty space far from any dummy or enemy
	player.global_position = Vector3(50.0, 0.1, 50.0)

	var feedback_events: Array[String] = []
	player.feedback_coordinator.feedback_triggered.connect(func(ev: String, _d: Dictionary):
		feedback_events.append(ev)
	)

	# Execute light attack into empty air
	player.melee_attack.try_attack()
	player.melee_attack._physics_process(0.25)

	var ok: bool = feedback_events.is_empty()
	_assert_test("Missed attack does not trigger hit-confirmation effects", ok, "events=%s" % [feedback_events])
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 3: A blocked hit triggers the appropriate feedback
# -----------------------------------------------------------------------------
func _test_3_blocked_hit_triggers_block_feedback() -> void:
	var env: Dictionary = await _setup_env()
	var player: PlayerController = env["player"]

	var feedback_events: Array[String] = []
	player.feedback_coordinator.feedback_triggered.connect(func(ev: String, _d: Dictionary):
		feedback_events.append(ev)
	)

	# Player guards
	player.visual_root.rotation.y = 0.0
	player.guard.start_guard()

	# Incoming frontal attack
	player.apply_incoming_damage(20.0, player.global_position + Vector3(0, 0, -2))

	var block_count: int = feedback_events.count("guard_blocked")
	var trauma: float = player.camera_impulse.get_trauma()

	var ok: bool = block_count == 1 and trauma > 0.0
	_assert_test("Blocked hit triggers guard-block visual and camera feedback", ok, "blocks=%d, trauma=%.2f" % [block_count, trauma])
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 4: Guard break produces a distinct event and feedback
# -----------------------------------------------------------------------------
func _test_4_guard_break_produces_distinct_event_and_feedback() -> void:
	var env: Dictionary = await _setup_env()
	var player: PlayerController = env["player"]

	var feedback_events: Array[String] = []
	player.feedback_coordinator.feedback_triggered.connect(func(ev: String, _d: Dictionary):
		feedback_events.append(ev)
	)

	player.guard.start_guard()
	# Drain stamina to 1.0, then deliver heavy attack requiring 20+ stamina
	player.stamina.current_stamina = 1.0
	player.apply_incoming_damage(50.0, player.global_position + Vector3(0, 0, -2))

	var break_count: int = feedback_events.count("guard_broken")
	var trauma: float = player.camera_impulse.get_trauma()

	var ok: bool = break_count == 1 and trauma >= 0.35 and player.guard.is_guard_broken
	_assert_test("Guard break produces distinct feedback event with strong camera impulse", ok, "breaks=%d, trauma=%.2f" % [break_count, trauma])
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 5: Stagger produces feedback without modifying poise logic
# -----------------------------------------------------------------------------
func _test_5_stagger_produces_feedback_without_modifying_poise() -> void:
	var env: Dictionary = await _setup_env()
	var player: PlayerController = env["player"]
	var soldier: SoldierEnemy = env["soldier"]

	player.global_position = Vector3(0, 0.1, -5.8) # 1.2m from soldier at (0, 0, -7)
	soldier.global_position = Vector3(0, 0.1, -7.0)
	player.visual_root.rotation.y = 0.0

	var feedback_events: Array[String] = []
	player.feedback_coordinator.feedback_triggered.connect(func(ev: String, _d: Dictionary):
		feedback_events.append(ev)
	)

	# Deliver enough poise damage to trigger stagger (soldier max poise is 60)
	soldier.apply_posture_damage(60.0)
	player.feedback_coordinator.trigger_stagger_feedback(soldier)

	var stagger_count: int = feedback_events.count("stagger")
	var is_staggered: bool = soldier.is_staggered()
	var trauma: float = player.camera_impulse.get_trauma()

	var ok: bool = stagger_count == 1 and is_staggered and trauma >= 0.20
	_assert_test("Stagger triggers distinct feedback while preserving poise state machine", ok, "staggers=%d, is_staggered=%s, trauma=%.2f" % [stagger_count, is_staggered, trauma])
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 6: Death cleans up temporary visual effects safely
# -----------------------------------------------------------------------------
func _test_6_death_cleans_up_visual_effects_safely() -> void:
	var env: Dictionary = await _setup_env()
	var soldier: SoldierEnemy = env["soldier"]

	# Trigger hit flash
	soldier.trigger_hit_flash()
	var was_flashing: bool = soldier._flash_timer > 0.0

	# Kill soldier
	soldier.take_damage(999.0)

	var ok: bool = was_flashing and soldier.current_state == SoldierEnemy.State.DEAD and is_equal_approx(soldier._flash_timer, 0.0)
	_assert_test("Death resets flash timers and cleans up visual feedback safely", ok, "flashing=%s, state=%s, timer=%.2f" % [was_flashing, soldier.get_state_name(), soldier._flash_timer])
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 7: Repeated effects do not accumulate transform offsets
# -----------------------------------------------------------------------------
func _test_7_repeated_effects_do_not_accumulate_transform_offsets() -> void:
	var env: Dictionary = await _setup_env()
	var player: PlayerController = env["player"]

	var base_cam_pos: Vector3 = player.camera.position
	var base_cam_rot: Vector3 = player.camera.rotation
	var base_spring_pos: Vector3 = player.spring_arm.position
	var base_player_pos: Vector3 = player.global_position

	# Trigger multiple successive impulses
	for _i in range(10):
		player.camera_impulse.add_trauma(0.2)
		player.camera_impulse._physics_process(0.016)

	# Reset/decay impulse to zero
	player.camera_impulse.reset_impulse()

	var cam_pos_drift: float = base_cam_pos.distance_to(player.camera.position)
	var cam_rot_drift: float = base_cam_rot.distance_to(player.camera.rotation)
	var spring_drift: float = base_spring_pos.distance_to(player.spring_arm.position)
	var player_drift: float = base_player_pos.distance_to(player.global_position)

	var ok: bool = (
		is_equal_approx(cam_pos_drift, 0.0)
		and is_equal_approx(cam_rot_drift, 0.0)
		and is_equal_approx(spring_drift, 0.0)
		and is_equal_approx(player_drift, 0.0)
	)
	_assert_test("Repeated feedback effects leave zero accumulated transform or rig offsets", ok, "pos_drift=%.4f, rot_drift=%.4f" % [cam_pos_drift, cam_rot_drift])
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 8: Camera feedback returns the camera to its baseline transform
# -----------------------------------------------------------------------------
func _test_8_camera_feedback_returns_to_baseline() -> void:
	var env: Dictionary = await _setup_env()
	var player: PlayerController = env["player"]

	# Deliver maximum trauma impulse
	player.camera_impulse.add_trauma(1.0)
	var had_active_impulse: bool = player.camera_impulse.get_trauma() > 0.0

	# Advance physics frames until decay completes (~0.25s at decay_rate 6.0)
	for _i in range(30):
		player.camera_impulse._physics_process(0.016)

	var final_trauma: float = player.camera_impulse.get_trauma()
	var h_ok: bool = is_equal_approx(player.camera.h_offset, 0.0)
	var v_ok: bool = is_equal_approx(player.camera.v_offset, 0.0)

	var ok: bool = had_active_impulse and is_equal_approx(final_trauma, 0.0) and h_ok and v_ok
	_assert_test("Camera impulse decays smoothly and restores exact baseline projection", ok, "trauma=%.4f, h=%.4f, v=%.4f" % [final_trauma, player.camera.h_offset, player.camera.v_offset])
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 9: Camera feedback does not rotate the player collision body
# -----------------------------------------------------------------------------
func _test_9_camera_feedback_does_not_rotate_player_collider() -> void:
	var env: Dictionary = await _setup_env()
	var player: PlayerController = env["player"]

	var initial_rot_y: float = player.rotation.y
	var initial_shape_rot: Vector3 = player.get_node("CollisionShape3D").rotation

	player.camera_impulse.add_trauma(0.8)
	for _i in range(5):
		player.camera_impulse._physics_process(0.016)

	var rot_unchanged: bool = is_equal_approx(player.rotation.y, initial_rot_y)
	var shape_unchanged: bool = player.get_node("CollisionShape3D").rotation.is_equal_approx(initial_shape_rot)

	var ok: bool = rot_unchanged and shape_unchanged
	_assert_test("Camera impulses do not rotate the CharacterBody3D collider or root transform", ok)
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 10: Camera orbit and lock-on tracking remain functional
# -----------------------------------------------------------------------------
func _test_10_camera_orbit_and_lock_on_remain_functional() -> void:
	var env: Dictionary = await _setup_env()
	var player: PlayerController = env["player"]
	var dummy: LockOnTarget = env["dummy_center"]

	# Test lock-on acquisition with active camera impulse
	player.camera_impulse.add_trauma(0.5)
	player.global_position = Vector3(0, 0.1, 1.0)
	dummy.global_position = Vector3(0, 0.1, -2.0)

	var lock_success: bool = player.lock_on.acquire_target()
	var is_locked: bool = player.lock_on.is_locked_on

	player.lock_on.unlock()
	var unlocked: bool = not player.lock_on.is_locked_on

	var ok: bool = lock_success and is_locked and unlocked
	_assert_test("Camera orbit and lock-on tracking remain functional during impulses", ok, "lock=%s, unlocked=%s" % [is_locked, unlocked])
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 11: Enemy health UI reflects health changes
# -----------------------------------------------------------------------------
func _test_11_enemy_health_ui_reflects_health_changes() -> void:
	var env: Dictionary = await _setup_env()
	var player: PlayerController = env["player"]
	var soldier: SoldierEnemy = env["soldier"]
	var hud: CombatHUD = env["hud"]

	# Lock on to soldier
	player.global_position = Vector3(0, 0.1, -4.0)
	soldier.global_position = Vector3(0, 0.1, -7.0)
	player.lock_on.acquire_target()

	var hud_visible: bool = hud.target_container.visible
	var initial_val: float = hud.target_health_bar.value

	# Apply damage to soldier
	soldier.take_damage(25.0)

	var updated_val: float = hud.target_health_bar.value
	var value_matches: bool = is_equal_approx(updated_val, 55.0) # 80 - 25

	var ok: bool = hud_visible and is_equal_approx(initial_val, 80.0) and value_matches
	_assert_test("Enemy health UI shows on lock-on and updates immediately on damage signal", ok, "vis=%s, val=%.1f (exp 55.0)" % [hud_visible, updated_val])
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 12: Target switching reconnects the health UI correctly
# -----------------------------------------------------------------------------
func _test_12_target_switching_reconnects_health_ui_correctly() -> void:
	var env: Dictionary = await _setup_env()
	var player: PlayerController = env["player"]
	var dummy_center: LockOnTarget = env["dummy_center"]
	var dummy_left: LockOnTarget = env["dummy_left"]
	var hud: CombatHUD = env["hud"]

	# Bind first target (Dummy_Center: 100 HP)
	hud.bind_target(dummy_center)
	var first_val: float = hud.target_health_bar.value

	# Damage dummy_left first so it has distinct health (e.g. 70 HP)
	dummy_left.take_damage(30.0)

	# Switch to dummy_left
	hud.bind_target(dummy_left)
	var switched_val: float = hud.target_health_bar.value

	# Now damage dummy_center further (should NOT update HUD since we switched away)
	dummy_center.take_damage(20.0)
	var after_old_damage: float = hud.target_health_bar.value

	var ok: bool = (
		is_equal_approx(first_val, 100.0)
		and is_equal_approx(switched_val, 70.0)
		and is_equal_approx(after_old_damage, 70.0)
	)
	_assert_test("Target switching rebinds health UI cleanly with zero stale signal cross-talk", ok, "first=%.1f, switched=%.1f, after_old=%.1f" % [first_val, switched_val, after_old_damage])
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 13: Dead or removed targets do not leave stale health bars
# -----------------------------------------------------------------------------
func _test_13_dead_or_removed_targets_do_not_leave_stale_health_bars() -> void:
	var env: Dictionary = await _setup_env()
	var soldier: SoldierEnemy = env["soldier"]
	var hud: CombatHUD = env["hud"]

	hud.bind_target(soldier.lock_on_target)
	var was_visible: bool = hud.target_container.visible

	# Kill target
	soldier.take_damage(999.0)

	var hidden_on_death: bool = not hud.target_container.visible

	# Test unlock
	hud.bind_target(env["dummy_center"])
	hud.unbind_target()
	var hidden_on_unbind: bool = not hud.target_container.visible

	var ok: bool = was_visible and hidden_on_death and hidden_on_unbind
	_assert_test("Dead or unlocked targets clear and hide the enemy health bar immediately", ok, "was_vis=%s, hid_death=%s, hid_unbind=%s" % [was_visible, hidden_on_death, hidden_on_unbind])
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 14: Missing audio assets do not cause runtime errors
# -----------------------------------------------------------------------------
func _test_14_missing_audio_assets_do_not_cause_runtime_errors() -> void:
	var env: Dictionary = await _setup_env()
	var player: PlayerController = env["player"]

	var missing_list: Array[String] = player.audio_manager.get_missing_streams()
	var has_missing: bool = missing_list.size() > 0

	# Call all audio hooks with null streams: must return false gracefully with zero errors
	var ret_hit: bool = player.audio_manager.play_hit(1)
	var ret_block: bool = player.audio_manager.play_guard_block()
	var ret_break: bool = player.audio_manager.play_guard_break()
	var ret_stagger: bool = player.audio_manager.play_stagger()
	var ret_death: bool = player.audio_manager.play_enemy_death()

	var ok: bool = (
		has_missing
		and not ret_hit
		and not ret_block
		and not ret_break
		and not ret_stagger
		and not ret_death
	)
	_assert_test("Missing audio assets trigger gracefully without throwing runtime errors", ok, "missing_count=%d" % [missing_list.size()])
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 15: Existing combat systems remain operational
# -----------------------------------------------------------------------------
func _test_15_existing_combat_systems_remain_operational() -> void:
	var env: Dictionary = await _setup_env()
	var player: PlayerController = env["player"]
	var soldier: SoldierEnemy = env["soldier"]

	# Test guard
	var guard_ok: bool = player.guard.start_guard()
	player.guard.stop_guard()

	# Test dodge
	var dodge_ok: bool = player.dodge.try_dodge(Vector3.FORWARD)
	player.dodge.end_dodge()

	# Test combo
	var attack_ok: bool = player.melee_attack.try_attack()
	player.melee_attack.end_attack()

	# Test soldier state machine
	var soldier_alive: bool = soldier.current_state in [SoldierEnemy.State.IDLE, SoldierEnemy.State.PATROL, SoldierEnemy.State.CHASE]

	var ok: bool = guard_ok and dodge_ok and attack_ok and soldier_alive
	_assert_test("Existing guard, dodge, combo, stamina, and soldier AI remain fully operational", ok)
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 16: Existing navigation and collision behavior remain unchanged
# -----------------------------------------------------------------------------
func _test_16_existing_navigation_and_collision_remain_unchanged() -> void:
	var env: Dictionary = await _setup_env()
	var main: Node3D = env["main"]
	var nav_region: NavigationRegion3D = main.get_node_or_null("NavigationRegion3D") as NavigationRegion3D

	var map_rid: RID = main.get_world_3d().get_navigation_map()
	var path: PackedVector3Array = NavigationServer3D.map_get_path(
		map_rid,
		Vector3(-1.5, 0.5, -3.5),
		Vector3(-1.5, 0.5, 3.5),
		true
	)

	var nav_valid: bool = nav_region != null and nav_region.navigation_mesh != null
	var path_detours: bool = path.size() >= 3

	var ok: bool = nav_valid and path_detours
	_assert_test("Existing arena navigation region and obstacle detour pathing remain intact", ok, "points=%d" % [path.size()])
	await _cleanup_env(env)
