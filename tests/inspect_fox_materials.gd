extends SceneTree

func _init() -> void:
	var packed = load("res://assets/characters/protagonist/imported/anime_fox_girl.glb")
	var inst: Node3D = packed.instantiate()
	root.add_child(inst)
	
	var meshes = []
	_find_nodes(inst, MeshInstance3D, meshes)
	print("Total meshes: ", meshes.size())
	for m: MeshInstance3D in meshes:
		print("Mesh: ", m.name, " visible=", m.visible, " parent=", m.get_parent().name)
		if m.mesh:
			print("  surface count=", m.mesh.get_surface_count())
			for s in range(m.mesh.get_surface_count()):
				var mat = m.get_active_material(s)
				print("    surf ", s, " mat=", mat.resource_name if mat else "null", " cull_mode=", mat.cull_mode if mat is StandardMaterial3D else "N/A", " transparency=", mat.transparency if mat is StandardMaterial3D else "N/A")
	inst.free()
	quit(0)

func _find_nodes(node: Node, type, arr: Array) -> void:
	if is_instance_of(node, type):
		arr.append(node)
	for child in node.get_children():
		_find_nodes(child, type, arr)
