extends SceneTree

func _init() -> void:
	var packed = load("res://characters/enemies/soldier/anime-girl_running_panic.glb")
	var inst: Node3D = packed.instantiate()
	root.add_child(inst)
	var ap: AnimationPlayer = inst.find_child("AnimationPlayer", true, false)
	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	
	print("inst.get_path_to(skel): ", inst.get_path_to(skel))
	print("ap.root_node: ", ap.root_node)
	
	# Check what path existing anim uses:
	var native_anim = ap.get_animation("Animation")
	print("Track 0 path in native anim: ", native_anim.track_get_path(0))
	
	inst.free()
	quit(0)
