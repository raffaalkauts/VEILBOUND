extends SceneTree

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0


func _init() -> void:
	print("==================================================")
	print("VEILBOUND Phase 1.6 Automated Test Suite")
	print("Testing Soldier Enemy AI, Perception & Combat")
	print("==================================================")

	call_deferred("_run_all_tests")


func _run_all_tests() -> void:
	# --- SOLDIER LIFECYCLE & STATE TESTS (1 to 5) ---
	await _test_1_soldier_scene_instantiates()
	await _test_2_initial_state_is_valid()
	await _test_3_soldier_patrols_between_points()
	await _test_4_player_detection_transitions_to_chase()
	await _test_5_soldier_approaches_player_without_falling()

	# --- TELEGRAPH & COMBAT TESTS (6 to 13) ---
	await _test_6_soldier_initiates_telegraph_at_attack_range()
	await _test_7_no_damage_during_telegraph()
	await _test_8_attack_applies_damage_once()
	await _test_9_attack_respects_range_and_obstacles()
	await _test_10_attack_does_not_repeat_damage_during_swing()
	await _test_11_dodge_iframes_prevent_soldier_damage()
	await _test_12_frontal_guard_mitigates_soldier_attack()
	await _test_13_rear_attack_bypasses_frontal_guard()

	# --- STAGGER & DEATH TESTS (14 to 18) ---
	await _test_14_soldier_can_be_staggered()
	await _test_15_stagger_interrupts_pending_attack()
	await _test_16_soldier_resumes_valid_behavior_after_stagger()
	await _test_17_soldier_enters_dead_once_on_zero_health()
	await _test_18_dead_soldier_cannot_attack_or_be_locked_on()

	# --- SYSTEM INTEGRATION & REGRESSION (19 to 20) ---
	await _test_19_existing_dummies_remain_targetable_and_damageable()
	await _test_20_existing_player_combat_systems_continue_working()

	print("==================================================")
	print("Results: Total=%d | Passed=%d | Failed=%d" % [total_tests, passed_tests, failed_tests])
	print("==================================================")

	if failed_tests > 0:
		print("FAILED: Some Phase 1.6 tests failed!")
		quit(1)
	else:
		print("SUCCESS: All 20 Phase 1.6 tests passed!")
		quit(0)


func _assert_test(test_name: String, condition: bool, details: String = "") -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("  [PASS] Test %d: %s" % [total_tests, test_name])
	else:
		failed_tests += 1
		print("  [FAIL] Test %d: %s - %s" % [total_tests, test_name, details])


func _setup_env(player_pos: Vector3 = Vector3(0, 0.1, 100), soldier_pos: Vector3 = Vector3(0, 0.1, 0)) -> Dictionary:
	var floor_node := StaticBody3D.new()
	floor_node.name = "TestFloor"
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(50, 1, 50)
	col.shape = box
	floor_node.add_child(col)
	floor_node.position = Vector3(0, -0.5, 0)
	root.add_child(floor_node)

	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: CharacterBody3D = player_scene.instantiate()
	player.position = player_pos
	root.add_child(player)
	player._resolve_nodes()

	var soldier_scene: PackedScene = load("res://characters/enemies/soldier/soldier_enemy.tscn")
	var soldier: SoldierEnemy = soldier_scene.instantiate() as SoldierEnemy
	soldier.position = soldier_pos
	root.add_child(soldier)

	for _i in range(5):
		await physics_frame

	return {"player": player, "soldier": soldier, "floor": floor_node}


func _cleanup_env(env: Dictionary) -> void:
	for key in env:
		var n: Node = env[key]
		if n != null and is_instance_valid(n):
			n.queue_free()
	await process_frame
	await process_frame


# -----------------------------------------------------------------------------
# TEST 1: Soldier scene instantiates without errors
# -----------------------------------------------------------------------------
func _test_1_soldier_scene_instantiates() -> void:
	var soldier_scene: PackedScene = load("res://characters/enemies/soldier/soldier_enemy.tscn")
	var soldier: SoldierEnemy = soldier_scene.instantiate() as SoldierEnemy
	root.add_child(soldier)
	await physics_frame

	var ok: bool = (
		soldier != null
		and soldier.health != null
		and soldier.poise != null
		and soldier.lock_on_target != null
		and soldier.collision_layer == 4
	)
	_assert_test("Soldier scene instantiates with all required components and collision", ok)
	soldier.queue_free()
	await process_frame


# -----------------------------------------------------------------------------
# TEST 2: Initial state is valid
# -----------------------------------------------------------------------------
func _test_2_initial_state_is_valid() -> void:
	var soldier_scene: PackedScene = load("res://characters/enemies/soldier/soldier_enemy.tscn")
	var soldier: SoldierEnemy = soldier_scene.instantiate() as SoldierEnemy
	root.add_child(soldier)
	await physics_frame

	var ok: bool = (
		soldier.current_state == SoldierEnemy.State.IDLE
		and soldier.get_state_name() == "IDLE"
		and is_equal_approx(soldier.health.current_health, 80.0)
		and is_equal_approx(soldier.poise.current_poise, 60.0)
		and soldier.lock_on_target.is_available()
	)
	_assert_test("Initial state is IDLE with valid health, poise, and targetability", ok, "state=%s, hp=%.1f, poise=%.1f" % [soldier.get_state_name(), soldier.health.current_health, soldier.poise.current_poise])
	soldier.queue_free()
	await process_frame


# -----------------------------------------------------------------------------
# TEST 3: Soldier patrols between configured points
# -----------------------------------------------------------------------------
func _test_3_soldier_patrols_between_points() -> void:
	var env: Dictionary = await _setup_env(Vector3(0, 0.1, 100), Vector3(0, 0.1, 0)) # Player far away
	var soldier: SoldierEnemy = env["soldier"]

	soldier.patrol_pause_duration = 0.05
	soldier.patrol_points = [Vector3(0, 0, 3.0), Vector3(0, 0, 0.0)]

	# Advance past initial idle pause
	soldier._physics_process(0.1)

	var entered_patrol: bool = soldier.current_state == SoldierEnemy.State.PATROL
	var moves: bool = soldier.velocity.length() > 0.0

	_assert_test("Soldier transitions to PATROL and moves toward patrol point", entered_patrol and moves, "state=%s, vel=%s" % [soldier.get_state_name(), soldier.velocity])
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 4: Player detection transitions Soldier into CHASE
# -----------------------------------------------------------------------------
func _test_4_player_detection_transitions_to_chase() -> void:
	var env: Dictionary = await _setup_env(Vector3(0, 0.1, 100), Vector3(0, 0.1, 0))
	var player: CharacterBody3D = env["player"]
	var soldier: SoldierEnemy = env["soldier"]

	player.global_position = Vector3(0, 0.1, 4.0) # 4m distance (< 10m radius)
	soldier._physics_process(0.016)

	var ok: bool = (
		soldier.current_state == SoldierEnemy.State.CHASE
		and soldier._target_player != null
	)
	_assert_test("Player detected within detection radius triggers transition to CHASE", ok, "state=%s, target=%s" % [soldier.get_state_name(), soldier._target_player])
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 5: Soldier approaches the player without passing through the floor
# -----------------------------------------------------------------------------
func _test_5_soldier_approaches_player_without_falling() -> void:
	var env: Dictionary = await _setup_env(Vector3(0, 0.1, 100), Vector3(0, 0.1, 0))
	var player: CharacterBody3D = env["player"]
	var soldier: SoldierEnemy = env["soldier"]

	player.global_position = Vector3(0, 0.1, 5.0)

	for _i in range(15):
		await physics_frame

	var y_pos_valid: bool = soldier.global_position.y >= -0.05
	var moved_toward: bool = soldier.global_position.z > 0.2

	_assert_test("Soldier pursues player along horizontal plane without passing through floor", y_pos_valid and moved_toward, "y=%.3f, z=%.3f" % [soldier.global_position.y, soldier.global_position.z])
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 6: Soldier stops and initiates TELEGRAPH at attack range
# -----------------------------------------------------------------------------
func _test_6_soldier_initiates_telegraph_at_attack_range() -> void:
	var env: Dictionary = await _setup_env(Vector3(0, 0.1, 100), Vector3(0, 0.1, 0))
	var player: CharacterBody3D = env["player"]
	var soldier: SoldierEnemy = env["soldier"]

	var telegraph_fired := {"count": 0}
	soldier.telegraph_started.connect(func(): telegraph_fired["count"] += 1)

	player.global_position = Vector3(0, 0.1, 1.5) # 1.5m (< 1.8m attack dist)
	soldier._physics_process(0.016) # IDLE -> CHASE
	soldier._physics_process(0.016) # CHASE -> TELEGRAPH

	var ok: bool = (
		soldier.current_state == SoldierEnemy.State.TELEGRAPH
		and telegraph_fired["count"] == 1
		and is_equal_approx(soldier.velocity.x, 0.0)
		and is_equal_approx(soldier.velocity.z, 0.0)
	)
	_assert_test("Soldier stops velocity and initiates TELEGRAPH at preferred attack range", ok, "state=%s, count=%d" % [soldier.get_state_name(), telegraph_fired["count"]])
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 7: No damage occurs during the telegraph
# -----------------------------------------------------------------------------
func _test_7_no_damage_during_telegraph() -> void:
	var env: Dictionary = await _setup_env(Vector3(0, 0.1, 100), Vector3(0, 0.1, 0))
	var player: CharacterBody3D = env["player"]
	var soldier: SoldierEnemy = env["soldier"]

	player.global_position = Vector3(0, 0.1, 1.5)
	soldier._physics_process(0.016) # IDLE -> CHASE
	soldier._physics_process(0.016) # CHASE -> TELEGRAPH

	# Advance 0.4s (within 0.65s telegraph_duration)
	soldier._physics_process(0.4)

	var ok: bool = (
		soldier.current_state == SoldierEnemy.State.TELEGRAPH
		and is_equal_approx(player.health.current_health, 100.0)
	)
	_assert_test("No damage occurs during telegraph warning period", ok, "state=%s, player_hp=%.1f" % [soldier.get_state_name(), player.health.current_health])
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 8: Attack applies damage exactly once during its active window
# -----------------------------------------------------------------------------
func _test_8_attack_applies_damage_once() -> void:
	var env: Dictionary = await _setup_env(Vector3(0, 0.1, 100), Vector3(0, 0.1, 0))
	var player: CharacterBody3D = env["player"]
	var soldier: SoldierEnemy = env["soldier"]

	var damage_records := {"count": 0, "amount": 0.0}
	player.health.damaged.connect(func(amount: float, _cur: float):
		damage_records["count"] += 1
		damage_records["amount"] = amount
	)

	player.global_position = Vector3(0, 0.1, 1.5)
	soldier._physics_process(0.016) # IDLE -> CHASE
	soldier._physics_process(0.016) # CHASE -> TELEGRAPH
	soldier._physics_process(0.66)  # Finishes telegraph -> transitions to ATTACK
	soldier._physics_process(0.016) # Executes ATTACK -> calls _execute_melee_hit()

	var ok: bool = (
		damage_records["count"] == 1
		and is_equal_approx(damage_records["amount"], 18.0)
		and is_equal_approx(player.health.current_health, 82.0)
	)
	_assert_test("Attack applies configured 18.0 HP damage exactly once upon resolution", ok, "count=%d, amount=%.1f, player_hp=%.1f" % [damage_records["count"], damage_records["amount"], player.health.current_health])
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 9: Attack respects range and obstacle checks
# -----------------------------------------------------------------------------
func _test_9_attack_respects_range_and_obstacles() -> void:
	var env: Dictionary = await _setup_env(Vector3(0, 0.1, 100), Vector3(0, 0.1, 0))
	var player: CharacterBody3D = env["player"]
	var soldier: SoldierEnemy = env["soldier"]

	player.global_position = Vector3(0, 0.1, 1.5)
	soldier._physics_process(0.016) # IDLE -> CHASE
	soldier._physics_process(0.016) # CHASE -> TELEGRAPH

	# Player escapes range during telegraph
	player.global_position = Vector3(0, 0.1, 10.0)
	soldier._physics_process(0.66)  # Transitions to ATTACK
	soldier._physics_process(0.016) # Executes attack out of range

	var ok: bool = is_equal_approx(player.health.current_health, 100.0)
	_assert_test("Attack respects range limit and misses when player retreats", ok, "player_hp=%.1f" % [player.health.current_health])
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 10: Attack does not repeatedly damage player during one swing
# -----------------------------------------------------------------------------
func _test_10_attack_does_not_repeat_damage_during_swing() -> void:
	var env: Dictionary = await _setup_env(Vector3(0, 0.1, 100), Vector3(0, 0.1, 0))
	var player: CharacterBody3D = env["player"]
	var soldier: SoldierEnemy = env["soldier"]

	player.global_position = Vector3(0, 0.1, 1.5)
	soldier._physics_process(0.016) # IDLE -> CHASE
	soldier._physics_process(0.016) # CHASE -> TELEGRAPH
	soldier._physics_process(0.66)  # Transitions to ATTACK
	soldier._physics_process(0.016) # Resolves attack

	# Tick multiple times during active and recovery
	for _i in range(10):
		soldier._physics_process(0.05)

	var ok: bool = is_equal_approx(player.health.current_health, 82.0) # 100 - 18
	_assert_test("Attack does not repeatedly damage player during one swing", ok, "player_hp=%.1f" % [player.health.current_health])
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 11: Dodge i-frames prevent attack damage
# -----------------------------------------------------------------------------
func _test_11_dodge_iframes_prevent_soldier_damage() -> void:
	var env: Dictionary = await _setup_env(Vector3(0, 0.1, 100), Vector3(0, 0.1, 0))
	var player: CharacterBody3D = env["player"]
	var soldier: SoldierEnemy = env["soldier"]

	player.global_position = Vector3(0, 0.1, 1.5)
	soldier._physics_process(0.016) # IDLE -> CHASE
	soldier._physics_process(0.016) # CHASE -> TELEGRAPH

	# Activate dodge i-frame invulnerability on player
	player.health.set_invulnerable(true)

	soldier._physics_process(0.66)  # Transitions to ATTACK
	soldier._physics_process(0.016) # Attack executes

	var ok: bool = is_equal_approx(player.health.current_health, 100.0)
	_assert_test("Dodge i-frames prevent Soldier attack damage via centralized routing", ok, "player_hp=%.1f" % [player.health.current_health])
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 12: Frontal guard mitigates Soldier's attack
# -----------------------------------------------------------------------------
func _test_12_frontal_guard_mitigates_soldier_attack() -> void:
	var env: Dictionary = await _setup_env(Vector3(0, 0.1, 100), Vector3(0, 0.1, 0))
	var player: CharacterBody3D = env["player"]
	var soldier: SoldierEnemy = env["soldier"]

	player.global_position = Vector3(0, 0.1, 1.5)
	# Player faces Soldier (-Z) and guards
	player.visual_root.rotation.y = 0.0 # Facing forward towards -Z (toward soldier at 0, 0)
	player.guard.start_guard()

	var stamina_before: float = player.stamina.current_stamina
	soldier._physics_process(0.016) # IDLE -> CHASE
	soldier._physics_process(0.016) # CHASE -> TELEGRAPH
	soldier._physics_process(0.66)  # Transitions to ATTACK
	soldier._physics_process(0.016) # Attack executes

	# 18.0 damage: 70% mitigated = 12.6, 5.4 applied. Expected HP = 100 - 5.4 = 94.6
	var expected_hp: float = 94.6
	var stamina_cost: float = 12.6 * 1.5 # 18.9 stamina

	var hp_ok: bool = is_equal_approx(player.health.current_health, expected_hp)
	var stamina_ok: bool = is_equal_approx(player.stamina.current_stamina, stamina_before - stamina_cost)

	_assert_test("Frontal guard mitigates Soldier's attack by 70% and spends block stamina", hp_ok and stamina_ok, "hp=%.2f (exp 94.60), stam=%.2f" % [player.health.current_health, player.stamina.current_stamina])
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 13: Rear attacks bypass frontal guard correctly
# -----------------------------------------------------------------------------
func _test_13_rear_attack_bypasses_frontal_guard() -> void:
	var env: Dictionary = await _setup_env(Vector3(0, 0.1, 100), Vector3(0, 0.1, 0))
	var player: CharacterBody3D = env["player"]
	var soldier: SoldierEnemy = env["soldier"]

	player.global_position = Vector3(0, 0.1, 1.5)
	# Player faces away from Soldier (+Z facing, soldier is at -Z)
	player.visual_root.rotation.y = PI
	player.guard.start_guard()

	var stamina_before: float = player.stamina.current_stamina
	soldier._physics_process(0.016) # IDLE -> CHASE
	soldier._physics_process(0.016) # CHASE -> TELEGRAPH
	soldier._physics_process(0.66)  # Transitions to ATTACK
	soldier._physics_process(0.016) # Attack executes

	# Full 18.0 damage applies, no block stamina spent
	var hp_ok: bool = is_equal_approx(player.health.current_health, 82.0)
	var stamina_ok: bool = is_equal_approx(player.stamina.current_stamina, stamina_before)

	_assert_test("Attacks from behind bypass frontal guard and apply full damage without stamina cost", hp_ok and stamina_ok, "hp=%.1f (exp 82.0), stam=%.1f" % [player.health.current_health, player.stamina.current_stamina])
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 14: Soldier can be staggered by player melee attacks
# -----------------------------------------------------------------------------
func _test_14_soldier_can_be_staggered() -> void:
	var env: Dictionary = await _setup_env(Vector3(0, 0.1, 100), Vector3(0, 0.1, 0))
	var soldier: SoldierEnemy = env["soldier"]

	# Soldier max poise is 60. Apply 60 posture damage
	soldier.apply_posture_damage(60.0)

	var ok: bool = (
		soldier.is_staggered()
		and soldier.current_state == SoldierEnemy.State.STAGGERED
		and soldier.get_state_name() == "STAGGERED"
	)
	_assert_test("Soldier enters STAGGERED state upon poise depletion", ok, "state=%s, is_staggered=%s" % [soldier.get_state_name(), soldier.is_staggered()])
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 15: Stagger interrupts pending Soldier attacks
# -----------------------------------------------------------------------------
func _test_15_stagger_interrupts_pending_attack() -> void:
	var env: Dictionary = await _setup_env(Vector3(0, 0.1, 100), Vector3(0, 0.1, 0))
	var player: CharacterBody3D = env["player"]
	var soldier: SoldierEnemy = env["soldier"]

	player.global_position = Vector3(0, 0.1, 1.5)
	soldier._physics_process(0.016) # IDLE -> CHASE
	soldier._physics_process(0.016) # CHASE -> TELEGRAPH
	var was_telegraphing: bool = soldier.current_state == SoldierEnemy.State.TELEGRAPH

	# Stagger the soldier during telegraph
	soldier.apply_posture_damage(60.0)
	var interrupted_to_stagger: bool = soldier.current_state == SoldierEnemy.State.STAGGERED

	# Tick past telegraph duration
	soldier._physics_process(0.7)
	soldier._physics_process(0.016)

	# Verify player took no damage
	var no_damage: bool = is_equal_approx(player.health.current_health, 100.0)

	var ok: bool = was_telegraphing and interrupted_to_stagger and no_damage
	_assert_test("Stagger interrupts pending telegraph and cancels attack damage", ok, "tele=%s, stag=%s, player_hp=%.1f" % [was_telegraphing, interrupted_to_stagger, player.health.current_health])
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 16: Soldier resumes valid behavior after stagger
# -----------------------------------------------------------------------------
func _test_16_soldier_resumes_valid_behavior_after_stagger() -> void:
	var env: Dictionary = await _setup_env(Vector3(0, 0.1, 100), Vector3(0, 0.1, 0))
	var player: CharacterBody3D = env["player"]
	var soldier: SoldierEnemy = env["soldier"]

	player.global_position = Vector3(0, 0.1, 4.0) # 4m away (in chase range, outside attack range 1.8m)
	soldier._physics_process(0.016) # IDLE -> CHASE

	soldier.apply_posture_damage(60.0) # Enters STAGGERED
	var was_staggered: bool = soldier.current_state == SoldierEnemy.State.STAGGERED

	# Advance past stagger_duration (0.8s)
	soldier.poise._physics_process(0.85)
	soldier._physics_process(0.016)

	var resumed_chase: bool = soldier.current_state == SoldierEnemy.State.CHASE
	var poise_restored: bool = is_equal_approx(soldier.poise.current_poise, soldier.poise.max_poise)

	_assert_test("Soldier resumes CHASE and restores full poise after stagger expires", was_staggered and resumed_chase and poise_restored, "state=%s, poise=%.1f" % [soldier.get_state_name(), soldier.poise.current_poise])
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 17: Soldier enters DEAD exactly once when health reaches zero
# -----------------------------------------------------------------------------
func _test_17_soldier_enters_dead_once_on_zero_health() -> void:
	var env: Dictionary = await _setup_env(Vector3(0, 0.1, 100), Vector3(0, 0.1, 0))
	var soldier: SoldierEnemy = env["soldier"]

	var death_count := {"count": 0}
	soldier.died.connect(func(): death_count["count"] += 1)

	soldier.take_damage(999.0)
	soldier._physics_process(0.016)

	# Additional damage should be ignored
	soldier.take_damage(50.0)
	soldier.apply_posture_damage(20.0)

	var ok: bool = (
		soldier.current_state == SoldierEnemy.State.DEAD
		and death_count["count"] == 1
		and not soldier.lock_on_target.is_available()
	)
	_assert_test("Soldier enters DEAD state exactly once and rejects further damage", ok, "state=%s, deaths=%d, targetable=%s" % [soldier.get_state_name(), death_count["count"], soldier.lock_on_target.is_available()])
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 18: Dead Soldier cannot attack or be reacquired by lock-on
# -----------------------------------------------------------------------------
func _test_18_dead_soldier_cannot_attack_or_be_locked_on() -> void:
	var env: Dictionary = await _setup_env(Vector3(0, 0.1, 100), Vector3(0, 0.1, 0))
	var player: CharacterBody3D = env["player"]
	var soldier: SoldierEnemy = env["soldier"]

	player.global_position = Vector3(0, 0.1, 2.0)
	soldier.take_damage(999.0)
	soldier._physics_process(0.016)

	var lock_ret: bool = player.lock_on.acquire_target()
	var not_locked_to_dead: bool = player.lock_on.current_target != soldier.lock_on_target

	# Verify dead soldier cannot execute attacks
	soldier._execute_melee_hit()
	var no_attack: bool = is_equal_approx(player.health.current_health, 100.0)

	_assert_test("Dead Soldier cannot be acquired by lock-on or execute attacks", not_locked_to_dead and no_attack, "lock_ret=%s, player_hp=%.1f" % [lock_ret, player.health.current_health])
	await _cleanup_env(env)


# -----------------------------------------------------------------------------
# TEST 19: Existing dummies remain targetable and damageable
# -----------------------------------------------------------------------------
func _test_19_existing_dummies_remain_targetable_and_damageable() -> void:
	var dummy_scene: PackedScene = load("res://characters/enemies/lock_on_dummy.tscn")
	var dummy: LockOnTarget = dummy_scene.instantiate() as LockOnTarget
	dummy.position = Vector3(0, 0, -2)
	root.add_child(dummy)
	await physics_frame

	var initial_hp: float = dummy.health.current_health
	dummy.take_damage(20.0)
	dummy.apply_posture_damage(30.0)

	var ok: bool = (
		dummy.is_available()
		and is_equal_approx(dummy.health.current_health, initial_hp - 20.0)
		and is_equal_approx(dummy.poise.current_poise, 70.0)
	)
	_assert_test("Existing LockOnDummy remains fully targetable, damageable, and poise-responsive", ok, "hp=%.1f, poise=%.1f" % [dummy.health.current_health, dummy.poise.current_poise])
	dummy.queue_free()
	await process_frame


# -----------------------------------------------------------------------------
# TEST 20: Existing player combat systems continue working
# -----------------------------------------------------------------------------
func _test_20_existing_player_combat_systems_continue_working() -> void:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: CharacterBody3D = player_scene.instantiate()
	root.add_child(player)
	player._resolve_nodes()
	await physics_frame

	var guard_ok: bool = player.guard.start_guard()
	player.guard.stop_guard()

	var dodge_ok: bool = player.dodge.try_dodge(Vector3.FORWARD)
	player.dodge.end_dodge()

	var attack_ok: bool = player.melee_attack.try_attack()
	player.melee_attack.end_attack()

	player.stamina.current_stamina = 50.0
	player.stamina._physics_process(0.5)
	var stamina_ok: bool = player.stamina.current_stamina > 0.0

	var ok: bool = guard_ok and dodge_ok and attack_ok and stamina_ok
	_assert_test("Existing player guard, dodge, katana combo, health, and stamina systems remain operational", ok)
	player.queue_free()
	await process_frame
