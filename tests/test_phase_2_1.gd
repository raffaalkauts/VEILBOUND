extends SceneTree

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0


func _init() -> void:
	print("==================================================")
	print("VEILBOUND Phase 2.1 Automated Test Suite")
	print("Testing Player Character Art & Animation Integration")
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
	var dummy: LockOnTarget = main.get_node_or_null("Dummy_Center") as LockOnTarget

	for _i in range(5):
		await physics_frame

	return {
		"main": main,
		"player": player,
		"soldier": soldier,
		"hud": hud,
		"dummy": dummy
	}


func _cleanup_env(env: Dictionary) -> void:
	if env.has("main") and is_instance_valid(env["main"]):
		env["main"].queue_free()
	await process_frame
	await process_frame


func _run_all_tests() -> void:
	await _test_1_player_instantiates_with_character_model()
	await _test_2_model_hierarchy_and_parts_present()
	await _test_3_collision_shape_and_camera_rig_preserved()
	await _test_4_model_scale_and_proportions_appropriate()
	await _test_5_weapon_sheathe_and_draw_coordination()
	await _test_6_locomotion_states_drive_animations()
	await _test_7_secondary_motion_updates_tail_and_ears()
	await _test_8_hit_reaction_visual_triggers()
	await _test_9_death_visual_triggers_cleanly()
	await _test_10_repeated_movement_leaves_zero_accumulated_offsets()
	await _test_11_lock_on_and_targeting_remain_functional()
	await _test_12_melee_attack_and_combo_remain_functional()
	await _test_13_dodge_and_iframes_remain_functional()
	await _test_14_guard_and_damage_mitigation_remain_functional()

	print("==================================================")
	print("Results: Total=%d | Passed=%d | Failed=%d" % [total_tests, passed_tests, failed_tests])
	print("==================================================")

	if failed_tests > 0:
		print("FAILED: Some Phase 2.1 tests failed!")
		quit(1)
	else:
		print("SUCCESS: All Phase 2.1 tests passed!")
		quit(0)


# -----------------------------------------------------------------------------
# TEST 1: Player instantiates with PlayerCharacterModel
# -----------------------------------------------------------------------------
func _test_1_player_instantiates_with_character_model() -> void:
	var env: Dictionary = await _setup_env()
	var player: PlayerController = env["player"]

	var visual_root: PlayerVisualDriver = player.visual_root as PlayerVisualDriver
	var has_model: bool = visual_root != null and visual_root.has_character_model()
	var model: PlayerCharacterModel = visual_root.get_character_model() if has_model else null

	var ok: bool = has_model and model != null and is_instance_valid(model)
	_assert_test("Player instantiates with PlayerCharacterModel under VisualRoot", ok)
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 2: Model hierarchy and key stylized parts present
# -----------------------------------------------------------------------------
func _test_2_model_hierarchy_and_parts_present() -> void:
	var env: Dictionary = await _setup_env()
	var player: PlayerController = env["player"]
	var model: PlayerCharacterModel = (player.visual_root as PlayerVisualDriver).get_character_model()

	var secondary = model.secondary_motion
	var has_ears: bool = secondary != null and secondary.group_chain_count(&"ears") == 2
	var has_tail: bool = secondary != null and secondary.group_chain_count(&"tail") == 1
	var has_hair: bool = secondary != null and secondary.group_chain_count(&"hair") >= 12
	var has_scabbard: bool = model.scabbard != null
	var has_sheathed_hilt: bool = model.sheathed_hilt != null
	var has_katana_hand: bool = model.katana_in_hand != null
	var has_anim_player: bool = model.anim_player != null

	var ok: bool = has_ears and has_tail and has_hair and has_scabbard and has_sheathed_hilt and has_katana_hand and has_anim_player
	_assert_test("Model hierarchy includes full spring chains (ears, tail, hair), scabbard, katana, and AnimationPlayer", ok)
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 3: Collision shape and camera rig preserved
# -----------------------------------------------------------------------------
func _test_3_collision_shape_and_camera_rig_preserved() -> void:
	var env: Dictionary = await _setup_env()
	var player: PlayerController = env["player"]

	var col: CollisionShape3D = player.get_node_or_null("CollisionShape3D") as CollisionShape3D
	var capsule: CapsuleShape3D = col.shape as CapsuleShape3D if col != null else null
	var cam_pivot: Node3D = player.camera_pivot
	var spring: SpringArm3D = player.spring_arm

	var col_ok: bool = capsule != null and is_equal_approx(capsule.radius, 0.4) and is_equal_approx(capsule.height, 1.8)
	var cam_ok: bool = cam_pivot != null and spring != null and is_equal_approx(spring.spring_length, 4.0)

	var ok: bool = col_ok and cam_ok
	_assert_test("Collision shape (0.4m x 1.8m) and camera rig transforms are preserved", ok)
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 4: Model scale and proportions appropriate
# -----------------------------------------------------------------------------
func _test_4_model_scale_and_proportions_appropriate() -> void:
	var env: Dictionary = await _setup_env()
	var player: PlayerController = env["player"]
	var model: PlayerCharacterModel = (player.visual_root as PlayerVisualDriver).get_character_model()

	# Base scale of model should be Vector3.ONE
	var scale_ok: bool = model.scale.is_equal_approx(Vector3.ONE)
	# Position relative to VisualRoot should be at Vector3.ZERO
	var pos_ok: bool = model.position.is_equal_approx(Vector3.ZERO)

	var ok: bool = scale_ok and pos_ok
	_assert_test("Model scale is Vector3.ONE and properly aligned with VisualRoot origin", ok)
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 5: Weapon sheathe and draw coordination
# -----------------------------------------------------------------------------
func _test_5_weapon_sheathe_and_draw_coordination() -> void:
	var env: Dictionary = await _setup_env()
	var player: PlayerController = env["player"]
	var model: PlayerCharacterModel = (player.visual_root as PlayerVisualDriver).get_character_model()

	# Idle: Katana should be sheathed on hip
	model.set_combat_mode(false)
	var sheathed_ok: bool = not model.katana_in_hand.visible and model.sheathed_hilt.visible

	# Attack: Katana drawn in hand
	model.set_combat_mode(true)
	var drawn_ok: bool = model.katana_in_hand.visible and not model.sheathed_hilt.visible

	# Reset
	model.set_combat_mode(false)
	var reset_ok: bool = not model.katana_in_hand.visible and model.sheathed_hilt.visible

	var ok: bool = sheathed_ok and drawn_ok and reset_ok
	_assert_test("Katana sheathes on hip in idle and draws into hand in combat mode", ok)
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 6: Locomotion states drive animations safely
# -----------------------------------------------------------------------------
func _test_6_locomotion_states_drive_animations() -> void:
	var env: Dictionary = await _setup_env()
	var player: PlayerController = env["player"]
	var driver: PlayerVisualDriver = player.visual_root as PlayerVisualDriver
	var model: PlayerCharacterModel = driver.get_character_model()

	var required_clips: Array[String] = [
		"idle", "walk", "sprint", "jump", "fall", "dodge", "attack_1", "attack_2", "attack_3", "guard", "hit_react", "death"
	]
	var missing_clips: Array[String] = []
	for clip in required_clips:
		if not model.anim_player.has_animation(clip):
			missing_clips.append(clip)

	# Test safe playing of a valid clip and an unknown clip
	var play_valid: bool = model.play_animation("idle")
	var play_unknown: bool = not model.play_animation("non_existent_clip_xyz")

	var ok: bool = missing_clips.is_empty() and play_valid and play_unknown
	_assert_test("All 12 required animation clips exist in library and play safely", ok, "missing=%s" % [missing_clips])
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 7: Secondary motion updates tail and ears dynamically
# -----------------------------------------------------------------------------
func _test_7_secondary_motion_updates_tail_and_ears() -> void:
	var env: Dictionary = await _setup_env()
	var player: PlayerController = env["player"]
	var model: PlayerCharacterModel = (player.visual_root as PlayerVisualDriver).get_character_model()
	var secondary = model.secondary_motion

	var tail_root_bone: int = -1
	var tail_chain_found: bool = false
	for chain: Dictionary in secondary.get_chains():
		if chain["group"] == &"tail":
			tail_root_bone = int(chain["root_bone"])
			tail_chain_found = true

	# The simulator only exposes its result during the skeleton update; read it
	# there instead of after Skeleton3D restores the authored pose.
	var latest: Array[Quaternion] = [Quaternion.IDENTITY]
	var sample := func() -> void:
		latest[0] = model.skeleton.get_bone_pose_rotation(tail_root_bone)
	model.skeleton.skeleton_updated.connect(sample)
	for _i in range(8):
		await process_frame
	var before: Quaternion = latest[0]
	secondary.apply_impulse(Vector3(4.0, 0.0, 0.0))
	for _i in range(12):
		await process_frame
	var after: Quaternion = latest[0]
	model.skeleton.skeleton_updated.disconnect(sample)

	var tail_moved: bool = tail_root_bone >= 0 and before.angle_to(after) > deg_to_rad(0.5)
	var ear_chains: bool = secondary.group_chain_count(&"ears") == 2
	var simulator_on_skeleton: bool = secondary.get_simulator(&"tail").get_parent() == model.skeleton

	var ok: bool = tail_chain_found and tail_moved and ear_chains and simulator_on_skeleton
	_assert_test("Native spring chains articulate tail and ears, and react to a gameplay impulse", ok)
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 8: Hit reaction visual triggers
# -----------------------------------------------------------------------------
func _test_8_hit_reaction_visual_triggers() -> void:
	var env: Dictionary = await _setup_env()
	var player: PlayerController = env["player"]
	var driver: PlayerVisualDriver = player.visual_root as PlayerVisualDriver
	var model: PlayerCharacterModel = driver.get_character_model()

	driver.trigger_hit_reaction()
	var anim_name: String = model.anim_player.current_animation

	var ok: bool = anim_name == "hit_react"
	_assert_test("Hit reaction triggers hit_react animation on character model", ok, "current_anim=%s" % [anim_name])
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 9: Death visual triggers cleanly
# -----------------------------------------------------------------------------
func _test_9_death_visual_triggers_cleanly() -> void:
	var env: Dictionary = await _setup_env()
	var player: PlayerController = env["player"]
	var driver: PlayerVisualDriver = player.visual_root as PlayerVisualDriver
	var model: PlayerCharacterModel = driver.get_character_model()

	driver.trigger_death_visual()
	var anim_name: String = model.anim_player.current_animation
	var is_dead: bool = model._is_dead

	var ok: bool = is_dead and anim_name == "death"
	_assert_test("Death visual switches model to dead state and plays death animation", ok, "is_dead=%s, anim=%s" % [is_dead, anim_name])
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 10: Repeated movement leaves zero accumulated offsets
# -----------------------------------------------------------------------------
func _test_10_repeated_movement_leaves_zero_accumulated_offsets() -> void:
	var env: Dictionary = await _setup_env()
	var player: PlayerController = env["player"]
	var driver: PlayerVisualDriver = player.visual_root as PlayerVisualDriver

	var base_pos: Vector3 = driver.get_base_position()
	var base_scale: Vector3 = driver.get_base_scale()

	# Simulate 30 frames of diverse states
	for i in range(30):
		var state: int = i % 8
		driver.update_procedural_visuals(state, 5.0, 0.016, 1)

	driver.reset_to_base()

	var pos_match: bool = driver.position.is_equal_approx(base_pos)
	var scale_match: bool = driver.scale.is_equal_approx(base_scale)

	var ok: bool = pos_match and scale_match
	_assert_test("Repeated state transitions and resets leave zero accumulated transform drift", ok)
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 11: Lock-on and targeting remain functional
# -----------------------------------------------------------------------------
func _test_11_lock_on_and_targeting_remain_functional() -> void:
	var env: Dictionary = await _setup_env()
	var player: PlayerController = env["player"]
	var dummy: LockOnTarget = env["dummy"]

	player.global_position = Vector3(0, 0.1, 0)
	dummy.global_position = Vector3(0, 0.1, -4)

	var lock_ok: bool = player.lock_on.acquire_target()
	var has_target: bool = player.lock_on.is_locked_on and player.lock_on.current_target == dummy
	player.lock_on.unlock()

	var ok: bool = lock_ok and has_target and not player.lock_on.is_locked_on
	_assert_test("Lock-on target acquisition and release remain functional", ok)
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 12: Melee attack and combo remain functional
# -----------------------------------------------------------------------------
func _test_12_melee_attack_and_combo_remain_functional() -> void:
	var env: Dictionary = await _setup_env()
	var player: PlayerController = env["player"]

	var attack_1: bool = player.melee_attack.try_attack()
	var is_attacking: bool = player.melee_attack.is_attacking
	var combo_idx: int = player.melee_attack.combo_index
	player.melee_attack.end_attack()

	var ok: bool = attack_1 and is_attacking and combo_idx == 1
	_assert_test("Melee katana attack initiates correctly with proper combo indexing", ok)
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 13: Dodge and iframes remain functional
# -----------------------------------------------------------------------------
func _test_13_dodge_and_iframes_remain_functional() -> void:
	var env: Dictionary = await _setup_env()
	var player: PlayerController = env["player"]

	var dodge_ok: bool = player.dodge.try_dodge(Vector3.FORWARD)
	var is_dodging: bool = player.dodge.is_dodging
	player.dodge.end_dodge()

	var ok: bool = dodge_ok and is_dodging and not player.dodge.is_dodging
	_assert_test("Dodge roll initiates and clears cleanly without modifying gameplay timing", ok)
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 14: Guard and damage mitigation remain functional
# -----------------------------------------------------------------------------
func _test_14_guard_and_damage_mitigation_remain_functional() -> void:
	var env: Dictionary = await _setup_env()
	var player: PlayerController = env["player"]

	player.guard.start_guard()
	var is_guarding: bool = player.guard.is_guarding

	var res: Dictionary = player.apply_incoming_damage(20.0, player.global_position + Vector3(0, 0, -2))
	var blocked: bool = res["blocked"]
	var mitigated: float = res["mitigated"]
	player.guard.stop_guard()

	var ok: bool = is_guarding and blocked and is_equal_approx(mitigated, 14.0)
	_assert_test("Directional guard blocks frontal attack with 70% damage reduction", ok, "mitigated=%.1f" % [mitigated])
	await _cleanup_env(env)
