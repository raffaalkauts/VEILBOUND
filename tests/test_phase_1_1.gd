extends SceneTree

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0


func _init() -> void:
	print("==================================================")
	print("VEILBOUND Phase 1.1 Automated Test Suite")
	print("Testing Health, Stamina, HUD, and Integration")
	print("==================================================")

	call_deferred("_run_all_tests")


func _run_all_tests() -> void:
	# --- HEALTH COMPONENT TESTS (1 to 8) ---
	_test_1_initial_health()
	_test_2_valid_damage()
	_test_3_healing()
	_test_4_damage_cannot_reduce_below_zero()
	_test_5_healing_cannot_exceed_max()
	_test_6_death_signal_fires_once()
	_test_7_dead_component_ignores_damage()
	_test_8_reset_restores_health()

	# --- STAMINA COMPONENT TESTS (9 to 16) ---
	_test_9_initial_stamina()
	_test_10_successful_consumption()
	_test_11_failed_consumption_atomic()
	_test_12_stamina_never_negative()
	_test_13_regeneration_delay()
	_test_14_regeneration_after_delay()
	_test_15_full_stamina_clamp()
	_test_16_exhaustion_recovery_transitions()

	# --- INTEGRATION TESTS (17 to 21) ---
	await _test_17_to_21_player_and_hud_integration()

	print("==================================================")
	print("Results: Total=%d | Passed=%d | Failed=%d" % [total_tests, passed_tests, failed_tests])
	print("==================================================")

	if failed_tests > 0:
		print("FAILED: Some tests failed!")
		quit(1)
	else:
		print("SUCCESS: All 21 tests passed!")
		quit(0)


func _assert_test(name: String, condition: bool, details: String = "") -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("  [PASS] Test %d: %s" % [total_tests, name])
	else:
		failed_tests += 1
		print("  [FAIL] Test %d: %s -> %s" % [total_tests, name, details])


# 1. Initial health equals maximum health.
func _test_1_initial_health() -> void:
	var h: HealthComponent = HealthComponent.new()
	h.max_health = 120.0
	h._ready()
	_assert_test(
		"Initial health equals maximum health",
		h.get_health() == 120.0 and h.get_max_health() == 120.0,
		"Expected 120.0, got %f" % h.get_health()
	)
	h.free()


# 2. Valid damage decreases health correctly.
func _test_2_valid_damage() -> void:
	var h: HealthComponent = HealthComponent.new()
	h.max_health = 100.0
	h._ready()

	var record: Dictionary = {"emitted": false, "amt": 0.0, "curr": 0.0}
	h.damaged.connect(func(amt: float, curr: float):
		record["emitted"] = true
		record["amt"] = amt
		record["curr"] = curr
	)

	h.take_damage(35.0)

	var ok: bool = (
		h.get_health() == 65.0
		and record["emitted"]
		and record["amt"] == 35.0
		and record["curr"] == 65.0
	)
	_assert_test("Valid damage decreases health correctly", ok, "Health: %f, Record: %s" % [h.get_health(), str(record)])
	h.free()


# 3. Healing restores health correctly.
func _test_3_healing() -> void:
	var h: HealthComponent = HealthComponent.new()
	h.max_health = 100.0
	h._ready()
	h.take_damage(50.0)

	var record: Dictionary = {"emitted": false, "amt": 0.0}
	h.healed.connect(func(amt: float, _curr: float):
		record["emitted"] = true
		record["amt"] = amt
	)

	h.heal(20.0)
	var ok: bool = h.get_health() == 70.0 and record["emitted"] and record["amt"] == 20.0
	_assert_test("Healing restores health correctly", ok, "Health: %f, Record: %s" % [h.get_health(), str(record)])
	h.free()


# 4. Damage cannot reduce health below zero.
func _test_4_damage_cannot_reduce_below_zero() -> void:
	var h: HealthComponent = HealthComponent.new()
	h.max_health = 100.0
	h._ready()
	h.take_damage(150.0)
	_assert_test("Damage cannot reduce health below zero", h.get_health() == 0.0, "Health is %f" % h.get_health())
	h.free()


# 5. Healing cannot exceed maximum health.
func _test_5_healing_cannot_exceed_max() -> void:
	var h: HealthComponent = HealthComponent.new()
	h.max_health = 100.0
	h._ready()
	h.take_damage(20.0)
	h.heal(50.0)
	_assert_test("Healing cannot exceed maximum health", h.get_health() == 100.0, "Health is %f" % h.get_health())
	h.free()


# 6. Death signal fires exactly once.
func _test_6_death_signal_fires_once() -> void:
	var h: HealthComponent = HealthComponent.new()
	h.max_health = 100.0
	h._ready()

	var record: Dictionary = {"count": 0}
	h.died.connect(func(): record["count"] += 1)

	h.take_damage(100.0)
	h.take_damage(50.0)
	h.take_damage(100.0)

	_assert_test("Death signal fires exactly once", record["count"] == 1 and h.is_dead(), "Death count: %d" % record["count"])
	h.free()


# 7. Dead components ignore further damage until reset.
func _test_7_dead_component_ignores_damage() -> void:
	var h: HealthComponent = HealthComponent.new()
	h.max_health = 100.0
	h._ready()
	h.take_damage(100.0)

	var record: Dictionary = {"emitted": false}
	h.damaged.connect(func(_a, _b): record["emitted"] = true)
	h.take_damage(25.0)

	_assert_test("Dead components ignore further damage until reset", not record["emitted"] and h.get_health() == 0.0, "Extra damage emitted: %s" % record["emitted"])
	h.free()


# 8. Reset restores the expected health.
func _test_8_reset_restores_health() -> void:
	var h: HealthComponent = HealthComponent.new()
	h.max_health = 100.0
	h._ready()
	h.take_damage(100.0)

	h.reset_health()
	var ok: bool = h.get_health() == 100.0 and not h.is_dead() and h.is_alive()
	_assert_test("Reset restores the expected health", ok, "Health: %f, is_dead: %s" % [h.get_health(), h.is_dead()])
	h.free()


# 9. Initial stamina equals maximum stamina.
func _test_9_initial_stamina() -> void:
	var s: StaminaComponent = StaminaComponent.new()
	s.max_stamina = 120.0
	s._ready()
	_assert_test("Initial stamina equals maximum stamina", s.get_stamina() == 120.0 and s.get_max_stamina() == 120.0, "Got %f" % s.get_stamina())
	s.free()


# 10. Successful consumption subtracts the correct amount.
func _test_10_successful_consumption() -> void:
	var s: StaminaComponent = StaminaComponent.new()
	s.max_stamina = 100.0
	s._ready()

	var success: bool = s.try_consume(35.0)
	_assert_test("Successful consumption subtracts the correct amount", success and is_equal_approx(s.get_stamina(), 65.0), "Success: %s, Stamina: %f" % [success, s.get_stamina()])
	s.free()


# 11. Failed consumption does not partially spend stamina.
func _test_11_failed_consumption_atomic() -> void:
	var s: StaminaComponent = StaminaComponent.new()
	s.max_stamina = 50.0
	s._ready()

	var success: bool = s.try_consume(60.0)
	_assert_test("Failed consumption does not partially spend stamina", not success and is_equal_approx(s.get_stamina(), 50.0), "Success: %s, Stamina: %f" % [success, s.get_stamina()])
	s.free()


# 12. Stamina never becomes negative.
func _test_12_stamina_never_negative() -> void:
	var s: StaminaComponent = StaminaComponent.new()
	s.max_stamina = 100.0
	s._ready()

	s.consume_continuous(500.0, 1.0)
	_assert_test("Stamina never becomes negative", s.get_stamina() == 0.0, "Stamina: %f" % s.get_stamina())
	s.free()


# 13. Regeneration waits for the configured delay.
func _test_13_regeneration_delay() -> void:
	var s: StaminaComponent = StaminaComponent.new()
	s.max_stamina = 100.0
	s.regen_rate = 25.0
	s.regen_delay = 1.0
	s._ready()

	s.try_consume(40.0) # Stamina is 60.0, delay is 1.0s
	s._physics_process(0.5) # Advance 0.5s (0.5s delay remains)

	_assert_test("Regeneration waits for the configured delay", is_equal_approx(s.get_stamina(), 60.0) and is_equal_approx(s.get_regen_timer(), 0.5), "Stamina: %f, Timer: %f" % [s.get_stamina(), s.get_regen_timer()])
	s.free()


# 14. Regeneration restores stamina after the delay.
func _test_14_regeneration_after_delay() -> void:
	var s: StaminaComponent = StaminaComponent.new()
	s.max_stamina = 100.0
	s.regen_rate = 20.0
	s.regen_delay = 1.0
	s._ready()

	s.try_consume(50.0) # Stamina 50.0
	s._physics_process(1.0) # Expire delay
	s._physics_process(0.5) # 0.5s * 20.0 = 10.0 regen -> should be 60.0

	_assert_test("Regeneration restores stamina after the delay", is_equal_approx(s.get_stamina(), 60.0), "Stamina: %f" % s.get_stamina())
	s.free()


# 15. Full stamina does not exceed its maximum.
func _test_15_full_stamina_clamp() -> void:
	var s: StaminaComponent = StaminaComponent.new()
	s.max_stamina = 100.0
	s.regen_rate = 50.0
	s._ready()

	s.try_consume(10.0)
	s._physics_process(1.0) # Expire delay
	s._physics_process(5.0) # Massive regen time

	_assert_test("Full stamina does not exceed its maximum", is_equal_approx(s.get_stamina(), 100.0), "Stamina: %f" % s.get_stamina())
	s.free()


# 16. Exhaustion and recovery transitions are correct.
func _test_16_exhaustion_recovery_transitions() -> void:
	var s: StaminaComponent = StaminaComponent.new()
	s.max_stamina = 100.0
	s.regen_rate = 50.0
	s.regen_delay = 0.5
	s._ready()

	var record: Dictionary = {"exhausted": 0, "recovered": 0}
	s.exhausted.connect(func(): record["exhausted"] += 1)
	s.recovered.connect(func(): record["recovered"] += 1)

	s.consume_continuous(200.0, 1.0) # Deplete completely
	var is_exh: bool = s.is_exhausted() and record["exhausted"] == 1

	s._physics_process(0.5) # Expire delay
	s._physics_process(0.1) # Regen above 0
	var is_rec: bool = not s.is_exhausted() and record["recovered"] == 1

	_assert_test("Exhaustion and recovery transitions are correct", is_exh and is_rec, "Exhausted: %s (count %d), Recovered: %s (count %d)" % [is_exh, record["exhausted"], is_rec, record["recovered"]])
	s.free()


# 17 - 21: Integration with Player Scene & HUD
func _test_17_to_21_player_and_hud_integration() -> void:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(player)

	# Give player a dummy floor below to stand on
	var floor_body: StaticBody3D = StaticBody3D.new()
	var col: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(40, 1, 40)
	col.shape = box
	floor_body.add_child(col)
	floor_body.position = Vector3(0, -0.5, 0)
	root.add_child(floor_body)

	player.position = Vector3(0, 0.1, 0)

	# Wait for physics simulation frames so player lands on floor
	for i in range(15):
		await physics_frame

	# Test 17: Sprint drains stamina in actual physics simulation
	var p_stamina: StaminaComponent = player.stamina
	var initial_sp: float = p_stamina.get_stamina()

	# Simulate move and sprint input
	Input.action_press("move_forward")
	Input.action_press("sprint")

	for i in range(15):
		await physics_frame

	var sp_drained: float = p_stamina.get_stamina()
	_assert_test(
		"Sprint drains stamina in actual physics simulation",
		sp_drained < initial_sp,
		"Initial: %f, Drained: %f" % [initial_sp, sp_drained]
	)

	# Test 18: Sprint stops when stamina is exhausted
	# Deplete remaining stamina to 0
	p_stamina.current_stamina = 0.0
	p_stamina._is_exhausted = true

	for i in range(10):
		await physics_frame

	var sp_zero: float = p_stamina.get_stamina()
	# With stamina at 0, target_speed is walk_speed (4.0).
	# Velocity horizontal magnitude should be at or near walk_speed, not sprint_speed (6.5).
	var horiz_vel: float = Vector2(player.velocity.x, player.velocity.z).length()
	_assert_test(
		"Sprint stops when stamina is exhausted",
		sp_zero <= 0.001 and horiz_vel <= player.walk_speed + 0.1,
		"Stamina: %f, Velocity: %f (walk: %f, sprint: %f)" % [sp_zero, horiz_vel, player.walk_speed, player.sprint_speed]
	)

	# Test 19: Releasing sprint permits regeneration after delay
	Input.action_release("sprint")
	Input.action_release("move_forward")

	# Wait for regen_delay (1.0s = 60 physics frames) + a few frames of regen
	for i in range(80):
		await physics_frame

	var sp_regen: float = p_stamina.get_stamina()
	_assert_test(
		"Releasing sprint permits regeneration after the delay",
		sp_regen > 0.0,
		"Stamina after release & delay: %f" % sp_regen
	)

	# Test 20: HUD bars update when signals are emitted
	var hud_scene: PackedScene = load("res://ui/combat_hud.tscn")
	var hud: CombatHUD = hud_scene.instantiate() as CombatHUD
	root.add_child(hud)

	# Reset player health and stamina to known full state before binding HUD
	player.health.reset_health()
	player.stamina.reset_stamina()
	hud.bind_player(player)

	# Initial values match
	var hp_bar_match: bool = hud.health_bar.value == player.health.get_health()
	var sp_bar_match: bool = hud.stamina_bar.value == player.stamina.get_stamina()

	# Damage player and verify HUD updates via signal
	player.health.take_damage(20.0)
	var hp_updated: bool = (
		hud.health_bar.value == player.health.get_health()
		and hud.health_label.text.contains("80")
	)

	# Consume stamina and verify HUD updates via signal
	player.stamina.try_consume(15.0)
	var sp_updated: bool = (
		is_equal_approx(hud.stamina_bar.value, player.stamina.get_stamina())
		and hud.stamina_label.text.contains("85")
	)

	_assert_test(
		"HUD bars update when signals are emitted",
		hp_bar_match and sp_bar_match and hp_updated and sp_updated,
		"HP match: %s, SP match: %s, HP updated: %s, SP updated: %s" % [hp_bar_match, sp_bar_match, hp_updated, sp_updated]
	)

	# Test 21: Existing movement, jumping, and lock-on remain operational
	var lock_on_exists: bool = player.lock_on != null

	# Test walking movement
	Input.action_press("move_forward")
	for i in range(10):
		await physics_frame
	Input.action_release("move_forward")
	var move_operates: bool = Vector2(player.velocity.x, player.velocity.z).length() > 0.5

	# Test jump
	Input.action_press("jump")
	await physics_frame
	Input.action_release("jump")
	await physics_frame

	var jump_operates: bool = player.velocity.y > 0.0 or not player.is_on_floor()

	_assert_test(
		"Existing movement, jumping, and lock-on remain operational",
		lock_on_exists and move_operates and jump_operates,
		"Lock-on exists: %s, Move operates: %s, Jump operates: %s" % [lock_on_exists, move_operates, jump_operates]
	)

	# Cleanup
	hud.queue_free()
	player.queue_free()
	floor_body.queue_free()
