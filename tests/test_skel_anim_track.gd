extends SceneTree

func _init() -> void:
	var packed = load("res://assets/characters/protagonist/imported/anime_fox_girl.glb")
	var inst: Node3D = packed.instantiate()
	root.add_child(inst)
	
	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	var ap: AnimationPlayer = inst.find_child("AnimationPlayer", true, false)
	
	var skel_path = inst.get_path_to(skel)
	print("Relative path from inst to skel: ", skel_path)
	
	# Create a test animation
	var anim = Animation.new()
	anim.length = 1.0
	var track_idx = anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(track_idx, String(skel_path) + ":Shibahu_RightArm_0165_220")
	anim.rotation_track_insert_key(track_idx, 0.0, Quaternion.IDENTITY)
	anim.rotation_track_insert_key(track_idx, 0.5, Quaternion(Vector3(1, 0, 0), deg_to_rad(45)))
	anim.rotation_track_insert_key(track_idx, 1.0, Quaternion.IDENTITY)
	
	var lib = AnimationLibrary.new()
	lib.add_animation("test_swing", anim)
	ap.add_animation_library("custom", lib)
	
	ap.play("custom/test_swing")
	ap.advance(0.5)
	
	var arm_idx = skel.find_bone("Shibahu_RightArm_0165_220")
	var pose_rot = skel.get_bone_pose_rotation(arm_idx)
	print("Arm pose rotation after advance(0.5): ", pose_rot)
	
	inst.free()
	quit(0)
