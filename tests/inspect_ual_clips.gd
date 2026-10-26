extends SceneTree

func _init() -> void:
	var ual: Node = load("res://assets/animations/quaternius/universal_animation_library_standard.glb").instantiate()
	var ap: AnimationPlayer = ual.find_child("AnimationPlayer", true, false)
	var lib: AnimationLibrary = ap.get_animation_library("")
	for n in lib.get_animation_list():
		var a: Animation = lib.get_animation(n)
		print("UAL ", n, " len=", snappedf(a.length, 0.001), " tracks=", a.get_track_count())
	var lib2: AnimationLibrary = load("res://characters/player/visual/player_animations.tres")
	for n in lib2.get_animation_list():
		print("PLAYER ", n, " len=", lib2.get_animation(n).length)
	ual.free()
	quit(0)
