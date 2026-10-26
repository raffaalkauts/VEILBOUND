extends SceneTree

func _init() -> void:
	print("--- Inspecting Sketchfab Anime Fox Girl Model ---")
	var packed: PackedScene = load("res://assets/characters/protagonist/imported/anime_fox_girl.glb")
	if not packed:
		printerr("Failed to load anime_fox_girl.glb")
		quit(1)
		return
		
	var inst: Node3D = packed.instantiate()
	print("Root: ", inst.name, " (", inst.get_class(), ")")
	
	# Check for AnimationPlayer
	var anim_players = []
	_find_nodes(inst, AnimationPlayer, anim_players)
	print("AnimationPlayers found: ", anim_players.size())
	for ap in anim_players:
		print("  AP: ", ap.name, " path: ", inst.get_path_to(ap))
		for lib in ap.get_animation_library_list():
			print("    Lib '", lib, "': ", ap.get_animation_library(lib).get_animation_list())
			
	# Check for Skeleton3D
	var skels = []
	_find_nodes(inst, Skeleton3D, skels)
	print("Skeletons found: ", skels.size())
	for sk in skels:
		print("  Skeleton: ", sk.name, " (", sk.get_bone_count(), " bones)")
		var bones = []
		for b in range(sk.get_bone_count()):
			bones.append(sk.get_bone_name(b))
		print("    First 30 bones: ", bones.slice(0, 30))
		if sk.get_bone_count() > 30:
			print("    Last 30 bones: ", bones.slice(sk.get_bone_count() - 30, sk.get_bone_count()))
			
	# Check Meshes, Tris, Verts, AABB
	var meshes = []
	_find_nodes(inst, MeshInstance3D, meshes)
	print("MeshInstances found: ", meshes.size())
	var total_tris = 0
	var total_verts = 0
	var full_aabb: AABB
	var first_mesh = true
	for m in meshes:
		var mesh: Mesh = m.mesh
		var tri_count = 0
		var vert_count = 0
		if mesh:
			for s in range(mesh.get_surface_count()):
				var arrs = mesh.surface_get_arrays(s)
				if arrs and arrs.size() > Mesh.ARRAY_VERTEX and arrs[Mesh.ARRAY_VERTEX] != null:
					var v_arr: PackedVector3Array = arrs[Mesh.ARRAY_VERTEX]
					vert_count += v_arr.size()
					if arrs.size() > Mesh.ARRAY_INDEX and arrs[Mesh.ARRAY_INDEX] != null:
						var idx_arr: PackedInt32Array = arrs[Mesh.ARRAY_INDEX]
						tri_count += idx_arr.size() / 3
					else:
						tri_count += v_arr.size() / 3
			total_tris += tri_count
			total_verts += vert_count
			var m_aabb = m.global_transform * m.get_aabb()
			if first_mesh:
				full_aabb = m_aabb
				first_mesh = false
			else:
				full_aabb = full_aabb.merge(m_aabb)
		print("  Mesh '", m.name, "': tris=", tri_count, " verts=", vert_count, " surfaces=", mesh.get_surface_count() if mesh else 0)
		
	print("TOTAL TRIS: ", total_tris)
	print("TOTAL VERTS: ", total_verts)
	print("FULL AABB: ", full_aabb)
	print("HEIGHT: ", full_aabb.size.y, " WIDTH: ", full_aabb.size.x, " DEPTH: ", full_aabb.size.z)
	print("GROUND Y: min=", full_aabb.position.y, " max=", full_aabb.position.y + full_aabb.size.y)
	
	inst.free()
	quit(0)

func _find_nodes(node: Node, type, arr: Array) -> void:
	if is_instance_of(node, type):
		arr.append(node)
	for child in node.get_children():
		_find_nodes(child, type, arr)
