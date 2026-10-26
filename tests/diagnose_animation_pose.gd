extends SceneTree

func _init() -> void:
	var scene := load("res://main.tscn") as PackedScene
	var main := scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var model := main.get_node("Player/VisualRoot/PlayerCharacterModel") as PlayerCharacterModel
	var ap := model.anim_player
	var skel := model.skeleton
	print("animation=", ap.current_animation, " position=", ap.current_animation_position, " length=", ap.get_animation(ap.current_animation).length)
	print("tracks=", ap.get_animation(ap.current_animation).get_track_count(), " skeleton=", skel.get_path(), " bones=", skel.get_bone_count())
	for name in ["Shibahu_LeftShoulder_099_156", "Shibahu_LeftArm_0100_155", "Shibahu_LeftForeArm_0101_154", "Shibahu_LeftHand_0102_152", "Shibahu_RightShoulder_0164_221", "Shibahu_RightArm_0165_220", "Shibahu_RightForeArm_0166_219", "Shibahu_RightHand_0167_217", "Shibahu_Spine_01_224", "Shibahu_Hips_00_245", "Shibahu_LeftUpLeg_0189_228", "Shibahu_RightUpLeg_0193_232"]:
		var idx := skel.find_bone(name)
		var pose := skel.get_bone_global_pose(idx)
		print(name, " idx=", idx, " pos=", pose.origin, " basis=", pose.basis)
	for clip in ["idle", "walk", "sprint", "dodge", "attack_1"]:
		model.play_animation(clip, 0.0, true)
		for frame in range(3):
			await process_frame
			var l_idx := skel.find_bone("Shibahu_LeftArm_0100_155")
			var r_idx := skel.find_bone("Shibahu_RightArm_0165_220")
			print("clip=", clip, " t=", ap.current_animation_position, " L=", skel.get_bone_global_pose(l_idx).origin, " R=", skel.get_bone_global_pose(r_idx).origin)
	quit(0)
