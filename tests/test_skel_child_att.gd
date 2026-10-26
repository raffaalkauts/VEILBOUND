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
	hand_att.bone_name = "Shibahu_RightHand_0167_217"
	hand_att.bone_idx = skel.find_bone("Shibahu_RightHand_0167_217")
	skel.add_child(hand_att)
	
	await process_frame
	
	print("Inside Skel: HandAtt global pos: ", hand_att.global_position)
	print("Inside Skel: HandAtt global scale: ", hand_att.global_transform.basis.get_scale())
	
	root_node.free()
	quit(0)
