extends SceneTree

## Phase 2.7 cost attribution probe (dev, no assertions).
## Run with --disable-render-loop. Pinpoints where the entry-view frame time sits
## by disabling one system at the time with the forced-draw instrument.

const WARMUP: int = 25
const SAMPLES: int = 100
const ROUNDS: int = 2

var _main: Node3D
var _camera: Camera3D
var _light: DirectionalLight3D
var _hud: CanvasLayer
var _player: PlayerController
var _soldier: SoldierEnemy
var _visual: Node3D
var _env: Node3D


func _init() -> void:
	call_deferred("_run")


func _draw_once() -> void:
	await process_frame
	RenderingServer.force_draw(false)


func _measure(label: String) -> float:
	var round_avgs: Array[float] = []
	for round_index in range(ROUNDS):
		for _i in range(WARMUP):
			await _draw_once()
		var total: float = 0.0
		var last: int = Time.get_ticks_usec()
		for _i in range(SAMPLES):
			await process_frame
			RenderingServer.force_draw(false)
			var now: int = Time.get_ticks_usec()
			total += float(now - last) / 1000.0
			last = now
		round_avgs.append(total / float(SAMPLES))
	var mean: float = 0.0
	for value: float in round_avgs:
		mean += value
	mean /= float(ROUNDS)
	print("%-24s avg=%6.2fms rounds=%s" % [label, mean, str(round_avgs)])
	return mean


func _set_entry_station() -> void:
	_player.global_position = Vector3(0.0, -1.9, 11.0)
	_player.velocity = Vector3.ZERO
	_soldier.global_position = Vector3(0.0, 0.0, -7.0)
	_soldier._change_state(SoldierEnemy.State.IDLE)
	_camera.global_position = Vector3(0.0, -0.35, 13.2)
	_camera.look_at(Vector3(0.0, 0.4, -6.0), Vector3.UP)
	_camera.current = true


func _restore_all() -> void:
	_hud.visible = true
	_visual.visible = true
	_soldier.visible = true
	_env.visible = true
	_light.shadow_enabled = true


func _run() -> void:
	Engine.max_fps = 0
	DisplayServer.window_set_size(Vector2i(1152, 648))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_main = (load("res://main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(_main)
	await process_frame
	_player = _main.get_node("Player") as PlayerController
	_soldier = _main.get_node("SoldierEnemy") as SoldierEnemy
	_light = _main.get_node("DirectionalLight3D") as DirectionalLight3D
	_hud = _main.get_node("CombatHUD") as CanvasLayer
	_env = _main.get_node("NavigationRegion3D/DarkRuinsEnvironment") as Node3D
	_visual = _player.get_node("VisualRoot") as Node3D
	_player.health.is_invulnerable = true
	_soldier.set_physics_process(false)
	_camera = Camera3D.new()
	_camera.far = 250.0
	_main.add_child(_camera)
	_set_entry_station()
	for _i in range(60):
		await _draw_once()

	await _measure("entry_full")
	_hud.visible = false
	await _measure("entry_hud_off")
	_visual.visible = false
	await _measure("plus_player_off")
	_soldier.visible = false
	await _measure("plus_soldier_off")
	_env.visible = false
	await _measure("plus_env_off")
	_light.shadow_enabled = false
	await _measure("plus_shadow_off")
	_restore_all()
	_set_entry_station()
	quit(0)
