class_name SoldierEnemy
extends CharacterBody3D

const UAL_SCENE: PackedScene = preload("res://assets/animations/quaternius/universal_animation_library_standard.glb")

## Basic Melee Soldier Enemy for VEILBOUND
## Features a dedicated state machine: Patrol, Chase, Telegraph, Attack, Recovery, Stagger, and Death.
## Fully integrates with Player's LockOnComponent, MeleeAttackComponent, and directional Guard.

enum State {
	IDLE,
	PATROL,
	CHASE,
	TELEGRAPH,
	ATTACK,
	RECOVERY,
	STAGGERED,
	RETURNING,
	DEAD,
}

signal state_changed(previous_state: State, new_state: State)
signal telegraph_started()
signal attack_executed(target: Node3D, damage: float)
signal stagger_received()
signal died()

@export_group("State")
@export var current_state: State = State.IDLE

@export_group("Perception & Movement")
@export var detection_radius: float = 10.0
@export var preferred_attack_distance: float = 1.8
@export var lose_target_distance: float = 14.0
@export var max_patrol_leash: float = 18.0
@export var chase_speed: float = 3.5
@export var patrol_speed: float = 1.6
@export var rotation_speed: float = 8.0
@export var patrol_pause_duration: float = 1.5
@export var patrol_points: Array[Vector3] = [Vector3.ZERO, Vector3(0.0, 0.0, 4.0)]

@export_group("Combat Tuning")
@export var telegraph_duration: float = 0.65
@export var attack_damage: float = 18.0
@export var attack_range: float = 1.9
@export var recovery_duration: float = 0.9
@export var attack_cooldown: float = 1.2

# Node references
@onready var health: HealthComponent = get_node_or_null("HealthComponent")
@onready var poise: PoiseComponent = get_node_or_null("PoiseComponent")
@onready var lock_on_target: LockOnTarget = get_node_or_null("LockOnTarget")
@onready var visual_root: Node3D = get_node_or_null("VisualRoot")
@onready var body_mesh: MeshInstance3D = get_node_or_null("VisualRoot/BodyMesh")
@onready var weapon_mesh: MeshInstance3D = get_node_or_null("VisualRoot/WeaponMesh")
@onready var nav_agent: NavigationAgent3D = get_node_or_null("NavigationAgent3D")
@onready var anim_player: AnimationPlayer = null
@onready var skeleton: Skeleton3D = null
var _ual_animation_ready: bool = false

# Navigation tracking
const REPATH_INTERVAL: float = 0.2
const ATTACK_ACTIVE_START: float = 0.35
const ATTACK_ACTIVE_DURATION: float = 0.12
const ATTACK_CLIP_FALLBACK_DURATION: float = 0.65
var _nav_target_position: Vector3 = Vector3(INF, INF, INF)
var _nav_repath_timer: float = 0.0

# Runtime tracking
var spawn_position: Vector3 = Vector3.ZERO
var _target_player: Node3D = null
var _current_patrol_index: int = 0
var _state_timer: float = 0.0
var _cooldown_timer: float = 0.0
var _has_attacked_this_swing: bool = false

# Visual materials
var _original_body_mat: StandardMaterial3D = null
var _telegraph_mat: StandardMaterial3D = null
var _flash_mat: StandardMaterial3D = null
var _stagger_mat: StandardMaterial3D = null
var _flash_timer: float = 0.0
var _original_weapon_pos: Vector3 = Vector3.ZERO
var _original_weapon_rot: Vector3 = Vector3.ZERO


func _ready() -> void:
	spawn_position = global_position
	_resolve_components()
	_setup_visuals()
	_play_anim("soldier/idle", 0.0)


func _resolve_components() -> void:
	if health == null:
		health = get_node_or_null("HealthComponent")
	if health != null:
		if not health.damaged.is_connected(_on_damaged):
			health.damaged.connect(_on_damaged)
		if not health.died.is_connected(_on_died):
			health.died.connect(_on_died)

	if poise == null:
		poise = get_node_or_null("PoiseComponent")
	if poise != null:
		if not poise.stagger_started.is_connected(_on_stagger_started):
			poise.stagger_started.connect(_on_stagger_started)
		if not poise.stagger_ended.is_connected(_on_stagger_ended):
			poise.stagger_ended.connect(_on_stagger_ended)

	if lock_on_target == null:
		lock_on_target = get_node_or_null("LockOnTarget")
	if nav_agent == null:
		nav_agent = get_node_or_null("NavigationAgent3D")

	if visual_root == null:
		visual_root = get_node_or_null("VisualRoot")
	if body_mesh == null:
		body_mesh = find_child("Object_7", true, false) as MeshInstance3D
	if body_mesh == null:
		body_mesh = get_node_or_null("VisualRoot/BodyMesh")
	if weapon_mesh == null:
		weapon_mesh = get_node_or_null("VisualRoot/WeaponMesh")
	if anim_player == null:
		anim_player = find_child("AnimationPlayer", true, false) as AnimationPlayer
	if skeleton == null:
		skeleton = find_child("Skeleton3D", true, false) as Skeleton3D


func _setup_visuals() -> void:
	if anim_player != null and not anim_player.has_animation_library("soldier"):
		var lib := load("res://characters/enemies/soldier/soldier_animations.tres") as AnimationLibrary
		if lib != null:
			anim_player.add_animation_library("soldier", lib)
	if anim_player != null and anim_player.has_animation("Animation"):
		# The imported run cycle is the genuine patrol/chase clip. Loop it so
		# navigation state changes cannot leave the Soldier on its last frame.
		var run_animation: Animation = anim_player.get_animation("Animation")
		if run_animation != null:
			run_animation.loop_mode = Animation.LOOP_LINEAR
	_build_ual_animation_library()

	if skeleton != null and weapon_mesh != null and weapon_mesh.get_parent() != skeleton:
		var r_hand_idx := skeleton.find_bone("CC_Base_R_Hand_88")
		if r_hand_idx != -1:
			var hand_att := BoneAttachment3D.new()
			hand_att.name = "RightHandAttachment"
			hand_att.bone_name = "CC_Base_R_Hand_88"
			hand_att.bone_idx = r_hand_idx
			skeleton.add_child(hand_att)
			weapon_mesh.reparent(hand_att)
			weapon_mesh.scale = Vector3(25.7375, 25.7375, 25.7375)
			weapon_mesh.position = Vector3(0.0, 0.0, 0.0)
			weapon_mesh.rotation = Vector3(0.0, 0.0, 0.0)

	if body_mesh != null and body_mesh.get_active_material(0) != null:
		_original_body_mat = body_mesh.get_active_material(0).duplicate() as StandardMaterial3D
		body_mesh.material_override = _original_body_mat

		_telegraph_mat = _original_body_mat.duplicate() as StandardMaterial3D
		_telegraph_mat.albedo_color = Color(1.0, 0.45, 0.2, 1.0)
		_telegraph_mat.emission_enabled = true
		_telegraph_mat.emission = Color(1.0, 0.2, 0.05, 1.0)
		_telegraph_mat.emission_energy_multiplier = 2.0

		_flash_mat = _original_body_mat.duplicate() as StandardMaterial3D
		_flash_mat.albedo_color = Color(1.0, 0.95, 0.85, 1.0)
		_flash_mat.emission_enabled = true
		_flash_mat.emission = Color(1.0, 0.9, 0.3, 1.0)
		_flash_mat.emission_energy_multiplier = 2.5

		_stagger_mat = _original_body_mat.duplicate() as StandardMaterial3D
		_stagger_mat.albedo_color = Color(1.0, 0.65, 0.3, 1.0)
		_stagger_mat.emission_enabled = true
		_stagger_mat.emission = Color(1.0, 0.5, 0.1, 1.0)
		_stagger_mat.emission_energy_multiplier = 2.2

	if weapon_mesh != null:
		_original_weapon_pos = weapon_mesh.position
		_original_weapon_rot = weapon_mesh.rotation


func _build_ual_animation_library() -> void:
	if _ual_animation_ready or anim_player == null or skeleton == null:
		return
	var source_instance: Node3D = UAL_SCENE.instantiate() as Node3D
	if source_instance == null:
		return
	add_child(source_instance)
	source_instance.visible = false
	var source_player: AnimationPlayer = source_instance.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var source_skeleton: Skeleton3D = source_instance.find_child("Skeleton3D", true, false) as Skeleton3D
	if source_player == null or source_skeleton == null or not source_player.has_animation_library(""):
		source_instance.queue_free()
		return
	var source_library: AnimationLibrary = source_player.get_animation_library("")
	var target_library := AnimationLibrary.new()
	var clip_map: Dictionary = {
		"idle": "Idle",
		"walk": "Walk",
		"sprint": "Sprint",
		"attack": "Sword_Attack",
		"hit": "Hit_Chest",
		"death": "Death01",
		# Telegraph previously stayed on the custom upper-body-only clip: any
		# limb it ignored fell back to the mesh's authored "running panic" rest
		# pose and looked rubbery. Punch_Enter is a real full-body windup tell.
		"telegraph": "Punch_Enter",
	}
	for target_name: String in clip_map:
		var source_name: String = clip_map[target_name]
		if not source_library.has_animation(source_name):
			continue
		var result: Animation = _retarget_ual_animation(source_library.get_animation(source_name), source_name, source_skeleton, source_player)
		if result != null and result.get_track_count() > 0:
			if target_name == "attack":
				_retime_animation(result, ATTACK_CLIP_FALLBACK_DURATION)
			if target_name in ["idle", "walk", "sprint", "telegraph"]:
				result.loop_mode = Animation.LOOP_LINEAR
			target_library.add_animation(target_name, result)
	if target_library.get_animation_list().size() > 0:
		anim_player.add_animation_library("soldier_ual", target_library)
		_ual_animation_ready = true
	source_instance.queue_free()


func _retime_animation(animation: Animation, target_length: float) -> void:
	if animation.length <= 0.0 or target_length <= 0.0:
		return
	var time_scale: float = target_length / animation.length
	for track_index in range(animation.get_track_count()):
		for key_index in range(animation.track_get_key_count(track_index)):
			var old_time: float = animation.track_get_key_time(track_index, key_index)
			animation.track_set_key_time(track_index, key_index, old_time * time_scale)
	animation.length = target_length


## Phase 2.8 retarget: per-sample GLOBAL rotation transfer.
##
## The previous formula (target_rest * source_rest^-1 * source_pose) assumes
## both rigs share the same local bone-axis conventions. They do not: the
## retargeted Idle put the Soldier's hands at shoulder height (verified with
## tests/diagnose_phase_2_8_soldier_pose.gd, source hands sit at hip level).
##
## The new approach transfers each source bone's MODEL-SPACE rotation onto the
## target through a single constant alignment rotation derived from the two
## rigs' rest-pose landmark axes (right-thigh vector = "right", pelvis→head =
## "up"). Local keys are back-solved from the accumulated target globals, so
## local axis conventions become irrelevant for mapped chains.
func _retarget_ual_animation(source: Animation, source_name: String, source_skeleton: Skeleton3D, source_player: AnimationPlayer) -> Animation:
	var align: Quaternion = _ual_align_rotation(source_skeleton)
	var pose_samples: Dictionary = {} # source bone idx -> { time: Quaternion }
	var mapped: Dictionary = {} # source bone idx -> target bone idx
	for track_index in range(source.get_track_count()):
		if source.track_get_type(track_index) != Animation.TYPE_ROTATION_3D:
			continue
		var source_path := String(source.track_get_path(track_index))
		var separator := source_path.rfind(":")
		if separator < 0:
			continue
		var source_bone: String = source_path.substr(separator + 1)
		var source_index: int = source_skeleton.find_bone(source_bone)
		if source_index < 0:
			continue
		if not pose_samples.has(source_index):
			pose_samples[source_index] = {}
		for key_index in range(source.track_get_key_count(track_index)):
			pose_samples[source_index][source.track_get_key_time(track_index, key_index)] = \
				(source.track_get_key_value(track_index, key_index) as Quaternion)
		if mapped.has(source_index):
			continue
		var target_index: int = skeleton.find_bone(_map_ual_bone(source_bone))
		if target_index >= 0:
			mapped[source_index] = target_index
	# Mapped-name bones the clip leaves WITHOUT rotation tracks (UAL "root",
	# "DEF-spine.001") are static ancestors: the source keeps them at rest, but
	# the target's own unmapped rest chain (RL_BoneRoot/Hip_99/Waist_98 lean)
	# does not represent the same orientation. Drive them explicitly from the
	# per-sample source pose so the whole upper-body invariant holds.
	for bone_index in range(source_skeleton.get_bone_count()):
		if mapped.has(bone_index):
			continue
		# The source "root" bone carries a ~90 deg baked rest pitch and is left
		# untouched by the clips; driving the target's rootJoint with it would
		# pitch the whole position tree (positions are not rotated by tracks).
		# Its rest(RL_BoneRoot x Hip_99) cancels out below, so leaving both
		# roots at rest preserves the layout AND the pose invariant.
		if source_skeleton.get_bone_name(bone_index) == "root":
			continue
		var static_target: int = skeleton.find_bone(_map_ual_bone(source_skeleton.get_bone_name(bone_index)))
		if static_target >= 0:
			mapped[bone_index] = static_target
	if mapped.is_empty():
		return null

	# Pelvis/hips position transfer (rescaled): source crouch/death/attack
	# body heights must carry over, otherwise the target keeps a standing
	# pelvis while the limb bends suggest crouching or collapsing.
	var source_hips_index: int = source_skeleton.find_bone("DEF-hips")
	var target_pelvis_index: int = skeleton.find_bone("CC_Base_Pelvis_30")
	var pelvis_scale_stand: float = 1.0
	var pelvis_offset: Vector3 = Vector3.ZERO
	var pelvis_track: int = -1
	if mapped.get(source_hips_index, -1) == target_pelvis_index:
		var source_stand: Vector3 = source_skeleton.get_bone_global_rest(source_hips_index).origin
		var target_stand: Vector3 = skeleton.get_bone_global_rest(target_pelvis_index).origin
		if source_stand.length_squared() > 0.0001:
			var align_basis: Basis = Basis(align)
			pelvis_scale_stand = maxf(0.01, target_stand.length() / maxf(0.01, source_stand.length()))
			# Calibrated so the rest/stand pose lands on the target's own rest
			# position; per-key offsets are rotated by the frame alignment.
			pelvis_offset = target_stand - (align_basis * (source_stand * pelvis_scale_stand))

	# One consistent sample grid: every rotation key time of every source bone
	# that participates in a mapped chain (ancestors included), plus the hips
	# position keys so pelvis heights (crouch / collapse / lunge) are sampled.
	var seen_times: Dictionary = {}
	for source_index: int in pose_samples:
		for time: float in pose_samples[source_index]:
			seen_times[float(time)] = true
	var pelvis_transfer: bool = mapped.get(source_hips_index, -1) == target_pelvis_index
	if pelvis_transfer:
		for track_index in range(source.get_track_count()):
			if source.track_get_type(track_index) != Animation.TYPE_POSITION_3D:
				continue
			var position_path := String(source.track_get_path(track_index))
			var position_separator: int = position_path.rfind(":")
			if position_separator < 0 or position_path.substr(position_separator + 1) != "DEF-hips":
				continue
			for key_index in range(source.track_get_key_count(track_index)):
				seen_times[source.track_get_key_time(track_index, key_index)] = true
	var union_times: Array[float] = []
	union_times.assign(seen_times.keys())
	union_times.sort()

	var result := Animation.new()
	result.length = source.length
	var target_root: Node3D = anim_player.get_parent() as Node3D
	var target_prefix: String = String(target_root.get_path_to(skeleton))
	var track_map: Dictionary = {} # target bone idx -> result track idx

	# Parents must be processed before children so accumulated target globals
	# are available when back-solving local keys.
	var order: Array[int] = []
	order.assign(mapped.keys())
	var depth_cache: Dictionary = {}
	order.sort_custom(func(a: int, b: int) -> bool:
		return _ual_bone_depth(source_skeleton, a, depth_cache) < _ual_bone_depth(source_skeleton, b, depth_cache))

	for time: float in union_times:
		source_player.play(source_name)
		source_player.seek(time, true)
		source_player.advance(0.0)
		var computed: Dictionary = {} # target bone idx -> target global rotation at this sample
		for source_index: int in order:
			var target_index: int = mapped[source_index]
			var source_global: Quaternion = source_skeleton.get_bone_global_pose(source_index).basis.get_rotation_quaternion()
			var target_global: Quaternion = align * source_global
			# Walk up the target chain to the nearest already-computed mapped
			# ancestor; unmapped target bones in between keep their rest rotation.
			var base_global: Quaternion = Quaternion.IDENTITY
			var rest_product: Quaternion = Quaternion.IDENTITY
			var walk: int = skeleton.get_bone_parent(target_index)
			while walk >= 0 and not computed.has(walk):
				rest_product = skeleton.get_bone_rest(walk).basis.get_rotation_quaternion() * rest_product
				walk = skeleton.get_bone_parent(walk)
			if walk >= 0:
				base_global = (computed[walk] as Quaternion) * rest_product
			var local_pose: Quaternion = base_global.inverse() * target_global
			if not track_map.has(target_index):
				var track: int = result.add_track(Animation.TYPE_ROTATION_3D)
				result.track_set_path(track, NodePath(target_prefix + ":" + skeleton.get_bone_name(target_index)))
				result.track_set_interpolation_type(track, Animation.INTERPOLATION_LINEAR)
				track_map[target_index] = track
			result.track_insert_key(track_map[target_index], time, local_pose)
			computed[target_index] = target_global
		if pelvis_transfer:
			if pelvis_track == -1:
				pelvis_track = result.add_track(Animation.TYPE_POSITION_3D)
				result.track_set_path(pelvis_track, NodePath(target_prefix + ":" + skeleton.get_bone_name(target_pelvis_index)))
				result.track_set_interpolation_type(pelvis_track, Animation.INTERPOLATION_LINEAR)
			# Source model-space hips position -> rescaled, frame-aligned target
			# global position -> back-solved pelvis local key.
			var source_hips_global_pos: Vector3 = source_skeleton.get_bone_global_pose(source_hips_index).origin
			var target_global_pos: Vector3 = Basis(align) * (source_hips_global_pos * pelvis_scale_stand) + pelvis_offset
			var pelvis_parent: int = skeleton.get_bone_parent(target_pelvis_index)
			var parent_transform: Transform3D = skeleton.get_bone_global_rest(pelvis_parent) if pelvis_parent >= 0 else Transform3D()
			result.track_insert_key(pelvis_track, time, parent_transform.affine_inverse() * target_global_pos)
	return result


func _ual_bone_depth(bone_skeleton: Skeleton3D, bone_index: int, cache: Dictionary) -> int:
	if cache.has(bone_index):
		return cache[bone_index]
	var depth: int = 0
	var walk: int = bone_skeleton.get_bone_parent(bone_index)
	while walk >= 0:
		depth += 1
		walk = bone_skeleton.get_bone_parent(walk)
	cache[bone_index] = depth
	return depth


## Constant rotation mapping the UAL source model frame onto the Soldier
## target model frame, derived from rest-pose landmark axes (pose independent).
var _ual_align_cache: Quaternion = Quaternion.IDENTITY
var _ual_align_valid: bool = false

func _ual_align_rotation(source_skeleton: Skeleton3D) -> Quaternion:
	if _ual_align_valid:
		return _ual_align_cache
	var landmarks: Array = [
		source_skeleton.find_bone("DEF-thigh.R"), source_skeleton.find_bone("DEF-thigh.L"),
		source_skeleton.find_bone("DEF-head"), source_skeleton.find_bone("DEF-hips"),
		skeleton.find_bone("CC_Base_R_Thigh_29"), skeleton.find_bone("CC_Base_L_Thigh_14"),
		skeleton.find_bone("CC_Base_Head_41"), skeleton.find_bone("CC_Base_Pelvis_30"),
	]
	var landmarks_missing: bool = false
	for landmark: int in landmarks:
		if landmark < 0:
			landmarks_missing = true
	if landmarks_missing:
		push_warning("Soldier UAL retarget: alignment landmarks missing; identity used.")
		_ual_align_valid = true
		return _ual_align_cache
	var x_src: Vector3 = (source_skeleton.get_bone_global_rest(landmarks[0]).origin \
		- source_skeleton.get_bone_global_rest(landmarks[1]).origin).normalized()
	var y_src: Vector3 = (source_skeleton.get_bone_global_rest(landmarks[2]).origin \
		- source_skeleton.get_bone_global_rest(landmarks[3]).origin).normalized()
	var x_tgt: Vector3 = (skeleton.get_bone_global_rest(landmarks[4]).origin \
		- skeleton.get_bone_global_rest(landmarks[5]).origin).normalized()
	var y_tgt: Vector3 = (skeleton.get_bone_global_rest(landmarks[6]).origin \
		- skeleton.get_bone_global_rest(landmarks[7]).origin).normalized()
	var z_src: Vector3 = x_src.cross(y_src).normalized()
	var z_tgt: Vector3 = x_tgt.cross(y_tgt).normalized()
	var y_src_ortho: Vector3 = z_src.cross(x_src).normalized()
	var y_tgt_ortho: Vector3 = z_tgt.cross(x_tgt).normalized()
	var source_basis: Basis = Basis(x_src, y_src_ortho, z_src)
	var target_basis: Basis = Basis(x_tgt, y_tgt_ortho, z_tgt)
	_ual_align_cache = (target_basis * source_basis.inverse()).get_rotation_quaternion()
	_ual_align_valid = true
	return _ual_align_cache


func _map_ual_bone(source_bone: String) -> String:
	var normalized: String = source_bone.trim_prefix("DEF-")
	var side: String = ""
	if normalized.ends_with(".L"):
		side = "L"
		normalized = normalized.trim_suffix(".L")
	elif normalized.ends_with(".R"):
		side = "R"
		normalized = normalized.trim_suffix(".R")
	match normalized:
		"root": return "GLTF_created_0_rootJoint"
		"hips": return "CC_Base_Pelvis_30"
		"spine.001": return "CC_Base_Waist_98"
		"spine.002": return "CC_Base_Spine01_97"
		"spine.003": return "CC_Base_Spine02_96"
		"neck": return "CC_Base_NeckTwist02_42"
		"head": return "CC_Base_Head_41"
		"shoulder": return "CC_Base_%s_Clavicle_%s" % [side, "67" if side == "L" else "91"]
		"upper_arm": return "CC_Base_%s_Upperarm_%s" % [side, "66" if side == "L" else "90"]
		"forearm": return "CC_Base_%s_Forearm_%s" % [side, "63" if side == "L" else "89"]
		"hand": return "CC_Base_%s_Hand_%s" % [side, "62" if side == "L" else "88"]
		"thigh": return "CC_Base_%s_Thigh_%s" % [side, "14" if side == "L" else "29"]
		"shin": return "CC_Base_%s_Calf_%s" % [side, "11" if side == "L" else "28"]
		"foot": return "CC_Base_%s_Foot_%s" % [side, "7" if side == "L" else "24"]
		_: return ""


func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	# Apply gravity
	var grav: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
	if not is_on_floor():
		velocity.y -= grav * delta
	else:
		if velocity.y < 0.0:
			velocity.y = 0.0

	# Decrement cooldown
	if _cooldown_timer > 0.0:
		_cooldown_timer = maxf(0.0, _cooldown_timer - delta)

	# Decrement navigation repath timer
	if _nav_repath_timer > 0.0:
		_nav_repath_timer = maxf(0.0, _nav_repath_timer - delta)

	# Decrement material flash timer
	if _flash_timer > 0.0:
		_flash_timer = maxf(0.0, _flash_timer - delta)
		if _flash_timer <= 0.0:
			_restore_visuals()

	# Execute current state logic
	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.PATROL:
			_process_patrol(delta)
		State.CHASE:
			_process_chase(delta)
		State.TELEGRAPH:
			_process_telegraph(delta)
		State.ATTACK:
			_process_attack(delta)
		State.RECOVERY:
			_process_recovery(delta)
		State.STAGGERED:
			_process_staggered(delta)
		State.RETURNING:
			_process_returning(delta)

	move_and_slide()


# -----------------------------------------------------------------------------
# STATE MACHINE TRANSITIONS
# -----------------------------------------------------------------------------
func _change_state(new_state: State) -> void:
	if current_state == new_state or current_state == State.DEAD:
		return

	var prev: State = current_state

	# --- EXIT PREVIOUS STATE ---
	match prev:
		State.TELEGRAPH:
			_restore_visuals()
		State.ATTACK:
			_restore_visuals()

	current_state = new_state
	_state_timer = 0.0

	# --- ENTER NEW STATE ---
	match current_state:
		State.IDLE:
			velocity.x = 0.0
			velocity.z = 0.0
			_play_anim("soldier_ual/idle" if _ual_animation_ready else "soldier/idle", 0.2)
		State.PATROL:
			_nav_target_position = Vector3(INF, INF, INF)
			_nav_repath_timer = 0.0
			_play_anim("soldier_ual/walk" if _ual_animation_ready else "Animation", 0.15)
			if not patrol_points.is_empty():
				_update_navigation_target(spawn_position + patrol_points[_current_patrol_index], true)
		State.CHASE:
			_nav_target_position = Vector3(INF, INF, INF)
			_nav_repath_timer = 0.0
			_play_anim("soldier_ual/sprint" if _ual_animation_ready else "Animation", 0.12)
			if _target_player != null:
				_update_navigation_target(_target_player.global_position, true)
		State.TELEGRAPH:
			velocity.x = 0.0
			velocity.z = 0.0
			_show_telegraph_visuals()
			_play_anim("soldier_ual/telegraph" if _ual_animation_ready else "soldier/telegraph", 0.08)
			telegraph_started.emit()
		State.ATTACK:
			velocity.x = 0.0
			velocity.z = 0.0
			_has_attacked_this_swing = false
			_play_anim("soldier_ual/attack" if _ual_animation_ready else "soldier/attack", 0.05)
		State.RECOVERY:
			velocity.x = 0.0
			velocity.z = 0.0
			_restore_visuals()
			_play_anim("soldier_ual/idle" if _ual_animation_ready else "soldier/idle", 0.15)
		State.STAGGERED:
			velocity.x = 0.0
			velocity.z = 0.0
			_restore_visuals()
			_play_anim("soldier_ual/hit" if _ual_animation_ready else "soldier/stagger", 0.05)
			stagger_received.emit()
		State.RETURNING:
			_target_player = null
			_nav_target_position = Vector3(INF, INF, INF)
			_nav_repath_timer = 0.0
			_play_anim("soldier_ual/sprint" if _ual_animation_ready else "Animation", 0.15)
			_update_navigation_target(spawn_position, true)
		State.DEAD:
			velocity = Vector3.ZERO
			_restore_visuals()
			_apply_dead_visuals()
			_play_anim("soldier_ual/death" if _ual_animation_ready else "soldier/death", 0.1)
			if lock_on_target != null:
				lock_on_target.is_targetable = false
			died.emit()

	state_changed.emit(prev, current_state)


# -----------------------------------------------------------------------------
# STATE PROCESSING LOGIC
# -----------------------------------------------------------------------------
func _process_idle(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)

	# Check for player detection
	var p: Node3D = _detect_player()
	if p != null:
		_target_player = p
		_change_state(State.CHASE)
		return

	_state_timer += delta
	if _state_timer >= patrol_pause_duration:
		_current_patrol_index = (_current_patrol_index + 1) % maxi(1, patrol_points.size())
		_change_state(State.PATROL)


func _process_patrol(delta: float) -> void:
	# Check for player detection
	var p: Node3D = _detect_player()
	if p != null:
		_target_player = p
		_change_state(State.CHASE)
		return

	if patrol_points.is_empty():
		_change_state(State.IDLE)
		return

	var dest: Vector3 = spawn_position + patrol_points[_current_patrol_index]
	var to_dest: Vector3 = dest - global_position
	to_dest.y = 0.0

	var dist: float = to_dest.length()
	if dist <= 0.4:
		_change_state(State.IDLE)
		return

	var move_dir: Vector3 = to_dest.normalized()
	if nav_agent != null:
		_update_navigation_target(dest)
		if not nav_agent.is_target_reached():
			var next_pos: Vector3 = nav_agent.get_next_path_position()
			var to_next: Vector3 = next_pos - global_position
			to_next.y = 0.0
			if to_next.length_squared() > 0.01:
				move_dir = to_next.normalized()

	velocity.x = move_dir.x * patrol_speed
	velocity.z = move_dir.z * patrol_speed
	_face_direction(move_dir, delta)


func _process_chase(delta: float) -> void:
	if not is_instance_valid(_target_player) or not _is_target_valid(_target_player):
		_target_player = null
		_change_state(State.RETURNING)
		return

	var to_target: Vector3 = _target_player.global_position - global_position
	to_target.y = 0.0
	var dist: float = to_target.length()

	# Leash check from home
	var dist_from_spawn: float = (global_position - spawn_position).length()
	if dist > lose_target_distance or dist_from_spawn > max_patrol_leash:
		_change_state(State.RETURNING)
		return

	# Check if close enough to attack
	if dist <= preferred_attack_distance:
		velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
		_face_direction(to_target.normalized(), delta * 1.5)
		if _cooldown_timer <= 0.0:
			_change_state(State.TELEGRAPH)
		return

	# Move toward player (using navigation path when available)
	var move_dir: Vector3 = to_target.normalized()
	if nav_agent != null:
		_update_navigation_target(_target_player.global_position)
		if not nav_agent.is_target_reached():
			var next_pos: Vector3 = nav_agent.get_next_path_position()
			var to_next: Vector3 = next_pos - global_position
			to_next.y = 0.0
			if to_next.length_squared() > 0.01:
				move_dir = to_next.normalized()

	velocity.x = move_dir.x * chase_speed
	velocity.z = move_dir.z * chase_speed
	_face_direction(move_dir, delta)


func _process_telegraph(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)

	# Keep facing target during telegraph for readability
	if _is_target_valid(_target_player):
		var to_target: Vector3 = _target_player.global_position - global_position
		to_target.y = 0.0
		if to_target.length_squared() > 0.01:
			_face_direction(to_target.normalized(), delta * 1.5)

	_state_timer += delta
	if _state_timer >= telegraph_duration:
		_change_state(State.ATTACK)


func _process_attack(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)

	_state_timer += delta
	# The visible attack clip starts moving the raised arm at roughly 0.35s.
	# Damage is delayed to that authored strike window instead of firing when
	# the state is entered, which previously made the Soldier hit too early.
	if not _has_attacked_this_swing and _state_timer >= ATTACK_ACTIVE_START:
		_execute_melee_hit()
		_has_attacked_this_swing = true

	var attack_clip_name: String = "soldier_ual/attack" if _ual_animation_ready else "soldier/attack"
	var attack_duration: float = _get_animation_length(attack_clip_name, ATTACK_CLIP_FALLBACK_DURATION)
	var minimum_duration: float = ATTACK_ACTIVE_START + ATTACK_ACTIVE_DURATION
	if _state_timer >= maxf(attack_duration, minimum_duration):
		_change_state(State.RECOVERY)


func _process_recovery(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)

	_state_timer += delta
	if _state_timer >= recovery_duration:
		_cooldown_timer = attack_cooldown
		if _is_target_valid(_target_player):
			var dist: float = global_position.distance_to(_target_player.global_position)
			if dist <= lose_target_distance:
				_change_state(State.CHASE)
				return
		_change_state(State.RETURNING)


func _process_staggered(_delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0


func _process_returning(delta: float) -> void:
	# Check if player re-entered detection range while returning
	var p: Node3D = _detect_player()
	if p != null:
		var dist_from_spawn: float = (p.global_position - spawn_position).length()
		if dist_from_spawn <= max_patrol_leash:
			_target_player = p
			_change_state(State.CHASE)
			return

	var to_spawn: Vector3 = spawn_position - global_position
	to_spawn.y = 0.0
	var dist: float = to_spawn.length()

	if dist <= 0.6:
		_change_state(State.IDLE)
		return

	var move_dir: Vector3 = to_spawn.normalized()
	if nav_agent != null:
		_update_navigation_target(spawn_position)
		if not nav_agent.is_target_reached():
			var next_pos: Vector3 = nav_agent.get_next_path_position()
			var to_next: Vector3 = next_pos - global_position
			to_next.y = 0.0
			if to_next.length_squared() > 0.01:
				move_dir = to_next.normalized()

	velocity.x = move_dir.x * patrol_speed
	velocity.z = move_dir.z * patrol_speed
	_face_direction(move_dir, delta)


func _update_navigation_target(target_pos: Vector3, force: bool = false) -> void:
	if nav_agent == null:
		return
	var moved_dist: float = _nav_target_position.distance_to(target_pos)
	if force or moved_dist > 0.5 or _nav_repath_timer <= 0.0:
		_nav_target_position = target_pos
		nav_agent.target_position = target_pos
		_nav_repath_timer = REPATH_INTERVAL


# -----------------------------------------------------------------------------
# COMBAT & ATTACK EXECUTION
# -----------------------------------------------------------------------------
func _execute_melee_hit() -> void:
	if current_state == State.DEAD or current_state == State.STAGGERED:
		return
	if health != null and health.is_dead():
		return
	if not _is_target_valid(_target_player):
		return

	var dist: float = global_position.distance_to(_target_player.global_position)
	if dist > attack_range + 0.5:
		return

	# Line of sight check against environment obstacles
	if not _has_line_of_sight_to(_target_player):
		return

	# Apply damage through player's centralized incoming-damage routing entry point
	if _target_player.has_method("apply_incoming_damage"):
		_target_player.apply_incoming_damage(attack_damage, global_position)
		attack_executed.emit(_target_player, attack_damage)
	elif _target_player.has_method("take_damage"):
		_target_player.take_damage(attack_damage)
		attack_executed.emit(_target_player, attack_damage)


func _has_line_of_sight_to(target: Node3D) -> bool:
	if not is_inside_tree() or target == null:
		return true

	var space_state := get_world_3d().direct_space_state
	var from_pos: Vector3 = global_position + Vector3(0.0, 1.2, 0.0)
	var to_pos: Vector3 = target.global_position + Vector3(0.0, 1.2, 0.0)

	var query := PhysicsRayQueryParameters3D.create(
		from_pos,
		to_pos,
		1, # World obstacles only (Layer 1)
		[get_rid()]
	)

	var result := space_state.intersect_ray(query)
	return result.is_empty()


# -----------------------------------------------------------------------------
# PERCEPTION & TARGETING HELPERS
# -----------------------------------------------------------------------------
func _detect_player() -> Node3D:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	for node in players:
		var p := node as Node3D
		if _is_target_valid(p):
			var dist: float = global_position.distance_to(p.global_position)
			if dist <= detection_radius and _has_line_of_sight_to(p):
				return p
	return null


func _is_target_valid(p: Variant) -> bool:
	if p == null or not is_instance_valid(p):
		return false
	if not (p is Node3D) or not (p as Node3D).is_inside_tree():
		return false
	var p_health: HealthComponent = p.get_node_or_null("HealthComponent") as HealthComponent
	if p_health != null and p_health.is_dead():
		return false
	return true


func _face_direction(dir: Vector3, delta: float) -> void:
	if dir.length_squared() < 0.001 or visual_root == null:
		return
	var target_yaw: float = atan2(-dir.x, -dir.z)
	visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_yaw, rotation_speed * delta)


# -----------------------------------------------------------------------------
# VISUAL FEEDBACK
# -----------------------------------------------------------------------------
func _show_telegraph_visuals() -> void:
	if body_mesh != null and _telegraph_mat != null:
		body_mesh.material_override = _telegraph_mat
	if weapon_mesh != null:
		weapon_mesh.position = _original_weapon_pos + Vector3(0.1, 0.2, 0.1)
		weapon_mesh.rotation.x = _original_weapon_rot.x + deg_to_rad(-35.0)


func trigger_hit_flash() -> void:
	if current_state == State.DEAD:
		return
	if body_mesh != null and _flash_mat != null:
		body_mesh.material_override = _flash_mat
		_flash_timer = 0.08


func trigger_stagger_flash() -> void:
	if current_state == State.DEAD:
		return
	if body_mesh != null and _stagger_mat != null:
		body_mesh.material_override = _stagger_mat
		_flash_timer = 0.20


func _restore_visuals() -> void:
	if body_mesh != null and not (health != null and health.is_dead()):
		if current_state == State.STAGGERED and _stagger_mat != null:
			body_mesh.material_override = _stagger_mat
		elif current_state == State.TELEGRAPH and _telegraph_mat != null:
			body_mesh.material_override = _telegraph_mat
		elif _original_body_mat != null:
			body_mesh.material_override = _original_body_mat
	if weapon_mesh != null:
		weapon_mesh.position = _original_weapon_pos
		weapon_mesh.rotation = _original_weapon_rot


func _apply_dead_visuals() -> void:
	_flash_timer = 0.0
	if body_mesh != null:
		var dead_mat := StandardMaterial3D.new()
		dead_mat.albedo_color = Color(0.2, 0.22, 0.25, 1.0)
		dead_mat.roughness = 0.9
		body_mesh.material_override = dead_mat
	if visual_root != null:
		visual_root.rotation.x = deg_to_rad(85.0) # Collapsed on ground
		visual_root.position.y = -0.3


# -----------------------------------------------------------------------------
# HEALTH & POISE DAMAGE INTEGRATION
# -----------------------------------------------------------------------------
func take_damage(amount: float) -> void:
	if health != null and not health.is_dead():
		health.take_damage(amount)


func apply_posture_damage(amount: float) -> void:
	if poise != null and not (health != null and health.is_dead()):
		poise.apply_posture_damage(amount)


func is_staggered() -> bool:
	return poise != null and poise.is_staggered()


func get_state_name() -> String:
	match current_state:
		State.IDLE: return "IDLE"
		State.PATROL: return "PATROL"
		State.CHASE: return "CHASE"
		State.TELEGRAPH: return "TELEGRAPH"
		State.ATTACK: return "ATTACK"
		State.RECOVERY: return "RECOVERY"
		State.STAGGERED: return "STAGGERED"
		State.RETURNING: return "RETURNING"
		State.DEAD: return "DEAD"
		_: return "UNKNOWN"


func _on_damaged(_amount: float, _current: float) -> void:
	trigger_hit_flash()


func _on_stagger_started() -> void:
	_change_state(State.STAGGERED)
	trigger_stagger_flash()


func _on_stagger_ended() -> void:
	if current_state == State.DEAD:
		return
	if _is_target_valid(_target_player):
		var dist: float = global_position.distance_to(_target_player.global_position)
		if dist <= lose_target_distance:
			_change_state(State.CHASE)
			return
	_change_state(State.RETURNING)


func _on_died() -> void:
	_change_state(State.DEAD)


func _play_anim(anim_name: String, blend_time: float = 0.1) -> void:
	if anim_player != null and anim_player.has_animation(anim_name):
		if anim_player.current_animation != anim_name:
			anim_player.play(anim_name, blend_time)


func _get_animation_length(anim_name: String, fallback: float) -> float:
	if anim_player == null or not anim_player.has_animation(anim_name):
		return fallback
	var animation: Animation = anim_player.get_animation(anim_name)
	return animation.length if animation != null and animation.length > 0.0 else fallback
