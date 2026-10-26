extends SceneTree

func _init() -> void:
	var packed := load("res://assets/animations/quaternius/universal_animation_library_standard.glb") as PackedScene
	var instance := packed.instantiate() as Node3D
	root.add_child(instance)
	var player := instance.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var animation := player.get_animation("Sword_Attack")
	for index in range(mini(animation.get_track_count(), 15)):
		print(index, " ", animation.track_get_type(index), " ", animation.track_get_path(index))
	quit(0)
