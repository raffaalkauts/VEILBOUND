extends SceneTree

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0


func _init() -> void:
	print("==================================================")
	print("VEILBOUND Phase 1.5 Automated Test Suite")
	print("Testing Hit Reactions, Poise & Stagger Mechanics")
	print("==================================================")

	call_deferred("_run_all_tests")


func _run_all_tests() -> void:
	# --- UNIT & POISE COMPONENT TESTS (1 to 9) ---
	_test_1_initial_poise_equals_maximum()
	_test_2_valid_posture_damage_reduces_poise()
	_test_3_poise_never_falls_below_zero()
	_test_4_invalid_posture_damage_rejected()
	_test_5_stagger_triggers_once_when_depleted()
	_test_6_hits_during_stagger_do_not_duplicate_stagger()
	_test_7_posture_recovery_waits_for_delay()
	_test_8_poise_recovers_at_configured_rate()
	_test_9_poise_recovery_stops_at_maximum()

	# --- INTEGRATION & HIT REGISTRATION TESTS (10 to 18) ---
	await _test_10_melee_attacks_apply_configured_posture_damage()
	await _test_11_target_receives_posture_damage_once_per_swing()
	await _test_12_later_combo_swings_apply_posture_damage()
	await _test_13_target_without_poise_takes_health_damage()
	await _test_14_dead_targets_cannot_be_staggered_or_damaged()
	await _test_15_stagger_ends_after_duration_and_restores_state()
	await _test_16_repeated_reactions_do_not_accumulate_transforms()
	await _test_17_lock_on_valid_during_stagger_and_releases_on_death()
	await _test_18_existing_combat_systems_remain_functional()

	print("==================================================")
	print("Results: Total=%d | Passed=%d | Failed=%d" % [total_tests, passed_tests, failed_tests])
	print("==================================================")

	if failed_tests > 0:
		print("FAILED: Some Phase 1.5 tests failed!")
		quit(1)
	else:
		print("SUCCESS: All 18 Phase 1.5 tests passed!")
		quit(0)


func _assert_test(test_name: String, condition: bool, details: String = "") -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("  [PASS] Test %d: %s" % [total_tests, test_name])
	else:
		failed_tests += 1
		print("  [FAIL] Test %d: %s - %s" % [total_tests, test_name, details])


func _setup_player(with_floor: bool = true) -> CharacterBody3D:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: CharacterBody3D = player_scene.instantiate()
	player.position = Vector3(0.0, 0.1, 0.0)
	root.add_child(player)
	player._resolve_nodes()

	if with_floor:
		var floor_node := StaticBody3D.new()
		floor_node.name = "TestFloor"
		var col := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(50, 1, 50)
		col.shape = box
		floor_node.add_child(col)
		floor_node.position = Vector3(0, -0.5, 0)
		root.add_child(floor_node)

	return player


func _setup_dummy(pos: Vector3 = Vector3(0.0, 0.0, -1.5)) -> LockOnTarget:
	var dummy_scene: PackedScene = load("res://characters/enemies/lock_on_dummy.tscn")
	var dummy: LockOnTarget = dummy_scene.instantiate() as LockOnTarget
	dummy.position = pos
	root.add_child(dummy)
	return dummy


func _cleanup_nodes(nodes: Array) -> void:
	for n in nodes:
		if n != null and is_instance_valid(n):
			n.queue_free()
	var floor_node: Node = root.get_node_or_null("TestFloor")
	if floor_node != null and is_instance_valid(floor_node):
		floor_node.queue_free()
	await process_frame
	await process_frame


# -----------------------------------------------------------------------------
# TEST 1: Initial poise equals maximum poise
# -----------------------------------------------------------------------------
func _test_1_initial_poise_equals_maximum() -> void:
	var poise := PoiseComponent.new()
	poise._ready()

	var ok: bool = (
		is_equal_approx(poise.current_poise, poise.max_poise)
		and is_equal_approx(poise.current_poise, 100.0)
		and not poise.is_staggered()
	)
	_assert_test("Initial poise equals maximum poise (100.0)", ok, "poise=%.1f, max=%.1f" % [poise.current_poise, poise.max_poise])
	poise.free()


# -----------------------------------------------------------------------------
# TEST 2: Valid posture damage reduces poise
# -----------------------------------------------------------------------------
func _test_2_valid_posture_damage_reduces_poise() -> void:
	var poise := PoiseComponent.new()
	poise._ready()

	var signal_data := {"fired": false, "current": 0.0, "max": 0.0}
	poise.poise_changed.connect(func(c: float, m: float):
		signal_data["fired"] = true
		signal_data["current"] = c
		signal_data["max"] = m
	)

	var applied: bool = poise.apply_posture_damage(25.0)
	var ok: bool = (
		applied
		and is_equal_approx(poise.current_poise, 75.0)
		and signal_data["fired"]
		and is_equal_approx(signal_data["current"], 75.0)
	)
	_assert_test("Valid posture damage reduces poise and emits poise_changed", ok, "applied=%s, poise=%.1f" % [applied, poise.current_poise])
	poise.free()


# -----------------------------------------------------------------------------
# TEST 3: Poise never falls below zero
# -----------------------------------------------------------------------------
func _test_3_poise_never_falls_below_zero() -> void:
	var poise := PoiseComponent.new()
	poise._ready()

	poise.apply_posture_damage(200.0)
	var ok: bool = is_equal_approx(poise.current_poise, 0.0)
	_assert_test("Poise never falls below zero when taking excessive posture damage", ok, "poise=%.1f" % [poise.current_poise])
	poise.free()


# -----------------------------------------------------------------------------
# TEST 4: Invalid posture damage is rejected
# -----------------------------------------------------------------------------
func _test_4_invalid_posture_damage_rejected() -> void:
	var poise := PoiseComponent.new()
	poise._ready()

	var neg_ret: bool = poise.apply_posture_damage(-15.0)
	var zero_ret: bool = poise.apply_posture_damage(0.0)
	var nan_ret: bool = poise.apply_posture_damage(NAN)

	var ok: bool = (
		not neg_ret
		and not zero_ret
		and not nan_ret
		and is_equal_approx(poise.current_poise, 100.0)
	)
	_assert_test("Invalid or negative posture damage is rejected safely", ok, "neg=%s, zero=%s, nan=%s, poise=%.1f" % [neg_ret, zero_ret, nan_ret, poise.current_poise])
	poise.free()


# -----------------------------------------------------------------------------
# TEST 5: Stagger triggers exactly once when poise is depleted
# -----------------------------------------------------------------------------
func _test_5_stagger_triggers_once_when_depleted() -> void:
	var poise := PoiseComponent.new()
	poise._ready()

	var start_count := {"count": 0}
	poise.stagger_started.connect(func(): start_count["count"] += 1)

	poise.apply_posture_damage(60.0)
	var not_staggered_yet: bool = not poise.is_staggered() and start_count["count"] == 0

	poise.apply_posture_damage(40.0)
	var staggered_now: bool = poise.is_staggered() and start_count["count"] == 1

	var ok: bool = not_staggered_yet and staggered_now
	_assert_test("Stagger triggers exactly once when poise reaches zero", ok, "staggered=%s, count=%d" % [poise.is_staggered(), start_count["count"]])
	poise.free()


# -----------------------------------------------------------------------------
# TEST 6: Additional hits during stagger do not trigger duplicate stagger-start events
# -----------------------------------------------------------------------------
func _test_6_hits_during_stagger_do_not_duplicate_stagger() -> void:
	var poise := PoiseComponent.new()
	poise._ready()

	var start_count := {"count": 0}
	poise.stagger_started.connect(func(): start_count["count"] += 1)

	poise.apply_posture_damage(100.0)
	var ret_hit2: bool = poise.apply_posture_damage(25.0)
	var ret_hit3: bool = poise.apply_posture_damage(30.0)

	var ok: bool = (
		poise.is_staggered()
		and start_count["count"] == 1
		and not ret_hit2
		and not ret_hit3
	)
	_assert_test("Additional hits during active stagger do not duplicate stagger events", ok, "count=%d, ret2=%s, ret3=%s" % [start_count["count"], ret_hit2, ret_hit3])
	poise.free()


# -----------------------------------------------------------------------------
# TEST 7: Posture recovery waits for its configured delay
# -----------------------------------------------------------------------------
func _test_7_posture_recovery_waits_for_delay() -> void:
	var poise := PoiseComponent.new()
	poise._ready()
	poise.apply_posture_damage(40.0) # poise = 60.0, delay = 2.0s

	# Advance by 1.5s (less than 2.0s recovery_delay)
	poise._physics_process(1.5)

	var ok: bool = is_equal_approx(poise.current_poise, 60.0)
	_assert_test("Posture recovery waits for the configured 2.0s delay", ok, "poise=%.2f (exp 60.0)" % [poise.current_poise])
	poise.free()


# -----------------------------------------------------------------------------
# TEST 8: Poise recovers at the configured rate
# -----------------------------------------------------------------------------
func _test_8_poise_recovers_at_configured_rate() -> void:
	var poise := PoiseComponent.new()
	poise._ready()
	poise.apply_posture_damage(40.0) # poise = 60.0

	# Advance 2.0s delay
	poise._physics_process(2.0)
	# Advance 0.5s regeneration at 35.0/s -> +17.5 poise
	poise._physics_process(0.5)

	var expected_poise: float = 60.0 + (35.0 * 0.5) # 77.5
	var ok: bool = is_equal_approx(poise.current_poise, expected_poise)
	_assert_test("Poise regenerates at configured 35.0 poise/s after delay", ok, "poise=%.2f, exp=%.2f" % [poise.current_poise, expected_poise])
	poise.free()


# -----------------------------------------------------------------------------
# TEST 9: Poise recovery stops at maximum
# -----------------------------------------------------------------------------
func _test_9_poise_recovery_stops_at_maximum() -> void:
	var poise := PoiseComponent.new()
	poise._ready()
	poise.apply_posture_damage(30.0) # poise = 70.0

	# Advance delay + generous recovery time
	poise._physics_process(2.0)
	poise._physics_process(3.0)

	var ok: bool = is_equal_approx(poise.current_poise, poise.max_poise)
	_assert_test("Poise recovery clamps cleanly at maximum (100.0)", ok, "poise=%.2f" % [poise.current_poise])
	poise.free()


# -----------------------------------------------------------------------------
# TEST 10: Melee attacks apply the configured posture damage
# -----------------------------------------------------------------------------
func _test_10_melee_attacks_apply_configured_posture_damage() -> void:
	var player: CharacterBody3D = _setup_player()
	var dummy: LockOnTarget = _setup_dummy(Vector3(0.0, 0.0, -1.4))

	await physics_frame
	await physics_frame

	var initial_poise: float = dummy.poise.current_poise
	var attack_1_poise_dmg: float = player.melee_attack.attacks[0].poise_damage # 12.0

	# Trigger attack 1
	player.melee_attack.try_attack()

	# Step until hit confirms
	for _i in range(15):
		await physics_frame

	var ok: bool = (
		is_equal_approx(attack_1_poise_dmg, 12.0)
		and is_equal_approx(dummy.poise.current_poise, initial_poise - 12.0)
	)
	_assert_test("Melee Attack 1 applies exactly 12.0 posture damage", ok, "dummy_poise=%.1f (exp 88.0)" % [dummy.poise.current_poise])
	await _cleanup_nodes([player, dummy])


# -----------------------------------------------------------------------------
# TEST 11: One target receives posture damage at most once per swing
# -----------------------------------------------------------------------------
func _test_11_target_receives_posture_damage_once_per_swing() -> void:
	var player: CharacterBody3D = _setup_player()
	var dummy: LockOnTarget = _setup_dummy(Vector3(0.0, 0.0, -1.4))

	await physics_frame
	await physics_frame

	player.melee_attack.try_attack()

	# Tick multiple physics frames during ACTIVE phase
	for _i in range(25):
		await physics_frame

	# Attack 1 deals 12.0 poise damage. If deduplication fails, poise would be 0 or heavily drained
	var ok: bool = is_equal_approx(dummy.poise.current_poise, 88.0)
	_assert_test("Target receives posture damage at most once per swing", ok, "dummy_poise=%.1f (exp 88.0)" % [dummy.poise.current_poise])
	await _cleanup_nodes([player, dummy])


# -----------------------------------------------------------------------------
# TEST 12: A later combo swing can apply posture damage again
# -----------------------------------------------------------------------------
func _test_12_later_combo_swings_apply_posture_damage() -> void:
	var player: CharacterBody3D = _setup_player()
	var dummy: LockOnTarget = _setup_dummy(Vector3(0.0, 0.0, -1.4))

	await physics_frame
	await physics_frame

	# Attack 1 (12 poise dmg)
	player.melee_attack.try_attack()
	for _i in range(12):
		await physics_frame

	# Buffer Attack 2 (18 poise dmg)
	player.melee_attack.try_attack()
	for _i in range(25):
		await physics_frame

	# Poise after hit 1 and 2: 100 - 12 - 18 = 70.0
	var poise_after_hit_2: float = dummy.poise.current_poise

	# Buffer Attack 3 (28 poise dmg)
	player.melee_attack.try_attack()
	for _i in range(40):
		await physics_frame

	# Poise after full 3-hit combo: 70 - 28 = 42.0
	var poise_after_hit_3: float = dummy.poise.current_poise

	var ok: bool = (
		is_equal_approx(poise_after_hit_2, 70.0)
		and is_equal_approx(poise_after_hit_3, 42.0)
	)
	_assert_test("Combo sequence applies successive posture damage (12 -> 18 -> 28)", ok, "hit2=%.1f (exp 70.0), hit3=%.1f (exp 42.0)" % [poise_after_hit_2, poise_after_hit_3])
	await _cleanup_nodes([player, dummy])


# -----------------------------------------------------------------------------
# TEST 13: Target without PoiseComponent still receives normal health damage
# -----------------------------------------------------------------------------
func _test_13_target_without_poise_takes_health_damage() -> void:
	var player: CharacterBody3D = _setup_player()

	# Custom dummy without PoiseComponent
	var simple_target := StaticBody3D.new()
	simple_target.collision_layer = 4
	simple_target.position = Vector3(0.0, 0.0, -1.4)
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.5
	shape.height = 1.8
	col.shape = shape
	col.position = Vector3(0.0, 0.9, 0.0)
	simple_target.add_child(col)

	var health := HealthComponent.new()
	health.name = "HealthComponent"
	simple_target.add_child(health)
	root.add_child(simple_target)

	await physics_frame
	await physics_frame

	player.melee_attack.try_attack()
	for _i in range(15):
		await physics_frame

	var ok: bool = is_equal_approx(health.current_health, 80.0) # 100 - 20 dmg
	_assert_test("Target without PoiseComponent still receives normal health damage", ok, "target_hp=%.1f" % [health.current_health])
	await _cleanup_nodes([player, simple_target])


# -----------------------------------------------------------------------------
# TEST 14: Dead targets cannot be staggered or damaged again
# -----------------------------------------------------------------------------
func _test_14_dead_targets_cannot_be_staggered_or_damaged() -> void:
	var dummy: LockOnTarget = _setup_dummy()
	await physics_frame

	# Kill the dummy
	dummy.take_damage(999.0)
	await physics_frame

	var is_dead: bool = dummy.health.is_dead()
	var poise_before: float = dummy.poise.current_poise

	# Attempt to inflict posture and health damage while dead
	dummy.apply_posture_damage(50.0)
	dummy.take_damage(20.0)

	var ok: bool = (
		is_dead
		and not dummy.is_staggered()
		and is_equal_approx(dummy.poise.current_poise, poise_before)
		and not dummy.is_available()
	)
	_assert_test("Dead targets cannot be staggered or damaged further", ok, "dead=%s, staggered=%s, available=%s" % [is_dead, dummy.is_staggered(), dummy.is_available()])
	await _cleanup_nodes([dummy])


# -----------------------------------------------------------------------------
# TEST 15: Stagger ends after duration and restores a valid state
# -----------------------------------------------------------------------------
func _test_15_stagger_ends_after_duration_and_restores_state() -> void:
	var dummy: LockOnTarget = _setup_dummy()
	await physics_frame

	var signal_data := {"ended": false}
	dummy.poise.stagger_ended.connect(func(): signal_data["ended"] = true)

	# Trigger stagger by applying 100 posture damage
	dummy.apply_posture_damage(100.0)
	var entered_stagger: bool = dummy.is_staggered()

	# Tick 0.85s to exceed 0.8s stagger_duration
	dummy.poise._physics_process(0.85)
	var exited_stagger: bool = not dummy.is_staggered()
	var poise_restored: bool = is_equal_approx(dummy.poise.current_poise, dummy.poise.max_poise)

	var ok: bool = entered_stagger and exited_stagger and signal_data["ended"] and poise_restored
	_assert_test("Stagger ends after 0.8s duration and restores full poise", ok, "entered=%s, exited=%s, signal=%s, poise=%.1f" % [entered_stagger, exited_stagger, signal_data["ended"], dummy.poise.current_poise])
	await _cleanup_nodes([dummy])


# -----------------------------------------------------------------------------
# TEST 16: Repeated visual reactions do not accumulate transforms
# -----------------------------------------------------------------------------
func _test_16_repeated_reactions_do_not_accumulate_transforms() -> void:
	var dummy: LockOnTarget = _setup_dummy()
	await physics_frame

	var base_pos: Vector3 = dummy.visual_mesh.position
	var base_rot: Vector3 = dummy.visual_mesh.rotation

	# Trigger multiple hit reactions
	for _i in range(5):
		dummy._on_damaged(10.0, 90.0)
		dummy._process(0.016)

	# Trigger stagger reaction
	dummy._on_stagger_started()
	dummy._process(0.016)

	# Allow visual feedback to recover
	dummy._on_stagger_ended()
	for _i in range(30):
		dummy._process(0.05)

	var final_pos: Vector3 = dummy.visual_mesh.position
	var final_rot: Vector3 = dummy.visual_mesh.rotation

	var pos_ok: bool = final_pos.is_equal_approx(base_pos)
	var rot_ok: bool = final_rot.is_equal_approx(base_rot)

	_assert_test("Repeated hit and stagger reactions do not accumulate transform offsets", pos_ok and rot_ok, "pos_diff=%s, rot_diff=%s" % [final_pos - base_pos, final_rot - base_rot])
	await _cleanup_nodes([dummy])


# -----------------------------------------------------------------------------
# TEST 17: Lock-on remains valid during stagger and releases on death
# -----------------------------------------------------------------------------
func _test_17_lock_on_valid_during_stagger_and_releases_on_death() -> void:
	var player: CharacterBody3D = _setup_player()
	var dummy: LockOnTarget = _setup_dummy(Vector3(0.0, 0.0, -3.0))

	await physics_frame
	await physics_frame

	# Acquire target
	var acquired: bool = player.lock_on.acquire_target()
	var locked_initially: bool = acquired and player.lock_on.is_locked_on

	# Stagger dummy
	dummy.apply_posture_damage(100.0)
	var lock_valid_during_stagger: bool = player.lock_on.is_locked_on and dummy.is_available()

	# Kill dummy
	dummy.take_damage(999.0)
	await physics_frame
	await physics_frame

	var lock_released_on_death: bool = not player.lock_on.is_locked_on

	var ok: bool = locked_initially and lock_valid_during_stagger and lock_released_on_death
	_assert_test("Lock-on remains active during stagger and releases cleanly on death", ok, "locked=%s, during_stagger=%s, released=%s" % [locked_initially, lock_valid_during_stagger, lock_released_on_death])
	await _cleanup_nodes([player, dummy])


# -----------------------------------------------------------------------------
# TEST 18: Existing combat systems remain functional
# -----------------------------------------------------------------------------
func _test_18_existing_combat_systems_remain_functional() -> void:
	var player: CharacterBody3D = _setup_player()
	await physics_frame

	# Guard check
	var guard_ok: bool = player.guard.start_guard()
	player.guard.stop_guard()

	# Dodge check
	var dodge_ok: bool = player.dodge.try_dodge(Vector3.FORWARD)
	player.dodge.end_dodge()

	# Melee combo check
	var attack_ok: bool = player.melee_attack.try_attack()
	player.melee_attack.end_attack()

	# Health & stamina check
	player.stamina.current_stamina = 50.0
	player.stamina._physics_process(0.5)
	var stamina_ok: bool = player.stamina.current_stamina > 0.0

	var ok: bool = guard_ok and dodge_ok and attack_ok and stamina_ok
	_assert_test("Existing guard, dodge, light combo, health, and stamina systems remain operational", ok, "guard=%s, dodge=%s, attack=%s, stamina=%s" % [guard_ok, dodge_ok, attack_ok, stamina_ok])
	await _cleanup_nodes([player])
