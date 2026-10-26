extends SceneTree

func _init() -> void:
	call_deferred("_capture_all")


func _capture_all() -> void:
	var main_scene = load("res://main.tscn")
	var main = main_scene.instantiate()
	root.add_child(main)

	var player = main.get_node_or_null("Player")
	var soldier = main.get_node_or_null("SoldierEnemy")
	var checkpoint: LanternCheckpoint = main.get_node_or_null("LanternCheckpoint")

	# Activate checkpoint for glowing visual
	if checkpoint and player:
		checkpoint.activate_checkpoint(player)

	# Dedicated Capture Camera
	var cam = Camera3D.new()
	cam.current = true
	main.add_child(cam)

	# Warm up rendering pipeline
	for i in range(30):
		await process_frame

	# Setup shots:
	var shots = [
		{
			"name": "screenshot_phase_2_3_overview.png",
			"pos": Vector3(0.0, 7.5, 12.0),
			"look_at": Vector3(0.0, 1.2, -4.0),
			"fov": 65.0
		},
		{
			"name": "screenshot_phase_2_3_checkpoint.png",
			"pos": Vector3(4.5, 1.8, 4.5),
			"look_at": Vector3(7.0, 1.2, 2.0),
			"fov": 60.0
		},
		{
			"name": "screenshot_phase_2_3_combat.png",
			"pos": Vector3(-2.8, 2.0, -2.5),
			"look_at": Vector3(0.0, 1.2, -6.5),
			"fov": 65.0
		},
		{
			"name": "screenshot_phase_2_3_gate.png",
			"pos": Vector3(0.0, 2.2, -8.0),
			"look_at": Vector3(0.0, 2.5, -14.0),
			"fov": 70.0
		}
	]

	for shot in shots:
		cam.global_position = shot["pos"]
		cam.look_at(shot["look_at"], Vector3.UP)
		cam.fov = shot["fov"]

		for f in range(10):
			await process_frame

		var img: Image = root.get_viewport().get_texture().get_image()
		var save_path: String = "res://" + shot["name"]
		var err = img.save_png(save_path)
		print("Captured: ", shot["name"], " -> result=", err, " (", img.get_width(), "x", img.get_height(), ")")

	# Measure Performance / FPS over 60 active frames
	var start_time: float = Time.get_ticks_msec()
	for f in range(60):
		await process_frame
	var elapsed_ms: float = Time.get_ticks_msec() - start_time
	var avg_frame_time_ms: float = elapsed_ms / 60.0
	var approx_fps: float = 1000.0 / avg_frame_time_ms

	print("==================================================")
	print("PERFORMANCE BENCHMARK (Compatibility Renderer):")
	print("  Elapsed time (60 frames): %.2f ms" % elapsed_ms)
	print("  Average frame time: %.2f ms" % avg_frame_time_ms)
	print("  Measured FPS: %.1f FPS" % approx_fps)
	print("==================================================")

	quit(0)
