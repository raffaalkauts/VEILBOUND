extends SceneTree

func _init() -> void:
	var root_node = Node3D.new()
	var ap = AnimationPlayer.new()
	ap.name = "AnimationPlayer"
	root_node.add_child(ap)
	ap.owner = root_node
	
	var lib = load("res://characters/player/visual/player_animations.tres") as AnimationLibrary
	ap.add_animation_library("", lib)
	
	var packed = PackedScene.new()
	packed.pack(root_node)
	ResourceSaver.save(packed, "res://tests/test_ap_packed.tscn")
	print("Saved test_ap_packed.tscn")
	
	root_node.free()
	quit(0)
