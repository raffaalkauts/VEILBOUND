extends SceneTree

func _init() -> void:
	var packed = load("res://characters/enemies/soldier/anime-girl_running_panic.glb")
	var inst: Node3D = packed.instantiate()
	root.add_child(inst)
	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	
	var head_idx = skel.find_bone("CC_Base_Head_41")
	var head_pose = skel.get_bone_global_pose(head_idx)
	print("Soldier Head global pose: ", head_pose.origin)
	
	var toe_l_idx = skel.find_bone("CC_Base_L_ToeBase_6")
	var toe_r_idx = skel.find_bone("CC_Base_R_ToeBase_22")
	print("Toe L global pose: ", skel.get_bone_global_pose(toe_l_idx).origin if toe_l_idx != -1 else null)
	print("Toe R global pose: ", skel.get_bone_global_pose(toe_r_idx).origin if toe_r_idx != -1 else null)
	
	var r_hand_idx = skel.find_bone("CC_Base_R_Hand_88")
	print("Soldier R_Hand pose: ", skel.get_bone_global_pose(r_hand_idx).origin if r_hand_idx != -1 else null)
	
	var pelvis_idx = skel.find_bone("CC_Base_Pelvis_30")
	print("Soldier Pelvis pose: ", skel.get_bone_global_pose(pelvis_idx).origin if pelvis_idx != -1 else null)

	inst.free()
	quit(0)
