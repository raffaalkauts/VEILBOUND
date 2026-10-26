extends SceneTree

func _init() -> void:
	var packed = load("res://characters/enemies/soldier/anime-girl_running_panic.glb")
	var inst: Node3D = packed.instantiate()
	root.add_child(inst)
	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	
	var r_arm_idx = skel.find_bone("CC_Base_R_Upperarm_90")
	var l_arm_idx = skel.find_bone("CC_Base_L_Upperarm_66")
	
	print("R_Arm rest quat: ", skel.get_bone_rest(r_arm_idx).basis.get_rotation_quaternion())
	print("L_Arm rest quat: ", skel.get_bone_rest(l_arm_idx).basis.get_rotation_quaternion())
	
	# Rotate arms down along body
	var r_down = skel.get_bone_rest(r_arm_idx).basis.get_rotation_quaternion() * Quaternion.from_euler(Vector3(0, 0, deg_to_rad(-70)))
	var l_down = skel.get_bone_rest(l_arm_idx).basis.get_rotation_quaternion() * Quaternion.from_euler(Vector3(0, 0, deg_to_rad(70)))
	
	skel.set_bone_pose_rotation(r_arm_idx, r_down)
	skel.set_bone_pose_rotation(l_arm_idx, l_down)
	
	var r_hand_idx = skel.find_bone("CC_Base_R_Hand_88")
	var l_hand_idx = skel.find_bone("CC_Base_L_Hand_62")
	
	print("R_Hand pose after down: ", skel.get_bone_global_pose(r_hand_idx).origin)
	print("L_Hand pose after down: ", skel.get_bone_global_pose(l_hand_idx).origin)
	
	inst.free()
	quit(0)
