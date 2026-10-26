extends SceneTree

func _init() -> void:
	var packed = load("res://assets/characters/protagonist/imported/anime_fox_girl.glb")
	var inst: Node3D = packed.instantiate()
	_print_tree(inst, "")
	inst.free()
	quit(0)

func _print_tree(node: Node, indent: String) -> void:
	print(indent + node.name + " (" + node.get_class() + ")")
	for child in node.get_children():
		_print_tree(child, indent + "  ")
