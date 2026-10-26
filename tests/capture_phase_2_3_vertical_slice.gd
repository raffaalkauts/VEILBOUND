extends SceneTree

const CAPTURE_FRAMES: int = 180


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var main: Node3D = (load("res://main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(main)
	var player: PlayerController = main.get_node("Player") as PlayerController
	var soldier: SoldierEnemy = main.get_node("SoldierEnemy") as SoldierEnemy
	var checkpoint: LanternCheckpoint = main.get_node("LanternCheckpoint") as LanternCheckpoint
	checkpoint.activate_checkpoint(player)

	var camera: Camera3D = Camera3D.new()
	camera.name = "VerticalSliceCaptureCamera"
	camera.current = true
	main.add_child(camera)
	for _frame in range(45):
		await process_frame

	var shots: Array[Dictionary] = [
		{
			"name": "screenshot_phase_2_3_vertical_slice_overview.png",
			"position": Vector3(11.0, 20.0, 22.0),
			"look_at": Vector3(0.0, -0.4, -2.0),
			"fov": 86.0
		},
		{
			"name": "screenshot_phase_2_3_vertical_slice_approach.png",
			"position": Vector3(0.0, 0.6, 17.5),
			"look_at": Vector3(0.0, -0.2, 5.0),
			"fov": 68.0
		},
		{
			"name": "screenshot_phase_2_3_vertical_slice_checkpoint.png",
			"position": Vector3(4.0, 3.5, 4.5),
			"look_at": Vector3(7.0, 0.8, 2.0),
			"fov": 62.0
		},
		{
			"name": "screenshot_phase_2_3_vertical_slice_gate.png",
			"position": Vector3(0.0, 3.2, -8.0),
			"look_at": Vector3(0.0, 2.4, -14.0),
			"fov": 68.0
		}
	]
	for shot in shots:
		camera.global_position = shot["position"]
		camera.look_at(shot["look_at"], Vector3.UP)
		camera.fov = shot["fov"]
		for _frame in range(20):
			await process_frame
		var image: Image = root.get_viewport().get_texture().get_image()
		var output_path: String = "res://" + shot["name"]
		var save_result: Error = image.save_png(output_path)
		print("RENDERED_SCREENSHOT path=", output_path, " size=", image.get_width(), "x", image.get_height(), " result=", save_result)

	player.global_position = Vector3(0.0, 0.1, -4.0)
	soldier.global_position = Vector3(0.0, 0.0, -7.0)
	player.lock_on.acquire_target()
	player.melee_attack.try_attack()
	camera.global_position = Vector3(-3.2, 2.8, -2.8)
	camera.look_at(Vector3(0.0, 1.0, -6.5), Vector3.UP)
	camera.fov = 68.0
	for _frame in range(20):
		await process_frame
	var combat_image: Image = root.get_viewport().get_texture().get_image()
	var combat_path: String = "res://screenshot_phase_2_3_vertical_slice_combat.png"
	var combat_result: Error = combat_image.save_png(combat_path)
	print("RENDERED_SCREENSHOT path=", combat_path, " size=", combat_image.get_width(), "x", combat_image.get_height(), " result=", combat_result)

	for _frame in range(45):
		await process_frame
	var start_usec: int = Time.get_ticks_usec()
	var min_fps: float = INF
	var max_fps: float = 0.0
	var fps_total: float = 0.0
	var min_frame_ms: float = INF
	var max_frame_ms: float = 0.0
	for _frame in range(CAPTURE_FRAMES):
		var frame_start: int = Time.get_ticks_usec()
		await process_frame
		var frame_ms: float = float(Time.get_ticks_usec() - frame_start) / 1000.0
		var fps: float = 1000.0 / maxf(frame_ms, 0.001)
		fps_total += fps
		min_fps = minf(min_fps, fps)
		max_fps = maxf(max_fps, fps)
		min_frame_ms = minf(min_frame_ms, frame_ms)
		max_frame_ms = maxf(max_frame_ms, frame_ms)
	var elapsed_ms: float = float(Time.get_ticks_usec() - start_usec) / 1000.0
	var average_fps: float = fps_total / float(CAPTURE_FRAMES)
	var memory_info: Dictionary = OS.get_memory_info()
	print("==================================================")
	print("VERTICAL SLICE RENDERED PERFORMANCE (Compatibility Renderer)")
	print("  OS: ", OS.get_name(), " | CPU: ", OS.get_processor_name())
	print("  GPU: ", RenderingServer.get_video_adapter_vendor(), " ", RenderingServer.get_video_adapter_name())
	print("  Physical memory total: ", memory_info.get("physical", -1), " bytes")
	print("  Samples: ", CAPTURE_FRAMES, " rendered frames over ", elapsed_ms, " ms")
	print("  Average FPS (per-frame): ", average_fps, " | Min: ", min_fps, " | Max: ", max_fps)
	print("  Average elapsed frame: ", elapsed_ms / float(CAPTURE_FRAMES), " ms | Min: ", min_frame_ms, " | Max: ", max_frame_ms)
	print("  Render objects: ", Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME), " | Draw calls: ", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	print("  Visible nodes in level: ", Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME), " | FPS monitor: ", Performance.get_monitor(Performance.TIME_FPS))
	print("==================================================")
	quit(0)
