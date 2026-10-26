extends SceneTree

func _init() -> void:
	var packed = load("res://assets/characters/protagonist/imported/anime_fox_girl.glb")
	var inst: Node3D = packed.instantiate()
	root.add_child(inst)
	var cur: Node = inst.find_child("Skeleton3D", true, false)
	while cur != null:
		if cur is Node3D:
			print(cur.name, " pos=", (cur as Node3D).position)
		cur = cur.get_parent()
	inst.free()
	quit(0)
