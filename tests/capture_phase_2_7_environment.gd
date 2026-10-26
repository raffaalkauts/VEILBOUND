extends SceneTree

## Phase 2.7 environment evidence capture.
## Windowed run required (rendering). Shows the batching/shadow changes at the
## exact benchmark stations, plus a close view of the cemetery props.

const OUTPUT_PREFIX: String = "res://screenshot_phase_2_7_"


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var main: Node3D = (load("res://main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(main)
	await process_frame
	var player: PlayerController = main.get_node("Player") as PlayerController
	var soldier: Node3D = main.get_node("SoldierEnemy") as Node3D
	var hud: CanvasLayer = main.get_node("CombatHUD") as CanvasLayer
	hud.visible = false
	var model: PlayerCharacterModel = player.get_node("VisualRoot/PlayerCharacterModel") as PlayerCharacterModel
	model.play_animation("idle", 0.0, true)
	var camera := Camera3D.new()
	camera.far = 250.0
	main.add_child(camera)
	camera.current = true
	for _i in range(40):
		await process_frame

	var shots: Array[Dictionary] = [
		{
			"name": "env_entry",
			"player": Vector3(0.0, -1.9, 11.0),
			"camera": Vector3(0.0, -0.35, 13.2),
			"look": Vector3(0.0, 0.4, -6.0),
		},
		{
			"name": "env_dense",
			"player": Vector3(0.0, 0.0, 2.0),
			"camera": Vector3(0.0, 2.0, 2.6),
			"look": Vector3(0.0, 1.1, -13.0),
		},
		{
			"name": "env_courtyard",
			"player": Vector3(0.0, 0.0, 2.0),
			"camera": Vector3(0.0, 1.5, 4.5),
			"look": Vector3(-5.0, 0.4, -8.0),
		},
		{
			"name": "env_gate",
			"player": Vector3(0.0, 0.0, 2.0),
			"camera": Vector3(0.0, 1.2, -4.0),
			"look": Vector3(0.0, 1.4, -14.0),
		},
	]
	for shot: Dictionary in shots:
		player.global_position = shot["player"]
		player.velocity = Vector3.ZERO
		soldier.global_position = Vector3(0.0, 0.0, -7.0)
		camera.global_position = shot["camera"]
		camera.look_at(shot["look"], Vector3.UP)
		for _i in range(24):
			await process_frame
		_save_view(OUTPUT_PREFIX + String(shot["name"]) + ".png")

	main.free()
	quit(0)


func _save_view(path: String) -> void:
	var image: Image = root.get_viewport().get_texture().get_image()
	if image == null:
		printerr("CAPTURE: no image for ", path)
		return
	image.save_png(path)
	print("CAPTURE: ", path)
