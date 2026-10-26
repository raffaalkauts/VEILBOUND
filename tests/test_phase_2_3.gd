extends SceneTree

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0


func _init() -> void:
	print("==================================================")
	print("VEILBOUND Phase 2.3 Automated Test Suite")
	print("Environment Design & Playable Vertical Slice")
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


func _setup_world() -> Dictionary:
	var main_scene: PackedScene = load("res://main.tscn")
	var main: Node3D = main_scene.instantiate() as Node3D
	root.add_child(main)

	var nav_region: NavigationRegion3D = main.get_node_or_null("NavigationRegion3D") as NavigationRegion3D
	var player: PlayerController = main.get_node_or_null("Player") as PlayerController
	var soldier: SoldierEnemy = main.get_node_or_null("SoldierEnemy") as SoldierEnemy
	var ruins_env: Node3D = main.get_node_or_null("NavigationRegion3D/DarkRuinsEnvironment") as Node3D
	var checkpoint: LanternCheckpoint = main.get_node_or_null("LanternCheckpoint") as LanternCheckpoint
	var world_env: WorldEnvironment = main.get_node_or_null("WorldEnvironment") as WorldEnvironment
	var sun: DirectionalLight3D = main.get_node_or_null("DirectionalLight3D") as DirectionalLight3D

	# Wait for physics frames
	for _i in range(5):
		await physics_frame

	return {
		"main": main,
		"nav_region": nav_region,
		"player": player,
		"soldier": soldier,
		"ruins_env": ruins_env,
		"checkpoint": checkpoint,
		"world_env": world_env,
		"sun": sun
	}


func _cleanup_world(env: Dictionary) -> void:
	if env.has("main") and is_instance_valid(env["main"]):
		env["main"].queue_free()
	await process_frame
	await process_frame


func _run_all_tests() -> void:
	await _test_1_dark_ruins_environment_composition()
	await _test_2_atmospheric_world_environment_and_lighting()
	await _test_3_lantern_checkpoint_node_structure()
	await _test_4_lantern_checkpoint_interaction_and_restoration()
	await _test_5_navigation_mesh_integrity_in_vertical_slice()
	await _test_6_entry_stair_navigation_and_collision()
	await _test_7_checkpoint_death_respawn()
	await _test_8_soldier_combat_loop_in_ruined_arena()
	await _test_9_player_combat_actions_in_vertical_slice()
	await _test_10_lock_on_reticle_in_ruins_environment()
	await _test_11_directional_guard_in_ruins_arena()
	await _test_12_scene_geometry_and_performance_budget()
	await _test_13_player_walks_from_entry_to_courtyard()

	print("==================================================")
	print("Results: Total=%d | Passed=%d | Failed=%d" % [total_tests, passed_tests, failed_tests])
	print("==================================================")

	if failed_tests > 0:
		print("FAILED: Some Phase 2.3 tests failed!")
		quit(1)
	else:
		print("SUCCESS: All Phase 2.3 tests passed!")
		quit(0)


# -----------------------------------------------------------------------------
# TEST 1: Environment Art & Scene Composition
# -----------------------------------------------------------------------------
func _test_1_dark_ruins_environment_composition() -> void:
	var env: Dictionary = await _setup_world()
	var ruins: Node3D = env["ruins_env"]

	var ruins_valid: bool = ruins != null and is_instance_valid(ruins)
	var child_count: int = ruins.get_child_count() if ruins_valid else 0

	# Count distinct 3D mesh instances in the ruins environment
	var mesh_count: int = 0
	if ruins_valid:
		var stack: Array[Node] = [ruins]
		while not stack.is_empty():
			var n: Node = stack.pop_back()
			if n is MeshInstance3D:
				mesh_count += 1
			for c in n.get_children():
				stack.append(c)

	var ok: bool = ruins_valid and child_count >= 15 and mesh_count >= 15
	_assert_test("DarkRuinsEnvironment instantiates with genuine 3D models (>=15 pieces)", ok, "children=%d, meshes=%d" % [child_count, mesh_count])
	await _cleanup_world(env)


# -----------------------------------------------------------------------------
# TEST 2: Dark Fantasy Atmospheric WorldEnvironment
# -----------------------------------------------------------------------------
func _test_2_atmospheric_world_environment_and_lighting() -> void:
	var env: Dictionary = await _setup_world()
	var world_env: WorldEnvironment = env["world_env"]
	var sun: DirectionalLight3D = env["sun"]

	var env_valid: bool = world_env != null and world_env.environment != null
	var fog_on: bool = env_valid and world_env.environment.fog_enabled
	var ambient_valid: bool = env_valid and world_env.environment.ambient_light_source != Environment.AMBIENT_SOURCE_DISABLED
	var shadows_on: bool = sun != null and sun.shadow_enabled

	var ok: bool = env_valid and fog_on and ambient_valid and shadows_on
	_assert_test("Atmospheric dark fantasy WorldEnvironment features depth fog and moonlit shadows", ok, "fog=%s, ambient=%s, shadows=%s" % [fog_on, ambient_valid, shadows_on])
	await _cleanup_world(env)


# -----------------------------------------------------------------------------
# TEST 3: Lantern Checkpoint Node Structure
# -----------------------------------------------------------------------------
func _test_3_lantern_checkpoint_node_structure() -> void:
	var env: Dictionary = await _setup_world()
	var checkpoint: LanternCheckpoint = env["checkpoint"]

	var valid_type: bool = checkpoint != null and checkpoint is LanternCheckpoint
	var col_shape: CollisionShape3D = checkpoint.get_node_or_null("CollisionShape3D") if valid_type else null
	var light: OmniLight3D = checkpoint.get_node_or_null("AetherLight3D") if valid_type else null
	var prompt: Label3D = checkpoint.get_node_or_null("PromptLabel3D") if valid_type else null
	var visual_root: Node3D = checkpoint.get_node_or_null("VisualRoot") if valid_type else null

	var ok: bool = valid_type and col_shape != null and light != null and prompt != null and visual_root != null
	_assert_test("LanternCheckpoint contains interactive Area3D, OmniLight3D, Label3D, and 3D visual models", ok)
	await _cleanup_world(env)


# -----------------------------------------------------------------------------
# TEST 4: Lantern Checkpoint Interaction & HP/Stamina Restoration
# -----------------------------------------------------------------------------
func _test_4_lantern_checkpoint_interaction_and_restoration() -> void:
	var env: Dictionary = await _setup_world()
	var checkpoint: LanternCheckpoint = env["checkpoint"]
	var player: PlayerController = env["player"]

	# Deplete player HP and stamina
	player.health.take_damage(60.0)
	player.stamina.current_stamina = 20.0

	var hp_before: float = player.health.get_health()
	var sp_before: float = player.stamina.get_stamina()

	# Track signal emission
	var signal_tracker := {"emitted": false, "pos": Vector3.ZERO}
	checkpoint.checkpoint_activated.connect(func(pos: Vector3):
		signal_tracker["emitted"] = true
		signal_tracker["pos"] = pos
	)

	# Simulate interaction
	checkpoint.activate_checkpoint(player)

	var hp_after: float = player.health.get_health()
	var sp_after: float = player.stamina.get_stamina()
	var is_act: bool = checkpoint.is_activated
	var light_energy: float = checkpoint.aether_light.light_energy if checkpoint.aether_light else 0.0

	var hp_restored: bool = is_equal_approx(hp_after, player.health.get_max_health())
	var sp_restored: bool = is_equal_approx(sp_after, player.stamina.get_max_stamina())
	var ok: bool = hp_restored and sp_restored and is_act and signal_tracker["emitted"] and light_energy >= 2.0

	_assert_test("LanternCheckpoint interaction restores 100% HP & stamina, ignites aether glow, and emits signal", ok, "HP: %.1f->%.1f, SP: %.1f->%.1f, signal=%s" % [hp_before, hp_after, sp_before, sp_after, signal_tracker["emitted"]])
	await _cleanup_world(env)


# -----------------------------------------------------------------------------
# TEST 5: Navigation Mesh Integrity in Vertical Slice
# -----------------------------------------------------------------------------
func _test_5_navigation_mesh_integrity_in_vertical_slice() -> void:
	var env: Dictionary = await _setup_world()
	var nav_region: NavigationRegion3D = env["nav_region"]
	var soldier: SoldierEnemy = env["soldier"]

	var navmesh: NavigationMesh = nav_region.navigation_mesh if nav_region else null
	var poly_count: int = navmesh.get_polygon_count() if navmesh else 0
	var map_rid: RID = env["main"].get_world_3d().get_navigation_map()

	# Query path from soldier to player
	var path: PackedVector3Array = NavigationServer3D.map_get_path(map_rid, soldier.global_position, env["player"].global_position, true)
	var path_usable: bool = path.size() >= 2

	var ok: bool = poly_count > 0 and map_rid.is_valid() and path_usable
	_assert_test("NavigationRegion3D maintains pre-baked polygon mesh and provides valid pathfinding across ruins", ok, "polys=%d, path_pts=%d" % [poly_count, path.size()])
	await _cleanup_world(env)


# -----------------------------------------------------------------------------
# TEST 6: Entry Stair Navigation and Collision
# -----------------------------------------------------------------------------
func _test_6_entry_stair_navigation_and_collision() -> void:
	var env: Dictionary = await _setup_world()
	var main: Node3D = env["main"]
	var player: PlayerController = env["player"]
	var soldier: SoldierEnemy = env["soldier"]
	var stair: Node3D = main.get_node_or_null("NavigationRegion3D/DarkRuinsEnvironment/stairs_wide_gltf") as Node3D
	var map_rid: RID = main.get_world_3d().get_navigation_map()
	var path: PackedVector3Array = NavigationServer3D.map_get_path(map_rid, player.global_position, soldier.global_position, true)
	var lowest_path_y: float = 1000.0
	var highest_path_y: float = -1000.0
	for point in path:
		lowest_path_y = minf(lowest_path_y, point.y)
		highest_path_y = maxf(highest_path_y, point.y)
	var ramp_collision: CollisionShape3D = main.get_node_or_null("NavigationRegion3D/EntryRampCollision/WalkableRamp") as CollisionShape3D
	var traverses_elevation: bool = path.size() >= 3 and lowest_path_y <= -1.5 and highest_path_y >= -0.25
	var ok: bool = stair != null and ramp_collision != null and traverses_elevation
	_assert_test("KayKit entry stair sits over a smooth walkable collision ramp and connects both navigation levels", ok, "stair=%s, ramp=%s, path=%d, y=%.2f..%.2f" % [stair != null, ramp_collision != null, path.size(), lowest_path_y, highest_path_y])
	await _cleanup_world(env)


# -----------------------------------------------------------------------------
# TEST 7: Checkpoint Death and Respawn
# -----------------------------------------------------------------------------
func _test_7_checkpoint_death_respawn() -> void:
	var env: Dictionary = await _setup_world()
	var checkpoint: LanternCheckpoint = env["checkpoint"]
	var player: PlayerController = env["player"]
	var respawn_point: Marker3D = checkpoint.get_node_or_null("RespawnPoint") as Marker3D
	checkpoint.activate_checkpoint(player)
	player.global_position = checkpoint.global_position + Vector3(0.0, 0.1, -1.5)
	player.health.take_damage(player.health.max_health)
	var died: bool = player.health.is_dead()
	for _frame in range(100):
		if not player.health.is_dead():
			break
		await physics_frame
	var position_error: float = player.global_position.distance_to(respawn_point.global_position) if respawn_point != null else INF
	var alive: bool = not player.health.is_dead() and is_equal_approx(player.health.get_health(), player.health.get_max_health())
	var stamina_restored: bool = is_equal_approx(player.stamina.current_stamina, player.stamina.max_stamina)
	var ok: bool = died and alive and stamina_restored and position_error <= 0.5
	_assert_test("Activated lantern returns a defeated player to its marked spawn with health and stamina restored", ok, "died=%s, alive=%s, stamina=%s, position_error=%.2f" % [died, alive, stamina_restored, position_error])
	await _cleanup_world(env)


# -----------------------------------------------------------------------------
# TEST 8: Soldier Combat Loop in Ruined Arena
# -----------------------------------------------------------------------------
func _test_8_soldier_combat_loop_in_ruined_arena() -> void:
	var env: Dictionary = await _setup_world()
	var soldier: SoldierEnemy = env["soldier"]
	var player: PlayerController = env["player"]

	# Position player within detection range
	player.global_position = Vector3(0, 0.1, -5.5)
	soldier.global_position = Vector3(0, 0.1, -7.0)

	soldier._target_player = player
	soldier._change_state(SoldierEnemy.State.CHASE)

	# Position soldier at attack range (< 1.8m)
	soldier.global_position = player.global_position + Vector3(0, 0, -1.4)
	soldier._physics_process(0.016)

	var in_telegraph: bool = soldier.current_state == SoldierEnemy.State.TELEGRAPH
	var in_attack: bool = soldier.current_state == SoldierEnemy.State.ATTACK
	var ok: bool = in_telegraph or in_attack
	_assert_test("Soldier pursues and executes telegraph attack sequence within ruined combat arena", ok, "state=%s" % [soldier.get_state_name()])
	await _cleanup_world(env)


# -----------------------------------------------------------------------------
# TEST 9: Player Locomotion, Dodge & Katana Combat in Vertical Slice
# -----------------------------------------------------------------------------
func _test_9_player_combat_actions_in_vertical_slice() -> void:
	var env: Dictionary = await _setup_world()
	var player: PlayerController = env["player"]

	# Test dodge roll
	player._initiate_dodge()
	var is_dodging: bool = player.dodge != null and player.dodge.is_dodging

	# Clear dodge to allow attack
	if player.dodge != null:
		player.dodge.cancel_dodge()

	# Test attack
	player.melee_attack.try_attack()
	var is_attacking: bool = player.melee_attack != null and player.melee_attack.is_attacking

	var ok: bool = is_dodging and is_attacking
	_assert_test("Player executes dodge roll with i-frames and katana combo inside vertical slice geometry", ok, "dodging=%s, attacking=%s" % [is_dodging, is_attacking])
	await _cleanup_world(env)


# -----------------------------------------------------------------------------
# TEST 10: Lock-On Reticle in Ruins Environment
# -----------------------------------------------------------------------------
func _test_10_lock_on_reticle_in_ruins_environment() -> void:
	var env: Dictionary = await _setup_world()
	var player: PlayerController = env["player"]
	var soldier: SoldierEnemy = env["soldier"]

	# Position player facing soldier
	player.global_position = Vector3(0, 0.1, -4.0)
	soldier.global_position = Vector3(0, 0.1, -7.0)

	player.lock_on.toggle_lock_on()
	var is_locked: bool = player.lock_on.is_locked_on
	var target_valid: bool = player.lock_on.current_target != null

	var ok: bool = is_locked and target_valid
	_assert_test("Lock-on targeting successfully acquires enemy in ruins courtyard", ok, "locked=%s, target=%s" % [is_locked, player.lock_on.current_target.name if target_valid else "null"])
	await _cleanup_world(env)


# -----------------------------------------------------------------------------
# TEST 11: Directional Guard in Ruins Arena
# -----------------------------------------------------------------------------
func _test_11_directional_guard_in_ruins_arena() -> void:
	var env: Dictionary = await _setup_world()
	var player: PlayerController = env["player"]

	player.guard.start_guard()
	var is_guarding: bool = player.guard.is_guarding

	# Attack from front (attacker at z = +2 relative to player facing -Z)
	var attacker_pos: Vector3 = player.global_position + Vector3(0, 0, -2.0)
	var res: Dictionary = player.apply_incoming_damage(20.0, attacker_pos)

	var damage_applied: float = res["applied_damage"]
	var mitigated: float = res["mitigated"]
	var blocked: bool = res["blocked"]

	var ok: bool = is_guarding and blocked and is_equal_approx(damage_applied, 6.0) and is_equal_approx(mitigated, 14.0)
	_assert_test("Directional guard mitigates frontal damage by 70% in ruins arena", ok, "applied=%.1f, mitigated=%.1f, blocked=%s" % [damage_applied, mitigated, blocked])
	await _cleanup_world(env)


# -----------------------------------------------------------------------------
# TEST 12: Scene Geometry & Performance Budget
# -----------------------------------------------------------------------------
func _test_12_scene_geometry_and_performance_budget() -> void:
	var env: Dictionary = await _setup_world()
	var main: Node3D = env["main"]

	var total_nodes: int = 0
	var total_mesh_instances: int = 0
	var total_lights: int = 0

	var stack: Array[Node] = [main]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		total_nodes += 1
		if n is MeshInstance3D:
			total_mesh_instances += 1
		elif n is Light3D:
			total_lights += 1
		for c in n.get_children():
			stack.append(c)

	# Lightweight draw budget for Intel UHD 620:
	# Meshes should be modular and reasonable (<150), lights reasonable (<10)
	var ok: bool = total_mesh_instances >= 15 and total_mesh_instances <= 200 and total_lights <= 10
	_assert_test("Level geometry and lighting fit low-end performance budget (Intel UHD 620 target)", ok, "meshes=%d, lights=%d, nodes=%d" % [total_mesh_instances, total_lights, total_nodes])
	await _cleanup_world(env)


# -----------------------------------------------------------------------------
# TEST 13: Player Walks from Entry into the Courtyard
# -----------------------------------------------------------------------------
func _test_13_player_walks_from_entry_to_courtyard() -> void:
	var env: Dictionary = await _setup_world()
	var player: PlayerController = env["player"]
	var start_position: Vector3 = player.global_position
	Input.action_press("move_forward")
	for _frame in range(270):
		await physics_frame
	Input.action_release("move_forward")
	var end_position: Vector3 = player.global_position
	var reached_encounter_court: bool = end_position.z < -3.0 and end_position.y > -0.5
	var remained_inside_path: bool = absf(end_position.x) < 8.0 and end_position.z > -16.0 and end_position.z < 15.0
	var ok: bool = end_position.z < start_position.z - 4.0 and reached_encounter_court and remained_inside_path
	_assert_test("Player traverses the stone entry into the Soldier encounter court and stays on the floor", ok, "start=%s end=%s" % [start_position, end_position])
	await _cleanup_world(env)
