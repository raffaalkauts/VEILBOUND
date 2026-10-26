extends SceneTree

func _init() -> void:
	var packed = load("res://assets/characters/protagonist/imported/anime_fox_girl.glb")
	var inst: Node3D = packed.instantiate()
	root.add_child(inst)
	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	
	var bones = [
		"Shibahu_Spine_01_224", "Shibahu_Spine1_02_223", "Shibahu_Spine2_03_222",
		"Shibahu_LeftArm_0100_155", "Shibahu_LeftForeArm_0101_154", "Shibahu_LeftHand_0102_152",
		"Shibahu_RightArm_0165_220", "Shibahu_RightForeArm_0166_219", "Shibahu_RightHand_0167_217",
		"Shibahu_LeftUpLeg_0189_228", "Shibahu_LeftLeg_0190_227",
		"Shibahu_RightUpLeg_0193_232", "Shibahu_RightLeg_0194_231",
		"Shibahu_Head_05_130"
	]
	
	for b in bones:
		var idx = skel.find_bone(b)
		if idx != -1:
			var rest = skel.get_bone_rest(idx)
			print(b, " (", idx, "): rest rot basis euler=", rest.basis.get_euler())
			
	inst.free()
	quit(0)
