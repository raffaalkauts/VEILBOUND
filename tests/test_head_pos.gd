extends SceneTree

func _init() -> void:
	var root_node = Node3D.new()
	root.add_child(root_node)
	
	var fox_mesh = load("res://assets/characters/protagonist/imported/anime_fox_girl.glb").instantiate()
	fox_mesh.name = "FoxGirlMesh"
	fox_mesh.rotation.y = PI
	root_node.add_child(fox_mesh)
	
	var skel: Skeleton3D = fox_mesh.find_child("Skeleton3D", true, false)
	var head_idx = skel.find_bone("Shibahu_Head_05_130")
	var head_att = BoneAttachment3D.new()
	head_att.name = "HeadAtt"
	head_att.bone_name = "Shibahu_Head_05_130"
	head_att.bone_idx = head_idx
	skel.add_child(head_att)
	
	await process_frame
	print("HeadAtt global pos: ", head_att.global_position)
	root_node.free()
	quit(0)
