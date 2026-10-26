extends SceneTree

func _init() -> void:
	var res = load("res://characters/player/visual/player_animations.tres")
	print("Loaded res: ", res)
	if res:
		print("Type: ", res.get_class())
		if res is AnimationLibrary:
			print("Anims: ", (res as AnimationLibrary).get_animation_list())
	quit(0)
