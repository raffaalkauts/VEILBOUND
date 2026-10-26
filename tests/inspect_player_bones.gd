extends SceneTree

func _init() -> void:
	var packed: PackedScene = load("res://characters/player/visual/player_character_model.tscn")
	var inst: Node = packed.instantiate()
	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	for i in range(skel.get_bone_count()):
		var n: String = skel.get_bone_name(i)
		if n.begins_with("Shibahu_") and (n.contains("Foot") or n.contains("Toe") or n.contains("Hips") or n.contains("Spine") or n.contains("Neck") or n.contains("Head_") or n.contains("UpLeg") or n.contains("_Leg_") or n.contains("Leg_") or n.contains("Shoulder") or n.contains("Arm") or n.contains("Hand_")) and not n.contains("Finger") and not n.contains("Thumb") and not n.contains("Index") and not n.contains("Middle") and not n.contains("Ring") and not n.contains("Pinky"):
			var p: int = skel.get_bone_parent(i)
			print(i, " ", n, " parent=", skel.get_bone_name(p) if p >= 0 else "-")
	print("root bones:")
	for i in range(skel.get_bone_count()):
		if skel.get_bone_parent(i) < 0:
			print("  ", skel.get_bone_name(i))
	inst.free()
	quit(0)
