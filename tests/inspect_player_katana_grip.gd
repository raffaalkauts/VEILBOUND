extends SceneTree

## Prints the katana rotation (in right-hand bone space) that points the blade
## forward-and-up in the model frame for several retargeted poses.

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var model: PlayerCharacterModel = (load("res://characters/player/visual/player_character_model.tscn") as PackedScene).instantiate() as PlayerCharacterModel
	root.add_child(model)
	await process_frame
	await process_frame
	var skel: Skeleton3D = model.skeleton
	var hand: int = skel.find_bone("Shibahu_RightHand_0167_217")
	for entry: Array in [["guard", 0.3], ["attack_1", 0.0], ["attack_1", 0.22], ["idle", 0.5], ["walk", 0.3]]:
		model.anim_player.play(entry[0], 0.0)
		model.anim_player.seek(entry[1], true)
		model.anim_player.advance(0.0)
		var hand_world: Basis = (skel.global_transform * skel.get_bone_global_pose(hand)).basis.orthonormalized()
		var want_dir: Vector3 = model.global_basis * Vector3(0.0, 0.45, -0.89)
		var local_dir: Vector3 = hand_world.inverse() * want_dir.normalized()
		var q := Quaternion(Vector3.UP, local_dir.normalized())
		print("KATANA ", entry, " local_dir=", local_dir.normalized(), " euler=", q.get_euler())
	quit(0)
