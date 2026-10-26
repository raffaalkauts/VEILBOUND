extends SceneTree

func _init() -> void:
	var model = Node3D.new()
	model.name = "PlayerCharacterModel"
	root.add_child(model)
	
	var fox = load("res://assets/characters/protagonist/imported/anime_fox_girl.glb").instantiate()
	fox.name = "FoxGirlMesh"
	fox.position = Vector3(0.542849, -0.113543, 0.0)
	fox.rotation.y = PI
	model.add_child(fox)
	
	var skel: Skeleton3D = fox.find_child("Skeleton3D", true, false)
	
	var r_att = BoneAttachment3D.new()
	r_att.name = "RightHandAttachment"
	r_att.bone_name = "Shibahu_RightHand_0167_217"
	r_att.bone_idx = skel.find_bone("Shibahu_RightHand_0167_217")
	skel.add_child(r_att)
	
	var hip_att = BoneAttachment3D.new()
	hip_att.name = "HipAttachment"
	hip_att.bone_name = "Shibahu_Hips_00_245"
	hip_att.bone_idx = skel.find_bone("Shibahu_Hips_00_245")
	skel.add_child(hip_att)
	
	await process_frame
	
	print("RightHand rest pose: ", skel.get_bone_rest(r_att.bone_idx))
	print("RightHand global pose in skel: ", skel.get_bone_global_pose(r_att.bone_idx))
	print("Hip global pose in skel: ", skel.get_bone_global_pose(hip_att.bone_idx))
	
	model.free()
	quit(0)
