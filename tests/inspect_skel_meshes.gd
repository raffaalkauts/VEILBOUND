extends SceneTree

func _init() -> void:
	var packed = load("res://assets/characters/protagonist/imported/anime_fox_girl.glb")
	var inst: Node3D = packed.instantiate()
	root.add_child(inst)
	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	for child in skel.get_children():
		if child is MeshInstance3D:
			print("Skel child mesh: ", child.name, " aabb=", child.mesh.get_aabb() if child.mesh else null)
	inst.free()
	quit(0)
