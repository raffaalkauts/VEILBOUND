extends SceneTree

const OUTPUT_PREFIX: String = "res://screenshot_phase_2_6_"

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var main: Node3D = (load("res://main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(main)
	var player: PlayerController = main.get_node("Player") as PlayerController
	var soldier: SoldierEnemy = main.get_node("SoldierEnemy") as SoldierEnemy
	var camera := Camera3D.new()
	camera.current = true
	main.add_child(camera)
	for _i in range(30):
		await process_frame

	var player_clips: Array[String] = ["idle", "walk", "sprint", "jump", "dodge", "attack_1", "attack_2", "attack_3", "guard"]
	for clip_name: String in player_clips:
		var model: PlayerCharacterModel = player.get_node("VisualRoot/PlayerCharacterModel") as PlayerCharacterModel
		model.set_combat_mode(clip_name.begins_with("attack") or clip_name == "guard")
		model.play_animation(clip_name, 0.0, true)
		player.global_position = Vector3.ZERO
		camera.global_position = Vector3(0.0, 1.35, 3.0)
		camera.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
		for frame_index in range(3):
			await process_frame
			_save_view(OUTPUT_PREFIX + "player_" + clip_name + "_" + str(frame_index) + ".png")

	# Isolate the actual Soldier resource in the production scene and capture
	# combat states from its live state machine, not a mock model.
	player.visible = false
	soldier.global_position = Vector3.ZERO
	soldier.visible = true
	for state_name: String in ["idle", "telegraph", "attack", "recovery", "staggered"]:
		var state: SoldierEnemy.State = SoldierEnemy.State.IDLE
		match state_name:
			"telegraph": state = SoldierEnemy.State.TELEGRAPH
			"attack": state = SoldierEnemy.State.ATTACK
			"recovery": state = SoldierEnemy.State.RECOVERY
			"staggered": state = SoldierEnemy.State.STAGGERED
		soldier._change_state(state)
		camera.global_position = Vector3(0.0, 1.35, 3.2)
		camera.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
		for frame_index in range(3):
			await process_frame
			_save_view(OUTPUT_PREFIX + "soldier_" + state_name + "_" + str(frame_index) + ".png")

	main.free()
	quit(0)

func _save_view(path: String) -> void:
	var image: Image = root.get_viewport().get_texture().get_image()
	if image != null:
		var result: Error = image.save_png(path)
		print("ANIMATION_CAPTURE path=%s result=%d size=%dx%d" % [path, result, image.get_width(), image.get_height()])
