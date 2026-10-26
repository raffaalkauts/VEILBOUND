extends SceneTree

func _init() -> void:
	var packed = load("res://assets/characters/protagonist/imported/anime_fox_girl.glb")
	var inst: Node3D = packed.instantiate()
	root.add_child(inst)
	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	var head_idx = skel.find_bone("Shibahu_Head_05_130")
	var spine_idx = skel.find_bone("Shibahu_Spine_01_224")
	
	print("--- NO ANIMATION PLAYING ---")
	print("Spine rest rot: ", skel.get_bone_rest(spine_idx).basis.get_euler())
	print("Spine pose rot: ", skel.get_bone_pose_rotation(spine_idx).get_euler())
	print("Head global pose: ", skel.get_bone_global_pose(head_idx).origin)
	
	print("--- PLAYING IDLE ANIMATION ---")
	var ap = inst.find_child("AnimationPlayer", true, false)
	var lib = load("res://characters/player/visual/player_animations.tres")
	ap.add_animation_library("test", lib)
	ap.play("test/idle")
	ap.advance(0.1)
	
	print("Spine pose rot with idle: ", skel.get_bone_pose_rotation(spine_idx).get_euler())
	print("Head global pose with idle: ", skel.get_bone_global_pose(head_idx).origin)
	
	inst.free()
	quit(0)
