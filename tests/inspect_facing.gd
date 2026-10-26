extends SceneTree

func _init() -> void:
	var packed = load("res://assets/characters/protagonist/imported/anime_fox_girl.glb")
	var inst: Node3D = packed.instantiate()
	root.add_child(inst)
	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	
	var head_idx = skel.find_bone("Shibahu_Head_05_130")
	var head_pose = skel.get_bone_global_pose(head_idx)
	print("Head global pose: ", head_pose.origin)
	
	for i in range(skel.get_bone_count()):
		var bname = skel.get_bone_name(i)
		if "Nose" in bname or "Toe" in bname or "Face" in bname:
			var pose = skel.get_bone_global_pose(i)
			print(bname, " global pose: ", pose.origin)
			
	inst.free()
	quit(0)
