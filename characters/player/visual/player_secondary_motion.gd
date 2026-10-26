class_name PlayerSecondaryMotion
extends RefCounted

## Full-body secondary motion for the VEILBOUND protagonist.
##
## Uses Godot's native SpringBoneSimulator3D. Every simulator is created as a
## direct child of the imported Skeleton3D *before* that skeleton enters the
## scene tree, so the skeleton discovers it on POST_ENTER_TREE.
##
## The rig is authored in centimetres and imported with a 0.01 root scale.
## Spring gravity is expressed in simulator/world units, so values here are
## intentionally small (0.02 - 0.12 m/s^2) instead of real-world 9.8.
##
## Chains are grouped by motion profile so each group can be tuned and
## enabled/disabled independently:
##   hair        - 16 outer/inner hair chains + ahoge
##   ears        - left/right fox ear chains
##   tail        - 7-bone fox tail
##   clothing    - 9 jacket hem chains + belt
##   accessories - dogtag and chest follow-through
##
## One bone chain is owned by exactly one simulator/setting. No chain is
## simulated twice.

const GROUP_ORDER: Array[StringName] = [&"hair", &"ears", &"tail", &"clothing", &"accessories"]

const HEAD_BONE: String = "Shibahu_Head_05_130"
const TORSO_BONE: String = "Shibahu_Spine1_02_223"
const HIPS_BONE: String = "Shibahu_Hips_00_245"

## group, root-bone regex, profile id, human label
const CHAIN_DEFINITIONS: Array[Dictionary] = [
	{"group": &"hair", "regex": "^Shibahu_Hair[ABCD]1_", "profile": &"hair_long", "label": "back hair"},
	{"group": &"hair", "regex": "^Shibahu_Hair[EFGHIJK]1_", "profile": &"hair_side", "label": "side hair"},
	{"group": &"hair", "regex": "^Shibahu_Hair_In[A-E]1_", "profile": &"hair_inner", "label": "inner hair"},
	{"group": &"hair", "regex": "^Shibahu_Ahoge1_", "profile": &"ahoge", "label": "ahoge"},
	{"group": &"ears", "regex": "^Shibahu_Ear_Left1_", "profile": &"ear", "label": "left ear"},
	{"group": &"ears", "regex": "^Shibahu_Ear_Right1_", "profile": &"ear", "label": "right ear"},
	{"group": &"tail", "regex": "^Shibahu_Tail1_", "profile": &"tail", "label": "tail"},
	{"group": &"clothing", "regex": "^Shibahu_Jacket[A-I]1_", "profile": &"jacket", "label": "jacket hem"},
	{"group": &"clothing", "regex": "^Shibahu_Belt1_", "profile": &"belt", "label": "belt"},
	{"group": &"accessories", "regex": "^Shibahu_Dogtag1_", "profile": &"dogtag", "label": "dogtag"},
	{"group": &"accessories", "regex": "^Shibahu_Bust_Left1_", "profile": &"bust", "label": "bust L"},
	{"group": &"accessories", "regex": "^Shibahu_Bust_Right1_", "profile": &"bust", "label": "bust R"},
]

## stiffness: pull back toward the animated pose
## drag: velocity damping (higher = settles faster)
## gravity: world-space sag in m/s^2 (scaled for the 0.01 imported skeleton)
## radius: collision/self radius in metres
## impulse: multiplier for gameplay impulses (heavier parts react less)
const PROFILES: Dictionary = {
	&"hair_long": {"stiffness": 1.05, "drag": 0.52, "gravity": 0.030, "radius": 0.018, "impulse": 1.0},
	&"hair_side": {"stiffness": 0.90, "drag": 0.46, "gravity": 0.042, "radius": 0.016, "impulse": 1.15},
	&"hair_inner": {"stiffness": 1.25, "drag": 0.60, "gravity": 0.022, "radius": 0.014, "impulse": 0.85},
	&"ahoge": {"stiffness": 1.45, "drag": 0.58, "gravity": 0.018, "radius": 0.010, "impulse": 1.35},
	&"ear": {"stiffness": 1.55, "drag": 0.62, "gravity": 0.028, "radius": 0.012, "impulse": 1.2},
	&"tail": {"stiffness": 0.95, "drag": 0.50, "gravity": 0.050, "radius": 0.026, "impulse": 1.1},
	&"jacket": {"stiffness": 0.80, "drag": 0.55, "gravity": 0.075, "radius": 0.020, "impulse": 0.9},
	&"belt": {"stiffness": 1.10, "drag": 0.62, "gravity": 0.055, "radius": 0.018, "impulse": 0.7},
	&"dogtag": {"stiffness": 1.50, "drag": 0.66, "gravity": 0.120, "radius": 0.012, "impulse": 0.8},
	&"bust": {"stiffness": 1.70, "drag": 0.82, "gravity": 0.000, "radius": 0.012, "impulse": 0.5},
}

const MAX_IMPULSE: float = 1.6
const IMPULSE_DECAY: float = 5.0

var skeleton: Skeleton3D = null

var _simulators: Dictionary = {}   # StringName -> SpringBoneSimulator3D
var _chains: Array[Dictionary] = [] # id, group, profile, label, bone_names, root_bone, end_bone
var _chain_group: Dictionary = {}   # chain id -> group
var _impulse: Vector3 = Vector3.ZERO
var _last_speed: float = 0.0
var _was_in_air: bool = false
var _was_guarding: bool = false
var _was_attacking: bool = false
var _solo_chain: String = ""


## Must be called before the skeleton enters the scene tree.
func setup(p_skeleton: Skeleton3D) -> bool:
	skeleton = p_skeleton
	if skeleton == null or skeleton.get_bone_count() < 16:
		return false
	_collect_chains()
	if _chains.is_empty():
		return false
	for group: StringName in GROUP_ORDER:
		_create_group_simulator(group)
	return true


func is_ready() -> bool:
	return skeleton != null and not _chains.is_empty() and not _simulators.is_empty()


func chain_count() -> int:
	return _chains.size()


func get_chains() -> Array[Dictionary]:
	return _chains.duplicate(true)


func get_chain_group(chain_id: String) -> StringName:
	return _chain_group.get(chain_id, &"")


func get_group_names() -> Array[StringName]:
	return GROUP_ORDER.duplicate()


func get_simulator(group: StringName) -> SpringBoneSimulator3D:
	return _simulators.get(group, null) as SpringBoneSimulator3D


func group_chain_count(group: StringName) -> int:
	var total: int = 0
	for chain: Dictionary in _chains:
		if chain["group"] == group:
			total += 1
	return total


func set_group_enabled(group: StringName, enabled: bool) -> void:
	var sim: SpringBoneSimulator3D = get_simulator(group)
	if sim != null and _solo_chain == "":
		sim.active = enabled


func is_group_enabled(group: StringName) -> bool:
	var sim: SpringBoneSimulator3D = get_simulator(group)
	return sim != null and sim.active


## Development-only: keep a single chain alive so it can be inspected in isolation.
func solo_chain(chain_id: String) -> bool:
	if not _chain_group.has(chain_id):
		_solo_chain = ""
		_rebuild_all_settings()
		return false
	_solo_chain = chain_id
	for group: StringName in GROUP_ORDER:
		var sim: SpringBoneSimulator3D = get_simulator(group)
		if sim == null:
			continue
		if group == _chain_group[chain_id]:
			sim.active = true
			_apply_settings(sim, group, chain_id)
		else:
			sim.active = false
	return true


func clear_solo() -> void:
	_solo_chain = ""
	_rebuild_all_settings()


func apply_impulse(world_impulse: Vector3) -> void:
	_impulse = (_impulse + world_impulse).limit_length(MAX_IMPULSE)


func impulse_strength() -> float:
	return _impulse.length()


## Called every physics frame by PlayerCharacterModel.update_secondary_motion.
func update(delta: float, horizontal_speed: float, in_air: bool, guarding: bool, attacking: bool) -> void:
	if not is_ready():
		return
	# Gameplay transients get a clamped impulse; the authored animation keeps
	# driving the body, springs only add follow-through.
	if in_air and not _was_in_air:
		apply_impulse(Vector3.UP * 0.35)
	elif not in_air and _was_in_air:
		apply_impulse(Vector3.DOWN * 0.95)
	if attacking and not _was_attacking:
		apply_impulse(Vector3.FORWARD * 0.30)
	if guarding and not _was_guarding:
		apply_impulse(Vector3.FORWARD * 0.16)
	_was_in_air = in_air
	_was_guarding = guarding
	_was_attacking = attacking

	# Strong acceleration/deceleration adds a small directional kick. This is
	# capped so a teleport or respawn cannot fling the chains.
	var acceleration: float = (horizontal_speed - _last_speed) / maxf(delta, 0.0001)
	_last_speed = horizontal_speed
	var kick: float = clampf(acceleration * 0.010, -0.35, 0.35)
	if absf(kick) > 0.02:
		apply_impulse(-skeleton.global_transform.basis.z * kick)

	_impulse = _impulse.move_toward(Vector3.ZERO, IMPULSE_DECAY * delta)
	for group: StringName in GROUP_ORDER:
		var sim: SpringBoneSimulator3D = get_simulator(group)
		if sim == null or not sim.active:
			continue
		sim.external_force = _impulse * _group_impulse_scale(group)


## Reset all chains onto the authored pose (respawn, death, scene reload).
func reset() -> void:
	_impulse = Vector3.ZERO
	_last_speed = 0.0
	_was_in_air = false
	_was_guarding = false
	_was_attacking = false
	for group: StringName in GROUP_ORDER:
		var sim: SpringBoneSimulator3D = get_simulator(group)
		if sim != null:
			sim.reset()


func _group_impulse_scale(group: StringName) -> float:
	match group:
		&"hair":
			return 1.0
		&"ears":
			return 1.2
		&"tail":
			return 1.15
		&"clothing":
			return 0.85
		&"accessories":
			return 0.7
	return 1.0


func _collect_chains() -> void:
	for definition: Dictionary in CHAIN_DEFINITIONS:
		var regex := RegEx.new()
		if regex.compile(definition["regex"]) != OK:
			push_warning("Secondary motion: invalid chain regex %s" % definition["regex"])
			continue
		for bone_index in range(skeleton.get_bone_count()):
			var bone_name: String = skeleton.get_bone_name(bone_index)
			if regex.search(bone_name) == null:
				continue
			var parent_index: int = skeleton.get_bone_parent(bone_index)
			if parent_index >= 0 and regex.search(skeleton.get_bone_name(parent_index)) != null:
				continue
			var bone_chain: Array[int] = _walk_chain(bone_index)
			if bone_chain.size() < 2:
				continue
			var group: StringName = definition["group"]
			# Root bone names are unique, so group:root is a unique chain id
			# (the naive first label slice collided across Hair_In[A-E], both
			# ears and both bust chains).
			var chain_id: String = "%s:%s" % [group, bone_name.trim_prefix("Shibahu_")]
			_chains.append({
				"id": chain_id,
				"group": group,
				"profile": definition["profile"],
				"label": definition["label"],
				"bone_names": _bone_names(bone_chain),
				"root_bone": bone_chain[0],
				"end_bone": bone_chain[bone_chain.size() - 1],
			})
			_chain_group[chain_id] = group


func _walk_chain(root_bone: int) -> Array[int]:
	var chain: Array[int] = [root_bone]
	var cursor: int = root_bone
	var guard: int = 0
	while guard < 12:
		var children: PackedInt32Array = skeleton.get_bone_children(cursor)
		if children.is_empty():
			break
		cursor = children[0]
		chain.append(cursor)
		guard += 1
	return chain


func _bone_names(bone_indices: Array[int]) -> Array[String]:
	var names: Array[String] = []
	for bone_index: int in bone_indices:
		names.append(skeleton.get_bone_name(bone_index))
	return names


func _create_group_simulator(group: StringName) -> void:
	var sim := SpringBoneSimulator3D.new()
	sim.name = "SecondarySpring_%s" % group
	sim.mutable_bone_axes = false
	skeleton.add_child(sim)
	_simulators[group] = sim
	_create_collisions(sim, group)
	_apply_settings(sim, group, "")


func _rebuild_all_settings() -> void:
	for group: StringName in GROUP_ORDER:
		var sim: SpringBoneSimulator3D = get_simulator(group)
		if sim == null:
			continue
		sim.active = true
		_apply_settings(sim, group, "")


func _apply_settings(sim: SpringBoneSimulator3D, group: StringName, solo_id: String) -> void:
	var selected: Array[Dictionary] = []
	for chain: Dictionary in _chains:
		if chain["group"] != group:
			continue
		if solo_id != "" and chain["id"] != solo_id:
			continue
		selected.append(chain)

	sim.set_setting_count(0)
	if selected.is_empty():
		return
	sim.set_setting_count(selected.size())

	var collision_count: int = _collision_count_for_group(group)
	for setting_index in range(selected.size()):
		var chain: Dictionary = selected[setting_index]
		var profile: Dictionary = PROFILES[chain["profile"]]
		var stiffness: float = float(profile["stiffness"])
		var drag: float = float(profile["drag"])
		var gravity: float = float(profile["gravity"])
		# Deterministic per-chain variation keeps strands from moving as a
		# single rigid block without needing unique hand-authored values.
		var variation: float = 1.0 + 0.07 * float((setting_index % 3) - 1)
		sim.set_root_bone(setting_index, int(chain["root_bone"]))
		sim.set_end_bone(setting_index, int(chain["end_bone"]))
		sim.set_rotation_axis(setting_index, SpringBoneSimulator3D.ROTATION_AXIS_ALL)
		sim.set_stiffness(setting_index, stiffness * variation)
		sim.set_drag(setting_index, clampf(drag * (2.0 - variation), 0.05, 0.95))
		sim.set_gravity(setting_index, gravity * (2.0 - variation))
		sim.set_radius(setting_index, float(profile["radius"]))
		sim.set_center_from(setting_index, SpringBoneSimulator3D.CENTER_FROM_WORLD_ORIGIN)
		sim.set_collision_count(setting_index, collision_count)
		for collision_index in range(collision_count):
			sim.set_collision_path(setting_index, collision_index, NodePath(_collision_name(group, collision_index)))


func _collision_count_for_group(group: StringName) -> int:
	match group:
		&"hair", &"ears", &"accessories":
			return 2
		&"tail", &"clothing":
			return 2
	return 0


func _collision_name(group: StringName, index: int) -> String:
	return "HeadCollision" if index == 0 else "BodyCollision"


func _create_collisions(sim: SpringBoneSimulator3D, group: StringName) -> void:
	if _collision_count_for_group(group) == 0:
		return
	# Head sphere: keeps hair/ears/accessories out of the skull.
	var head := SpringBoneCollisionSphere3D.new()
	head.name = _collision_name(group, 0)
	head.bone_name = HEAD_BONE
	head.position_offset = Vector3(0.0, 9.0, 0.0)
	head.radius = 0.105
	sim.add_child(head)

	# Body capsule: keeps long hair and jacket hems out of the torso.
	var body := SpringBoneCollisionCapsule3D.new()
	body.name = _collision_name(group, 1)
	body.bone_name = TORSO_BONE
	body.position_offset = Vector3(0.0, 7.0, 0.0)
	body.radius = 0.095
	body.height = 0.26
	sim.add_child(body)
