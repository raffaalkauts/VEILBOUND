extends SceneTree

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0


func _init() -> void:
	print("==================================================")
	print("VEILBOUND Phase 1.3 Automated Test Suite")
	print("Testing Katana Combo, Melee Hit Detection & Dummies")
	print("==================================================")

	call_deferred("_run_all_tests")


func _run_all_tests() -> void:
	# --- ATTACK STATE TESTS (1 to 9) ---
	_test_1_light_attack_starts_with_sufficient_stamina()
	_test_2_combo_steps_deduct_stamina_once()
	_test_3_insufficient_stamina_rejects_attack()
	_test_4_phase_timings_respected()
	_test_5_buffer_during_allowed_window()
	_test_6_inputs_outside_buffer_window_rejected()
	_test_7_holding_attack_no_infinite_combo()
	_test_8_combo_terminates_after_hit_3()
	await _test_9_returns_to_normal_locomotion()

	# --- HIT DETECTION TESTS (10 to 16) ---
	await _test_10_target_inside_hit_volume_damaged()
	await _test_11_target_outside_hit_volume_not_damaged()
	await _test_12_target_damaged_at_most_once_per_swing()
	await _test_13_target_damaged_by_separate_combo_swings()
	await _test_14_player_never_damages_itself()
	await _test_15_world_obstacles_block_hits()
	await _test_16_dead_target_cannot_be_damaged_repeatedly()

	# --- INTEGRATION TESTS (17 to 21) ---
	await _test_17_attack_movement_restrictions()
	await _test_18_dodge_and_iframes_still_work()
	await _test_19_stamina_regen_resumes_after_attack()
	await _test_20_lock_on_still_functional()
	_test_21_regression_suites_load()

	print("==================================================")
	print("Results: Total=%d | Passed=%d | Failed=%d" % [total_tests, passed_tests, failed_tests])
	print("==================================================")

	if failed_tests > 0:
		print("FAILED: Some Phase 1.3 tests failed!")
		quit(1)
	else:
		print("SUCCESS: All 21 Phase 1.3 tests passed!")
		quit(0)


func _assert_test(name: String, condition: bool, details: String = "") -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("  [PASS] Test %d: %s" % [total_tests, name])
	else:
		failed_tests += 1
		print("  [FAIL] Test %d: %s -> %s" % [total_tests, name, details])


# 1. Light attack starts when the player has sufficient stamina.
func _test_1_light_attack_starts_with_sufficient_stamina() -> void:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(player)

	player.stamina.reset_stamina()
	var success: bool = player.melee_attack.try_attack()

	var ok: bool = success and player.melee_attack.is_attacking and player.melee_attack.combo_index == 1
	_assert_test("Light attack starts when player has sufficient stamina", ok, "Success: %s, attacking: %s, combo: %d" % [success, player.melee_attack.is_attacking, player.melee_attack.combo_index])
	player.queue_free()


# 2. Each combo step deducts the correct stamina cost exactly once.
func _test_2_combo_steps_deduct_stamina_once() -> void:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(player)

	player.stamina.reset_stamina() # 100.0
	# Hit 1 cost: 12.0 -> 88.0
	player.melee_attack.try_attack()
	var sp_hit1: float = player.stamina.get_stamina()

	# Process hit 1 active & advance to hit 2 (cost 12.0 -> 76.0)
	player.melee_attack._physics_process(0.17) # enters ACTIVE
	player.melee_attack.try_attack() # buffer hit 2
	player.melee_attack._physics_process(0.13) # enters RECOVERY -> triggers hit 2
	var sp_hit2: float = player.stamina.get_stamina()

	# Advance to hit 3 (cost 15.0 -> 61.0)
	player.melee_attack._physics_process(0.20) # enters ACTIVE of hit 2
	player.melee_attack.try_attack() # buffer hit 3
	player.melee_attack._physics_process(0.13) # enters RECOVERY -> triggers hit 3
	var sp_hit3: float = player.stamina.get_stamina()

	var ok: bool = (
		is_equal_approx(sp_hit1, 88.0)
		and is_equal_approx(sp_hit2, 76.0)
		and is_equal_approx(sp_hit3, 61.0)
	)
	_assert_test("Each combo step deducts correct stamina cost once", ok, "Hit1: %f (exp 88), Hit2: %f (exp 76), Hit3: %f (exp 61)" % [sp_hit1, sp_hit2, sp_hit3])
	player.queue_free()


# 3. Insufficient stamina rejects an attack.
func _test_3_insufficient_stamina_rejects_attack() -> void:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(player)

	player.stamina.current_stamina = 5.0 # Attack 1 needs 12.0
	var success: bool = player.melee_attack.try_attack()

	var ok: bool = (
		not success
		and not player.melee_attack.is_attacking
		and is_equal_approx(player.stamina.get_stamina(), 5.0)
	)
	_assert_test("Insufficient stamina rejects attack", ok, "Success: %s, Stamina: %f" % [success, player.stamina.get_stamina()])
	player.queue_free()


# 4. Startup, active, and recovery timings are respected.
func _test_4_phase_timings_respected() -> void:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(player)

	player.stamina.reset_stamina()
	player.melee_attack.try_attack() # Hit 1: 0.16 startup, 0.12 active, 0.30 recovery

	var phase_startup: bool = player.melee_attack.current_phase == MeleeAttackComponent.AttackPhase.STARTUP
	player.melee_attack._physics_process(0.17)
	var phase_active: bool = player.melee_attack.current_phase == MeleeAttackComponent.AttackPhase.ACTIVE
	player.melee_attack._physics_process(0.13)
	var phase_recovery: bool = player.melee_attack.current_phase == MeleeAttackComponent.AttackPhase.RECOVERY
	player.melee_attack._physics_process(0.31)
	var phase_ended: bool = not player.melee_attack.is_attacking

	var ok: bool = phase_startup and phase_active and phase_recovery and phase_ended
	_assert_test("Startup, active, and recovery timings are respected", ok, "Startup: %s, Active: %s, Recovery: %s, Ended: %s" % [phase_startup, phase_active, phase_recovery, phase_ended])
	player.queue_free()


# 5. The next attack can be buffered during the allowed window.
func _test_5_buffer_during_allowed_window() -> void:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(player)

	player.stamina.reset_stamina()
	player.melee_attack.try_attack() # Hit 1: startup 0.16s
	player.melee_attack._physics_process(0.17) # In ACTIVE phase

	var buffer_success: bool = player.melee_attack.try_attack()
	var has_buffered: bool = player.melee_attack.has_buffered_attack()

	# Process rest of active -> automatically executes Hit 2
	player.melee_attack._physics_process(0.13)
	var combo2_started: bool = player.melee_attack.combo_index == 2

	var ok: bool = buffer_success and has_buffered and combo2_started
	_assert_test("Next attack can be buffered during allowed window", ok, "Buffered: %s, Has buffered: %s, Combo2: %s" % [buffer_success, has_buffered, combo2_started])
	player.queue_free()


# 6. Inputs outside the buffer window do not incorrectly advance the combo.
func _test_6_inputs_outside_buffer_window_rejected() -> void:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(player)

	player.stamina.reset_stamina()
	player.melee_attack.try_attack() # Hit 1: startup 0.16s
	player.melee_attack._physics_process(0.05) # Still in STARTUP (outside buffer window)

	var buffer_attempt: bool = player.melee_attack.try_attack()
	var has_buffered: bool = player.melee_attack.has_buffered_attack()

	# Advance through active and recovery
	player.melee_attack._physics_process(0.25)
	player.melee_attack._physics_process(0.35)

	# Combo should NOT have advanced to Hit 2; should have cleanly finished
	var finished_at_hit1: bool = not player.melee_attack.is_attacking and player.melee_attack.combo_index == 0

	var ok: bool = not buffer_attempt and not has_buffered and finished_at_hit1
	_assert_test("Inputs outside buffer window do not incorrectly advance combo", ok, "Buffer attempt: %s, Has buffered: %s, Finished: %s" % [buffer_attempt, has_buffered, finished_at_hit1])
	player.queue_free()


# 7. Holding attack does not create an infinite combo.
func _test_7_holding_attack_no_infinite_combo() -> void:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(player)

	player.stamina.reset_stamina()
	# One press triggers Hit 1
	player.melee_attack.try_attack()

	# Holding does not re-call try_attack in controller; process full combo duration without new inputs
	for i in range(40):
		player.melee_attack._physics_process(0.05)

	# Should be completely finished, not looping
	var ok: bool = not player.melee_attack.is_attacking and player.melee_attack.combo_index == 0
	_assert_test("Holding attack does not create infinite combo", ok, "Is attacking: %s, Combo: %d" % [player.melee_attack.is_attacking, player.melee_attack.combo_index])
	player.queue_free()


# 8. The combo terminates correctly after hit 3.
func _test_8_combo_terminates_after_hit_3() -> void:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(player)

	player.stamina.reset_stamina()
	player.melee_attack.try_attack() # Hit 1

	# Transition to Hit 2
	player.melee_attack._physics_process(0.17)
	player.melee_attack.try_attack()
	player.melee_attack._physics_process(0.13)

	# Transition to Hit 3
	player.melee_attack._physics_process(0.20)
	player.melee_attack.try_attack()
	player.melee_attack._physics_process(0.13)
	var on_hit_3: bool = player.melee_attack.combo_index == 3

	# Attempt to buffer past Hit 3 -> rejected
	player.melee_attack._physics_process(0.25) # in ACTIVE of hit 3
	var buffer_past_3: bool = player.melee_attack.try_attack()

	# Finish Hit 3 recovery (needs ~0.55s)
	player.melee_attack._physics_process(0.60)
	var terminated: bool = not player.melee_attack.is_attacking and player.melee_attack.combo_index == 0

	var ok: bool = on_hit_3 and not buffer_past_3 and terminated
	_assert_test("Combo terminates correctly after hit 3", ok, "On hit 3: %s, Buffer past 3: %s, Terminated: %s" % [on_hit_3, buffer_past_3, terminated])
	player.queue_free()


# 9. The player returns to normal locomotion after recovery.
func _test_9_returns_to_normal_locomotion() -> void:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(player)
	player.position = Vector3(0, 0.1, 0)

	var floor_b: StaticBody3D = StaticBody3D.new()
	var col: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(20, 1, 20)
	col.shape = box
	floor_b.add_child(col)
	floor_b.position = Vector3(0, -0.5, 0)
	root.add_child(floor_b)

	for i in range(10):
		await physics_frame

	player.stamina.reset_stamina()
	player.melee_attack.try_attack()
	await physics_frame
	var state_attack: bool = player.current_state == PlayerController.LocomotionState.ATTACK

	# Let attack complete full duration (0.58s = ~36 physics frames)
	for i in range(45):
		await physics_frame

	var state_idle: bool = player.current_state == PlayerController.LocomotionState.IDLE

	var ok: bool = state_attack and state_idle
	_assert_test("Player returns to normal locomotion after recovery", ok, "State attack: %s, State idle: %s" % [state_attack, state_idle])

	floor_b.queue_free()
	player.queue_free()


# 10. A target inside the active hit volume receives damage.
func _test_10_target_inside_hit_volume_damaged() -> void:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(player)
	player.position = Vector3(0, 0.1, 0)

	var dummy_scene: PackedScene = load("res://characters/enemies/lock_on_dummy.tscn")
	var dummy: Node3D = dummy_scene.instantiate() as Node3D
	# Position directly in front of player facing (-Z) at distance 1.2m
	dummy.position = Vector3(0, 0.1, -1.2)
	root.add_child(dummy)

	for i in range(5):
		await physics_frame

	var initial_hp: float = dummy.get_node("HealthComponent").get_health()

	player.stamina.reset_stamina()
	player.melee_attack.try_attack() # Attack 1 damage: 20.0

	# Process until ACTIVE phase
	for i in range(15):
		await physics_frame

	var final_hp: float = dummy.get_node("HealthComponent").get_health()
	var ok: bool = is_equal_approx(final_hp, initial_hp - 20.0)
	_assert_test("Target inside active hit volume receives damage", ok, "Initial: %f, Final: %f (expected %f)" % [initial_hp, final_hp, initial_hp - 20.0])

	dummy.queue_free()
	player.queue_free()


# 11. A target outside the hit volume receives no damage.
func _test_11_target_outside_hit_volume_not_damaged() -> void:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(player)
	player.position = Vector3(0, 0.1, 0)

	var dummy_scene: PackedScene = load("res://characters/enemies/lock_on_dummy.tscn")
	var dummy: Node3D = dummy_scene.instantiate() as Node3D
	# Position far behind player
	dummy.position = Vector3(0, 0.1, 8.0)
	root.add_child(dummy)

	for i in range(5):
		await physics_frame

	var initial_hp: float = dummy.get_node("HealthComponent").get_health()

	player.stamina.reset_stamina()
	player.melee_attack.try_attack()

	for i in range(25):
		await physics_frame

	var final_hp: float = dummy.get_node("HealthComponent").get_health()
	var ok: bool = is_equal_approx(final_hp, initial_hp)
	_assert_test("Target outside hit volume receives no damage", ok, "Initial: %f, Final: %f" % [initial_hp, final_hp])

	dummy.queue_free()
	player.queue_free()


# 12. One target is damaged at most once per swing.
func _test_12_target_damaged_at_most_once_per_swing() -> void:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(player)
	player.position = Vector3(0, 0.1, 0)

	var dummy_scene: PackedScene = load("res://characters/enemies/lock_on_dummy.tscn")
	var dummy: Node3D = dummy_scene.instantiate() as Node3D
	dummy.position = Vector3(0, 0.1, -1.2)
	root.add_child(dummy)

	var record: Dictionary = {"hit_count": 0}
	dummy.get_node("HealthComponent").damaged.connect(func(_amt, _curr): record["hit_count"] += 1)

	for i in range(5):
		await physics_frame

	player.stamina.reset_stamina()
	player.melee_attack.try_attack()

	# Let the entire Attack 1 play out through its active and recovery
	for i in range(40):
		await physics_frame

	var ok: bool = record["hit_count"] == 1 and is_equal_approx(dummy.get_node("HealthComponent").get_health(), 80.0)
	_assert_test("One target is damaged at most once per swing", ok, "Hit count: %d (expected 1)" % record["hit_count"])

	dummy.queue_free()
	player.queue_free()


# 13. A target can be damaged by a later, separate swing.
func _test_13_target_damaged_by_separate_combo_swings() -> void:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(player)
	player.position = Vector3(0, 0.1, 0)

	var dummy_scene: PackedScene = load("res://characters/enemies/lock_on_dummy.tscn")
	var dummy: Node3D = dummy_scene.instantiate() as Node3D
	dummy.position = Vector3(0, 0.1, -1.2)
	root.add_child(dummy)

	for i in range(5):
		await physics_frame

	player.stamina.reset_stamina()
	player.melee_attack.try_attack() # Swing 1 (dmg 20)

	# Wait until active phase
	for i in range(12):
		await physics_frame

	# Buffer Swing 2 (dmg 24)
	player.melee_attack.try_attack()

	# Wait for swing 2 active phase
	for i in range(25):
		await physics_frame

	# Expected hp: 100 - 20 - 24 = 56.0
	var final_hp: float = dummy.get_node("HealthComponent").get_health()
	var ok: bool = is_equal_approx(final_hp, 56.0)
	_assert_test("Target can be damaged by later separate combo swings", ok, "Final HP: %f (expected 56.0)" % final_hp)

	dummy.queue_free()
	player.queue_free()


# 14. The player never damages itself.
func _test_14_player_never_damages_itself() -> void:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(player)
	player.position = Vector3(0, 0.1, 0)

	for i in range(5):
		await physics_frame

	player.stamina.reset_stamina()
	player.health.reset_health()
	player.melee_attack.try_attack()

	for i in range(30):
		await physics_frame

	var ok: bool = is_equal_approx(player.health.get_health(), 100.0)
	_assert_test("Player never damages itself", ok, "Player health: %f" % player.health.get_health())
	player.queue_free()


# 15. World obstacles and unrelated collision bodies are ignored.
func _test_15_world_obstacles_block_hits() -> void:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(player)
	player.position = Vector3(0, 0.1, 0)

	# Place solid wall (Layer 1) at z = -1.0
	var wall: StaticBody3D = StaticBody3D.new()
	wall.collision_layer = 1
	var col_w: CollisionShape3D = CollisionShape3D.new()
	var box_w: BoxShape3D = BoxShape3D.new()
	box_w.size = Vector3(4.0, 3.0, 0.5)
	col_w.shape = box_w
	wall.add_child(col_w)
	wall.position = Vector3(0, 1.0, -1.0)
	root.add_child(wall)

	# Place dummy behind wall at z = -1.8
	var dummy_scene: PackedScene = load("res://characters/enemies/lock_on_dummy.tscn")
	var dummy: Node3D = dummy_scene.instantiate() as Node3D
	dummy.position = Vector3(0, 0.1, -1.8)
	root.add_child(dummy)

	for i in range(5):
		await physics_frame

	player.stamina.reset_stamina()
	player.melee_attack.try_attack()

	for i in range(25):
		await physics_frame

	# Wall blocked hit -> dummy health undamaged
	var hp: float = dummy.get_node("HealthComponent").get_health()
	var ok: bool = is_equal_approx(hp, 100.0)
	_assert_test("World obstacles block hits and are ignored as targets", ok, "Dummy HP: %f" % hp)

	dummy.queue_free()
	wall.queue_free()
	player.queue_free()


# 16. A dead target cannot be damaged repeatedly.
func _test_16_dead_target_cannot_be_damaged_repeatedly() -> void:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(player)
	player.position = Vector3(0, 0.1, 0)

	var dummy_scene: PackedScene = load("res://characters/enemies/lock_on_dummy.tscn")
	var dummy: Node3D = dummy_scene.instantiate() as Node3D
	dummy.position = Vector3(0, 0.1, -1.2)
	root.add_child(dummy)

	for i in range(5):
		await physics_frame

	# Kill the dummy first
	var d_health: HealthComponent = dummy.get_node("HealthComponent") as HealthComponent
	d_health.take_damage(100.0)
	var was_dead: bool = d_health.is_dead()

	# Attack dead dummy
	player.stamina.reset_stamina()
	player.melee_attack.try_attack()

	for i in range(25):
		await physics_frame

	var ok: bool = was_dead and d_health.get_health() == 0.0 and not dummy.is_available()
	_assert_test("A dead target cannot be damaged repeatedly", ok, "Was dead: %s, HP: %f, available: %s" % [was_dead, d_health.get_health(), dummy.is_available()])

	dummy.queue_free()
	player.queue_free()


# 17. Attack movement restrictions are respected.
func _test_17_attack_movement_restrictions() -> void:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(player)
	player.position = Vector3(0, 0.1, 0)

	var floor_b: StaticBody3D = StaticBody3D.new()
	var col: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(20, 1, 20)
	col.shape = box
	floor_b.add_child(col)
	floor_b.position = Vector3(0, -0.5, 0)
	root.add_child(floor_b)

	for i in range(5):
		await physics_frame

	player.stamina.reset_stamina()
	player.melee_attack.try_attack()

	# Hold move_forward during attack
	Input.action_press("move_forward")
	for i in range(15):
		await physics_frame
	Input.action_release("move_forward")

	# Speed should not reach walk_speed (4.0); restricted during attack
	var h_speed: float = Vector2(player.velocity.x, player.velocity.z).length()
	var ok: bool = h_speed < 1.0
	_assert_test("Attack movement restrictions are respected", ok, "Horizontal speed during attack: %f (walk is 4.0)" % h_speed)

	floor_b.queue_free()
	player.queue_free()


# 18. Existing dodge and i-frame behavior still works.
func _test_18_dodge_and_iframes_still_work() -> void:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(player)

	player.stamina.reset_stamina()
	player.health.reset_health()
	player.dodge.try_dodge(Vector3.FORWARD)

	player.dodge._physics_process(0.10) # inside i-frames
	var iframing: bool = player.dodge.is_iframe_active() and player.health.is_invulnerable
	player.health.take_damage(20.0)

	var ok: bool = iframing and is_equal_approx(player.health.get_health(), 100.0)
	_assert_test("Existing dodge and i-frame behavior still works", ok, "Iframing: %s, Health: %f" % [iframing, player.health.get_health()])
	player.queue_free()


# 19. Existing stamina regeneration resumes after attacks.
func _test_19_stamina_regen_resumes_after_attack() -> void:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(player)

	player.stamina.reset_stamina()
	player.melee_attack.try_attack() # Sp becomes 88.0

	# Process full attack duration (0.58s)
	for i in range(35):
		player.melee_attack._physics_process(0.02)
		player.stamina._physics_process(0.02)

	# Process regen delay (1.0s) + regen time (0.2s)
	for i in range(60):
		player.stamina._physics_process(0.02)

	var ok: bool = player.stamina.get_stamina() > 88.0
	_assert_test("Existing stamina regeneration resumes after attacks", ok, "Stamina: %f (was 88.0)" % player.stamina.get_stamina())
	player.queue_free()


# 20. Existing lock-on and target-facing behavior remain functional.
func _test_20_lock_on_still_functional() -> void:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(player)
	player.position = Vector3(0, 0.1, 0)

	var dummy_scene: PackedScene = load("res://characters/enemies/lock_on_dummy.tscn")
	var dummy: Node3D = dummy_scene.instantiate() as Node3D
	dummy.position = Vector3(0, 0.1, -4.0)
	root.add_child(dummy)

	for i in range(5):
		await physics_frame

	var acquired: bool = player.lock_on.acquire_target()
	for i in range(5):
		await physics_frame

	var ok: bool = acquired and player.lock_on.is_locked_on and player.lock_on.current_target != null
	_assert_test("Existing lock-on and target-facing behavior remain functional", ok, "Acquired: %s, Locked on: %s" % [acquired, player.lock_on.is_locked_on])

	dummy.queue_free()
	player.queue_free()


# 21. Existing Phase 1.1 and Phase 1.2 regression suites still pass.
func _test_21_regression_suites_load() -> void:
	var s1: Script = load("res://tests/test_phase_1_1.gd")
	var s2: Script = load("res://tests/test_phase_1_2.gd")
	var ok: bool = s1 != null and s2 != null
	_assert_test("Existing Phase 1.1 and Phase 1.2 regression suites load cleanly", ok, "s1: %s, s2: %s" % [s1 != null, s2 != null])
