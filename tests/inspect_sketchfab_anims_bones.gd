extends SceneTree

func _init() -> void:
	var packed: PackedScene = load("res://assets/characters/protagonist/imported/anime_fox_girl.glb")
	var inst: Node3D = packed.instantiate()
	
	var anim_players = []
	_find_nodes(inst, AnimationPlayer, anim_players)
	print("=== AnimationPlayers: ", anim_players.size(), " ===")
	for ap in anim_players:
		print("  AP name: ", ap.name)
		for lib in ap.get_animation_library_list():
			var l = ap.get_animation_library(lib)
			print("    Lib '", lib, "': ", l.get_animation_list())
			
	var skels = []
	_find_nodes(inst, Skeleton3D, skels)
	print("=== Skeletons: ", skels.size(), " ===")
	for sk in skels:
		print("  Skeleton name: ", sk.name, " (", sk.get_bone_count(), " bones)")
		for b in range(sk.get_bone_count()):
			var bname = sk.get_bone_name(b)
			if "hand" in bname.to_lower() or "arm" in bname.to_lower() or "head" in bname.to_lower() or "hip" in bname.to_lower() or "tail" in bname.to_lower() or "ear" in bname.to_lower() or "leg" in bname.to_lower():
				print("    Bone ", b, ": ", bname)
				
	inst.free()
	quit(0)

func _find_nodes(node: Node, type, arr: Array) -> void:
	if is_instance_of(node, type):
		arr.append(node)
	for child in node.get_children():
		_find_nodes(child, type, arr)
