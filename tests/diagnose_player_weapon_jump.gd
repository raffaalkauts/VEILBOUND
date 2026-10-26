extends SceneTree

func _init() -> void:
	var packed: PackedScene = load("res://characters/player/visual/player_character_model.tscn") as PackedScene
	var model: PlayerCharacterModel = packed.instantiate() as PlayerCharacterModel
	root.add_child(model)
	await process_frame
	var anim: Animation = model.anim_player.get_animation("jump")
	print("JUMP length=", anim.length, " tracks=", anim.get_track_count())
	for index in range(anim.get_track_count()):
		print("  ", index, " ", anim.track_get_path(index))
	model.set_combat_mode(true)
	model.play_animation("idle", 0.0, true)
	await process_frame
	var hand_basis: Basis = model.hand_attachment.global_transform.basis.orthonormalized()
	var desired_local: Vector3 = hand_basis.inverse() * Vector3(0.0, 0.0, -1.0)
	print("desired local vector for world forward -Z: ", desired_local, " euler=", Quaternion(Vector3.UP, desired_local.normalized()).get_euler())
	print("configured blade axis=", model.katana_in_hand.global_transform.basis.y.normalized(), " forward dot=", model.katana_in_hand.global_transform.basis.y.normalized().dot(Vector3(0.0, 0.0, -1.0)))
	for rotation_x: float in [PI * 0.5, -PI * 0.5, 0.0]:
		model.katana_in_hand.rotation = Vector3(rotation_x, 0.0, 0.0)
		var blade_axis: Vector3 = model.katana_in_hand.global_transform.basis.y.normalized()
		print("weapon rotation_x=", rotation_x, " hand=", model.hand_attachment.global_transform.basis, " blade_axis=", blade_axis)
	model.free()
	quit(0)
