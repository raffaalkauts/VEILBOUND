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
	
	var att = BoneAttachment3D.new()
	att.name = "RightHandAttachment"
	root_node.add_child(att)
	
	att.use_external_skeleton = true
	att.set_external_skeleton(att.get_path_to(skel))
	att.bone_name = "Shibahu_RightHand_0167_217"
	
	print("att external_skeleton path: ", att.get_external_skeleton())
	print("att bone_name: ", att.bone_name)
	print("att bone_idx: ", att.bone_idx)
	
	root_node.free()
	quit(0)
