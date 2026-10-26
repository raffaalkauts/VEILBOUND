extends SceneTree

func _init() -> void:
	var packed: PackedScene = load("res://characters/enemies/soldier/anime-girl_running_panic.glb") as PackedScene
	var inst: Node3D = packed.instantiate() as Node3D
	root.add_child(inst)
	var skeleton := inst.find_child("Skeleton3D", true, false) as Skeleton3D
	for index in range(skeleton.get_bone_count()):
		var bone := skeleton.get_bone_name(index)
		if index >= 30 and index <= 85:
			print(index, " ", bone, " parent=", skeleton.get_bone_parent(index))
	inst.free()
	quit(0)
