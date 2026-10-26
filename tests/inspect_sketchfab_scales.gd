extends SceneTree

func _init() -> void:
	var packed: PackedScene = load("res://assets/characters/protagonist/imported/anime_fox_girl.glb")
	var inst: Node3D = packed.instantiate()
	root.add_child(inst)
	
	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	if skel:
		var head_idx = skel.find_bone("Shibahu_Head_05_130")
		var hips_idx = skel.find_bone("Shibahu_Hips_00_245")
		var foot_r_idx = skel.find_bone("Shibahu_RightToeBase_0196_229")
		var foot_l_idx = skel.find_bone("Shibahu_LeftToeBase_0192_225")
		var r_hand_idx = skel.find_bone("Shibahu_RightHand_0167_217")
		var l_hand_idx = skel.find_bone("Shibahu_LeftHand_0102_152")
		
		print("Skel global transform: ", skel.global_transform)
		var head_g = skel.to_global(skel.get_bone_global_pose(head_idx).origin)
		var hips_g = skel.to_global(skel.get_bone_global_pose(hips_idx).origin)
		var foot_r_g = skel.to_global(skel.get_bone_global_pose(foot_r_idx).origin)
		var foot_l_g = skel.to_global(skel.get_bone_global_pose(foot_l_idx).origin)
		var r_hand_g = skel.to_global(skel.get_bone_global_pose(r_hand_idx).origin)
		
		print("Head pos: ", head_g)
		print("Hips pos: ", hips_g)
		print("Foot R pos: ", foot_r_g)
		print("Foot L pos: ", foot_l_g)
		print("RightHand pos: ", r_hand_g)
		print("Character Height (Head - Foot): ", head_g.y - foot_r_g.y)
		
	inst.free()
	quit(0)
