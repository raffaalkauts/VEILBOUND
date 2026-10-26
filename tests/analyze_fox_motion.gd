extends SceneTree

func _init() -> void:
	var packed = load("res://assets/characters/protagonist/imported/anime_fox_girl.glb")
	var inst: Node3D = packed.instantiate()
	root.add_child(inst)
	var ap: AnimationPlayer = inst.find_child("AnimationPlayer", true, false)
	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	var anim = ap.get_animation("Animation")
	
	print("Checking native clip bone motions...")
	var arm_r = skel.find_bone("Shibahu_RightArm_0165_220")
	var leg_l = skel.find_bone("Shibahu_LeftUpLeg_0189_228")
	var hip = skel.find_bone("Shibahu_Hips_00_245")
	
	for s in range(11):
		var t = float(s)
		ap.seek(t, true)
		print("t=", t, " ArmR rot=", skel.get_bone_pose_rotation(arm_r).get_euler(), " LegL rot=", skel.get_bone_pose_rotation(leg_l).get_euler(), " Hip pos=", skel.get_bone_pose_position(hip))
		
	inst.free()
	quit(0)
