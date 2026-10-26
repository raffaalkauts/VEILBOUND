extends SceneTree


func _init() -> void:
	_inspect_rig("Player", "res://characters/player/visual/player_character_model.tscn")
	_inspect_rig("Soldier", "res://characters/enemies/soldier/soldier_enemy.tscn")
	quit(0)


func _inspect_rig(label: String, scene_path: String) -> void:
	var packed: PackedScene = load(scene_path) as PackedScene
	var instance: Node = packed.instantiate()
	root.add_child(instance)
	var skeleton: Skeleton3D = instance.find_child("Skeleton3D", true, false) as Skeleton3D
	print("--- ", label, " bones ---")
	for index: int in range(skeleton.get_bone_count()):
		var bone_name: String = String(skeleton.get_bone_name(index))
		if index < 8 or bone_name.contains("Arm") or bone_name.contains("ForeArm") or bone_name.contains("Hand") or bone_name.contains("UpLeg") or bone_name.contains("Leg_") or bone_name.contains("Foot") or bone_name.contains("Toe") or bone_name.contains("Spine") or bone_name.contains("Hips") or bone_name.contains("Neck") or bone_name.contains("Head") or bone_name.contains("Shoulder"):
			print(index, " ", bone_name, " rest=", skeleton.get_bone_rest(index).basis.get_rotation_quaternion())
	instance.queue_free()
