extends SceneTree

func _init() -> void:
	var packed = load("res://characters/enemies/soldier/anime-girl_running_panic.glb")
	var inst: Node3D = packed.instantiate()
	root.add_child(inst)
	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	
	var r_arm_idx = skel.find_bone("CC_Base_R_Upperarm_90")
	var r_forearm_idx = skel.find_bone("CC_Base_R_Forearm_89")
	var l_arm_idx = skel.find_bone("CC_Base_L_Upperarm_66")
	var r_hand_idx = skel.find_bone("CC_Base_R_Hand_88")
	
	var r_rest = skel.get_bone_rest(r_arm_idx).basis.get_rotation_quaternion()
	var l_rest = skel.get_bone_rest(l_arm_idx).basis.get_rotation_quaternion()
	
	# Telegraph pose: Right arm raised high with blade, left arm down at side
	var r_up = r_rest * Quaternion.from_euler(Vector3(deg_to_rad(45), 0, deg_to_rad(65)))
	var l_down = l_rest * Quaternion.from_euler(Vector3(0, 0, deg_to_rad(70)))
	
	skel.set_bone_pose_rotation(r_arm_idx, r_up)
	skel.set_bone_pose_rotation(l_arm_idx, l_down)
	
	print("Right hand pose with R_Up: ", skel.get_bone_global_pose(r_hand_idx).origin)
	
	inst.free()
	quit(0)
