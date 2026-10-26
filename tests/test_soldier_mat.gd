extends SceneTree

func _init() -> void:
	var packed = load("res://characters/enemies/soldier/anime-girl_running_panic.glb")
	var inst: Node3D = packed.instantiate()
	root.add_child(inst)
	
	var obj7: MeshInstance3D = inst.find_child("Object_7", true, false)
	print("Object_7: ", obj7)
	if obj7:
		print("Material count: ", obj7.get_surface_override_material_count())
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color.RED
		obj7.material_override = mat
		print("Assigned material_override to Object_7 successfully")
		
	inst.free()
	quit(0)
