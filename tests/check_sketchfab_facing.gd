extends SceneTree

func _init() -> void:
	var packed: PackedScene = load("res://assets/characters/protagonist/imported/anime_fox_girl.glb")
	var inst: Node3D = packed.instantiate()
	root.add_child(inst)
	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	
	var head_idx = skel.find_bone("Shibahu_Head_05_130")
	var nose_idx = -1
	for b in range(skel.get_bone_count()):
		var bname = skel.get_bone_name(b).to_lower()
		if "eye" in bname or "nose" in bname:
			print("Found facial bone: ", skel.get_bone_name(b))
			nose_idx = b
			break
			
	var head_pos = skel.get_bone_global_pose(head_idx).origin
	print("Head pos: ", head_pos)
	if nose_idx >= 0:
		var face_pos = skel.get_bone_global_pose(nose_idx).origin
		print("Facial bone pos: ", face_pos)
		print("Face relative to head: ", face_pos - head_pos)
		
	# Check toe vs foot
	var toe_idx = skel.find_bone("Shibahu_RightToeBase_0196_229")
	var foot_idx = skel.find_bone("Shibahu_RightLeg_0194_231")
	var toe_pos = skel.get_bone_global_pose(toe_idx).origin
	var foot_pos = skel.get_bone_global_pose(foot_idx).origin
	print("Toe relative to foot: ", toe_pos - foot_pos)
	if (toe_pos - foot_pos).z > 0:
		print("Model is facing +Z")
	else:
		print("Model is facing -Z")
		
	inst.free()
	quit(0)
