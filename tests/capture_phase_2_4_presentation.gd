extends SceneTree

const OUTPUT_PREFIX: String = "res://screenshot_phase_2_4_"


func _init() -> void:
	call_deferred("_capture_states")


func _capture_states() -> void:
	var main: Node3D = (load("res://main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(main)
	var player: PlayerController = main.get_node("Player") as PlayerController
	var soldier: SoldierEnemy = main.get_node("SoldierEnemy") as SoldierEnemy
	for dummy: Node in main.get_tree().get_nodes_in_group("lock_on_targets"):
		if dummy != soldier.get_node("LockOnTarget"):
			var dummy_parent: Node = dummy.get_parent()
			if dummy_parent != null and dummy_parent.name.begins_with("Dummy"):
				dummy_parent.visible = false
	var camera: Camera3D = Camera3D.new()
	camera.current = true
	main.add_child(camera)

	for _i in range(30):
		await process_frame

	var shots: Array[Dictionary] = [
		{"name": "idle", "state": PlayerController.LocomotionState.IDLE},
		{"name": "walk", "state": PlayerController.LocomotionState.MOVE},
		{"name": "sprint", "state": PlayerController.LocomotionState.SPRINT},
		{"name": "dodge", "state": PlayerController.LocomotionState.DODGE},
		{"name": "attack", "state": PlayerController.LocomotionState.ATTACK},
		{"name": "guard", "state": PlayerController.LocomotionState.GUARD},
	]

	for shot: Dictionary in shots:
		player.global_position = Vector3(0.0, 0.1, 0.0)
		player.visual_root.rotation.y = PI
		player.visual_root.update_procedural_visuals(shot["state"], 0.0, 0.016, 1)
		camera.global_position = Vector3(0.0, 1.5, 3.2)
		camera.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
		for _i in range(8):
			await process_frame
		_save_view(OUTPUT_PREFIX + shot["name"] + ".png")

	# Soldier telegraph and attack are captured from the live AI state machine.
	soldier.global_position = Vector3(0.0, 0.1, -2.4)
	soldier._target_player = player
	for state_name: String in ["telegraph", "attack"]:
		soldier._change_state(SoldierEnemy.State.TELEGRAPH if state_name == "telegraph" else SoldierEnemy.State.ATTACK)
		camera.global_position = Vector3(0.0, 1.5, 3.2)
		camera.look_at(Vector3(0.0, 1.0, -1.0), Vector3.UP)
		for _i in range(8):
			await process_frame
		_save_view(OUTPUT_PREFIX + "soldier_" + state_name + ".png")

	main.free()
	quit(0)


func _save_view(path: String) -> void:
	var image: Image = root.get_viewport().get_texture().get_image()
	if image != null:
		var result: Error = image.save_png(path)
		print("PRESENTATION_CAPTURE path=%s result=%d size=%dx%d" % [path, result, image.get_width(), image.get_height()])
