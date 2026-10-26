extends SceneTree

## Phase 2.8 soldier UAL retarget inspection (dev probe, no assertions).
## Compares the UAL source rig's pose against the retargeted result on the
## production Soldier per clip, per sample: hand/foot heights relative to the
## hip and character-forward reach. Writes res://.godot/phase_2_8/soldier_pose.txt

const UAL_SCENE: PackedScene = preload("res://assets/animations/quaternius/universal_animation_library_standard.glb")

const CLIPS: Array[String] = ["Idle", "Walk", "Sprint", "Sword_Attack", "Hit_Chest", "Death01"]
const SAMPLE_TIMES: Array[float] = [0.0, 0.25, 0.5, 0.75, 1.0]

var _out: FileAccess


func _log(line: String) -> void:
	print(line)
	if _out != null:
		_out.store_line(line)
		_out.flush()


func _init() -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/phase_2_8")
	_out = FileAccess.open("res://.godot/phase_2_8/soldier_pose.txt", FileAccess.WRITE)
	call_deferred("_run")


func _guarded_pose(skeleton: Skeleton3D, bone_name: String, root_offset: Vector3) -> Vector3:
	var index: int = skeleton.find_bone(bone_name)
	if index < 0:
		if not skeleton.has_meta("missing_" + bone_name):
			skeleton.set_meta("missing_" + bone_name, true)
			_log("[POSE] WARNING: bone %s not found in %s" % [bone_name, skeleton.name])
		return root_offset
	return (skeleton.global_transform * skeleton.get_bone_global_pose(index)).origin


func _sample_rig(label: String, root: Node3D, skeleton: Skeleton3D, clip_name: String, player: AnimationPlayer, prefix: String) -> void:
	if not player.has_animation(clip_name):
		_log("[POSE] %s missing clip %s" % [label, clip_name])
		return
	var anim: Animation = player.get_animation(clip_name)
	_log("[POSE] ---- %s clip=%s ----" % [label, clip_name])
	for time: float in SAMPLE_TIMES:
		player.play(clip_name)
		player.seek(float(time) * anim.length, true)
		player.advance(0.0)
		var hand_r: Vector3
		var hand_l: Vector3
		var foot_r: Vector3
		var foot_l: Vector3
		var hip_pos: Vector3
		var head: Vector3
		if prefix == "UAL":
			hip_pos = _guarded_pose(skeleton, "DEF-hips", Vector3.ZERO)
			head = _guarded_pose(skeleton, "DEF-head", Vector3.ZERO)
			hand_r = _guarded_pose(skeleton, "DEF-hand.R", Vector3.ZERO)
			hand_l = _guarded_pose(skeleton, "DEF-hand.L", Vector3.ZERO)
			foot_r = _guarded_pose(skeleton, "DEF-foot.R", Vector3.ZERO)
			foot_l = _guarded_pose(skeleton, "DEF-foot.L", Vector3.ZERO)
		else:
			hip_pos = _guarded_pose(skeleton, "CC_Base_Hip_04", Vector3.ZERO)
			head = _guarded_pose(skeleton, "CC_Base_Head_41", Vector3.ZERO)
			hand_r = _guarded_pose(skeleton, "CC_Base_R_Hand_88", Vector3.ZERO)
			hand_l = _guarded_pose(skeleton, "CC_Base_L_Hand_62", Vector3.ZERO)
			foot_r = _guarded_pose(skeleton, "CC_Base_R_Foot_24", Vector3.ZERO)
			foot_l = _guarded_pose(skeleton, "CC_Base_L_Foot_7", Vector3.ZERO)
		var height: float = hip_pos.y
		_log("[POSE] t=%.2f hands_rel_hip R=(%.2f,%.2f,%.2f) L=(%.2f,%.2f,%.2f) head_rel_hip=%.2f feet_y=(%.2f,%.2f) hip_y=%.2f" % [
			time,
			hand_r.x - hip_pos.x, hand_r.y - height, hand_r.z - hip_pos.z,
			hand_l.x - hip_pos.x, hand_l.y - height, hand_l.z - hip_pos.z,
			head.y - height, foot_r.y, foot_l.y, height,
		])


func _run() -> void:
	# 1) UAL source rig plays its own clips on its own skeleton.
	var source: Node3D = UAL_SCENE.instantiate() as Node3D
	root.add_child(source)
	await process_frame
	var source_player: AnimationPlayer = source.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var source_skeleton: Skeleton3D = source.find_child("Skeleton3D", true, false) as Skeleton3D
	_log("[POSE] source rig bones=%d player_animations=%s" % [source_skeleton.get_bone_count(), str(source_player.get_animation_list().slice(0, 12))])
	for clip_name: String in CLIPS:
		_sample_rig("UAL_SOURCE", source, source_skeleton, clip_name, source_player, "UAL")
	source.queue_free()

	# 2) Production soldier with the built retarget library.
	var main: Node3D = (load("res://main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(main)
	await process_frame
	await process_frame
	var player: PlayerController = main.get_node("Player") as PlayerController
	var soldier: SoldierEnemy = main.get_node("SoldierEnemy") as SoldierEnemy
	player.health.is_invulnerable = true
	soldier.set_physics_process(false)
	var soldier_player: AnimationPlayer = soldier.anim_player
	var soldier_skeleton: Skeleton3D = soldier.skeleton
	_log("[POSE] soldier ual_ready=%s animations=%s" % [str(soldier._ual_animation_ready), str(soldier_player.get_animation_list().slice(0, 14))])
	_log("[POSE] align=%s valid=%s" % [str(soldier._ual_align_cache), str(soldier._ual_align_valid)])
	var src_sk: Skeleton3D = null
	var src_node: Node3D = soldier.find_child("*", true, false) as Node3D
	for child in soldier.get_children():
		for descendant in child.find_children("*", "Skeleton3D", true, false):
			src_sk = descendant
			break
	if src_sk != null:
		var thigh_r_src: Vector3 = (src_sk.get_bone_global_rest(src_sk.find_bone("DEF-thigh.R")).origin - src_sk.get_bone_global_rest(src_sk.find_bone("DEF-thigh.L")).origin).normalized()
		var thigh_r_tgt: Vector3 = (soldier_skeleton.get_bone_global_rest(soldier_skeleton.find_bone("CC_Base_R_Thigh_29")).origin - soldier_skeleton.get_bone_global_rest(soldier_skeleton.find_bone("CC_Base_L_Thigh_14")).origin).normalized()
		var head_src: Vector3 = (src_sk.get_bone_global_rest(src_sk.find_bone("DEF-head")).origin - src_sk.get_bone_global_rest(src_sk.find_bone("DEF-hips")).origin).normalized()
		var head_tgt: Vector3 = (soldier_skeleton.get_bone_global_rest(soldier_skeleton.find_bone("CC_Base_Head_41")).origin - soldier_skeleton.get_bone_global_rest(soldier_skeleton.find_bone("CC_Base_Pelvis_30")).origin).normalized()
		_log("[POSE] landmark axes: src_x=%s -> tgt_x=%s ; src_y=%s -> tgt_y=%s" % [str(thigh_r_src), str(thigh_r_tgt), str(head_src), str(head_tgt)])
		_log("[POSE] align applied: align*src_x=%s align*src_y=%s" % [str(soldier._ual_align_cache * thigh_r_src), str(soldier._ual_align_cache * head_src)])
	var targets: Dictionary = {"Idle": "soldier_ual/idle", "Walk": "soldier_ual/walk", "Sprint": "soldier_ual/sprint", "Sword_Attack": "soldier_ual/attack", "Hit_Chest": "soldier_ual/hit", "Death01": "soldier_ual/death"}
	for source_name: String in targets:
		var target_name: String = targets[source_name]
		if not soldier_player.has_animation(target_name):
			_log("[POSE] soldier missing %s" % target_name)
			continue
		_log("[POSE] ---- SOLDIER_RETARGETED clip=%s (source %s) ----" % [target_name, source_name])
		var anim: Animation = soldier_player.get_animation(target_name)
		for time: float in SAMPLE_TIMES:
			soldier_player.play(target_name)
			soldier_player.seek(time * anim.length, true)
			soldier_player.advance(0.0)
			await process_frame
			_sample_soldier(soldier_skeleton, soldier_player, target_name, time)
	_log("[POSE] inspection complete")
	_out.close()
	quit(0)


func _sample_soldier(skeleton: Skeleton3D, player_animation: AnimationPlayer, clip: String, time: float) -> void:
	var pelvis_pos: Vector3 = (skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("CC_Base_Pelvis_30"))).origin
	var hand_r: Vector3 = (skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("CC_Base_R_Hand_88"))).origin
	var hand_l: Vector3 = (skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("CC_Base_L_Hand_62"))).origin
	var head: Vector3 = (skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("CC_Base_Head_41"))).origin
	var foot_r: Vector3 = (skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("CC_Base_R_Foot_24"))).origin
	var foot_l: Vector3 = (skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("CC_Base_L_Foot_7"))).origin
	# World-space evidence (meters): unambiguous vertical layout.
	_log("[POSE] t=%.2f world pelvis_y=%.2f head=%.2f hands=(%.2f,%.2f) feet=(%.2f,%.2f) | head-pelvis=%.2f hand-pelvis=(%.2f,%.2f)" % [
		time, pelvis_pos.y, head.y, hand_r.y, hand_l.y, foot_r.y, foot_l.y,
		head.y - pelvis_pos.y, hand_r.y - pelvis_pos.y, hand_l.y - pelvis_pos.y,
	])
