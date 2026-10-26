extends SceneTree

const FoxAnimGen = preload("res://tests/generate_fox_animations.gd")

func _init() -> void:
	var model = Node3D.new()
	model.name = "PlayerCharacterModel"
	root.add_child(model)
	
	var fox = load("res://assets/characters/protagonist/imported/anime_fox_girl.glb").instantiate()
	fox.name = "FoxGirlMesh"
	fox.position = Vector3(0.542849, -0.113543, 0.0)
	fox.rotation.y = PI
	model.add_child(fox)
	
	var ap = AnimationPlayer.new()
	ap.name = "AnimationPlayer"
	model.add_child(ap)
	
	var lib = FoxAnimGen.build_player_animation_library()
	ap.add_animation_library("", lib)
	
	print("Testing playing all 12 animations on model...")
	for anim_name in lib.get_animation_list():
		ap.play(anim_name)
		ap.advance(0.1)
		print("  Played: ", anim_name, " current=", ap.current_animation)
		
	model.free()
	quit(0)
