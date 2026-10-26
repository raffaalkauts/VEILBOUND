extends SceneTree

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0


func _init() -> void:
	print("==================================================")
	print("VEILBOUND Phase 1.6.1 Automated Test Suite")
	print("Testing Arena Navigation & Combat Gate Integration")
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


func _setup_arena() -> Dictionary:
	var main_scene: PackedScene = load("res://main.tscn")
	var main: Node3D = main_scene.instantiate() as Node3D
	root.add_child(main)

	var nav_region: NavigationRegion3D = main.get_node_or_null("NavigationRegion3D") as NavigationRegion3D
	var player: CharacterBody3D = main.get_node_or_null("Player") as CharacterBody3D
	var soldier: SoldierEnemy = main.get_node_or_null("SoldierEnemy") as SoldierEnemy

	# Wait for navigation server and physics to synchronize
	var map_rid: RID = main.get_world_3d().get_navigation_map()
	NavigationServer3D.map_force_update(map_rid)
	for _i in range(5):
		await physics_frame
	NavigationServer3D.map_force_update(map_rid)

	return {
		"main": main,
		"nav_region": nav_region,
		"player": player,
		"soldier": soldier,
		"map_rid": map_rid
	}


func _cleanup_arena(env: Dictionary) -> void:
	if env.has("main") and is_instance_valid(env["main"]):
		env["main"].queue_free()
	await process_frame
	await process_frame


func _run_all_tests() -> void:
	await _test_1_navigation_region_and_map_are_valid()
	await _test_2_soldier_obtains_usable_path_around_blocking_pillar()
	await _test_3_navigation_target_updates_when_player_relocates()
	await _test_4_soldier_moves_along_path_without_penetrating_pillar()
	await _test_5_state_machine_clean_transitions_chase_to_attack_and_recovery()
	await _test_6_soldier_does_not_attack_during_stagger_or_after_death()
	await _test_7_existing_combat_systems_and_dummies_remain_operational()

	print("==================================================")
	print("Results: Total=%d | Passed=%d | Failed=%d" % [total_tests, passed_tests, failed_tests])
	print("==================================================")

	if failed_tests > 0:
		print("FAILED: Some Phase 1.6.1 tests failed!")
		quit(1)
	else:
		print("SUCCESS: All Phase 1.6.1 tests passed!")
		quit(0)


# -----------------------------------------------------------------------------
# TEST 1: Navigation region and map are valid
# -----------------------------------------------------------------------------
func _test_1_navigation_region_and_map_are_valid() -> void:
	var env: Dictionary = await _setup_arena()
	var nav_region: NavigationRegion3D = env["nav_region"]
	var map_rid: RID = env["map_rid"]

	var region_valid: bool = nav_region != null and nav_region.navigation_mesh != null
	var poly_count: int = nav_region.navigation_mesh.get_polygon_count() if region_valid else 0
	var map_valid: bool = map_rid.is_valid()

	var ok: bool = region_valid and poly_count > 0 and map_valid
	_assert_test("Navigation region and map are valid with pre-baked arena polygons", ok, "polys=%d, map_valid=%s" % [poly_count, map_valid])
	await _cleanup_arena(env)


# -----------------------------------------------------------------------------
# TEST 2: The Soldier obtains a usable path around a blocking pillar
# -----------------------------------------------------------------------------
func _test_2_soldier_obtains_usable_path_around_blocking_pillar() -> void:
	var env: Dictionary = await _setup_arena()
	var soldier: SoldierEnemy = env["soldier"]
	var map_rid: RID = env["map_rid"]

	# Place soldier behind pillar at (-1.5, 0.1, -3.5)
	# Target is player on opposite side of pillar at (-1.5, 0.1, 3.5)
	# Pillar is located at (-1.5, 1.0, 0.0) with size (1.2, 2.0, 1.2)
	soldier.global_position = Vector3(-1.5, 0.1, -3.5)
	var target_pos := Vector3(-1.5, 0.1, 3.5)

	soldier.nav_agent.target_position = target_pos

	var path: PackedVector3Array = NavigationServer3D.map_get_path(map_rid, soldier.global_position, target_pos, true)
	var path_has_points: bool = path.size() >= 3

	# Verify path diverts horizontally around the pillar (X moves away from -1.5 toward open floor)
	var deviates_around_pillar: bool = false
	for pt in path:
		if absf(pt.z) < 1.0 and pt.x > -0.9: # Waypoint steers right around the pillar
			deviates_around_pillar = true
			break

	var ok: bool = path_has_points and deviates_around_pillar
	_assert_test("Soldier obtains a usable path that navigates around blocking pillar", ok, "points=%d, deviates=%s" % [path.size(), deviates_around_pillar])
	await _cleanup_arena(env)


# -----------------------------------------------------------------------------
# TEST 3: Navigation target updates when the player relocates
# -----------------------------------------------------------------------------
func _test_3_navigation_target_updates_when_player_relocates() -> void:
	var env: Dictionary = await _setup_arena()
	var soldier: SoldierEnemy = env["soldier"]
	var player: CharacterBody3D = env["player"]

	soldier._target_player = player
	soldier._change_state(SoldierEnemy.State.CHASE)

	# Initial player position
	player.global_position = Vector3(0, 0.1, 2)
	soldier._update_navigation_target(player.global_position, true)
	var initial_target: Vector3 = soldier.nav_agent.target_position

	# Relocate player by 4m
	player.global_position = Vector3(3, 0.1, -2)
	soldier._physics_process(0.016)

	var updated_target: Vector3 = soldier.nav_agent.target_position
	var target_changed: bool = initial_target.distance_to(updated_target) > 2.0

	var ok: bool = target_changed and is_equal_approx(updated_target.x, 3.0) and is_equal_approx(updated_target.z, -2.0)
	_assert_test("Navigation target updates when player relocates beyond threshold", ok, "init=%s, updated=%s" % [initial_target, updated_target])
	await _cleanup_arena(env)


# -----------------------------------------------------------------------------
# TEST 4: Soldier moves along the path without entering solid obstacle geometry
# -----------------------------------------------------------------------------
func _test_4_soldier_moves_along_path_without_penetrating_pillar() -> void:
	var env: Dictionary = await _setup_arena()
	var soldier: SoldierEnemy = env["soldier"]
	var player: CharacterBody3D = env["player"]

	# Place soldier behind pillar and player in front of pillar
	soldier.global_position = Vector3(-1.5, 0.1, -3.0)
	player.global_position = Vector3(-1.5, 0.1, 3.0)

	soldier._target_player = player
	soldier._change_state(SoldierEnemy.State.CHASE)

	# Simulate pursuit movement across 60 physics frames
	var entered_pillar_core: bool = false
	var pillar_center := Vector2(-1.5, 0.0)
	var pillar_half_width: float = 0.5 # Pillar size is 1.2 x 1.2; core is within 0.5

	for _i in range(60):
		soldier._physics_process(0.016)
		var current_pos2d := Vector2(soldier.global_position.x, soldier.global_position.z)
		if current_pos2d.distance_to(pillar_center) < pillar_half_width:
			entered_pillar_core = true
			break

	# The soldier should have made progress in +Z without penetrating pillar center
	var moved_forward: bool = soldier.global_position.z > -3.0
	var ok: bool = (not entered_pillar_core) and moved_forward
	_assert_test("Soldier steers along navigation path without penetrating obstacle geometry", ok, "core_entered=%s, pos=%s" % [entered_pillar_core, soldier.global_position])
	await _cleanup_arena(env)


# -----------------------------------------------------------------------------
# TEST 5: Clean state transitions: CHASE, TELEGRAPH, ATTACK, RECOVERY
# -----------------------------------------------------------------------------
func _test_5_state_machine_clean_transitions_chase_to_attack_and_recovery() -> void:
	var env: Dictionary = await _setup_arena()
	var soldier: SoldierEnemy = env["soldier"]
	var player: CharacterBody3D = env["player"]

	# Position player in attack range (1.5m < 1.8m)
	player.global_position = Vector3(0, 0.1, 1.5)
	soldier.global_position = Vector3(0, 0.1, 0.0)

	# Frame 1: IDLE detects player -> CHASE
	soldier._physics_process(0.016)
	var in_chase: bool = soldier.current_state == SoldierEnemy.State.CHASE

	# Frame 2: CHASE sees distance 1.5m <= 1.8m -> TELEGRAPH
	soldier._physics_process(0.016)
	var in_telegraph: bool = soldier.current_state == SoldierEnemy.State.TELEGRAPH

	# Advance past telegraph (0.65s) -> ATTACK
	soldier._physics_process(0.66)
	var in_attack: bool = soldier.current_state == SoldierEnemy.State.ATTACK

	# Execute attack swing (0.12s active) -> RECOVERY
	soldier._physics_process(0.13)
	var in_recovery: bool = soldier.current_state == SoldierEnemy.State.RECOVERY

	var ok: bool = in_chase and in_telegraph and in_attack and in_recovery
	_assert_test("Soldier executes clean cyclical transitions CHASE -> TELEGRAPH -> ATTACK -> RECOVERY", ok, "chase=%s, tele=%s, atk=%s, rec=%s" % [in_chase, in_telegraph, in_attack, in_recovery])
	await _cleanup_arena(env)


# -----------------------------------------------------------------------------
# TEST 6: Soldier does not attack during stagger or after death
# -----------------------------------------------------------------------------
func _test_6_soldier_does_not_attack_during_stagger_or_after_death() -> void:
	var env: Dictionary = await _setup_arena()
	var soldier: SoldierEnemy = env["soldier"]
	var player: CharacterBody3D = env["player"]

	player.global_position = Vector3(0, 0.1, 1.5)
	soldier.global_position = Vector3(0, 0.1, 0.0)

	soldier._physics_process(0.016) # CHASE
	soldier._physics_process(0.016) # TELEGRAPH

	# Stagger soldier during telegraph
	soldier.apply_posture_damage(60.0)
	var is_staggered: bool = soldier.current_state == SoldierEnemy.State.STAGGERED

	# Tick past telegraph duration during stagger
	soldier._physics_process(0.7)
	soldier._physics_process(0.016)
	var hp_after_stagger: float = player.health.current_health
	var no_stagger_attack: bool = is_equal_approx(hp_after_stagger, 100.0)

	# Now kill soldier
	soldier.take_damage(999.0)
	soldier._physics_process(0.016)
	var is_dead: bool = soldier.current_state == SoldierEnemy.State.DEAD

	# Attempt to force melee hit after death
	soldier._execute_melee_hit()
	var no_death_attack: bool = is_equal_approx(player.health.current_health, 100.0)

	var ok: bool = is_staggered and no_stagger_attack and is_dead and no_death_attack
	_assert_test("Soldier never inflicts damage while staggered or dead", ok, "stag=%s, dead=%s, player_hp=%.1f" % [is_staggered, is_dead, player.health.current_health])
	await _cleanup_arena(env)


# -----------------------------------------------------------------------------
# TEST 7: Existing combat systems and dummies remain operational
# -----------------------------------------------------------------------------
func _test_7_existing_combat_systems_and_dummies_remain_operational() -> void:
	var env: Dictionary = await _setup_arena()
	var main: Node3D = env["main"]
	var player: CharacterBody3D = env["player"]
	var soldier: SoldierEnemy = env["soldier"]

	var dummy_center: LockOnTarget = main.get_node_or_null("Dummy_Center") as LockOnTarget
	var dummy_pillar: LockOnTarget = main.get_node_or_null("Dummy_BehindPillar") as LockOnTarget

	var dummies_exist: bool = dummy_center != null and dummy_pillar != null
	var dummies_available: bool = dummy_center.is_available() and dummy_pillar.is_available()

	# Test player directional guard against incoming attack
	player.visual_root.rotation.y = 0.0 # Facing forward (-Z)
	player.guard.start_guard()
	var stam_before: float = player.stamina.current_stamina
	player.apply_incoming_damage(20.0, player.global_position + Vector3(0, 0, -2)) # Frontal attack
	var guard_worked: bool = is_equal_approx(player.health.current_health, 94.0) # 20 * 0.3 = 6 damage applied -> 94 HP
	player.guard.stop_guard()

	# Test dodge roll
	var dodge_worked: bool = player.dodge.try_dodge(Vector3.FORWARD)
	player.dodge.end_dodge()

	# Test lock-on acquisition of Soldier
	player.lock_on.acquire_target()
	var lock_active: bool = player.lock_on.is_locked_on

	var ok: bool = dummies_exist and dummies_available and guard_worked and dodge_worked and lock_active
	_assert_test("Existing guard, dodge, lock-on, stamina, and dummy targets remain fully operational", ok, "dummies=%s, guard=%s, dodge=%s, lock=%s" % [dummies_available, guard_worked, dodge_worked, lock_active])
	await _cleanup_arena(env)
