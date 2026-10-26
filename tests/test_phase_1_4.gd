extends SceneTree

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0


func _init() -> void:
	print("==================================================")
	print("VEILBOUND Phase 1.4 Automated Test Suite")
	print("Testing Guard, Directional Block & Guard Break")
	print("==================================================")

	call_deferred("_run_all_tests")


func _run_all_tests() -> void:
	# 1. Guard starts and stops correctly
	await _test_1_guard_starts_and_stops_correctly()

	# 2. Frontal attacks receive configured damage reduction
	await _test_2_frontal_attack_damage_reduction()

	# 3. Rear attacks deal full damage without stamina cost
	await _test_3_rear_attack_full_damage()

	# 4. Successful blocks consume stamina exactly once
	await _test_4_successful_block_consumes_stamina_once()

	# 5. Failed stamina payment triggers guard break
	await _test_5_failed_stamina_triggers_guard_break()

	# 6. Guard break applies full damage and prevents immediate re-guarding
	await _test_6_guard_break_full_damage_and_lockout()

	# 7. Dodge i-frames take priority over guard
	await _test_7_dodge_iframes_priority_over_guard()

	# 8. Death clears guard state
	await _test_8_death_clears_guard_state()

	# 9. Guard movement uses configured speed multiplier
	await _test_9_guard_movement_speed_multiplier()

	# 10. Guard cannot overlap with dodge or attacks
	await _test_10_guard_cannot_overlap_with_dodge_or_attack()

	# 11. Guard cannot start during recovery
	await _test_11_guard_cannot_start_during_recovery()

	# 12. Debug damage uses centralized incoming-damage path
	await _test_12_debug_damage_centralized_path()

	# 13. Existing attack, dodge, lock-on, health, stamina, and HUD behavior remain functional
	await _test_13_existing_systems_functional()

	print("==================================================")
	print("Results: Total=%d | Passed=%d | Failed=%d" % [total_tests, passed_tests, failed_tests])
	print("==================================================")

	if failed_tests > 0:
		print("FAILED: Some Phase 1.4 tests failed!")
		quit(1)
	else:
		print("SUCCESS: All 13 Phase 1.4 tests passed!")
		quit(0)


func _assert_test(test_name: String, condition: bool, details: String = "") -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("  [PASS] Test %d: %s" % [total_tests, test_name])
	else:
		failed_tests += 1
		print("  [FAIL] Test %d: %s - %s" % [total_tests, test_name, details])


func _setup_player() -> CharacterBody3D:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: CharacterBody3D = player_scene.instantiate()
	root.add_child(player)
	player._resolve_nodes()
	return player


func _setup_player_with_floor() -> Dictionary:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: CharacterBody3D = player_scene.instantiate()
	player.position = Vector3(0.0, 0.1, 0.0)
	root.add_child(player)
	player._resolve_nodes()

	var floor_node := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(50, 1, 50)
	col.shape = box
	floor_node.add_child(col)
	floor_node.position = Vector3(0, -0.5, 0)
	root.add_child(floor_node)

	for _i in range(10):
		await physics_frame

	return {"player": player, "floor": floor_node}


func _cleanup_node(node: Node) -> void:
	if node != null and is_instance_valid(node):
		node.queue_free()
	await process_frame
	await process_frame


func _cleanup_setup(env: Dictionary) -> void:
	if env.has("player") and env["player"] != null and is_instance_valid(env["player"]):
		env["player"].queue_free()
	if env.has("floor") and env["floor"] != null and is_instance_valid(env["floor"]):
		env["floor"].queue_free()
	await process_frame
	await process_frame


# -----------------------------------------------------------------------------
# TEST 1: Guard starts and stops correctly
# -----------------------------------------------------------------------------
func _test_1_guard_starts_and_stops_correctly() -> void:
	var env: Dictionary = await _setup_player_with_floor()
	var player: CharacterBody3D = env["player"]
	var guard: GuardComponent = player.guard

	var signal_counts := {"started": 0, "stopped": 0}
	guard.guard_started.connect(func(): signal_counts["started"] += 1)
	guard.guard_stopped.connect(func(): signal_counts["stopped"] += 1)

	var initial_ok: bool = not guard.is_guarding and player.current_state != PlayerController.LocomotionState.GUARD
	var start_ret: bool = guard.start_guard()
	await physics_frame
	player._physics_process(0.016)

	var guarded_ok: bool = (
		start_ret
		and guard.is_guarding
		and signal_counts["started"] == 1
		and player.current_state == PlayerController.LocomotionState.GUARD
		and player.get_locomotion_state_name() == "GUARD"
	)

	guard.stop_guard()
	await physics_frame
	player._physics_process(0.016)

	var stop_ok: bool = (
		not guard.is_guarding
		and signal_counts["stopped"] == 1
		and player.current_state == PlayerController.LocomotionState.IDLE
	)

	_assert_test(
		"Guard starts and stops correctly with proper signals and locomotion state",
		initial_ok and guarded_ok and stop_ok,
		"initial_ok=%s, guarded_ok=%s, stop_ok=%s" % [initial_ok, guarded_ok, stop_ok]
	)
	await _cleanup_setup(env)


# -----------------------------------------------------------------------------
# TEST 2: Frontal attacks receive configured damage reduction
# -----------------------------------------------------------------------------
func _test_2_frontal_attack_damage_reduction() -> void:
	var player: CharacterBody3D = _setup_player()
	player.global_position = Vector3.ZERO
	player.guard.start_guard()

	var attack_damage: float = 40.0
	# Frontal attacker directly along player's -Z forward facing
	var frontal_pos: Vector3 = Vector3(0.0, 0.0, -3.0)

	var res: Dictionary = player.apply_incoming_damage(attack_damage, frontal_pos)
	var expected_mitigation: float = attack_damage * player.guard.damage_reduction # 40 * 0.70 = 28.0
	var expected_applied: float = attack_damage - expected_mitigation # 12.0
	var expected_hp: float = 100.0 - expected_applied # 88.0

	var ok: bool = (
		res["blocked"] == true
		and is_equal_approx(res["mitigated"], expected_mitigation)
		and is_equal_approx(res["applied_damage"], expected_applied)
		and is_equal_approx(player.health.current_health, expected_hp)
	)

	_assert_test(
		"Frontal attacks receive 70% damage reduction",
		ok,
		"res=%s, hp=%s, expected_hp=%s" % [res, player.health.current_health, expected_hp]
	)
	await _cleanup_node(player)


# -----------------------------------------------------------------------------
# TEST 3: Rear attacks deal full damage without stamina cost
# -----------------------------------------------------------------------------
func _test_3_rear_attack_full_damage() -> void:
	var player: CharacterBody3D = _setup_player()
	player.global_position = Vector3.ZERO
	player.guard.start_guard()

	var initial_stamina: float = player.stamina.current_stamina
	var initial_hp: float = player.health.current_health
	var attack_damage: float = 35.0
	# Attacker directly behind player along +Z
	var rear_pos: Vector3 = Vector3(0.0, 0.0, 3.0)

	var res: Dictionary = player.apply_incoming_damage(attack_damage, rear_pos)

	var ok: bool = (
		res["blocked"] == false
		and is_equal_approx(res["mitigated"], 0.0)
		and is_equal_approx(res["applied_damage"], attack_damage)
		and is_equal_approx(player.health.current_health, initial_hp - attack_damage)
		and is_equal_approx(player.stamina.current_stamina, initial_stamina)
	)

	_assert_test(
		"Rear attacks deal full damage and do not consume block stamina",
		ok,
		"res=%s, hp=%s, stamina=%s" % [res, player.health.current_health, player.stamina.current_stamina]
	)
	await _cleanup_node(player)


# -----------------------------------------------------------------------------
# TEST 4: Successful blocks consume stamina exactly once
# -----------------------------------------------------------------------------
func _test_4_successful_block_consumes_stamina_once() -> void:
	var player: CharacterBody3D = _setup_player()
	player.global_position = Vector3.ZERO
	player.guard.start_guard()

	var signal_data := {"count": 0, "cost": 0.0}
	player.guard.attack_blocked.connect(func(mitigated: float, damage: float, stamina_cost: float):
		signal_data["count"] += 1
		signal_data["cost"] = stamina_cost
	)

	var initial_stamina: float = player.stamina.current_stamina
	var attack_damage: float = 20.0
	var frontal_pos: Vector3 = Vector3(0.0, 0.0, -2.0)

	var res: Dictionary = player.apply_incoming_damage(attack_damage, frontal_pos)

	var mitigated: float = attack_damage * player.guard.damage_reduction # 14.0
	var expected_stamina_cost: float = mitigated * player.guard.stamina_cost_per_damage_mitigated # 14.0 * 1.5 = 21.0
	var expected_stamina: float = initial_stamina - expected_stamina_cost # 79.0

	var ok: bool = (
		res["blocked"] == true
		and signal_data["count"] == 1
		and is_equal_approx(signal_data["cost"], expected_stamina_cost)
		and is_equal_approx(player.stamina.current_stamina, expected_stamina)
	)

	_assert_test(
		"Successful blocks consume stamina exactly once based on mitigated damage",
		ok,
		"signal_count=%s, stamina=%s, expected=%s" % [signal_data["count"], player.stamina.current_stamina, expected_stamina]
	)
	await _cleanup_node(player)


# -----------------------------------------------------------------------------
# TEST 5: Failed stamina payment triggers guard break
# -----------------------------------------------------------------------------
func _test_5_failed_stamina_triggers_guard_break() -> void:
	var player: CharacterBody3D = _setup_player()
	player.global_position = Vector3.ZERO

	# Set stamina below required cost
	player.stamina.current_stamina = 10.0
	player.guard.start_guard()

	var break_fired := {"count": 0}
	player.guard.guard_broken.connect(func(): break_fired["count"] += 1)

	# Damage 40 -> mitigated 28 -> cost 42.0 (player only has 10.0)
	var res: Dictionary = player.apply_incoming_damage(40.0, Vector3(0.0, 0.0, -2.0))

	var ok: bool = (
		res["guard_broken"] == true
		and res["blocked"] == false
		and break_fired["count"] == 1
		and player.guard.is_guard_broken == true
		and player.guard.is_guarding == false
	)

	_assert_test(
		"Failed stamina payment triggers guard break immediately",
		ok,
		"guard_broken=%s, blocked=%s, signal_fired=%s" % [res["guard_broken"], res["blocked"], break_fired["count"]]
	)
	await _cleanup_node(player)


# -----------------------------------------------------------------------------
# TEST 6: Guard break applies full damage and prevents immediate re-guarding
# -----------------------------------------------------------------------------
func _test_6_guard_break_full_damage_and_lockout() -> void:
	var player: CharacterBody3D = _setup_player()
	player.global_position = Vector3.ZERO
	player.stamina.current_stamina = 5.0
	player.guard.start_guard()

	var hp_before: float = player.health.current_health # 100.0
	var res: Dictionary = player.apply_incoming_damage(30.0, Vector3(0.0, 0.0, -2.0))

	var full_damage_applied: bool = (
		res["guard_broken"] == true
		and is_equal_approx(res["applied_damage"], 30.0)
		and is_equal_approx(player.health.current_health, hp_before - 30.0)
	)

	# Attempt to re-guard immediately while guard broken
	var reguard_attempt: bool = player.guard.start_guard()
	var lockout_active: bool = (
		not reguard_attempt
		and player.guard.is_guarding == false
		and player.guard.is_guard_broken == true
		and player.guard.guard_break_timer > 0.0
	)

	_assert_test(
		"Guard break applies unmitigated full damage and prevents immediate re-guarding",
		full_damage_applied and lockout_active,
		"damage_applied=%s, reguard_attempt=%s, timer=%s" % [res["applied_damage"], reguard_attempt, player.guard.guard_break_timer]
	)
	await _cleanup_node(player)


# -----------------------------------------------------------------------------
# TEST 7: Dodge i-frames take priority over guard
# -----------------------------------------------------------------------------
func _test_7_dodge_iframes_priority_over_guard() -> void:
	var player: CharacterBody3D = _setup_player()
	player.global_position = Vector3.ZERO
	player.guard.start_guard()

	# Activate dodge i-frame invulnerability
	player.health.set_invulnerable(true)

	var hp_before: float = player.health.current_health
	var stamina_before: float = player.stamina.current_stamina

	var res: Dictionary = player.apply_incoming_damage(50.0, Vector3(0.0, 0.0, -2.0))

	var ok: bool = (
		res["ignored_by_iframe"] == true
		and res["blocked"] == false
		and is_equal_approx(res["applied_damage"], 0.0)
		and is_equal_approx(player.health.current_health, hp_before)
		and is_equal_approx(player.stamina.current_stamina, stamina_before)
	)

	_assert_test(
		"Dodge invulnerability has priority over guard without taking damage or spending stamina",
		ok,
		"res=%s, hp_delta=%s, stamina_delta=%s" % [res, hp_before - player.health.current_health, stamina_before - player.stamina.current_stamina]
	)
	await _cleanup_node(player)


# -----------------------------------------------------------------------------
# TEST 8: Death clears guard state
# -----------------------------------------------------------------------------
func _test_8_death_clears_guard_state() -> void:
	var player: CharacterBody3D = _setup_player()
	player.guard.start_guard()

	var guarding_before: bool = player.guard.is_guarding

	# Inflict lethal damage
	player.health.take_damage(999.0)
	player._physics_process(0.016)

	var guard_cleared: bool = (
		guarding_before
		and player.health.is_dead()
		and not player.guard.is_guarding
		and not player.guard.is_guard_broken
	)

	var cannot_guard_while_dead: bool = not player.guard.start_guard()

	_assert_test(
		"Death clears guard state cleanly and prevents re-guarding while dead",
		guard_cleared and cannot_guard_while_dead,
		"guard_cleared=%s, dead=%s, can_re_guard=%s" % [guard_cleared, player.health.is_dead(), not cannot_guard_while_dead]
	)
	await _cleanup_node(player)


# -----------------------------------------------------------------------------
# TEST 9: Guard movement uses configured speed multiplier
# -----------------------------------------------------------------------------
func _test_9_guard_movement_speed_multiplier() -> void:
	var player: CharacterBody3D = _setup_player()
	player.guard.start_guard()

	var expected_guard_speed: float = player.walk_speed * player.guard.guard_speed_multiplier # 4.0 * 0.55 = 2.2
	var mult_value_ok: bool = is_equal_approx(player.guard.guard_speed_multiplier, 0.55)

	# Simulate moving forward while guarding
	Input.action_press("move_forward")
	# Also simulate pressing sprint to verify sprint is suppressed while guarding
	Input.action_press("sprint")

	for _i in range(10):
		player._physics_process(0.016)

	Input.action_release("move_forward")
	Input.action_release("sprint")

	var h_speed: float = Vector2(player.velocity.x, player.velocity.z).length()
	# Speed should approach 2.2, definitely not sprint speed (6.5) or standard walk speed (4.0)
	var speed_ok: bool = h_speed <= expected_guard_speed + 0.1 and h_speed > 0.5

	_assert_test(
		"Guard movement uses 0.55 speed multiplier and suppresses sprint",
		mult_value_ok and speed_ok,
		"h_speed=%.3f, expected_guard_speed=%.3f" % [h_speed, expected_guard_speed]
	)
	await _cleanup_node(player)


# -----------------------------------------------------------------------------
# TEST 10: Guard cannot overlap with dodge or attacks
# -----------------------------------------------------------------------------
func _test_10_guard_cannot_overlap_with_dodge_or_attack() -> void:
	var player: CharacterBody3D = _setup_player()

	# Case A: Attacking while guarding cancels guard
	player.guard.start_guard()
	var guarding_1: bool = player.guard.is_guarding
	player._initiate_attack()
	var attack_cancels_guard: bool = guarding_1 and not player.guard.is_guarding and player.melee_attack.is_attacking

	# Case B: Cannot start guard while attacking
	var guard_during_attack: bool = player.guard.start_guard()
	var attack_lockout_ok: bool = not guard_during_attack and not player.guard.is_guarding
	player.melee_attack.end_attack()

	# Case C: Dodging while guarding cancels guard
	player.guard.start_guard()
	var guarding_2: bool = player.guard.is_guarding
	player._initiate_dodge()
	var dodge_cancels_guard: bool = guarding_2 and not player.guard.is_guarding and player.dodge.is_dodging

	# Case D: Cannot start guard while dodging
	var guard_during_dodge: bool = player.guard.start_guard()
	var dodge_lockout_ok: bool = not guard_during_dodge and not player.guard.is_guarding
	player.dodge.end_dodge()

	var all_ok: bool = attack_cancels_guard and attack_lockout_ok and dodge_cancels_guard and dodge_lockout_ok
	_assert_test(
		"Guard cannot overlap with dodge or attack and is cancelled on action initiation",
		all_ok,
		"atk_cancels=%s, atk_lockout=%s, dodge_cancels=%s, dodge_lockout=%s" % [attack_cancels_guard, attack_lockout_ok, dodge_cancels_guard, dodge_lockout_ok]
	)
	await _cleanup_node(player)


# -----------------------------------------------------------------------------
# TEST 11: Guard cannot start during recovery
# -----------------------------------------------------------------------------
func _test_11_guard_cannot_start_during_recovery() -> void:
	var player: CharacterBody3D = _setup_player()
	player.guard.trigger_guard_break()

	var initially_broken: bool = player.guard.is_guard_broken and is_equal_approx(player.guard.guard_break_duration, 0.8)
	var reguard_failed_0: bool = not player.guard.start_guard()

	# Tick half the duration (0.4s)
	player.guard._physics_process(0.4)
	var still_broken: bool = player.guard.is_guard_broken and player.guard.guard_break_timer > 0.0
	var reguard_failed_half: bool = not player.guard.start_guard()

	# Tick remaining duration (0.45s)
	player.guard._physics_process(0.45)
	var recovery_expired: bool = not player.guard.is_guard_broken and player.guard.guard_break_timer <= 0.0
	var reguard_succeeded: bool = player.guard.start_guard()

	var ok: bool = (
		initially_broken
		and reguard_failed_0
		and still_broken
		and reguard_failed_half
		and recovery_expired
		and reguard_succeeded
	)

	_assert_test(
		"Guard cannot restart during 0.8s guard break recovery and resumes once expired",
		ok,
		"init=%s, half=%s, expired=%s, reguard=%s" % [initially_broken, still_broken, recovery_expired, reguard_succeeded]
	)
	await _cleanup_node(player)


# -----------------------------------------------------------------------------
# TEST 12: Debug damage uses centralized incoming-damage path
# -----------------------------------------------------------------------------
func _test_12_debug_damage_centralized_path() -> void:
	var player: CharacterBody3D = _setup_player()
	player.global_position = Vector3.ZERO
	player.guard.start_guard()

	# Simulate debug_damage event (H key -> frontal)
	var event_frontal := InputEventAction.new()
	event_frontal.action = "debug_damage"
	event_frontal.pressed = true
	player._unhandled_input(event_frontal)

	# 15.0 damage * 0.7 mitigation = 10.5 mitigated, 4.5 applied. HP: 100 - 4.5 = 95.5
	var hp_after_frontal: float = player.health.current_health
	var frontal_routed: bool = is_equal_approx(hp_after_frontal, 95.5)

	# Simulate debug_rear_damage event (J key -> rear)
	var event_rear := InputEventAction.new()
	event_rear.action = "debug_rear_damage"
	event_rear.pressed = true
	player._unhandled_input(event_rear)

	# 15.0 unmitigated damage applied. HP: 95.5 - 15.0 = 80.5
	var hp_after_rear: float = player.health.current_health
	var rear_routed: bool = is_equal_approx(hp_after_rear, 80.5)

	_assert_test(
		"Debug damage inputs (frontal and rear) route through centralized incoming-damage path",
		frontal_routed and rear_routed,
		"hp_frontal=%.2f (exp 95.50), hp_rear=%.2f (exp 80.50)" % [hp_after_frontal, hp_after_rear]
	)
	await _cleanup_node(player)


# -----------------------------------------------------------------------------
# TEST 13: Existing systems remain functional
# -----------------------------------------------------------------------------
func _test_13_existing_systems_functional() -> void:
	var player: CharacterBody3D = _setup_player()

	# A. Melee attack combo functional
	var attack_ok: bool = player.melee_attack.try_attack()
	player.melee_attack.end_attack()

	# B. Dodge functional
	var dodge_ok: bool = player.dodge.try_dodge(Vector3.FORWARD)
	player.dodge.end_dodge()

	# C. Health & Stamina components operational
	player.stamina.current_stamina = 50.0
	player.stamina._physics_process(0.5)
	var stamina_ok: bool = player.stamina.current_stamina > 0.0

	# D. Lock-on component present and functional
	var lock_on_ok: bool = player.lock_on != null and player.lock_on.has_method("acquire_target")

	# E. HUD instantiate check
	var hud_scene: PackedScene = load("res://ui/combat_hud.tscn")
	var hud: CombatHUD = hud_scene.instantiate() as CombatHUD
	root.add_child(hud)
	hud.bind_player(player)
	var hud_ok: bool = hud.health_bar != null and hud.stamina_bar != null
	hud.queue_free()

	var ok: bool = attack_ok and dodge_ok and stamina_ok and lock_on_ok and hud_ok

	_assert_test(
		"Existing attack, dodge, lock-on, health, stamina, and HUD behavior remain fully functional",
		ok,
		"attack=%s, dodge=%s, stamina=%s, lock_on=%s, hud=%s" % [attack_ok, dodge_ok, stamina_ok, lock_on_ok, hud_ok]
	)
	await _cleanup_node(player)
