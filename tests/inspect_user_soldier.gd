extends SceneTree

func _init() -> void:
	print("--- Inspecting anime-girl_running_panic.glb ---")
	var packed = load("res://characters/enemies/soldier/anime-girl_running_panic.glb")
	if not packed:
		printerr("Failed to load anime-girl_running_panic.glb")
		quit(1)
		return
	var inst: Node3D = packed.instantiate()
	root.add_child(inst)
	
	var ap: AnimationPlayer = inst.find_child("AnimationPlayer", true, false)
	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	
	if ap:
		for l in ap.get_animation_library_list():
			var lib = ap.get_animation_library(l)
			print("Anim Library '", l, "': ", lib.get_animation_list())
			for aname in lib.get_animation_list():
				var a = lib.get_animation(aname)
				print("  Anim '", aname, "' len=", a.length, " tracks=", a.get_track_count())
				
	if skel:
		print("Skeleton bone count: ", skel.get_bone_count())
		var bones = []
		for i in range(skel.get_bone_count()):
			bones.append(skel.get_bone_name(i))
		print("Bones: ", bones.slice(0, 30))
		
	var meshes = []
	_find_nodes(inst, MeshInstance3D, meshes)
	print("Meshes found: ", meshes.size())
	var total_tris = 0
	for m in meshes:
		var mesh: Mesh = m.mesh
		var tri_count = 0
		if mesh:
			for s in range(mesh.get_surface_count()):
				var arrs = mesh.surface_get_arrays(s)
				if arrs and arrs.size() > Mesh.ARRAY_INDEX and arrs[Mesh.ARRAY_INDEX] != null:
					tri_count += arrs[Mesh.ARRAY_INDEX].size() / 3
		total_tris += tri_count
		print("  Mesh '", m.name, "' tris=", tri_count)
	print("TOTAL ENEMY TRIS: ", total_tris)
	
	inst.free()
	quit(0)

func _find_nodes(node: Node, type, arr: Array) -> void:
	if is_instance_of(node, type):
		arr.append(node)
	for child in node.get_children():
		_find_nodes(child, type, arr)
