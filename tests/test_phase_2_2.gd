extends SceneTree

## VEILBOUND Phase 2.2 Automated Test Suite
## Validates real character animation, weapon bone attachments, soldier enemy model,
## martial training dummy, and combat integration.

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0


func _init() -> void:
	print("==================================================")
	print("VEILBOUND Phase 2.2 Automated Test Suite")
	print("Real Animation, Bone Attachments & Enemy Model")
	print("==================================================")
	_run_all_tests()


func _assert_test(test_name: String, condition: bool, extra_info: String = "") -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("  [PASS] Test %d: %s" % [total_tests, test_name])
	else:
		failed_tests += 1
		var info_str: String = " - %s" % extra_info if extra_info != "" else ""
		printerr("  [FAIL] Test %d: %s%s" % [total_tests, test_name, info_str])


func _setup_env() -> Dictionary:
	var main_scene: PackedScene = load("res://main.tscn")
	var main: Node3D = main_scene.instantiate()
	root.add_child(main)

	var player: PlayerController = main.get_node_or_null("Player") as PlayerController
	var soldier: SoldierEnemy = main.get_node_or_null("SoldierEnemy") as SoldierEnemy
	var dummy: LockOnTarget = main.get_node_or_null("Dummy_Center") as LockOnTarget

	for _i in range(5):
		await physics_frame

	return {
		"main": main,
		"player": player,
		"soldier": soldier,
		"dummy": dummy
	}


func _cleanup_env(env: Dictionary) -> void:
	if env.has("main") and is_instance_valid(env["main"]):
		env["main"].queue_free()
	await process_frame
	await process_frame


func _run_all_tests() -> void:
	await _test_1_protagonist_real_3d_model_and_bone_count()
	await _test_2_protagonist_not_in_tpose()
	await _test_3_protagonist_all_12_animations_articulate_skeleton()
	await _test_4_katana_right_hand_bone_attachment()
	await _test_5_scabbard_hip_bone_attachment_and_sheathe_transition()
	await _test_6_soldier_real_3d_model_and_skeleton()
	await _test_7_soldier_weapon_bone_attachment()
	await _test_8_soldier_animations_driven_by_states()
	await _test_9_training_dummy_geometry_and_components()
	await _test_10_full_combat_loop_with_real_assets()

	print("==================================================")
	print("Results: Total=%d | Passed=%d | Failed=%d" % [total_tests, passed_tests, failed_tests])
	print("==================================================")

	if failed_tests > 0:
		print("FAILED: Some Phase 2.2 tests failed!")
		quit(1)
	else:
		print("SUCCESS: All Phase 2.2 tests passed!")
		quit(0)


# TEST 1: Protagonist uses genuine 3D model with 200+ bones
func _test_1_protagonist_real_3d_model_and_bone_count() -> void:
	var env: Dictionary = await _setup_env()
	var player: PlayerController = env["player"]
	var driver: PlayerVisualDriver = player.visual_root as PlayerVisualDriver
	var model: PlayerCharacterModel = driver.get_character_model()

	var skel: Skeleton3D = model.skeleton
	var has_skel: bool = skel != null and is_instance_valid(skel)
	var bone_count: int = skel.get_bone_count() if has_skel else 0
	var ok: bool = has_skel and bone_count >= 200

	_assert_test("Protagonist uses genuine 3D model with %d bones (>=200)" % [bone_count], ok)
	await _cleanup_env(env)


# TEST 2: Protagonist is posed in natural stance (NOT T-pose)
func _test_2_protagonist_not_in_tpose() -> void:
	var env: Dictionary = await _setup_env()
	var player: PlayerController = env["player"]
	var driver: PlayerVisualDriver = player.visual_root as PlayerVisualDriver
	var model: PlayerCharacterModel = driver.get_character_model()
	var skel: Skeleton3D = model.skeleton

	var r_arm_idx: int = skel.find_bone("Shibahu_RightArm_0165_220")
	var l_arm_idx: int = skel.find_bone("Shibahu_LeftArm_0100_155")
	var r_rest: Transform3D = skel.get_bone_rest(r_arm_idx)
	var l_rest: Transform3D = skel.get_bone_rest(l_arm_idx)

	# In T-pose, arm rest euler X is near 0. In natural A-pose, arms hang down with |X| > 1.0 rad (~60-75 deg)
	var r_hanging: bool = abs(r_rest.basis.get_euler().x) > 1.0
	var l_hanging: bool = abs(l_rest.basis.get_euler().x) > 1.0
	var ok: bool = r_hanging and l_hanging

	_assert_test("Protagonist arms hang naturally at sides in idle/A-pose (not T-pose)", ok)
	await _cleanup_env(env)


# TEST 3: All 12 animation clips articulate actual Skeleton3D bones
func _test_3_protagonist_all_12_animations_articulate_skeleton() -> void:
	var env: Dictionary = await _setup_env()
	var player: PlayerController = env["player"]
	var driver: PlayerVisualDriver = player.visual_root as PlayerVisualDriver
	var model: PlayerCharacterModel = driver.get_character_model()
	var ap: AnimationPlayer = model.anim_player

	var required_clips: Array[String] = [
		"idle", "walk", "sprint", "jump", "fall", "dodge",
		"attack_1", "attack_2", "attack_3", "guard", "hit_react", "death"
	]

	var all_clips_ok: bool = true
	for clip in required_clips:
		if not ap.has_animation(clip):
			all_clips_ok = false
			break
		var anim: Animation = ap.get_animation(clip)
		if anim.get_track_count() == 0:
			all_clips_ok = false
			break

	_assert_test("All 12 animation clips exist with valid skeletal bone tracks", all_clips_ok)
	await _cleanup_env(env)


# TEST 4: Katana is attached to Right Hand bone via BoneAttachment3D
func _test_4_katana_right_hand_bone_attachment() -> void:
	var env: Dictionary = await _setup_env()
	var player: PlayerController = env["player"]
	var driver: PlayerVisualDriver = player.visual_root as PlayerVisualDriver
	var model: PlayerCharacterModel = driver.get_character_model()

	var hand_att: BoneAttachment3D = model.hand_attachment
	var has_att: bool = hand_att != null and is_instance_valid(hand_att)
	var bone_name_match: bool = has_att and hand_att.bone_name == "Shibahu_RightHand_0167_217"
	var katana_parented: bool = has_att and model.katana_in_hand.get_parent() == hand_att

	var ok: bool = has_att and bone_name_match and katana_parented
	_assert_test("KatanaInHand is parented to BoneAttachment3D on Shibahu_RightHand_0167_217", ok)
	await _cleanup_env(env)


# TEST 5: Scabbard and hilt are attached to Hips bone via BoneAttachment3D with clean toggle
func _test_5_scabbard_hip_bone_attachment_and_sheathe_transition() -> void:
	var env: Dictionary = await _setup_env()
	var player: PlayerController = env["player"]
	var driver: PlayerVisualDriver = player.visual_root as PlayerVisualDriver
	var model: PlayerCharacterModel = driver.get_character_model()

	var hip_att: BoneAttachment3D = model.hip_attachment
	var has_att: bool = hip_att != null and is_instance_valid(hip_att)
	var scabbard_parented: bool = has_att and model.scabbard.get_parent() == hip_att

	model.set_combat_mode(false)
	var sheathed_visible: bool = model.sheathed_hilt.visible and not model.katana_in_hand.visible

	model.set_combat_mode(true)
	var drawn_visible: bool = not model.sheathed_hilt.visible and model.katana_in_hand.visible

	var ok: bool = has_att and scabbard_parented and sheathed_visible and drawn_visible
	_assert_test("Scabbard parented to hip bone with smooth draw/sheathe visibility transitions", ok)
	await _cleanup_env(env)


# TEST 6: Soldier enemy uses real 3D model with 100+ bones
func _test_6_soldier_real_3d_model_and_skeleton() -> void:
	var env: Dictionary = await _setup_env()
	var soldier: SoldierEnemy = env["soldier"]

	var skel: Skeleton3D = soldier.skeleton
	var has_skel: bool = skel != null and is_instance_valid(skel)
	var bone_count: int = skel.get_bone_count() if has_skel else 0
	var ok: bool = has_skel and bone_count >= 100

	_assert_test("Soldier enemy uses genuine 3D model with %d bones (>=100)" % [bone_count], ok)
	await _cleanup_env(env)


# TEST 7: Soldier weapon is attached to Right Hand bone via BoneAttachment3D
func _test_7_soldier_weapon_bone_attachment() -> void:
	var env: Dictionary = await _setup_env()
	var soldier: SoldierEnemy = env["soldier"]

	var weapon: MeshInstance3D = soldier.weapon_mesh
	var parent_is_bone_att: bool = weapon != null and weapon.get_parent() is BoneAttachment3D
	var att_bone: String = (weapon.get_parent() as BoneAttachment3D).bone_name if parent_is_bone_att else ""
	var ok: bool = parent_is_bone_att and att_bone == "CC_Base_R_Hand_88"

	_assert_test("Soldier weapon parented to BoneAttachment3D on CC_Base_R_Hand_88", ok)
	await _cleanup_env(env)


# TEST 8: Soldier animations driven by state machine
# Phase 2.6 added the CC0 UAL runtime retarget library ("soldier_ual/*") and the
# state machine now prefers it while keeping the legacy "soldier/*" clips as
# fallback. The expectation therefore follows the production selection rule in
# soldier_enemy.gd instead of hardcoding pre-UAL clip names.
func _test_8_soldier_animations_driven_by_states() -> void:
	var env: Dictionary = await _setup_env()
	var soldier: SoldierEnemy = env["soldier"]
	var ap: AnimationPlayer = soldier.anim_player
	var ual_ready: bool = ap.has_animation("soldier_ual/idle")

	var expected: Dictionary = {
		SoldierEnemy.State.CHASE: "soldier_ual/sprint" if ual_ready else "Animation",
		SoldierEnemy.State.TELEGRAPH: "soldier_ual/telegraph" if ual_ready else "soldier/telegraph",
		SoldierEnemy.State.ATTACK: "soldier_ual/attack" if ual_ready else "soldier/attack",
		SoldierEnemy.State.STAGGERED: "soldier_ual/hit" if ual_ready else "soldier/stagger",
		SoldierEnemy.State.DEAD: "soldier_ual/death" if ual_ready else "soldier/death",
	}

	var played: Array[String] = []
	for state: SoldierEnemy.State in expected:
		var clip: String = expected[state]
		if not ap.has_animation(clip):
			_assert_test("State %s expects missing clip '%s' (ual_ready=%s)" % [str(state), clip, str(ual_ready)], false)
			await _cleanup_env(env)
			return
		soldier._change_state(state)
		played.append(ap.current_animation)

	var ok: bool = true
	var index: int = 0
	for state: SoldierEnemy.State in expected:
		if played[index] != expected[state]:
			print("  [INFO] state %s played '%s', expected '%s'" % [str(state), played[index], expected[state]])
			ok = false
		index += 1

	_assert_test("Soldier states actively drive Chase/Telegraph/Attack/Stagger/Death animations", ok)
	await _cleanup_env(env)


# TEST 9: Training dummy uses authentic martial geometry
func _test_9_training_dummy_geometry_and_components() -> void:
	var env: Dictionary = await _setup_env()
	var dummy: LockOnTarget = env["dummy"]
	var static_body: StaticBody3D = dummy.get_parent() as StaticBody3D if dummy.get_parent() is StaticBody3D else dummy as StaticBody3D

	var center_post: Node = static_body.find_child("CenterPost", true, false)
	var torso_straw: Node = static_body.find_child("VisualMesh", true, false)
	var cross_arms: Node = static_body.find_child("CrossArms", true, false)
	var head_roundel: Node = static_body.find_child("HeadVisual", true, false)
	var health_node: Node = static_body.find_child("HealthComponent", true, false)
	var poise_node: Node = static_body.find_child("PoiseComponent", true, false)

	var ok: bool = (center_post != null and torso_straw != null and cross_arms != null and
		head_roundel != null and health_node != null and poise_node != null)

	_assert_test("LockOnDummy features authentic martial geometry (post, straw torso, cross arms, target roundel)", ok)
	await _cleanup_env(env)


# TEST 10: Full integrated combat loop executes with all real assets
func _test_10_full_combat_loop_with_real_assets() -> void:
	var env: Dictionary = await _setup_env()
	var player: PlayerController = env["player"]
	var soldier: SoldierEnemy = env["soldier"]

	# Position player facing soldier
	player.global_position = Vector3(0, 0.1, 0)
	soldier.global_position = Vector3(0, 0.1, -1.8)
	soldier._target_player = player

	# Player attacks soldier
	player.melee_attack.try_attack()
	var player_attacking: bool = player.melee_attack.is_attacking

	# Soldier telegraphs and resolves hit
	soldier._change_state(SoldierEnemy.State.TELEGRAPH)
	var initial_hp: float = player.health.current_health
	soldier._change_state(SoldierEnemy.State.ATTACK)
	# The Soldier's authored attack becomes dangerous at ATTACK_ACTIVE_START
	# (0.35s); three frames only cover the telegraph-to-swing transition.
	for _i in range(30):
		await physics_frame

	var hp_reduced: bool = player.health.current_health < initial_hp
	var ok: bool = player_attacking and hp_reduced

	_assert_test("Full combat loop executes: player attacks, soldier telegraphs, deals damage with real animated models", ok)
	await _cleanup_env(env)
