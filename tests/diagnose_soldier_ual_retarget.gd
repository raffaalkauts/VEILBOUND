extends SceneTree

const UAL_SCENE: PackedScene = preload("res://assets/animations/quaternius/universal_animation_library_standard.glb")
const SOLDIER_SCENE: PackedScene = preload("res://characters/enemies/soldier/anime-girl_running_panic.glb")

func _init() -> void:
	var source_instance: Node3D = UAL_SCENE.instantiate() as Node3D
	var target_instance: Node3D = SOLDIER_SCENE.instantiate() as Node3D
	root.add_child(source_instance)
	root.add_child(target_instance)
	var source_player: AnimationPlayer = source_instance.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var source_skeleton: Skeleton3D = source_instance.find_child("Skeleton3D", true, false) as Skeleton3D
	var target_player: AnimationPlayer = target_instance.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var target_skeleton: Skeleton3D = target_instance.find_child("Skeleton3D", true, false) as Skeleton3D
	print("target player path=", target_instance.get_path_to(target_player), " parent=", target_player.get_parent().name, " skeleton path=", target_instance.get_path_to(target_skeleton), " relative=", target_player.get_path_to(target_skeleton))
	var source_animation: Animation = source_player.get_animation("Sword_Attack")
	var result: Animation = _retarget_animation(source_animation, source_skeleton, target_instance, target_skeleton)
	var library := AnimationLibrary.new()
	library.add_animation("candidate", result)
	target_player.add_animation_library("candidate", library)
	target_player.play("candidate/candidate")
	print("current animation=", target_player.current_animation)
	for time in [0.0, 0.2, 0.4, 0.6, 0.8]:
		target_player.seek(time, true)
		target_player.advance(0.0)
		var hand: Vector3 = target_skeleton.get_bone_global_pose(target_skeleton.find_bone("CC_Base_R_Hand_88")).origin
		var hand_rotation: Quaternion = target_skeleton.get_bone_pose_rotation(target_skeleton.find_bone("CC_Base_R_Hand_88"))
		var shoulder: Vector3 = target_skeleton.get_bone_global_pose(target_skeleton.find_bone("CC_Base_R_Clavicle_91")).origin
		var foot_l: Vector3 = target_skeleton.get_bone_global_pose(target_skeleton.find_bone("CC_Base_L_Foot_7")).origin
		var foot_r: Vector3 = target_skeleton.get_bone_global_pose(target_skeleton.find_bone("CC_Base_R_Foot_24")).origin
		print("t=", time, " hand_y=", hand.y, " shoulder_y=", shoulder.y, " hand_shoulder_delta=", hand.y - shoulder.y, " hand_rot=", hand_rotation, " feet=", foot_l, " / ", foot_r)
	print("candidate tracks=", result.get_track_count(), " length=", result.length)
	quit(0)

func _retarget_animation(source: Animation, source_skeleton: Skeleton3D, target_root: Node3D, target_skeleton: Skeleton3D) -> Animation:
	var result := Animation.new()
	result.length = source.length
	var target_prefix: String = String(target_root.get_path_to(target_skeleton))
	for track_index in range(source.get_track_count()):
		if source.track_get_type(track_index) != Animation.TYPE_ROTATION_3D:
			continue
		var source_path := String(source.track_get_path(track_index))
		var separator := source_path.rfind(":")
		if separator < 0:
			continue
		var source_bone := source_path.substr(separator + 1)
		var target_bone := _map_bone(source_bone)
		var source_index := source_skeleton.find_bone(source_bone)
		var target_index := target_skeleton.find_bone(target_bone)
		if source_index < 0 or target_index < 0:
			continue
		var output_track := result.add_track(Animation.TYPE_ROTATION_3D)
		result.track_set_path(output_track, NodePath(target_prefix + ":" + target_bone))
		result.track_set_interpolation_type(output_track, Animation.INTERPOLATION_LINEAR)
		var source_rest: Quaternion = source_skeleton.get_bone_rest(source_index).basis.get_rotation_quaternion()
		var target_rest: Quaternion = target_skeleton.get_bone_rest(target_index).basis.get_rotation_quaternion()
		for key_index in range(source.track_get_key_count(track_index)):
			var source_pose: Quaternion = source.track_get_key_value(track_index, key_index)
			var target_pose: Quaternion = target_rest * source_rest.inverse() * source_pose
			result.track_insert_key(output_track, source.track_get_key_time(track_index, key_index), target_pose)
	return result

func _map_bone(source_bone: String) -> String:
	var normalized := source_bone.trim_prefix("DEF-")
	var side := ""
	if normalized.ends_with(".L"):
		side = "L"
		normalized = normalized.trim_suffix(".L")
	elif normalized.ends_with(".R"):
		side = "R"
		normalized = normalized.trim_suffix(".R")
	match normalized:
		"root": return "GLTF_created_0_rootJoint"
		"hips": return "CC_Base_Pelvis_30"
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
