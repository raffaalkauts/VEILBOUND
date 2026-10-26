extends SceneTree

func _init() -> void:
	var packed = load("res://assets/characters/protagonist/imported/anime_fox_girl.glb")
	var inst: Node3D = packed.instantiate()
	root.add_child(inst)
	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	
	var r_hand_idx = skel.find_bone("Shibahu_RightHand_0167_217")
	print("RightHand idx: ", r_hand_idx)
	if r_hand_idx != -1:
		print("RightHand rest: ", skel.get_bone_rest(r_hand_idx))
		
	var hip_idx = skel.find_bone("Shibahu_Hips_00_245")
	print("Hips idx: ", hip_idx)
	if hip_idx != -1:
		print("Hips rest: ", skel.get_bone_rest(hip_idx))
		
	var r_arm_idx = skel.find_bone("Shibahu_RightArm_0165_220")
	var l_arm_idx = skel.find_bone("Shibahu_LeftArm_0100_155")
	var r_leg_idx = skel.find_bone("Shibahu_RightUpLeg_0193_232")
	var l_leg_idx = skel.find_bone("Shibahu_LeftUpLeg_0189_228")
	var spine_idx = skel.find_bone("Shibahu_Spine_01_224")
	print("RightArm: ", r_arm_idx, " LeftArm: ", l_arm_idx, " RightLeg: ", r_leg_idx, " LeftLeg: ", l_leg_idx, " Spine: ", spine_idx)

	inst.free()
	quit(0)
