extends SceneTree

## Dev probe: list UAL source skeleton bone names and sample track paths.

const UAL_SCENE: PackedScene = preload("res://assets/animations/quaternius/universal_animation_library_standard.glb")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var source: Node3D = UAL_SCENE.instantiate() as Node3D
	root.add_child(source)
	await process_frame
	await process_frame
	var player: AnimationPlayer = source.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var skeleton: Skeleton3D = source.find_child("Skeleton3D", true, false) as Skeleton3D
	print("[UAL] bones=%d" % skeleton.get_bone_count())
	var names := []
	for index in range(skeleton.get_bone_count()):
		names.append(skeleton.get_bone_name(index))
	print("[UAL] bone_names=%s" % str(names))
	var idle: Animation = player.get_animation("Idle")
	print("[UAL] idle_track_count=%d" % idle.get_track_count())
	for track_index in range(mini(idle.get_track_count(), 10)):
		var path := String(idle.track_get_path(track_index))
		print("[UAL] track_path[%d]=%s rest_find=%d" % [track_index, path, skeleton.find_bone(path.substr(path.rfind(":") + 1))])
	quit(0)
