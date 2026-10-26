extends SceneTree
func _init() -> void:
	var inst := (load("res://assets/characters/protagonist/imported/anime_fox_girl.glb") as PackedScene).instantiate()
	root.add_child(inst)
	var skel := inst.find_child("Skeleton3D", true, false) as Skeleton3D
	for i in range(skel.get_bone_count()):
		var name := String(skel.get_bone_name(i))
		if name.contains("Hand") or name.contains("ForeArm") or name.contains("UpLeg") or name.contains("Leg") or name.contains("Shoulder") or name.contains("Neck"):
			print(name)
	quit(0)
