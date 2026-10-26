extends SceneTree

## Phase 2.7: full-body secondary motion gate.
## Verifies the real production rig, every chain group, spring response,
## settling, reset and preview toggles. Headless-safe: simulated poses are read
## during Skeleton3D's skeleton_updated signal (before the authored pose is
## restored for the next frame).

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var main: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	for _i in range(3):
		await process_frame

	var player: PlayerController = main.get_node("Player") as PlayerController
	var model: PlayerCharacterModel = player.get_node("VisualRoot/PlayerCharacterModel") as PlayerCharacterModel
	var secondary = model.secondary_motion

	_assert_test("Production player exposes secondary motion", secondary != null)
	if secondary == null:
		_finish()
		return
	_assert_test("All 33 rigged chains are configured", secondary.chain_count() == 33)
	_assert_test("Hair group covers 16 strands + ahoge", secondary.group_chain_count(&"hair") == 17)
	_assert_test("Ear group covers both fox ears", secondary.group_chain_count(&"ears") == 2)
	_assert_test("Tail chain is present", secondary.group_chain_count(&"tail") == 1)
	_assert_test("Clothing group covers 9 jacket hems + belt", secondary.group_chain_count(&"clothing") == 10)
	_assert_test("Accessories group covers dogtag + bust", secondary.group_chain_count(&"accessories") == 3)

	# Chain inventory: real bone names, full lengths, no duplicated bone owner.
	var seen_bones: Dictionary = {}
	var duplicate_bone: bool = false
	var tail_ok: bool = false
	var hair_long_ok: bool = false
	var jacket_ok: bool = false
	var ear_ok: bool = false
	for chain: Dictionary in secondary.get_chains():
		var bone_names: Array = chain["bone_names"]
		for bone_name: String in bone_names:
			if seen_bones.has(bone_name):
				duplicate_bone = true
			seen_bones[bone_name] = true
		if chain["group"] == &"tail" and bone_names.size() == 7:
			tail_ok = true
		if chain["group"] == &"hair" and String(chain["label"]) == "back hair" and bone_names.size() >= 5:
			hair_long_ok = true
		if chain["group"] == &"clothing" and String(chain["label"]) == "jacket hem" and bone_names.size() == 4:
			jacket_ok = true
		if chain["group"] == &"ears" and bone_names.size() == 5:
			ear_ok = true
	_assert_test("Every simulated bone belongs to exactly one chain", not duplicate_bone)
	_assert_test("Tail chain spans all 7 tail bones", tail_ok)
	_assert_test("Long hair chain spans 5+ bones", hair_long_ok)
	_assert_test("Jacket hem chain spans 4 bones", jacket_ok)
	_assert_test("Ear chain spans 5 bones", ear_ok)

	# One simulator per motion group, parented directly to the Skeleton3D.
	var simulators_ok: bool = true
	var settings_ok: bool = true
	for group: StringName in secondary.get_group_names():
		var sim: SpringBoneSimulator3D = secondary.get_simulator(group)
		if sim == null or sim.get_parent() != model.skeleton or not sim.active:
			simulators_ok = false
			continue
		if sim.get_setting_count() != secondary.group_chain_count(group):
			settings_ok = false
	_assert_test("Every spring simulator is a direct Skeleton3D child and active", simulators_ok)
	_assert_test("One setting per chain, no duplicated solver", settings_ok)
	_assert_test("Spring simulators live on the visual skeleton, not the collision root",
		secondary.get_simulator(&"tail").get_parent() == model.skeleton and player.get_node_or_null("SpringBoneSimulator3D") == null)

	# Collision primitives are configured to keep chains out of the body.
	var tail_sim: SpringBoneSimulator3D = secondary.get_simulator(&"tail")
	var collision_nodes: Array[Node] = tail_sim.find_children("*", "SpringBoneCollision3D", true, false)
	_assert_test("Tail chains use body collision primitives", collision_nodes.size() >= 1)

	# Sample the simulated tail and hair poses over real frames.
	var tail_root_bone: int = -1
	var hair_root_bone: int = -1
	for chain: Dictionary in secondary.get_chains():
		if tail_root_bone < 0 and chain["group"] == &"tail":
			tail_root_bone = int(chain["root_bone"])
		if hair_root_bone < 0 and chain["group"] == &"hair" and String(chain["label"]) == "back hair":
			hair_root_bone = int(chain["root_bone"])

	var tail_samples: Array[Quaternion] = []
	var hair_samples: Array[Quaternion] = []
	var sample := func() -> void:
		tail_samples.append(model.skeleton.get_bone_pose_rotation(tail_root_bone))
		hair_samples.append(model.skeleton.get_bone_pose_rotation(hair_root_bone))
	model.skeleton.skeleton_updated.connect(sample)
	for _i in range(90):
		await process_frame

	_assert_test("Tail receives a simulated pose", tail_samples.size() > 60)
	var idle_settled: bool = _max_step_degrees(tail_samples, 40) < 0.6
	_assert_test("Tail settles while idle (no endless oscillation)", idle_settled)

	var before_tail: Quaternion = tail_samples[tail_samples.size() - 1]
	var before_hair: Quaternion = hair_samples[hair_samples.size() - 1]
	secondary.apply_impulse(Vector3(5.0, 0.0, 0.0))
	for _i in range(20):
		await process_frame
	var after_tail: Quaternion = tail_samples[tail_samples.size() - 1]
	var after_hair: Quaternion = hair_samples[hair_samples.size() - 1]
	_assert_test("Tail responds to gameplay impulse",
		before_tail.angle_to(after_tail) > deg_to_rad(0.5))
	_assert_test("Hair responds to gameplay impulse",
		before_hair.angle_to(after_hair) > deg_to_rad(0.5))

	for _i in range(210):
		await process_frame
	var settled_after: bool = _max_step_degrees(tail_samples, 40) < 0.6
	_assert_test("Tail settles again after the impulse", settled_after)

	# Reset must clear the accumulated impulse and keep chains active.
	secondary.apply_impulse(Vector3(3.0, 0.0, 0.0))
	await process_frame
	model.reset_pose()
	await process_frame
	var reset_ok: bool = secondary.impulse_strength() < 0.001
	for group: StringName in secondary.get_group_names():
		if not secondary.is_group_enabled(group):
			reset_ok = false
	_assert_test("Respawn reset clears impulses and restores all groups", reset_ok)

	# Weapon attachment survives secondary motion.
	model.set_combat_mode(true)
	for _i in range(30):
		await process_frame
	var weapon_ok: bool = model.hand_attachment != null and model.hand_attachment.bone_name != "" and model.katana_in_hand != null and model.katana_in_hand.get_parent() == model.hand_attachment
	_assert_test("Katana stays attached to the hand bone under spring motion", weapon_ok)

	# Development preview controls: groups can be isolated and restored.
	secondary.set_group_enabled(&"ears", false)
	var ears_off: bool = not secondary.is_group_enabled(&"ears")
	secondary.set_group_enabled(&"ears", true)
	var ears_on: bool = secondary.is_group_enabled(&"ears")
	var tail_chain_id: String = ""
	for chain: Dictionary in secondary.get_chains():
		if chain["group"] == &"tail":
			tail_chain_id = String(chain["id"])
	var solo_ok: bool = secondary.solo_chain(tail_chain_id) \
		and not secondary.is_group_enabled(&"hair") and secondary.is_group_enabled(&"tail") \
		and secondary.get_simulator(&"tail").get_setting_count() == 1
	secondary.clear_solo()
	var restored_ok: bool = secondary.is_group_enabled(&"hair") \
		and secondary.get_simulator(&"hair").get_setting_count() == secondary.group_chain_count(&"hair")
	_assert_test("Preview can toggle groups and solo a single chain", ears_off and ears_on and solo_ok and restored_ok)

	model.skeleton.skeleton_updated.disconnect(sample)
	_finish()


func _max_step_degrees(samples: Array[Quaternion], tail_count: int) -> float:
	if samples.size() < 2:
		return 999.0
	var start: int = maxi(1, samples.size() - tail_count)
	var max_step: float = 0.0
	for index in range(start, samples.size()):
		max_step = maxf(max_step, rad_to_deg(samples[index - 1].angle_to(samples[index])))
	return max_step


func _assert_test(label: String, condition: bool) -> void:
	if condition:
		_passed += 1
		print("[PASS] ", label)
	else:
		_failed += 1
		printerr("[FAIL] ", label)


func _finish() -> void:
	print("==================================================")
	print("Results: Total=%d | Passed=%d | Failed=%d" % [_passed + _failed, _passed, _failed])
	print("==================================================")
	quit(1 if _failed > 0 else 0)
