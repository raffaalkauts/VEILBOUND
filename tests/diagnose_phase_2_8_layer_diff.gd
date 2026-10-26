extends SceneTree

## Dev probe: pinpoints the layer that injects the ~10 deg spine residual by
## (a) dumping the target rest chain (rotations + scales), (b) comparing
## RUNTIME target chain relative rotations against source chain relatives,
## and (c) checking the inserted local keys actually apply.

const UAL_SCENE: PackedScene = preload("res://assets/animations/quaternius/universal_animation_library_standard.glb")

var _out: FileAccess


func _log(line: String) -> void:
	print(line)
	if _out != null:
		_out.store_line(line)
		_out.flush()


func _angle(a: Quaternion, b: Quaternion) -> float:
	return absf((a.inverse() * b).get_angle())


func _q(q: Quaternion) -> String:
	return "(%.3f,%.3f,%.3f,%.3f)" % [q.x, q.y, q.z, q.w]


func _init() -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/phase_2_8")
	_out = FileAccess.open("res://.godot/phase_2_8/layer_diff.txt", FileAccess.WRITE)
	call_deferred("_run")


func _run() -> void:
	var main: Node3D = (load("res://main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(main)
	await process_frame
	await process_frame
	var player: PlayerController = main.get_node("Player") as PlayerController
	var soldier: SoldierEnemy = main.get_node("SoldierEnemy") as SoldierEnemy
	player.health.is_invulnerable = true
	soldier.set_physics_process(false)
	var skeleton: Skeleton3D = soldier.skeleton
	var align: Quaternion = soldier._ual_align_cache

	# --- (a) target rest chain dump (walk up from head) ---
	_log("[LAYER] --- target rest chain (spine path -> root) ---")
	var walk: int = skeleton.find_bone("CC_Base_Head_41")
	while walk >= 0:
		var rest: Transform3D = skeleton.get_bone_global_rest(walk)
		var local_rest: Transform3D = skeleton.get_bone_rest(walk)
		var rot: Quaternion = rest.basis.get_rotation_quaternion()
		var local_rot: Quaternion = local_rest.basis.get_rotation_quaternion()
		_log("[LAYER] bone=%-26s parent=%-26s global_rest_scale=%s local_rest_rot=%s local_rest_scale=%s" % [
			skeleton.get_bone_name(walk),
			(skeleton.get_bone_name(skeleton.get_bone_parent(walk)) if skeleton.get_bone_parent(walk) >= 0 else "<none>"),
			str(rest.basis.get_scale()), _q(local_rot), str(local_rest.basis.get_scale()),
		])
		walk = skeleton.get_bone_parent(walk)

	# --- fresh source rig ---
	var source_instance: Node3D = UAL_SCENE.instantiate() as Node3D
	source_instance.name = "Phase28LayerProbe"
	soldier.add_child(source_instance)
	source_instance.visible = false
	var source_player: AnimationPlayer = source_instance.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var source_skeleton: Skeleton3D = source_instance.find_child("Skeleton3D", true, false) as Skeleton3D
	if source_player == null or source_skeleton == null:
		_log("[LAYER] source player/skeleton missing")
		quit(1)
		return

	# --- same-time pose sampling ---
	var t_rel: float = 0.5
	var target_player: AnimationPlayer = soldier.anim_player
	target_player.play("soldier_ual/idle", 0.0) # custom_blend=0: no residue from soldier/idle
	var target_anim: Animation = target_player.get_animation("soldier_ual/idle")
	target_player.seek(t_rel * target_anim.length, true)
	await process_frame
	await process_frame
	source_player.play("Idle")
	source_player.seek(t_rel * source_player.get_animation("Idle").length, true)
	source_player.advance(0.0)

	var pairs: Dictionary = {
		"root":     ["root", "GLTF_created_0_rootJoint"],
		"pelvis":   ["DEF-hips", "CC_Base_Pelvis_30"],
		"spine001": ["DEF-spine.001", "CC_Base_Waist_98"],
		"spine002": ["DEF-spine.002", "CC_Base_Spine01_97"],
		"spine003": ["DEF-spine.003", "CC_Base_Spine02_96"],
		"neck":     ["DEF-neck", "CC_Base_NeckTwist02_42"],
		"head":     ["DEF-head", "CC_Base_Head_41"],
		"uarm_r":   ["DEF-upper_arm.R", "CC_Base_R_Upperarm_90"],
		"thigh_r":  ["DEF-thigh.R", "CC_Base_R_Thigh_29"],
	}
	var src_globals: Dictionary = {}
	var tgt_globals: Dictionary = {}
	_log("[LAYER] --- runtime globals at t=%.2f of Idle ---" % (t_rel * target_anim.length))
	for pair_name: String in pairs:
		var src_idx: int = source_skeleton.find_bone(String(pairs[pair_name][0]))
		var tgt_idx: int = skeleton.find_bone(String(pairs[pair_name][1]))
		src_globals[pair_name] = source_skeleton.get_bone_global_pose(src_idx).basis.get_rotation_quaternion()
		tgt_globals[pair_name] = skeleton.get_bone_global_pose(tgt_idx).basis.get_rotation_quaternion()
		var residual: float = _angle(src_globals[pair_name] as Quaternion, align.inverse() * (tgt_globals[pair_name] as Quaternion))
		_log("[LAYER] %-9s residual=%6.2f deg" % [pair_name, rad_to_deg(residual)])

	# --- relative rotations per layer ---
	var parents: Dictionary = {"pelvis": "root", "spine001": "pelvis", "spine002": "spine001", "spine003": "spine002", "neck": "spine003", "head": "neck", "uarm_r": "pelvis", "thigh_r": "pelvis"}
	_log("[LAYER] --- parent->child relative rotations ---")
	for pair_name: String in pairs:
		if not parents.has(pair_name):
			continue
		var parent_name: String = parents[pair_name]
		var src_rel: Quaternion = (src_globals[parent_name] as Quaternion).inverse() * (src_globals[pair_name] as Quaternion)
		var tgt_rel: Quaternion = (tgt_globals[parent_name] as Quaternion).inverse() * (tgt_globals[pair_name] as Quaternion)
		_log("[LAYER] %-9s src_rel=%s tgt_rel=%s rel_angle=%6.2f deg" % [pair_name, _q(src_rel), _q(tgt_rel), rad_to_deg(_angle(src_rel, tgt_rel))])

	# --- inserted keys vs runtime local pose (waist / spine01 / spine02 / root) ---
	_log("[LAYER] --- inserted local keys vs runtime bone local pose ---")
	var key_checks: Dictionary = {
		"GLTF_created_0_rootJoint": "root",
		"CC_Base_Waist_98": "DEF-spine.001",
		"CC_Base_Spine01_97": "DEF-spine.002",
		"CC_Base_Spine02_96": "DEF-spine.003",
	}
	for target_bone: String in key_checks:
		var tgt_idx2: int = skeleton.find_bone(target_bone)
		var runtime_local: Quaternion = skeleton.get_bone_pose(tgt_idx2).basis.get_rotation_quaternion()
		var track_index: int = target_anim.find_track(NodePath(String(target_player.get_parent().get_path_to(skeleton)) + ":" + target_bone), Animation.TYPE_ROTATION_3D)
		if track_index < 0:
			_log("[LAYER] %-22s NO result track" % target_bone)
			continue
		var nearest_key: int = 0
		var best: float = INF
		for key_index in range(target_anim.track_get_key_count(track_index)):
			var key_time: float = target_anim.track_get_key_time(track_index, key_index)
			var distance: float = absf(key_time - t_rel * target_anim.length)
			if distance < best:
				best = distance
				nearest_key = key_index
		var key_local: Quaternion = target_anim.track_get_key_value(track_index, nearest_key)
		var insert_vs_runtime: float = _angle(key_local, runtime_local)
		_log("[LAYER] %-22s inserted=%s runtime=%s angle=%6.2f deg" % [target_bone, _q(key_local), _q(runtime_local), rad_to_deg(insert_vs_runtime)])

	_log("[LAYER] done")
	# --- source rest chain through root/hips/spine001 ---
	_log("[LAYER] --- source rest globals ---")
	for bone_name: String in ["root", "DEF-hips", "DEF-spine.001", "DEF-spine.002"]:
		var idx: int = source_skeleton.find_bone(bone_name)
		var rest_q: Quaternion = source_skeleton.get_bone_global_rest(idx).basis.get_rotation_quaternion()
		_log("[LAYER] src_rest %-14s %s" % [bone_name, _q(rest_q)])
	_log("[LAYER] src_global(root) at pose=%s align=%s align*src_root=%s" % [
		_q(src_globals["root"] as Quaternion), _q(align), _q(align * (src_globals["root"] as Quaternion))])
	_out.close()
	quit(0)
