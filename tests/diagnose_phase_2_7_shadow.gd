extends SceneTree

## Phase 2.7 shadow budget diagnostic (dev probe, no assertions).
## Windowed run. Interleaves variants in a short run so GPU clock drift is
## visible instead of being mistaken for a shadow setting effect.

var _main: Node3D
var _camera: Camera3D
var _light: DirectionalLight3D
var _hud: CanvasLayer


func _init() -> void:
	call_deferred("_run")


func _measure(label: String, frames: int) -> Dictionary:
	for _i in range(24):
		await process_frame
	var total := 0.0
	var draws := 0.0
	var prims := 0.0
	var times: Array[float] = []
	var last := Time.get_ticks_usec()
	for _i in range(frames):
		await process_frame
		var now := Time.get_ticks_usec()
		var delta := float(now - last) / 1000.0
		last = now
		total += delta
		times.append(delta)
		draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		prims += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	var n := float(frames)
	times.sort()
	var median := times[int(n * 0.5)]
	var p95 := times[int(min(n - 1.0, n * 0.95))]
	print("%-22s avg=%6.2fms med=%6.2f p95=%6.2f draws=%6.1f prims=%8.0f" % [
		label, total / n, median, p95, draws / n, prims / n,
	])
	return {"avg": total / n, "median": median, "p95": p95, "draws": draws / n, "prims": prims / n}


func _apply(mode: int, size: int, shadow: bool) -> void:
	_light.directional_shadow_mode = mode
	_light.shadow_enabled = shadow
	RenderingServer.directional_shadow_atlas_set_size(size, true)


func _run() -> void:
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DisplayServer.window_set_size(Vector2i(1152, 648))
	_main = (load("res://main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(_main)
	await process_frame
	var player: PlayerController = _main.get_node("Player") as PlayerController
	var soldier: Node3D = _main.get_node("SoldierEnemy") as Node3D
	_hud = _main.get_node("CombatHUD") as CanvasLayer
	_light = _main.get_node("DirectionalLight3D") as DirectionalLight3D
	player.global_position = Vector3(0.0, -1.9, 11.0)
	soldier.global_position = Vector3(0.0, 0.0, -7.0)
	_camera = Camera3D.new()
	_camera.far = 250.0
	_main.add_child(_camera)
	_camera.current = true
	_camera.global_position = Vector3(0.0, -0.35, 13.2)
	_camera.look_at(Vector3(0.0, 0.4, -6.0), Vector3.UP)
	for _i in range(90):
		await process_frame

	for round_index in range(2):
		print("--- round %d ---" % (round_index + 1))
		_apply(DirectionalLight3D.SHADOW_ORTHOGONAL, 2048, true)
		await _measure("ortho_2048", 150)
		_apply(DirectionalLight3D.SHADOW_ORTHOGONAL, 4096, true)
		await _measure("ortho_4096", 150)
		_apply(DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS, 2048, true)
		await _measure("pssm4_2048", 150)
		_apply(DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS, 4096, true)
		await _measure("pssm4_4096", 150)
		_apply(DirectionalLight3D.SHADOW_ORTHOGONAL, 2048, false)
		await _measure("shadow_off", 150)
		_hud.visible = false
		await _measure("shadow_off_hud_off", 150)
		_hud.visible = true
	quit(0)
