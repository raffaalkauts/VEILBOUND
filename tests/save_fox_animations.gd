extends SceneTree

const FoxAnimGen = preload("res://tests/generate_fox_animations.gd")

func _init() -> void:
	var lib = FoxAnimGen.build_player_animation_library()
	var err = ResourceSaver.save(lib, "res://characters/player/visual/player_animations.tres")
	print("Save player_animations.tres result: ", err)
	quit(0 if err == OK else 1)
