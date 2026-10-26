extends SceneTree

## Phase 2.7 reproducible performance capture.
##
## Runs the real production scene with vsync disabled and records four fixed
## views on the real camera: low density, entry, dense architecture, combat.
## Writes JSON + CSV under res://.godot/phase_2_7/ (ignored by git).
##
## Usage:
##   godot --path E:\gamefurr --script res://tests/benchmark_phase_2_7.gd -- --tag=baseline
##
## GPU timing is not exposed by the Compatibility/OpenGL backend; only CPU-side
## process/physics time and renderer counters are available. That limitation is
## recorded in the output instead of inventing a GPU number.

const OUT_DIR: String = "res://.godot/phase_2_7"
const WARMUP_FRAMES: int = 60
const SAMPLE_FRAMES: int = 600
const SPIN_UP_FRAMES: int = 90
const ROUTE_PREWARM_FRAMES: int = 45
const ROUTE_ROUNDS: int = 1

var _main: Node3D
var _player: PlayerController
var _soldier: SoldierEnemy
var _camera: Camera3D
var _health: HealthComponent


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var tag: String = _read_tag()
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DisplayServer.window_set_size(Vector2i(1152, 648))
	print("[BENCH] window=", DisplayServer.window_get_size(), " viewport=", root.size)

	_main = (load("res://main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(_main)
	_player = _main.get_node("Player") as PlayerController
	_soldier = _main.get_node("SoldierEnemy") as SoldierEnemy
	_health = _player.get_node("HealthComponent") as HealthComponent
	_camera = Camera3D.new()
	_camera.name = "BenchmarkCamera"
	_camera.far = 250.0
	_main.add_child(_camera)
	_camera.current = true
	# Keep the player alive so the combat view stays stable while the soldier
	# actually attacks. Rendering cost is unaffected by invulnerability.
	_health.is_invulnerable = true

	for _i in range(SPIN_UP_FRAMES):
		await process_frame

	var stations: Array[Dictionary] = [
		{
			"id": "low_density",
			"description": "Entry plateau looking outward; minimal architecture",
			"player": Vector3(0.0, -1.9, 11.0),
			"camera": Vector3(0.0, -0.45, 13.6),
			"look": Vector3(0.0, -0.6, 24.0),
			"combat": false,
		},
		{
			"id": "entry",
			"description": "Entry threshold looking through the whole ruins",
			"player": Vector3(0.0, -1.9, 11.0),
			"camera": Vector3(0.0, -0.35, 13.2),
			"look": Vector3(0.0, 0.4, -6.0),
			"combat": false,
		},
		{
			"id": "dense_buildings",
			"description": "Inside the courtyard facing gate, walls, crypt and trees",
			"player": Vector3(0.0, 0.0, 2.0),
			"camera": Vector3(0.0, 2.0, 2.6),
			"look": Vector3(0.0, 1.1, -13.0),
			"combat": false,
		},
		{
			"id": "combat_active",
			"description": "Close combat with the live Soldier state machine",
			"player": Vector3(0.0, 0.0, -5.2),
			"camera": Vector3(1.0, 1.65, -2.5),
			"look": Vector3(0.0, 1.05, -6.4),
			"combat": true,
		},
	]

	var results: Dictionary = {}
	var rounds: Dictionary = {}
	var csv_lines: Array[String] = ["station,frame,ms,draw_calls,primitives,objects,process_ms,physics_ms"]
	# Walk the whole route before recording so every material/shader has been
	# compiled and the GPU has reached a steady clock state.
	for station: Dictionary in stations:
		_apply_station(station)
		for _i in range(ROUTE_PREWARM_FRAMES):
			await process_frame
	for round_index in range(ROUTE_ROUNDS):
		var round_results: Dictionary = {}
		for station: Dictionary in stations:
			_apply_station(station)
			await _warm_up()
			var sample: Dictionary = await _measure_station(String(station["id"]))
			var score: Dictionary = _summarise(sample)
			score["description"] = station["description"]
			score["camera"] = station["camera"]
			round_results[String(station["id"])] = score
			if round_index == ROUTE_ROUNDS - 1:
				results[String(station["id"])] = score
				_append_csv(csv_lines, String(station["id"]), sample)
				print("[BENCH] %-16s avg=%6.2fms (%5.2f fps) med=%6.2f p95=%6.2f 1%%low=%5.2f draws=%6.1f objs=%6.0f prims=%8.0f spikes>33ms=%4d cam=%s" % [
					station["id"], score["avg_ms"], score["avg_fps"], score["median_ms"], score["p95_ms"],
					score["one_percent_low_fps"], score["draw_calls_avg"], score["objects_avg"],
					score["primitives_avg"], score["spikes_over_33ms"], str(station["camera"]),
				])
			else:
				print("[BENCH] warmup round %s avg=%.2fms fps=%.2f prims=%.0f" % [
					station["id"], score["avg_ms"], score["avg_fps"], score["primitives_avg"],
				])
		rounds[round_index] = round_results

	var payload: Dictionary = {
		"tag": tag,
		"timestamp": Time.get_datetime_string_from_system(true),
		"resolution": [1152, 648],
		"renderer": ProjectSettings.get_setting("rendering/renderer/rendering_method"),
		"vsync": "disabled",
		"warmup_frames": WARMUP_FRAMES,
		"sample_frames": SAMPLE_FRAMES,
		"gpu_time_available": false,
		"gpu_time_note": "Compatibility/OpenGL backend does not expose GPU frame time.",
		"hardware": {
			"rendering_device": RenderingServer.get_video_adapter_name(),
			"vendor": RenderingServer.get_video_adapter_vendor(),
		},
		"stations": results,
	}
	var json_path: String = "%s/benchmark_%s.json" % [OUT_DIR, tag]
	var json_file: FileAccess = FileAccess.open(json_path, FileAccess.WRITE)
	if json_file != null:
		json_file.store_string(JSON.stringify(payload, "\t"))
		json_file.close()
		print("[BENCH] wrote ", json_path)
	var csv_path: String = "%s/benchmark_%s.csv" % [OUT_DIR, tag]
	var csv_file: FileAccess = FileAccess.open(csv_path, FileAccess.WRITE)
	if csv_file != null:
		for line: String in csv_lines:
			csv_file.store_line(line)
		csv_file.close()
		print("[BENCH] wrote ", csv_path)

	_main.free()
	quit(0)


func _read_tag() -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--tag="):
			return argument.trim_prefix("--tag=")
	return "run"


func _apply_station(station: Dictionary) -> void:
	var player_position: Vector3 = station["player"]
	_player.global_position = player_position
	_player.velocity = Vector3.ZERO
	_soldier.global_position = Vector3(0.0, 0.0, -7.0)
	if bool(station["combat"]):
		# Force the live state machine into combat; the player is invulnerable.
		_soldier._change_state(SoldierEnemy.State.CHASE)
	else:
		_soldier._change_state(SoldierEnemy.State.IDLE)
	_camera.global_position = station["camera"]
	_camera.look_at(station["look"], Vector3.UP)
	_camera.current = true


func _warm_up() -> void:
	for _i in range(WARMUP_FRAMES):
		await process_frame


func _measure_station(station_id: String) -> Dictionary:
	var frames: Array[float] = []
	var draw_calls: Array[float] = []
	var primitives: Array[float] = []
	var objects: Array[float] = []
	var process_ms: Array[float] = []
	var physics_ms: Array[float] = []
	var last_us: int = Time.get_ticks_usec()
	for _i in range(SAMPLE_FRAMES):
		await process_frame
		var now_us: int = Time.get_ticks_usec()
		var delta_us: float = float(now_us - last_us)
		last_us = now_us
		# Discard the first frame after a potential hitch in scene transitions.
		if frames.is_empty() and delta_us > 250000.0:
			continue
		frames.append(delta_us / 1000.0)
		draw_calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		primitives.append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
		objects.append(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
		process_ms.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		physics_ms.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
	return {
		"id": station_id,
		"frames_ms": frames,
		"draw_calls": draw_calls,
		"primitives": primitives,
		"objects": objects,
		"process_ms": process_ms,
		"physics_ms": physics_ms,
	}


func _summarise(sample: Dictionary) -> Dictionary:
	var frames: Array = (sample["frames_ms"] as Array).duplicate()
	if frames.is_empty():
		return {}
	var total: float = 0.0
	for value: float in frames:
		total += value
	var average: float = total / float(frames.size())
	var sorted: Array = frames.duplicate()
	sorted.sort()
	var median: float = float(sorted[sorted.size() / 2])
	var p95: float = float(sorted[mini(sorted.size() - 1, int(ceil(float(sorted.size()) * 0.95)) - 1)])
	var p99: float = float(sorted[mini(sorted.size() - 1, int(ceil(float(sorted.size()) * 0.99)) - 1)])
	var slow_count: int = maxi(1, int(ceil(float(sorted.size()) * 0.01)))
	var slow_total: float = 0.0
	for index in range(sorted.size() - slow_count, sorted.size()):
		slow_total += float(sorted[index])
	var slow_average: float = slow_total / float(slow_count)
	var spikes: int = 0
	for value: float in frames:
		if value > 33.34:
			spikes += 1
	return {
		"avg_ms": average,
		"avg_fps": 1000.0 / maxf(average, 0.001),
		"median_ms": median,
		"p95_ms": p95,
		"p99_ms": p99,
		"one_percent_low_fps": 1000.0 / maxf(slow_average, 0.001),
		"worst_ms": float(sorted[sorted.size() - 1]),
		"spikes_over_33ms": spikes,
		"draw_calls_avg": _average(sample["draw_calls"]),
		"draw_calls_max": _max(sample["draw_calls"]),
		"objects_avg": _average(sample["objects"]),
		"primitives_avg": _average(sample["primitives"]),
		"process_ms_avg": _average(sample["process_ms"]),
		"physics_ms_avg": _average(sample["physics_ms"]),
		"video_mem_bytes": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
		"static_mem_bytes": Performance.get_monitor(Performance.MEMORY_STATIC),
	}


func _average(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var total: float = 0.0
	for value: float in values:
		total += value
	return total / float(values.size())


func _max(values: Array) -> float:
	var result: float = 0.0
	for value: float in values:
		result = maxf(result, value)
	return result


func _append_csv(lines: Array[String], station_id: String, sample: Dictionary) -> void:
	var frames: Array = sample["frames_ms"]
	for index in range(frames.size()):
		lines.append("%s,%d,%.3f,%.0f,%.0f,%.0f,%.3f,%.3f" % [
			station_id, index, float(frames[index]),
			float(sample["draw_calls"][index]), float(sample["primitives"][index]),
			float(sample["objects"][index]), float(sample["process_ms"][index]),
			float(sample["physics_ms"][index]),
		])
