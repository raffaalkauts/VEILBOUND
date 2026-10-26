extends SceneTree

func _init() -> void:
	var packed: PackedScene = load("res://assets/characters/protagonist/imported/anime_fox_girl.glb")
	var inst: Node3D = packed.instantiate()
	root.add_child(inst)
	
	var ap: AnimationPlayer = inst.find_child("AnimationPlayer", true, false)
	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	
	var r_hand_bone = skel.find_bone("Shibahu_RightHand_0167_217")
	var l_hand_bone = skel.find_bone("Shibahu_LeftHand_0102_152")
	var r_leg_bone = skel.find_bone("Shibahu_RightLeg_0194_231")
	var l_leg_bone = skel.find_bone("Shibahu_LeftLeg_0190_227")
	
	print("RightHand rest pose: ", skel.get_bone_rest(r_hand_bone).origin)
	
	ap.play("Animation")
	var times = [0.0, 1.0, 2.0, 3.0, 5.0, 7.0, 9.0, 10.0]
	for t in times:
		ap.seek(t, true)
		var r_rot = skel.get_bone_pose_rotation(r_hand_bone)
		var l_rot = skel.get_bone_pose_rotation(l_hand_bone)
		print("t=", t, " R_hand_rot=", r_rot, " L_hand_rot=", l_rot)
		
	inst.free()
	quit(0)
