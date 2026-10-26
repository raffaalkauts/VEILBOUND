extends SceneTree


func _init() -> void:
	var packed: PackedScene = load("res://assets/animations/quaternius/universal_animation_library_standard.glb") as PackedScene
	if packed == null:
		push_error("Could not load the Quaternius Standard animation GLB.")
		quit(1)
		return

	var instance: Node3D = packed.instantiate() as Node3D
	root.add_child(instance)
	var players: Array[Node] = []
	_find_nodes(instance, "AnimationPlayer", players)
	var skeletons: Array[Node] = []
	_find_nodes(instance, "Skeleton3D", skeletons)
	print("Animation players: ", players.size(), " | skeletons: ", skeletons.size())
	for player_node: Node in players:
		var animation_player: AnimationPlayer = player_node as AnimationPlayer
		for library_name: StringName in animation_player.get_animation_library_list():
			var library: AnimationLibrary = animation_player.get_animation_library(library_name)
			print("Library ", library_name, " clips=", library.get_animation_list())
			for animation_name: StringName in library.get_animation_list():
				var animation: Animation = library.get_animation(animation_name)
				print("  ", animation_name, " length=", animation.length, " tracks=", animation.get_track_count())
	for skeleton_node: Node in skeletons:
		var skeleton: Skeleton3D = skeleton_node as Skeleton3D
		var bone_names: PackedStringArray = PackedStringArray()
		for bone_index: int in range(skeleton.get_bone_count()):
			bone_names.append(String(skeleton.get_bone_name(bone_index)))
		print("Skeleton ", skeleton.name, " bone_count=", skeleton.get_bone_count(), " bones=", bone_names)
	instance.queue_free()
	quit(0)


func _find_nodes(node: Node, class_name_to_find: String, found: Array[Node]) -> void:
	if node.is_class(class_name_to_find):
		found.append(node)
	for child: Node in node.get_children():
		_find_nodes(child, class_name_to_find, found)
