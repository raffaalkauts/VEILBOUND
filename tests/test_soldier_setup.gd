extends SceneTree

func _init() -> void:
	var packed = load("res://characters/enemies/soldier/anime-girl_running_panic.glb")
	var inst: Node3D = packed.instantiate()
	root.add_child(inst)
	inst.scale = Vector3(0.038, 0.038, 0.038)
	inst.rotation.y = PI
	
	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	var r_hand_idx = skel.find_bone("CC_Base_R_Hand_88")
	var head_idx = skel.find_bone("CC_Base_Head_41")
	var toe_idx = skel.find_bone("CC_Base_L_ToeBase_6")
	
	var r_att = BoneAttachment3D.new()
	r_att.name = "RightHandAttachment"
	r_att.bone_name = "CC_Base_R_Hand_88"
	r_att.bone_idx = r_hand_idx
	skel.add_child(r_att)
	
	await process_frame
	
	print("Soldier Head global pos: ", skel.global_transform * skel.get_bone_global_pose(head_idx).origin)
	print("Soldier Toe global pos: ", skel.global_transform * skel.get_bone_global_pose(toe_idx).origin)
	print("Soldier R_Hand global pos: ", r_att.global_position)
	print("Soldier R_Hand global scale: ", r_att.global_transform.basis.get_scale())
	
	inst.free()
	quit(0)
