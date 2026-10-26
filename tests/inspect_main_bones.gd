extends SceneTree

func _init() -> void:
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	
	for _i in range(5):
		await process_frame
		
	var player = main.get_node("Player")
	var model = player.visual_root.get_character_model()
	var skel: Skeleton3D = model.skeleton
	
	print("--- SKELETON BONE POSITIONS IN MAIN ---")
	for bname in ["Shibahu_Hips_00_245", "Shibahu_Spine_01_224", "Shibahu_Spine1_02_223", "Shibahu_Spine2_03_222", "Shibahu_Neck_04_131", "Shibahu_Head_05_130", "Shibahu_RightArm_0165_220", "Shibahu_LeftArm_0100_155"]:
		var b_idx = skel.find_bone(bname)
		if b_idx != -1:
			var world_pos = skel.global_transform * skel.get_bone_global_pose(b_idx).origin
			print("Bone ", bname, ": global_pos=", world_pos)
			
	# Also check mesh instances transforms
	var head_mesh = model.find_child("Object_15", true, false)
	if head_mesh:
		print("Object_15 global_pos: ", head_mesh.global_position)
		print("Object_15 aabb in world: ", head_mesh.get_aabb())
		
	main.free()
	quit(0)
