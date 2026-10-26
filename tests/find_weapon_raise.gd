extends SceneTree

func _init() -> void:
	var packed = load("res://characters/enemies/soldier/anime-girl_running_panic.glb")
	var inst: Node3D = packed.instantiate()
	root.add_child(inst)
	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	
	var r_arm_idx = skel.find_bone("CC_Base_R_Upperarm_90")
	var r_hand_idx = skel.find_bone("CC_Base_R_Hand_88")
	var rest_q = skel.get_bone_rest(r_arm_idx).basis.get_rotation_quaternion()
	
	# Test different rotations on R_Upperarm to see which puts R_Hand highest (Y maximum)
	var best_q = Quaternion.IDENTITY
	var max_y = -999.0
	for z_deg in [-70, -40, 0, 40, 70]:
		for x_deg in [-70, -40, 0, 40, 70]:
			for y_deg in [-40, 0, 40]:
				var test_q = rest_q * Quaternion.from_euler(Vector3(deg_to_rad(x_deg), deg_to_rad(y_deg), deg_to_rad(z_deg)))
				skel.set_bone_pose_rotation(r_arm_idx, test_q)
				var pos = skel.get_bone_global_pose(r_hand_idx).origin
				if pos.y > max_y:
					max_y = pos.y
					best_q = Quaternion(x_deg, y_deg, z_deg, 0)
					print("New highest R_Hand Y=", pos.y, " at (", x_deg, ", ", y_deg, ", ", z_deg, ")")
					
	inst.free()
	quit(0)
