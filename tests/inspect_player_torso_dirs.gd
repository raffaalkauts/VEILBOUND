extends SceneTree

func _vec(s: Skeleton3D, a: String, b: String, pose: bool) -> Vector3:
	var ia: int = s.find_bone(a)
	var ib: int = s.find_bone(b)
	if ia < 0 or ib < 0:
		return Vector3.ZERO
	if pose:
		return (s.get_bone_global_pose(ib).origin - s.get_bone_global_pose(ia).origin).normalized()
	return (s.get_bone_global_rest(ib).origin - s.get_bone_global_rest(ia).origin).normalized()


func _init() -> void:
	var model: Node = (load("res://characters/player/visual/player_character_model.tscn") as PackedScene).instantiate()
	root.add_child(model)
	await process_frame
	var t: Skeleton3D = model.find_child("Skeleton3D", true, false)
	var ual: Node = (load("res://assets/animations/quaternius/universal_animation_library_standard.glb") as PackedScene).instantiate()
	root.add_child(ual)
	var s: Skeleton3D = ual.find_child("Skeleton3D", true, false)
	var pairs: Array = [
		["hips->spine1", "DEF-hips", "DEF-spine.001", "Shibahu_Hips_00_245", "Shibahu_Spine_01_224"],
		["spine1->spine2", "DEF-spine.001", "DEF-spine.002", "Shibahu_Spine_01_224", "Shibahu_Spine1_02_223"],
		["spine2->spine3", "DEF-spine.002", "DEF-spine.003", "Shibahu_Spine1_02_223", "Shibahu_Spine2_03_222"],
		["spine3->neck", "DEF-spine.003", "DEF-neck", "Shibahu_Spine2_03_222", "Shibahu_Neck_04_131"],
		["neck->head", "DEF-neck", "DEF-head", "Shibahu_Neck_04_131", "Shibahu_Head_05_130"],
		["hips->head", "DEF-hips", "DEF-head", "Shibahu_Hips_00_245", "Shibahu_Head_05_130"],
		["thigh->shin", "DEF-thigh.L", "DEF-shin.L", "Shibahu_LeftUpLeg_0189_228", "Shibahu_LeftLeg_0190_227"],
	]
	var ap: AnimationPlayer = model.find_child("AnimationPlayer", true, false)
	ap.play("idle")
	ap.seek(0.0, true)
	ap.advance(0.0)
	for p: Array in pairs:
		var sr: Vector3 = _vec(s, p[1], p[2], false)
		var tr: Vector3 = _vec(t, p[3], p[4], false)
		var tp: Vector3 = _vec(t, p[3], p[4], true)
		print("%s  src_rest=%s  tgt_rest=%s  tgt_idle_pose=%s" % [p[0], sr, tr, tp])
	quit(0)
