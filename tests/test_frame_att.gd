extends SceneTree

func _init() -> void:
	var root_node = Node3D.new()
	root.add_child(root_node)
	
	var fox_mesh = load("res://assets/characters/protagonist/imported/anime_fox_girl.glb").instantiate()
	fox_mesh.name = "FoxGirlMesh"
	fox_mesh.scale = Vector3(0.01, 0.01, 0.01)
	fox_mesh.rotation.y = PI
	root_node.add_child(fox_mesh)
	
	var skel: Skeleton3D = fox_mesh.find_child("Skeleton3D", true, false)
	
	var hand_att = BoneAttachment3D.new()
	hand_att.name = "RightHandAttachment"
	root_node.add_child(hand_att)
	hand_att.use_external_skeleton = true
	hand_att.set_external_skeleton(hand_att.get_path_to(skel))
	hand_att.bone_name = "Shibahu_RightHand_0167_217"
	
	var hip_att = BoneAttachment3D.new()
	hip_att.name = "HipAttachment"
	root_node.add_child(hip_att)
	hip_att.use_external_skeleton = true
	hip_att.set_external_skeleton(hip_att.get_path_to(skel))
	hip_att.bone_name = "Shibahu_Hips_00_245"
	
	# Process one frame
	await process_frame
	
	print("HandAtt global pos: ", hand_att.global_position)
	print("HipAtt global pos: ", hip_att.global_position)
	
	root_node.free()
	quit(0)
