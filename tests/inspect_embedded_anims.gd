extends SceneTree

func _init() -> void:
	print("--- Inspecting Animation in anime_fox_girl.glb ---")
	var packed: PackedScene = load("res://assets/characters/protagonist/imported/anime_fox_girl.glb")
	var inst: Node3D = packed.instantiate()
	var ap: AnimationPlayer = inst.find_child("AnimationPlayer", true, false)
	if ap:
		var anim: Animation = ap.get_animation("Animation")
		print("Animation 'Animation' length: ", anim.length, " loop_mode: ", anim.loop_mode, " track_count: ", anim.get_track_count())
		for t in range(mini(20, anim.get_track_count())):
			print("  Track ", t, ": path=", anim.track_get_path(t), " type=", anim.track_get_type(t), " keys=", anim.track_get_key_count(t))
	inst.free()
	
	print("\n--- Inspecting anime-girl_running_panic.glb in soldier ---")
	var soldier_packed: PackedScene = load("res://characters/enemies/soldier/anime-girl_running_panic.glb")
	if soldier_packed:
		var s_inst: Node3D = soldier_packed.instantiate()
		print("Soldier model root: ", s_inst.name)
		var s_aps = []
		_find_nodes(s_inst, AnimationPlayer, s_aps)
		print("Soldier AnimationPlayers: ", s_aps.size())
		for s_ap in s_aps:
			print("  AP: ", s_ap.name)
			for lib in s_ap.get_animation_library_list():
				var l = s_ap.get_animation_library(lib)
				print("    Lib '", lib, "': ", l.get_animation_list())
				for a_name in l.get_animation_list():
					var a = l.get_animation(a_name)
					print("      Anim '", a_name, "' length=", a.length, " tracks=", a.get_track_count())
		var s_skels = []
		_find_nodes(s_inst, Skeleton3D, s_skels)
		print("Soldier Skeletons: ", s_skels.size())
		for sk in s_skels:
			print("  Skeleton: ", sk.name, " bones=", sk.get_bone_count())
		s_inst.free()
		
	quit(0)

func _find_nodes(node: Node, type, arr: Array) -> void:
	if is_instance_of(node, type):
		arr.append(node)
	for child in node.get_children():
		_find_nodes(child, type, arr)
