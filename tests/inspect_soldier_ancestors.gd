extends SceneTree

func _init() -> void:
	var packed = load("res://characters/enemies/soldier/anime-girl_running_panic.glb")
	var inst: Node3D = packed.instantiate()
	root.add_child(inst)
	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	var cur: Node = skel
	while cur != null:
		if cur is Node3D:
			print("Soldier Node: ", cur.name, " scale=", (cur as Node3D).scale, " basis_scale=", (cur as Node3D).transform.basis.get_scale())
		cur = cur.get_parent()
	inst.free()
	quit(0)
