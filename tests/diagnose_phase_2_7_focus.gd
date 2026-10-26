extends SceneTree

## Dev probe: is the render window actually presenting? Compares normal
## process_frame timing with RenderingServer.force_draw and with an always-on-top
## foreground window. No assertions.

func _init() -> void:
	call_deferred("_run")


func _report(label: String, frames: int) -> void:
	for _i in range(20):
		await process_frame
	var total := 0.0
	var last := Time.get_ticks_usec()
	for _i in range(frames):
		await process_frame
		var now := Time.get_ticks_usec()
		total += float(now - last) / 1000.0
		last = now
	print("%-24s avg=%6.2fms fps=%6.1f" % [label, total / frames, 1000.0 / (total / frames)])


func _state(label: String) -> void:
	print("%-24s focused=%s mode=%d top=%s pos=%s size=%s" % [
		label,
		DisplayServer.window_is_focused(),
		DisplayServer.window_get_mode(),
		DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP),
		DisplayServer.window_get_position(),
		DisplayServer.window_get_size(),
	])


func _run() -> void:
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DisplayServer.window_set_size(Vector2i(1152, 648))
	var main: Node3D = (load("res://main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(main)
	await process_frame
	var camera := Camera3D.new()
	camera.far = 250.0
	main.add_child(camera)
	camera.current = true
	camera.global_position = Vector3(0.0, -0.35, 13.2)
	camera.look_at(Vector3(0.0, 0.4, -6.0), Vector3.UP)
	var player: Node3D = main.get_node("Player") as Node3D
	player.global_position = Vector3(0.0, -1.9, 11.0)

	_state("initial")
	await _report("normal", 120)

	DisplayServer.window_move_to_foreground()
	await process_frame
	_state("after_foreground")
	await _report("foreground", 120)

	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	DisplayServer.window_set_position(Vector2i(0, 0))
	DisplayServer.window_move_to_foreground()
	await process_frame
	_state("topmost")
	await _report("topmost", 120)

	# Force a draw after each frame. If the window was being skipped, this should
	# restore GPU-bound timing (and is intentionally slower than a normal frame).
	var total := 0.0
	for _i in range(20):
		await process_frame
		RenderingServer.force_draw(false)
	var last := Time.get_ticks_usec()
	for _i in range(120):
		await process_frame
		RenderingServer.force_draw(false)
		var now := Time.get_ticks_usec()
		total += float(now - last) / 1000.0
		last = now
	print("%-24s avg=%6.2fms fps=%6.1f" % ["force_draw", total / 120.0, 120000.0 / total])
	quit(0)
