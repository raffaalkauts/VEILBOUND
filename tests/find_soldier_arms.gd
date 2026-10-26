extends SceneTree

func _init() -> void:
	var packed = load("res://characters/enemies/soldier/anime-girl_running_panic.glb")
	var inst: Node3D = packed.instantiate()
	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	
	print("Searching arm bones in soldier skeleton:")
	for i in range(skel.get_bone_count()):
		var bname = skel.get_bone_name(i)
		if "arm" in bname.to_lower() or "hand" in bname.to_lower() or "clavicle" in bname.to_lower() or "shoulder" in bname.to_lower():
			print("  ", i, ": ", bname)
			
	inst.free()
	quit(0)
