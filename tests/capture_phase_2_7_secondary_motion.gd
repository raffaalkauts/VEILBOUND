extends SceneTree

## Phase 2.7 evidence capture: real production player model, real spring chains.
## Windowed run required (rendering).

const OUTPUT_PREFIX: String = "res://screenshot_phase_2_7_"


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var main: Node3D = (load("res://main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(main)
	var player: PlayerController = main.get_node("Player") as PlayerController
	for _i in range(30):
		await process_frame

	var model: PlayerCharacterModel = player.get_node("VisualRoot/PlayerCharacterModel") as PlayerCharacterModel
	if model == null or model.secondary_motion == null:
		printerr("SECONDARY_MOTION_MISSING")
		quit(1)
		return
	print("SECONDARY chains=", model.secondary_motion.chain_count())

	var camera := Camera3D.new()
	camera.current = true
	main.add_child(camera)

	var shots: Array[Dictionary] = [
		{"clip": "idle", "frames": 30, "pos": Vector3(0.0, 1.35, 3.0), "look": Vector3(0.0, 1.05, 0.0), "name": "idle_front"},
		{"clip": "idle", "frames": 30, "pos": Vector3(1.9, 1.5, -1.9), "look": Vector3(0.0, 1.0, 0.0), "name": "idle_back"},
		{"clip": "sprint", "frames": 12, "pos": Vector3(1.8, 1.45, -2.2), "look": Vector3(0.0, 1.0, 0.0), "name": "sprint_back"},
		{"clip": "sprint", "frames": 26, "pos": Vector3(2.6, 1.3, 0.0), "look": Vector3(0.0, 1.0, 0.0), "name": "sprint_side"},
		{"clip": "walk", "frames": 20, "pos": Vector3(2.6, 1.3, 0.0), "look": Vector3(0.0, 1.0, 0.0), "name": "walk_side"},
		{"clip": "attack_1", "frames": 8, "pos": Vector3(1.4, 1.5, 2.6), "look": Vector3(0.0, 1.0, 0.0), "name": "attack_1"},
		{"clip": "attack_2", "frames": 8, "pos": Vector3(-1.6, 1.5, 2.5), "look": Vector3(0.0, 1.0, 0.0), "name": "attack_2"},
		{"clip": "guard", "frames": 12, "pos": Vector3(1.6, 1.4, 2.4), "look": Vector3(0.0, 1.0, 0.0), "name": "guard"},
		{"clip": "dodge", "frames": 10, "pos": Vector3(2.2, 1.3, 1.8), "look": Vector3(0.0, 1.0, 0.0), "name": "dodge"},
		{"clip": "jump", "frames": 12, "pos": Vector3(0.0, 1.5, 3.2), "look": Vector3(0.0, 1.1, 0.0), "name": "jump"},
	]

	for shot: Dictionary in shots:
		player.global_position = Vector3.ZERO
		player.velocity = Vector3.ZERO
		model.set_combat_mode(String(shot["clip"]).begins_with("attack") or shot["clip"] == "guard")
		model.play_animation(String(shot["clip"]), 0.0, true)
		model.secondary_motion.reset()
		camera.global_position = shot["pos"]
		camera.look_at(shot["look"], Vector3.UP)
		for _i in range(int(shot["frames"])):
			await process_frame
		_save_view(OUTPUT_PREFIX + String(shot["name"]) + ".png")

	# Close-up of individual chain groups so tail/hair/jacket can be inspected.
	var closeups: Array[Dictionary] = [
		{"group": &"tail", "pos": Vector3(1.1, 1.25, -1.5), "look": Vector3(0.0, 0.85, 0.0), "name": "chain_tail"},
		{"group": &"hair", "pos": Vector3(-1.4, 1.55, -1.6), "look": Vector3(0.0, 1.25, 0.0), "name": "chain_hair"},
		{"group": &"clothing", "pos": Vector3(1.4, 1.1, -1.4), "look": Vector3(0.0, 0.75, 0.0), "name": "chain_clothing"},
		{"group": &"ears", "pos": Vector3(-0.9, 1.6, 1.7), "look": Vector3(0.0, 1.35, 0.0), "name": "chain_ears"},
	]
	model.play_animation("walk", 0.0, true)
	camera.global_position = closeups[0]["pos"]
	camera.look_at(closeups[0]["look"], Vector3.UP)
	for shot: Dictionary in closeups:
		for group: StringName in model.secondary_motion.get_group_names():
			model.secondary_motion.set_group_enabled(group, group == shot["group"])
		camera.global_position = shot["pos"]
		camera.look_at(shot["look"], Vector3.UP)
		for _i in range(18):
			await process_frame
		_save_view(OUTPUT_PREFIX + String(shot["name"]) + ".png")

	main.free()
	quit(0)


func _save_view(path: String) -> void:
	var image: Image = root.get_viewport().get_texture().get_image()
	if image != null:
		var result: Error = image.save_png(path)
		print("SECONDARY_CAPTURE path=%s result=%d size=%dx%d" % [path, result, image.get_width(), image.get_height()])
