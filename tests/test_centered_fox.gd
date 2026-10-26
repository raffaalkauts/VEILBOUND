extends SceneTree

func _init() -> void:
	var root_node = Node3D.new()
	root.add_child(root_node)
	
	var fox_mesh = load("res://assets/characters/protagonist/imported/anime_fox_girl.glb").instantiate()
	fox_mesh.name = "FoxGirlMesh"
	# Centering offset!
	fox_mesh.position = Vector3(0.542849, -0.113543, 0.0)
	fox_mesh.rotation.y = PI
	root_node.add_child(fox_mesh)
	
	var skel: Skeleton3D = fox_mesh.find_child("Skeleton3D", true, false)
	var head_idx = skel.find_bone("Shibahu_Head_05_130")
	var hip_idx = skel.find_bone("Shibahu_Hips_00_245")
	var toe_l_idx = skel.find_bone("Shibahu_LeftToeBase_0192_225")
	var toe_r_idx = skel.find_bone("Shibahu_RightToeBase_0196_229")
	
	var head_att = BoneAttachment3D.new()
	head_att.bone_name = "Shibahu_Head_05_130"
	head_att.bone_idx = head_idx
	skel.add_child(head_att)
	
	var hip_att = BoneAttachment3D.new()
	hip_att.bone_name = "Shibahu_Hips_00_245"
	hip_att.bone_idx = hip_idx
	skel.add_child(hip_att)
	
	var toe_att = BoneAttachment3D.new()
	toe_att.bone_name = "Shibahu_LeftToeBase_0192_225"
	toe_att.bone_idx = toe_l_idx
	skel.add_child(toe_att)
	
	await process_frame
	print("Centered Head global pos: ", head_att.global_position)
	print("Centered Hip global pos: ", hip_att.global_position)
	print("Centered Toe global pos: ", toe_att.global_position)
	root_node.free()
	quit(0)
