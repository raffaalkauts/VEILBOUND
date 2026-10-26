extends SceneTree

func _init() -> void:
	var packed = load("res://assets/characters/protagonist/imported/anime_fox_girl.glb")
	var inst: Node3D = packed.instantiate()
	root.add_child(inst)
	
	var meshes = []
	_find_nodes(inst, MeshInstance3D, meshes)
	for m: MeshInstance3D in meshes:
		for s in range(m.mesh.get_surface_count()):
			var mat = m.get_active_material(s) as StandardMaterial3D
			if mat:
				print(m.name, " [", s, "] mat=", mat.resource_name,
					" trans=", mat.transparency,
					" depth_draw=", mat.depth_draw_mode,
					" cull=", mat.cull_mode,
					" blend=", mat.blend_mode,
					" alpha_scissor=", mat.alpha_scissor_threshold)
				if mat.albedo_texture:
					print("    tex=", mat.albedo_texture.resource_path)
					var img = mat.albedo_texture.get_image()
					if img:
						print("    img format=", img.get_format(), " size=", img.get_size(), " has_alpha=", img.has_alpha())
						
	inst.free()
	quit(0)

func _find_nodes(node: Node, type, arr: Array) -> void:
	if is_instance_of(node, type):
		arr.append(node)
	for child in node.get_children():
		_find_nodes(child, type, arr)
