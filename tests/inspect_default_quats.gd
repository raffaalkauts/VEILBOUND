extends SceneTree

func _init() -> void:
	var packed = load("res://assets/characters/protagonist/imported/anime_fox_girl.glb")
	var inst: Node3D = packed.instantiate()
	root.add_child(inst)
	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	
	for bname in ["Shibahu_Hips_00_245", "Shibahu_Spine_01_224", "Shibahu_Spine1_02_223", "Shibahu_Spine2_03_222", "Shibahu_Neck_04_131", "Shibahu_Head_05_130"]:
		var idx = skel.find_bone(bname)
		print(bname, " rest pose rot quat: ", skel.get_bone_rest(idx).basis.get_rotation_quaternion())
		print(bname, " default pose rot quat: ", skel.get_bone_pose_rotation(idx))
		
	inst.free()
	quit(0)
