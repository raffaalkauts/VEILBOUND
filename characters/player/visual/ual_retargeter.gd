class_name UalRetargeter
extends RefCounted

## Retargets Quaternius Universal Animation Library clips onto the 211-bone
## protagonist rig using a per-sample GLOBAL rotation transfer.
##
## Same technique as SoldierEnemy._retarget_ual_animation (proven in Phase 2.8):
## each source bone's model-space rotation is carried onto the target through
## one constant frame-alignment rotation derived from rest-pose landmarks, and
## local keys are back-solved from accumulated target globals. Local bone-axis
## conventions of the two rigs therefore stop mattering for mapped chains.
##
## One deliberate difference: when a mapped bone has NO mapped ancestor, its
## base is the product of the unmapped ancestors' rest rotations rather than
## identity, so rigs with a non-trivial root chain stay correct.

var _skeleton: Skeleton3D
var _anim_root: Node3D
var _map_bone: Callable
var _landmarks: Dictionary
var _pelvis_bone: String
var _align: Quaternion = Quaternion.IDENTITY
var _align_valid: bool = false


## landmarks keys: thigh_r, thigh_l, head, hips (target bone names).
func setup(skeleton: Skeleton3D, anim_root: Node3D, map_bone: Callable, landmarks: Dictionary, pelvis_bone: String) -> void:
	_skeleton = skeleton
	_anim_root = anim_root
	_map_bone = map_bone
	_landmarks = landmarks
	_pelvis_bone = pelvis_bone


func retarget(source: Animation, source_name: String, source_skeleton: Skeleton3D, source_player: AnimationPlayer) -> Animation:
	var align: Quaternion = _align_rotation(source_skeleton)
	var pose_samples: Dictionary = {}
	var mapped: Dictionary = {}
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
		var target_index: int = _skeleton.find_bone(_map_bone.call(source_bone))
		if target_index >= 0:
			mapped[source_index] = target_index
	# Static mapped ancestors (clip has no rotation track) still need driving.
	for bone_index in range(source_skeleton.get_bone_count()):
		if mapped.has(bone_index):
			continue
		var bone_name: String = source_skeleton.get_bone_name(bone_index)
		if bone_name == "root":
			continue
		var static_target: int = _skeleton.find_bone(_map_bone.call(bone_name))
		if static_target >= 0:
			mapped[bone_index] = static_target
	if mapped.is_empty():
		return null

	var source_hips_index: int = source_skeleton.find_bone("DEF-hips")
	var target_pelvis_index: int = _skeleton.find_bone(_pelvis_bone)
	var pelvis_transfer: bool = mapped.get(source_hips_index, -1) == target_pelvis_index and target_pelvis_index >= 0
	var pelvis_scale: float = 1.0
	var pelvis_offset: Vector3 = Vector3.ZERO
	var pelvis_track: int = -1
	if pelvis_transfer:
		var source_stand: Vector3 = source_skeleton.get_bone_global_rest(source_hips_index).origin
		var target_stand: Vector3 = _skeleton.get_bone_global_rest(target_pelvis_index).origin
		if source_stand.length_squared() > 0.0001:
			pelvis_scale = maxf(0.01, target_stand.length() / maxf(0.01, source_stand.length()))
			pelvis_offset = target_stand - (Basis(align) * (source_stand * pelvis_scale))
		else:
			pelvis_transfer = false

	var seen_times: Dictionary = {}
	for source_index: int in pose_samples:
		for time: float in pose_samples[source_index]:
			seen_times[float(time)] = true
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
	var target_prefix: String = String(_anim_root.get_path_to(_skeleton))
	var track_map: Dictionary = {}
	var order: Array[int] = []
	order.assign(mapped.keys())
	var depth_cache: Dictionary = {}
	order.sort_custom(func(a: int, b: int) -> bool:
		return _bone_depth(source_skeleton, a, depth_cache) < _bone_depth(source_skeleton, b, depth_cache))

	for time: float in union_times:
		source_player.play(source_name)
		source_player.seek(time, true)
		source_player.advance(0.0)
		var computed: Dictionary = {}
		for source_index: int in order:
			var target_index: int = mapped[source_index]
			var source_global: Quaternion = source_skeleton.get_bone_global_pose(source_index).basis.get_rotation_quaternion()
			var target_global: Quaternion = align * source_global
			if _is_axial(source_skeleton.get_bone_name(source_index)):
				var source_rest_global: Quaternion = source_skeleton.get_bone_global_rest(source_index).basis.get_rotation_quaternion()
				var target_rest_global: Quaternion = _skeleton.get_bone_global_rest(target_index).basis.get_rotation_quaternion()
				var delta_model: Quaternion = source_global * source_rest_global.inverse()
				target_global = align * delta_model * align.inverse() * target_rest_global
			var rest_product: Quaternion = Quaternion.IDENTITY
			var walk: int = _skeleton.get_bone_parent(target_index)
			while walk >= 0 and not computed.has(walk):
				rest_product = _skeleton.get_bone_rest(walk).basis.get_rotation_quaternion() * rest_product
				walk = _skeleton.get_bone_parent(walk)
			var base_global: Quaternion = rest_product
			if walk >= 0:
				base_global = (computed[walk] as Quaternion) * rest_product
			var local_pose: Quaternion = base_global.inverse() * target_global
			if not track_map.has(target_index):
				var track: int = result.add_track(Animation.TYPE_ROTATION_3D)
				result.track_set_path(track, NodePath(target_prefix + ":" + _skeleton.get_bone_name(target_index)))
				result.track_set_interpolation_type(track, Animation.INTERPOLATION_LINEAR)
				track_map[target_index] = track
			result.track_insert_key(track_map[target_index], time, local_pose)
			computed[target_index] = target_global
		if pelvis_transfer:
			if pelvis_track == -1:
				pelvis_track = result.add_track(Animation.TYPE_POSITION_3D)
				result.track_set_path(pelvis_track, NodePath(target_prefix + ":" + _pelvis_bone))
				result.track_set_interpolation_type(pelvis_track, Animation.INTERPOLATION_LINEAR)
			var source_pos: Vector3 = source_skeleton.get_bone_global_pose(source_hips_index).origin
			var target_pos: Vector3 = Basis(align) * (source_pos * pelvis_scale) + pelvis_offset
			var pelvis_parent: int = _skeleton.get_bone_parent(target_pelvis_index)
			var parent_xform: Transform3D = _skeleton.get_bone_global_rest(pelvis_parent) if pelvis_parent >= 0 else Transform3D()
			result.track_insert_key(pelvis_track, time, parent_xform.affine_inverse() * target_pos)
	return result


## Uniform retime of every key to a new clip length.
static func retime(animation: Animation, target_length: float) -> void:
	if animation.length <= 0.0 or target_length <= 0.0:
		return
	var scale: float = target_length / animation.length
	for track_index in range(animation.get_track_count()):
		for key_index in range(animation.track_get_key_count(track_index)):
			animation.track_set_key_time(track_index, key_index, animation.track_get_key_time(track_index, key_index) * scale)
	animation.length = target_length


## Piecewise-linear warp so the source time `source_peak` lands on
## `target_peak` while the whole clip ends at `target_length`. Used to place a
## swing apex inside the gameplay damage window.
static func warp(animation: Animation, source_peak: float, target_peak: float, target_length: float) -> void:
	var source_length: float = animation.length
	if source_length <= 0.0 or source_peak <= 0.0 or source_peak >= source_length or target_peak <= 0.0 or target_peak >= target_length:
		retime(animation, target_length)
		return
	var head_scale: float = target_peak / source_peak
	var tail_scale: float = (target_length - target_peak) / (source_length - source_peak)
	for track_index in range(animation.get_track_count()):
		for key_index in range(animation.track_get_key_count(track_index)):
			var old_time: float = animation.track_get_key_time(track_index, key_index)
			var new_time: float = old_time * head_scale if old_time <= source_peak else target_peak + (old_time - source_peak) * tail_scale
			animation.track_set_key_time(track_index, key_index, new_time)
	animation.length = target_length


func _is_axial(source_bone: String) -> bool:
	var n: String = source_bone.trim_prefix("DEF-")
	return n == "hips" or n.begins_with("spine") or n == "neck" or n == "head" or n.begins_with("shoulder")


func _bone_depth(bone_skeleton: Skeleton3D, bone_index: int, cache: Dictionary) -> int:
	if cache.has(bone_index):
		return cache[bone_index]
	var depth: int = 0
	var walk: int = bone_skeleton.get_bone_parent(bone_index)
	while walk >= 0:
		depth += 1
		walk = bone_skeleton.get_bone_parent(walk)
	cache[bone_index] = depth
	return depth


func _align_rotation(source_skeleton: Skeleton3D) -> Quaternion:
	if _align_valid:
		return _align
	_align_valid = true
	var ids: Array[int] = [
		source_skeleton.find_bone("DEF-thigh.R"), source_skeleton.find_bone("DEF-thigh.L"),
		source_skeleton.find_bone("DEF-head"), source_skeleton.find_bone("DEF-hips"),
		_skeleton.find_bone(_landmarks["thigh_r"]), _skeleton.find_bone(_landmarks["thigh_l"]),
		_skeleton.find_bone(_landmarks["head"]), _skeleton.find_bone(_landmarks["hips"]),
	]
	for id: int in ids:
		if id < 0:
			push_warning("UalRetargeter: alignment landmarks missing; identity used.")
			return _align
	var x_src: Vector3 = (source_skeleton.get_bone_global_rest(ids[0]).origin - source_skeleton.get_bone_global_rest(ids[1]).origin).normalized()
	var y_src: Vector3 = (source_skeleton.get_bone_global_rest(ids[2]).origin - source_skeleton.get_bone_global_rest(ids[3]).origin).normalized()
	var x_tgt: Vector3 = (_skeleton.get_bone_global_rest(ids[4]).origin - _skeleton.get_bone_global_rest(ids[5]).origin).normalized()
	var y_tgt: Vector3 = (_skeleton.get_bone_global_rest(ids[6]).origin - _skeleton.get_bone_global_rest(ids[7]).origin).normalized()
	var z_src: Vector3 = x_src.cross(y_src).normalized()
	var z_tgt: Vector3 = x_tgt.cross(y_tgt).normalized()
	var source_basis: Basis = Basis(x_src, z_src.cross(x_src).normalized(), z_src)
	var target_basis: Basis = Basis(x_tgt, z_tgt.cross(x_tgt).normalized(), z_tgt)
	_align = (target_basis * source_basis.inverse()).get_rotation_quaternion()
	return _align
