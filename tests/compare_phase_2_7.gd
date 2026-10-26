extends SceneTree

## Phase 2.7 before/after render comparison.
##
## MUST be run with --disable-render-loop. In that mode the normal frame does no
## rendering and RenderingServer.force_draw() executes exactly one draw, so the
## interval between forced draws measures submitted GPU work instead of how far
## the CPU can run ahead of the swap chain.
##
## The environment script exposes set_optimized_rendering(false) to rebuild the
## pre-optimization draw state (unbatched props, all casters shadowed) without
## touching collisions or navigation.

const OUT_DIR: String = "res://.godot/phase_2_7"
const WARMUP_FRAMES: int = 30
const SAMPLE_FRAMES: int = 120
const ROUNDS: int = 4


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	Engine.max_fps = 0
	DisplayServer.window_set_size(Vector2i(1152, 648))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var args: PackedStringArray = OS.get_cmdline_args()
	print("[COMPARE] instrument=RenderingServer.force_draw per sample (run with --disable-render-loop so each sample is exactly one draw)")
	var main: Node3D = (load("res://main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(main)
	await process_frame
	var player: PlayerController = main.get_node("Player") as PlayerController
	var soldier: SoldierEnemy = main.get_node("SoldierEnemy") as SoldierEnemy
	var light: DirectionalLight3D = main.get_node("DirectionalLight3D") as DirectionalLight3D
	var env: Node3D = main.get_node("NavigationRegion3D/DarkRuinsEnvironment") as Node3D
	player.health.is_invulnerable = true
	# Freeze enemy AI: the comparison measures rendering, not where the soldier
	# happens to have walked between samples.
	soldier.set_physics_process(false)
	var camera := Camera3D.new()
	camera.far = 250.0
	main.add_child(camera)
	camera.current = true
	var stations: Array[Dictionary] = [
		{
			"id": "low_density",
			"player": Vector3(0.0, -1.9, 11.0),
			"camera": Vector3(0.0, -0.45, 13.6),
			"look": Vector3(0.0, -0.6, 24.0),
			"combat": false,
		},
		{
			"id": "entry",
			"player": Vector3(0.0, -1.9, 11.0),
			"camera": Vector3(0.0, -0.35, 13.2),
			"look": Vector3(0.0, 0.4, -6.0),
			"combat": false,
		},
		{
			"id": "dense_buildings",
			"player": Vector3(0.0, 0.0, 2.0),
			"camera": Vector3(0.0, 2.0, 2.6),
			"look": Vector3(0.0, 1.1, -13.0),
			"combat": false,
		},
		{
			"id": "combat_active",
			"player": Vector3(0.0, 0.0, -5.2),
			"camera": Vector3(1.0, 1.65, -2.5),
			"look": Vector3(0.0, 1.05, -6.4),
			"combat": true,
		},
	]

	# Prewarm every station and both states so shader variants are compiled.
	for state: bool in [false, true]:
		_apply_state(env, light, state)
		for station: Dictionary in stations:
			_apply_station(player, soldier, camera, station)
			for _i in range(12):
				await _draw_once()

	var round_samples: Dictionary = {"baseline": {}, "optimized": {}}
	var results: Dictionary = {"baseline": {}, "optimized": {}}
	for round_index in range(ROUNDS):
		var order: Array[bool] = [false, true]
		if round_index % 2 != 0:
			order = [true, false]
		for station: Dictionary in stations:
			for state: bool in order:
				_apply_state(env, light, state)
				_apply_station(player, soldier, camera, station)
				var sample: Dictionary = await _measure()
				var key: String = "optimized" if state else "baseline"
				var station_id: String = String(station["id"])
				if not round_samples[key].has(station_id):
					round_samples[key][station_id] = []
				(round_samples[key][station_id] as Array).append(sample)
				print("[COMPARE] %-15s %-9s round%d avg=%6.2fms med=%6.2f p95=%6.2f draws=%6.1f prims=%8.0f" % [
					station_id, key, round_index + 1, sample["avg_ms"], sample["median_ms"],
					sample["p95_ms"], sample["draws"], sample["prims"],
				])

	for key: String in ["baseline", "optimized"]:
		for station: Dictionary in stations:
			var station_id: String = String(station["id"])
			results[key][station_id] = _average_samples(round_samples[key][station_id])

	print("--- summary (mean of %d rounds) ---" % ROUNDS)
	for station: Dictionary in stations:
		var id: String = String(station["id"])
		var base: Dictionary = results["baseline"][id]
		var opt: Dictionary = results["optimized"][id]
		var delta: float = (base["avg_ms"] - opt["avg_ms"]) / base["avg_ms"] * 100.0
		print("%-15s baseline=%6.2fms optimized=%6.2fms delta=%6.1f%% draws %6.1f -> %6.1f prims %8.0f -> %8.0f" % [
			id, base["avg_ms"], opt["avg_ms"], delta, base["draws"], opt["draws"],
			base["prims"], opt["prims"],
		])
	_apply_state(env, light, true)
	var json: Dictionary = {
		"timestamp": Time.get_datetime_string_from_system(true),
		"resolution": [1152, 648],
		"method": "one RenderingServer.force_draw per sample with --disable-render-loop",
		"rounds": ROUNDS,
		"warmup_frames": WARMUP_FRAMES,
		"sample_frames": SAMPLE_FRAMES,
		"results": results,
		"round_samples": round_samples,
	}
	var file: FileAccess = FileAccess.open(OUT_DIR + "/compare.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(json, "\t"))
		file.close()
		print("[COMPARE] wrote ", OUT_DIR + "/compare.json")
	quit(0)


func _apply_state(env: Node3D, light: DirectionalLight3D, optimized: bool) -> void:
	env.set_optimized_rendering(optimized)
	light.shadow_enabled = true
	light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	if optimized:
		light.directional_shadow_max_distance = 45.0
		RenderingServer.directional_shadow_atlas_set_size(2048, true)
	else:
		light.directional_shadow_max_distance = 100.0
		RenderingServer.directional_shadow_atlas_set_size(4096, true)


func _apply_station(player: PlayerController, soldier: SoldierEnemy, camera: Camera3D, station: Dictionary) -> void:
	player.global_position = station["player"]
	player.velocity = Vector3.ZERO
	soldier.global_position = Vector3(0.0, 0.0, -7.0)
	if bool(station["combat"]):
		soldier._change_state(SoldierEnemy.State.CHASE)
	else:
		soldier._change_state(SoldierEnemy.State.IDLE)
	camera.global_position = station["camera"]
	camera.look_at(station["look"], Vector3.UP)
	camera.current = true


func _draw_once() -> void:
	await process_frame
	RenderingServer.force_draw(false)


func _measure() -> Dictionary:
	for _i in range(WARMUP_FRAMES):
		await _draw_once()
	var times: Array[float] = []
	var draws: Array[float] = []
	var prims: Array[float] = []
	var last: int = Time.get_ticks_usec()
	for _i in range(SAMPLE_FRAMES):
		await process_frame
		RenderingServer.force_draw(false)
		var now: int = Time.get_ticks_usec()
		times.append(float(now - last) / 1000.0)
		last = now
		draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		prims.append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	var sorted_times: Array[float] = times.duplicate()
	sorted_times.sort()
	var total: float = 0.0
	for value: float in times:
		total += value
	var avg: float = total / float(times.size())
	var median: float = sorted_times[sorted_times.size() / 2]
	var p95: float = sorted_times[mini(sorted_times.size() - 1, int(float(sorted_times.size()) * 0.95))]
	var draw_avg := 0.0
	for value: float in draws:
		draw_avg += value
	draw_avg /= float(draws.size())
	var prim_avg := 0.0
	for value: float in prims:
		prim_avg += value
	prim_avg /= float(prims.size())
	var slow_total: float = 0.0
	var slow_count: int = maxi(1, sorted_times.size() / 100)
	for i in range(slow_count):
		slow_total += sorted_times[sorted_times.size() - 1 - i]
	var slow_average: float = slow_total / float(slow_count)
	return {
		"avg_ms": avg,
		"fps": 1000.0 / avg,
		"median_ms": median,
		"p95_ms": p95,
		"one_percent_low_fps": 1000.0 / maxf(slow_average, 0.001),
		"draws": draw_avg,
		"prims": prim_avg,
	}


func _average_samples(samples: Array) -> Dictionary:
	var keys: Array[String] = ["avg_ms", "median_ms", "p95_ms", "one_percent_low_fps", "draws", "prims"]
	var averages: Dictionary = {}
	for key: String in keys:
		var total: float = 0.0
		for sample: Dictionary in samples:
			total += float(sample[key])
		averages[key] = total / float(samples.size())
	averages["fps"] = 1000.0 / float(averages["avg_ms"])
	averages["sample_count"] = samples.size()
	return averages
