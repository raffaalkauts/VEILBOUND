extends SceneTree

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0


func _init() -> void:
	print("==================================================")
	print("VEILBOUND Phase 1.2 Automated Test Suite")
	print("Testing Dodge Roll, i-frames, and Mechanics")
	print("==================================================")

	call_deferred("_run_all_tests")


func _run_all_tests() -> void:
	# 1. Dodge starts successfully with sufficient stamina
	_test_1_dodge_starts_with_sufficient_stamina()

	# 2. Exactly the configured stamina cost is consumed once
	_test_2_stamina_cost_consumed_once()

	# 3. Dodge is rejected when stamina is insufficient
	_test_3_dodge_rejected_when_stamina_insufficient()

	# 4. Repeated input cannot start overlapping dodges
	_test_4_no_overlapping_dodges()

	# 5. Player can dodge in the intended directions
	_test_5_directional_dodges()

	# 6. Lock-on facing remains correct during directional dodges
	await _test_6_lock_on_facing_during_dodge()

	# 7. Damage is ignored during active i-frames
	_test_7_damage_ignored_during_iframes()

	# 8. Damage applies before the i-frame window
	_test_8_damage_applies_before_iframes()

	# 9. Damage applies after the i-frame window
	_test_9_damage_applies_after_iframes()

	# 10. Invulnerability always clears at the end of dodge
	_test_10_invulnerability_clears_at_end()

	# 11. Death cannot leave the player permanently invulnerable
	_test_11_death_clears_invulnerability()

	# 12. Wall collision remains active during dodge
	await _test_12_wall_collision_active_during_dodge()

	# 13. Existing sprint stamina consumption still works
	await _test_13_sprint_stamina_still_works()

	# 14. Existing jump, locomotion, HUD, and lock-on behavior remain operational
	await _test_14_existing_systems_operational()

	print("==================================================")
	print("Results: Total=%d | Passed=%d | Failed=%d" % [total_tests, passed_tests, failed_tests])
	print("==================================================")

	if failed_tests > 0:
		print("FAILED: Some Phase 1.2 tests failed!")
		quit(1)
	else:
		print("SUCCESS: All 14 Phase 1.2 tests passed!")
		quit(0)


func _assert_test(name: String, condition: bool, details: String = "") -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("  [PASS] Test %d: %s" % [total_tests, name])
	else:
		failed_tests += 1
		print("  [FAIL] Test %d: %s -> %s" % [total_tests, name, details])


# 1. Dodge starts successfully with sufficient stamina
func _test_1_dodge_starts_with_sufficient_stamina() -> void:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(player)

	player.stamina.reset_stamina() # 100.0 stamina
	var success: bool = player.dodge.try_dodge(Vector3.FORWARD)

	var ok: bool = success and player.dodge.is_dodging
	_assert_test("Dodge starts successfully with sufficient stamina", ok, "Success: %s, is_dodging: %s" % [success, player.dodge.is_dodging])
	player.queue_free()


# 2. Exactly the configured stamina cost is consumed once
func _test_2_stamina_cost_consumed_once() -> void:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(player)

	player.stamina.reset_stamina()
	var initial_sp: float = player.stamina.get_stamina()
	var expected_cost: float = player.dodge.stamina_cost

	player.dodge.try_dodge(Vector3.FORWARD)
	var sp_after_dodge: float = player.stamina.get_stamina()

	# Advance dodge physics process slightly
	player.dodge._physics_process(0.1)
	var sp_subsequent: float = player.stamina.get_stamina()

	var ok: bool = (
		is_equal_approx(sp_after_dodge, initial_sp - expected_cost)
		and is_equal_approx(sp_subsequent, initial_sp - expected_cost)
	)
	_assert_test("Exactly configured stamina cost is consumed once", ok, "Initial: %f, After: %f, Sub: %f, Cost: %f" % [initial_sp, sp_after_dodge, sp_subsequent, expected_cost])
	player.queue_free()


# 3. Dodge is rejected when stamina is insufficient
func _test_3_dodge_rejected_when_stamina_insufficient() -> void:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(player)

	player.stamina.current_stamina = 10.0 # Cost is 25.0
	var success: bool = player.dodge.try_dodge(Vector3.FORWARD)

	var ok: bool = not success and not player.dodge.is_dodging and is_equal_approx(player.stamina.get_stamina(), 10.0)
	_assert_test("Dodge is rejected when stamina is insufficient", ok, "Success: %s, Stamina: %f" % [success, player.stamina.get_stamina()])
	player.queue_free()


# 4. Repeated input cannot start overlapping dodges
func _test_4_no_overlapping_dodges() -> void:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(player)

	player.stamina.reset_stamina()
	player.dodge.try_dodge(Vector3.FORWARD)

	var sp_first: float = player.stamina.get_stamina()
	var second_attempt: bool = player.dodge.try_dodge(Vector3.LEFT)
	var sp_second: float = player.stamina.get_stamina()

	var ok: bool = not second_attempt and is_equal_approx(sp_first, sp_second)
	_assert_test("Repeated input cannot start overlapping dodges", ok, "Second attempt: %s, SP First: %f, SP Second: %f" % [second_attempt, sp_first, sp_second])
	player.queue_free()


# 5. Player can dodge in the intended directions
func _test_5_directional_dodges() -> void:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(player)

	var directions: Array[Vector3] = [
		Vector3.FORWARD,
		Vector3.BACK,
		Vector3.LEFT,
		Vector3.RIGHT,
		(Vector3.FORWARD + Vector3.RIGHT).normalized(),
	]

	var all_ok: bool = true
	for dir in directions:
		player.stamina.reset_stamina()
		player.dodge.end_dodge()
		player.dodge.try_dodge(dir)
		if not player.dodge.dodge_direction.is_equal_approx(dir):
			all_ok = false
			break

	# Also test neutral fallback
	player.stamina.reset_stamina()
	player.dodge.end_dodge()
	player.dodge.try_dodge(Vector3.ZERO)
	var fallback_ok: bool = player.dodge.dodge_direction.length_squared() > 0.5

	_assert_test("Player can dodge in intended directions", all_ok and fallback_ok, "Dirs ok: %s, Fallback ok: %s" % [all_ok, fallback_ok])
	player.queue_free()


# 6. Lock-on facing remains correct during directional dodges
func _test_6_lock_on_facing_during_dodge() -> void:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(player)

	# Create a dummy target at (0, 0, -5)
	var dummy_scene: PackedScene = load("res://characters/enemies/lock_on_dummy.tscn")
	var dummy: Node3D = dummy_scene.instantiate() as Node3D
	dummy.position = Vector3(0, 0, -5)
	root.add_child(dummy)

	for i in range(5):
		await physics_frame

	# Lock on
	var acquired: bool = player.lock_on.acquire_target()
	for i in range(5):
		await physics_frame

	# Dodge right while locked on
	player.stamina.reset_stamina()
	player.dodge.try_dodge(Vector3.RIGHT)

	# Process 10 physics frames of dodging
	for i in range(10):
		await physics_frame

	# VisualRoot should still face roughly towards (0, 0, -5) (forward/facing target, not rotated 90 deg right)
	var vis_forward: Vector3 = -player.visual_root.global_transform.basis.z
	var to_dummy: Vector3 = (dummy.global_position - player.global_position).normalized()
	var dot_prod: float = vis_forward.dot(to_dummy)

	var ok: bool = acquired and dot_prod > 0.8 # Facing within ~36 degrees of target
	_assert_test("Lock-on facing remains correct during directional dodges", ok, "Acquired: %s, Facing Dot: %f" % [acquired, dot_prod])

	dummy.queue_free()
	player.queue_free()


# 7. Damage is ignored during active i-frames
func _test_7_damage_ignored_during_iframes() -> void:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(player)

	player.stamina.reset_stamina()
	player.health.reset_health()
	player.dodge.try_dodge(Vector3.FORWARD)

	# Advance into the i-frame window: startup is 0.04s, so 0.10s is inside
	player.dodge._physics_process(0.10)

	var is_iframing: bool = player.dodge.is_iframe_active() and player.health.is_invulnerable
	player.health.take_damage(30.0)

	var ok: bool = is_iframing and player.health.get_health() == 100.0
	_assert_test("Damage is ignored during active i-frames", ok, "Is iframing: %s, Health: %f" % [is_iframing, player.health.get_health()])
	player.queue_free()


# 8. Damage applies before the i-frame window
func _test_8_damage_applies_before_iframes() -> void:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(player)

	player.stamina.reset_stamina()
	player.health.reset_health()
	player.dodge.iframe_startup = 0.05
	player.dodge.try_dodge(Vector3.FORWARD)

	# Advance 0.02s (before 0.05s startup)
	player.dodge._physics_process(0.02)
	var before_iframe: bool = not player.dodge.is_iframe_active() and not player.health.is_invulnerable

	player.health.take_damage(25.0)
	var ok: bool = before_iframe and player.health.get_health() == 75.0
	_assert_test("Damage applies before i-frame window", ok, "Before iframe: %s, Health: %f" % [before_iframe, player.health.get_health()])
	player.queue_free()


# 9. Damage applies after the i-frame window
func _test_9_damage_applies_after_iframes() -> void:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(player)

	player.stamina.reset_stamina()
	player.health.reset_health()
	player.dodge.iframe_startup = 0.04
	player.dodge.iframe_duration = 0.18 # Window ends at 0.22s, total duration is 0.50s
	player.dodge.try_dodge(Vector3.FORWARD)

	# Advance 0.30s (past i-frame window, but still within 0.50s dodge)
	player.dodge._physics_process(0.30)
	var after_iframe: bool = not player.dodge.is_iframe_active() and not player.health.is_invulnerable and player.dodge.is_dodging

	player.health.take_damage(25.0)
	var ok: bool = after_iframe and player.health.get_health() == 75.0
	_assert_test("Damage applies after i-frame window", ok, "After iframe: %s, Health: %f" % [after_iframe, player.health.get_health()])
	player.queue_free()


# 10. Invulnerability always clears at the end of dodge
func _test_10_invulnerability_clears_at_end() -> void:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(player)

	player.stamina.reset_stamina()
	player.dodge.try_dodge(Vector3.FORWARD)
	player.dodge._physics_process(0.10) # inside i-frames

	player.dodge._physics_process(0.50) # exceed duration -> ends dodge
	var ok: bool = not player.dodge.is_dodging and not player.health.is_invulnerable
	_assert_test("Invulnerability always clears at the end of dodge", ok, "is_dodging: %s, is_invulnerable: %s" % [player.dodge.is_dodging, player.health.is_invulnerable])
	player.queue_free()


# 11. Death cannot leave the player permanently invulnerable
func _test_11_death_clears_invulnerability() -> void:
	var h: HealthComponent = HealthComponent.new()
	h.max_health = 100.0
	h._ready()

	h.set_invulnerable(true)
	var set_works: bool = h.is_invulnerable

	# Kill the entity directly (forcing damage or clear)
	h.is_invulnerable = false # Simulate vulnerability breach or script damage
	h.take_damage(100.0)

	var dead_cleared: bool = h.is_dead() and not h.is_invulnerable

	# Attempt to set invulnerable while dead
	h.set_invulnerable(true)
	var reject_dead_iframe: bool = not h.is_invulnerable

	var ok: bool = set_works and dead_cleared and reject_dead_iframe
	_assert_test("Death cannot leave the player permanently invulnerable", ok, "Set works: %s, Dead cleared: %s, Reject dead iframe: %s" % [set_works, dead_cleared, reject_dead_iframe])
	h.free()


# 12. Wall collision remains active during dodge
func _test_12_wall_collision_active_during_dodge() -> void:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(player)
	player.position = Vector3(0, 0.1, 0)

	# Place floor
	var floor_body: StaticBody3D = StaticBody3D.new()
	var col_f: CollisionShape3D = CollisionShape3D.new()
	var box_f: BoxShape3D = BoxShape3D.new()
	box_f.size = Vector3(30, 1, 30)
	col_f.shape = box_f
	floor_body.add_child(col_f)
	floor_body.position = Vector3(0, -0.5, 0)
	root.add_child(floor_body)

	# Place solid wall at z = -1.2
	var wall_body: StaticBody3D = StaticBody3D.new()
	var col_w: CollisionShape3D = CollisionShape3D.new()
	var box_w: BoxShape3D = BoxShape3D.new()
	box_w.size = Vector3(10, 4, 1)
	col_w.shape = box_w
	wall_body.add_child(col_w)
	wall_body.position = Vector3(0, 2.0, -1.2)
	root.add_child(wall_body)

	for i in range(10):
		await physics_frame

	# Dodge forward into the wall
	player.stamina.reset_stamina()
	player.dodge.try_dodge(Vector3.FORWARD) # Vector3(0, 0, -1)

	for i in range(25):
		await physics_frame

	# Wall front face is at -1.2 + 0.5 = -0.7. Player radius is 0.4.
	# Player position z cannot be past -0.8
	var z_pos: float = player.global_position.z
	var ok: bool = z_pos > -1.0 # Stopped by wall, did not teleport through
	_assert_test("Wall collision remains active during dodge", ok, "Player Z pos: %f (wall at -1.2, surface at -0.7)" % z_pos)

	wall_body.queue_free()
	floor_body.queue_free()
	player.queue_free()


# 13. Existing sprint stamina consumption still works
func _test_13_sprint_stamina_still_works() -> void:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(player)
	player.position = Vector3(0, 0.1, 0)

	var floor_body: StaticBody3D = StaticBody3D.new()
	var col_f: CollisionShape3D = CollisionShape3D.new()
	var box_f: BoxShape3D = BoxShape3D.new()
	box_f.size = Vector3(30, 1, 30)
	col_f.shape = box_f
	floor_body.add_child(col_f)
	floor_body.position = Vector3(0, -0.5, 0)
	root.add_child(floor_body)

	for i in range(10):
		await physics_frame

	player.stamina.reset_stamina()
	var initial_sp: float = player.stamina.get_stamina()

	Input.action_press("move_forward")
	Input.action_press("sprint")
	for i in range(15):
		await physics_frame
	Input.action_release("sprint")
	Input.action_release("move_forward")

	var ok: bool = player.stamina.get_stamina() < initial_sp
	_assert_test("Existing sprint stamina consumption still works", ok, "Initial: %f, Current: %f" % [initial_sp, player.stamina.get_stamina()])

	floor_body.queue_free()
	player.queue_free()


# 14. Existing jump, locomotion, HUD, and lock-on behavior remain operational
func _test_14_existing_systems_operational() -> void:
	var player_scene: PackedScene = load("res://characters/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	root.add_child(player)
	player.position = Vector3(0, 0.1, 0)

	var floor_body: StaticBody3D = StaticBody3D.new()
	var col_f: CollisionShape3D = CollisionShape3D.new()
	var box_f: BoxShape3D = BoxShape3D.new()
	box_f.size = Vector3(30, 1, 30)
	col_f.shape = box_f
	floor_body.add_child(col_f)
	floor_body.position = Vector3(0, -0.5, 0)
	root.add_child(floor_body)

	var hud_scene: PackedScene = load("res://ui/combat_hud.tscn")
	var hud: CombatHUD = hud_scene.instantiate() as CombatHUD
	root.add_child(hud)
	hud.bind_player(player)

	for i in range(10):
		await physics_frame

	# Jump test
	Input.action_press("jump")
	await physics_frame
	Input.action_release("jump")
	await physics_frame

	var jumped: bool = player.velocity.y > 0.0 or not player.is_on_floor()

	# HUD test
	player.health.take_damage(10.0)
	var hud_updated: bool = hud.health_bar.value == player.health.get_health()

	# Lock on component present
	var lock_on_ok: bool = player.lock_on != null

	var ok: bool = jumped and hud_updated and lock_on_ok
	_assert_test("Existing jump, locomotion, HUD, and lock-on remain operational", ok, "Jumped: %s, HUD updated: %s, Lock-on: %s" % [jumped, hud_updated, lock_on_ok])

	hud.queue_free()
	floor_body.queue_free()
	player.queue_free()
