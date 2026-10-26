extends SceneTree

func _init() -> void:
	var soldier = load("res://characters/enemies/soldier/soldier_enemy.tscn").instantiate()
	root.add_child(soldier)
	
	await process_frame
	
	var ap: AnimationPlayer = soldier.anim_player
	print("Soldier AP: ", ap)
	print("Libraries: ", ap.get_animation_library_list())
	print("Has soldier/telegraph: ", ap.has_animation("soldier/telegraph"))
	print("Has Animation (running): ", ap.has_animation("Animation"))
	
	var skel: Skeleton3D = soldier.skeleton
	var r_arm_idx = skel.find_bone("CC_Base_R_Upperarm_78")
	print("Before telegraph: R_Arm rot=", skel.get_bone_pose_rotation(r_arm_idx).get_euler())
	
	soldier._change_state(SoldierEnemy.State.TELEGRAPH)
	ap.advance(0.5)
	
	print("During telegraph (t=0.5): R_Arm rot=", skel.get_bone_pose_rotation(r_arm_idx).get_euler())
	
	soldier.free()
	quit(0)
