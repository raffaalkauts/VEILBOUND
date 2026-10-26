extends SceneTree

func _init() -> void:
	var packed = load("res://assets/characters/protagonist/imported/anime_fox_girl.glb")
	var inst: Node3D = packed.instantiate()
	root.add_child(inst)
	
	var head_mesh = inst.find_child("Object_15", true, false) as MeshInstance3D
	var body_mesh = inst.find_child("Object_61", true, false) as MeshInstance3D
	var hair_mesh = inst.find_child("Object_65", true, false) as MeshInstance3D
	
	await process_frame
	
	print("Object_15 (Face): visible=", head_mesh.visible, " global_pos=", head_mesh.global_position)
	print("Object_61 (Body): visible=", body_mesh.visible, " global_pos=", body_mesh.global_position)
	print("Object_65 (Hair): visible=", hair_mesh.visible, " global_pos=", hair_mesh.global_position)
	
	# Check materials and textures
	for m in [head_mesh, body_mesh, hair_mesh]:
		var mat = m.get_active_material(0)
		if mat is StandardMaterial3D:
			print(m.name, " mat albedo_color=", mat.albedo_color, " albedo_texture=", mat.albedo_texture)
			
	inst.free()
	quit(0)
