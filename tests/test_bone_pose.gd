extends SceneTree

func _init() -> void:
	var packed = load("res://assets/characters/protagonist/imported/anime_fox_girl.glb")
	var inst: Node3D = packed.instantiate()
	root.add_child(inst)
	
	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	var att = BoneAttachment3D.new()
	var b_idx = skel.find_bone("Shibahu_RightHand_0167_217")
	att.bone_name = "Shibahu_RightHand_0167_217"
	att.bone_idx = b_idx
	skel.add_child(att)
	
	var pose = skel.get_bone_global_pose(b_idx)
	print("RightHand global pose in skel: origin=", pose.origin)
	
	var hip_idx = skel.find_bone("Shibahu_Hips_00_245")
	var hip_pose = skel.get_bone_global_pose(hip_idx)
	print("Hip global pose in skel: origin=", hip_pose.origin)
	
	inst.free()
	quit(0)
