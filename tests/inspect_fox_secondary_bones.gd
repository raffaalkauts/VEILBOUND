extends SceneTree

func _init() -> void:
	var packed: PackedScene = load("res://assets/characters/protagonist/imported/anime_fox_girl.glb") as PackedScene
	var inst: Node3D = packed.instantiate() as Node3D
	root.add_child(inst)
	var skeleton: Skeleton3D = inst.find_child("Skeleton3D", true, false) as Skeleton3D
	for index in range(skeleton.get_bone_count()):
		var bone: String = skeleton.get_bone_name(index)
		var lower: String = bone.to_lower()
		if lower.contains("hair") or lower.contains("tail") or lower.contains("ear") or lower.contains("chest") or lower.contains("breast") or lower.contains("bust") or lower.contains("pony") or lower.contains("cloth"):
			print(index, " ", bone, " parent=", skeleton.get_bone_parent(index))
	inst.free()
	quit(0)
