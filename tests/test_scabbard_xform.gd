extends SceneTree

func _init() -> void:
	var root_node = Node3D.new()
	root.add_child(root_node)
	
	var fox_mesh = load("res://assets/characters/protagonist/imported/anime_fox_girl.glb").instantiate()
	fox_mesh.name = "FoxGirlMesh"
	fox_mesh.position = Vector3(0.542849, -0.113543, 0.0)
	fox_mesh.rotation.y = PI
	root_node.add_child(fox_mesh)
	
	var skel: Skeleton3D = fox_mesh.find_child("Skeleton3D", true, false)
	var hip_att = BoneAttachment3D.new()
	hip_att.name = "HipAttachment"
	hip_att.bone_name = "Shibahu_Hips_00_245"
	hip_att.bone_idx = skel.find_bone("Shibahu_Hips_00_245")
	skel.add_child(hip_att)
	
	var scabbard = Node3D.new()
	scabbard.name = "Scabbard"
	scabbard.scale = Vector3(100.0, 100.0, 100.0)
	# Local offset on hip in cm
	scabbard.position = Vector3(-16.0, 2.0, 4.0)
	hip_att.add_child(scabbard)
	
	await process_frame
	
	print("Scabbard global pos: ", scabbard.global_position)
	print("Scabbard global scale: ", scabbard.global_transform.basis.get_scale())
	
	root_node.free()
	quit(0)
