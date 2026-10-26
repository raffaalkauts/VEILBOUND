extends SceneTree

func _init() -> void:
	var root_node = Node3D.new()
	root.add_child(root_node)
	
	var fox_mesh = load("res://assets/characters/protagonist/imported/anime_fox_girl.glb").instantiate()
	fox_mesh.name = "FoxGirlMesh"
	# DO NOT SCALE - let native scale take effect
	fox_mesh.rotation.y = PI
	root_node.add_child(fox_mesh)
	
	var skel: Skeleton3D = fox_mesh.find_child("Skeleton3D", true, false)
	
	var hand_att = BoneAttachment3D.new()
	hand_att.name = "RightHandAttachment"
	hand_att.bone_name = "Shibahu_RightHand_0167_217"
	hand_att.bone_idx = skel.find_bone("Shibahu_RightHand_0167_217")
	skel.add_child(hand_att)
	
	var hip_att = BoneAttachment3D.new()
	hip_att.name = "HipAttachment"
	hip_att.bone_name = "Shibahu_Hips_00_245"
	hip_att.bone_idx = skel.find_bone("Shibahu_Hips_00_245")
	skel.add_child(hip_att)
	
	await process_frame
	
	print("UNSCALED HandAtt global pos: ", hand_att.global_position)
	print("UNSCALED HipAtt global pos: ", hip_att.global_position)
	print("UNSCALED HandAtt global scale: ", hand_att.global_transform.basis.get_scale())
	
	root_node.free()
	quit(0)
