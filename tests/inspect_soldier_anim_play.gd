extends SceneTree

func _init() -> void:
	var packed = load("res://characters/enemies/soldier/anime-girl_running_panic.glb")
	var inst: Node3D = packed.instantiate()
	root.add_child(inst)
	var ap: AnimationPlayer = inst.find_child("AnimationPlayer", true, false)
	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	if ap:
		var anim = ap.get_animation("Animation")
		print("Soldier native animation length: ", anim.length, " loop: ", anim.loop_mode)
		ap.play("Animation")
		for t in [0.0, 1.0, 2.0, 5.0]:
			ap.seek(t, true)
			var head_idx = skel.find_bone("CC_Base_Head_41")
			var r_hand_idx = skel.find_bone("CC_Base_R_Hand_88")
			print("t=", t, " Head pose: ", skel.get_bone_global_pose(head_idx).origin, " R_Hand pose: ", skel.get_bone_global_pose(r_hand_idx).origin)
	inst.free()
	quit(0)
