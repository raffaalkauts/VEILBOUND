extends SceneTree

func _init() -> void:
	var packed = load("res://characters/enemies/soldier/anime-girl_running_panic.glb")
	var inst: Node3D = packed.instantiate()
	root.add_child(inst)
	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	
	var cur = skel.find_bone("CC_Base_Head_41")
	while cur != -1:
		print("Bone: ", skel.get_bone_name(cur), " rest origin: ", skel.get_bone_rest(cur).origin)
		cur = skel.get_bone_parent(cur)
		
	inst.free()
	quit(0)
