extends SceneTree

func _init() -> void:
	var packed = load("res://assets/characters/protagonist/imported/anime_fox_girl.glb")
	var inst: Node3D = packed.instantiate()
	root.add_child(inst)
	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	
	var head_idx = skel.find_bone("Shibahu_Head_05_130")
	var spine_idx = skel.find_bone("Shibahu_Spine_01_224")
	
	# Apply proper rest * delta
	var spine_rest_q = skel.get_bone_rest(spine_idx).basis.get_rotation_quaternion()
	var delta_q = Quaternion.from_euler(Vector3(deg_to_rad(2.0), 0.0, 0.0))
	var target_q = spine_rest_q * delta_q
	
	skel.set_bone_pose_rotation(spine_idx, target_q)
	
	print("Head global pose after correct spine rotation: ", skel.get_bone_global_pose(head_idx).origin)
	
	inst.free()
	quit(0)
