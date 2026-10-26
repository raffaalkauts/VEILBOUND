extends SceneTree

func _init() -> void:
	var packed = load("res://assets/characters/protagonist/imported/anime_fox_girl.glb")
	var inst: Node3D = packed.instantiate()
	root.add_child(inst)
	var cube = inst.find_child("Object_283", true, false)
	if cube:
		print("Object_283 mesh: ", cube.mesh, " aabb=", cube.mesh.get_aabb() if cube.mesh else null)
	var base = inst.find_child("Object_9", true, false)
	if base:
		print("Object_9 mesh: ", base.mesh, " aabb=", base.mesh.get_aabb() if base.mesh else null)
	inst.free()
	quit(0)
