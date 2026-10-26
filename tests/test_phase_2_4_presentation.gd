extends SceneTree

var _total: int = 0
var _passed: int = 0


func _init() -> void:
	call_deferred("_run")


func _assert_test(name: String, condition: bool, details: String = "") -> void:
	_total += 1
	if condition:
		_passed += 1
		print("[PASS] ", name)
	else:
		print("[FAIL] ", name, " ", details)


func _run() -> void:
	var main: Node3D = (load("res://main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(main)
	for _i in range(8):
		await physics_frame

	var player: PlayerController = main.get_node("Player") as PlayerController
	var soldier: SoldierEnemy = main.get_node("SoldierEnemy") as SoldierEnemy
	var hud: CombatHUD = main.get_node("CombatHUD") as CombatHUD
	var model: PlayerCharacterModel = player.get_node("VisualRoot/PlayerCharacterModel") as PlayerCharacterModel
	var health_bar: ProgressBar = hud.health_bar
	var health_trail: ProgressBar = hud.health_trail_bar
	var stamina_bar: ProgressBar = hud.stamina_bar
	var target_bar: ProgressBar = hud.target_health_bar
	var target_container: Control = hud.target_container

	_assert_test("HUD starts synchronized with player health", is_equal_approx(health_bar.value, player.health.get_health()) and is_equal_approx(health_bar.max_value, player.health.get_max_health()))
	_assert_test("HUD starts synchronized with player stamina", is_equal_approx(stamina_bar.value, player.stamina.get_stamina()) and is_equal_approx(stamina_bar.max_value, player.stamina.get_max_stamina()))

	player.health.take_damage(20.0)
	_assert_test("Player HP decreases immediately in HUD", is_equal_approx(health_bar.value, 80.0) and is_equal_approx(health_trail.value, 100.0))
	for _i in range(15):
		await physics_frame
	_assert_test("Player HP trail settles without a competing tween", health_trail.value < 100.0 and health_trail.value >= 80.0)

	player.stamina.try_consume(25.0)
	_assert_test("Stamina consumption is rendered immediately", is_equal_approx(stamina_bar.value, 75.0))
	player.health.take_damage(55.0)
	var low_health_accent: Control = hud.low_health_accent
	_assert_test("Low health state is visible but contained", low_health_accent.visible and not target_container.visible)

	# Isolate the genuine Soldier target so the HUD assertion exercises the
	# actual LockOnComponent.current_target rather than a nearby dummy.
	var soldier_target: LockOnTarget = soldier.get_node("LockOnTarget") as LockOnTarget
	for candidate_node in get_nodes_in_group("lock_on_targets"):
		var candidate: LockOnTarget = candidate_node as LockOnTarget
		if candidate != null and candidate != soldier_target:
			candidate.is_targetable = false
	player.global_position = Vector3(0.0, 0.1, -4.0)
	soldier.global_position = Vector3(0.0, 0.1, -7.0)
	player.lock_on.acquire_target()
	_assert_test("Target HUD follows current_lock_on target", player.lock_on.current_target == soldier_target and target_container.visible and hud.target_name_label.text == "SOLDIER")
	_assert_test("Target HP matches Soldier health", is_equal_approx(target_bar.value, soldier.health.get_health()) and is_equal_approx(target_bar.max_value, soldier.health.get_max_health()))
	soldier.health.take_damage(10.0)
	_assert_test("Target HP responds to the bound target signal", is_equal_approx(target_bar.value, 70.0))
	soldier.health.take_damage(soldier.health.get_health())
	_assert_test("Target death hides stale target UI immediately", not target_container.visible and hud._connected_target == null)

	# Player clip priority: an incoming hit cannot be replaced by the next
	# locomotion request on the following physics tick.
	player.health.reset_health()
	player.visual_root.trigger_hit_reaction()
	await physics_frame
	_assert_test("Player hit reaction survives locomotion update", model.anim_player.current_animation == "hit_react")

	# Confirm the imported skeleton is genuinely deforming and the attachment
	# uses the discovered right-hand and hip bones.
	var hand_idx: int = model.skeleton.find_bone("Shibahu_RightHand_0167_217")
	var hip_idx: int = model.skeleton.find_bone("Shibahu_Hips_00_245")
	_assert_test("Player uses the real hand and hip bones", hand_idx >= 0 and hip_idx >= 0)
	var left_shoulder_idx: int = model.skeleton.find_bone("Shibahu_LeftShoulder_099_156")
	var right_shoulder_idx: int = model.skeleton.find_bone("Shibahu_RightShoulder_0164_221")
	var left_hand_idx: int = model.skeleton.find_bone("Shibahu_LeftHand_0102_152")
	var idle_pose_valid: bool = true
	model.play_animation("idle", 0.0, true)
	var idle_clip: Animation = model.anim_player.get_animation("idle")
	for sample_index in range(6):
		model.anim_player.advance(idle_clip.length / 6.0)
		var left_hand_y: float = model.skeleton.get_bone_global_pose(left_hand_idx).origin.y
		var right_hand_y: float = model.skeleton.get_bone_global_pose(hand_idx).origin.y
		var left_shoulder_y: float = model.skeleton.get_bone_global_pose(left_shoulder_idx).origin.y
		var right_shoulder_y: float = model.skeleton.get_bone_global_pose(right_shoulder_idx).origin.y
		idle_pose_valid = idle_pose_valid and left_hand_y < left_shoulder_y - 10.0 and right_hand_y < right_shoulder_y - 10.0
	_assert_test("Player idle loop keeps both arms below the shoulders", idle_pose_valid)
	model.set_combat_mode(true)
	_assert_test("Drawn katana hides the complete sheathed set", model.katana_in_hand.visible and not model.scabbard.visible and not model.sheathed_hilt.visible)
	model.set_combat_mode(false)
	_assert_test("Sheathed katana hides the held mesh", not model.katana_in_hand.visible and model.scabbard.visible and model.sheathed_hilt.visible)
	var idle_pose: Quaternion = model.skeleton.get_bone_pose_rotation(hand_idx)
	model.play_animation("attack_1", 0.0, true)
	model.anim_player.advance(0.28)
	var attack_pose: Quaternion = model.skeleton.get_bone_pose_rotation(hand_idx)
	_assert_test("Attack clip changes the skinned hand pose", not _same_quaternion(idle_pose, attack_pose))

	# Soldier attack timing follows the visible attack clip instead of firing on
	# state entry, while the clip still reaches recovery cleanly.
	player.health.reset_health()
	soldier.health.reset_health()
	soldier_target.is_targetable = true
	soldier.current_state = SoldierEnemy.State.IDLE
	soldier.global_position = player.global_position + Vector3(0.0, 0.0, -1.4)
	soldier._target_player = player
	soldier._change_state(SoldierEnemy.State.ATTACK)
	var hp_before: float = player.health.get_health()
	soldier._physics_process(0.10)
	_assert_test("Soldier does not damage before attack active window", is_equal_approx(player.health.get_health(), hp_before))
	soldier._physics_process(0.30)
	_assert_test("Soldier damage lands during visible strike window", player.health.get_health() < hp_before)
	soldier._physics_process(0.30)
	_assert_test("Soldier leaves attack after the authored clip duration", soldier.current_state == SoldierEnemy.State.RECOVERY)
	var run_animation: Animation = soldier.anim_player.get_animation("Animation")
	_assert_test("Soldier patrol clip loops instead of freezing", run_animation != null and run_animation.loop_mode == Animation.LOOP_LINEAR)

	var soldier_arm_idx: int = soldier.skeleton.find_bone("CC_Base_R_Upperarm_90")
	_assert_test("Soldier attack track references a real arm bone", soldier_arm_idx >= 0)
	soldier._change_state(SoldierEnemy.State.ATTACK)
	var soldier_pose_before: Quaternion = soldier.skeleton.get_bone_pose_rotation(soldier_arm_idx)
	soldier.anim_player.advance(0.50)
	var soldier_pose_after: Quaternion = soldier.skeleton.get_bone_pose_rotation(soldier_arm_idx)
	_assert_test("Soldier attack clip deforms the imported skeleton", not _same_quaternion(soldier_pose_before, soldier_pose_after))

	print("Phase 2.4 presentation tests: %d/%d passed" % [_passed, _total])
	main.free()
	quit(0 if _passed == _total else 1)


func _same_quaternion(a: Quaternion, b: Quaternion) -> bool:
	return absf(a.x - b.x) < 0.0001 and absf(a.y - b.y) < 0.0001 and absf(a.z - b.z) < 0.0001 and absf(a.w - b.w) < 0.0001
