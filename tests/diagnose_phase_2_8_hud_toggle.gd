extends SceneTree

## Phase 2.8 HUD cost attribution probe (dev, no assertions).
## Run with --disable-render-loop. Measures draw-call volume per HUD subtree at
## the frozen entry station by hiding one panel group at a time. Panels are
## referenced by variable, not by node name, so runtime auto-renaming cannot
## break the probe.

const WARMUP: int = 25
const SAMPLES: int = 100
const ROUNDS: int = 2

var _main: Node3D
var _camera: Camera3D
var _player: PlayerController
var _soldier: SoldierEnemy
var _hud: CombatHUD
var _root: Control
var _panels: Array[Control] = []


func _init() -> void:
	call_deferred("_run")


func _draw_once() -> void:
	await process_frame
	RenderingServer.force_draw(false)


func _measure(label: String) -> float:
	var round_avgs: Array[float] = []
	for _round_index in range(ROUNDS):
		for _i in range(WARMUP):
			await _draw_once()
		var total: float = 0.0
		var monitor_samples: int = 0
		for _i in range(SAMPLES):
			await process_frame
			RenderingServer.force_draw(false)
			total += float(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
			monitor_samples += 1
		round_avgs.append(total / float(monitor_samples))
	var mean: float = 0.0
	for value: float in round_avgs:
		mean += value
	mean /= float(ROUNDS)
	print("[HUD] %-26s draws=%6.1f rounds=%s" % [label, mean, str(round_avgs)])
	return mean


func _run() -> void:
	Engine.max_fps = 0
	DisplayServer.window_set_size(Vector2i(1152, 648))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_main = (load("res://main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(_main)
	await process_frame
	await process_frame
	_player = _main.get_node("Player") as PlayerController
	_soldier = _main.get_node("SoldierEnemy") as SoldierEnemy
	_player.health.is_invulnerable = true
	_soldier.set_physics_process(false)
	_camera = Camera3D.new()
	_camera.far = 250.0
	_main.add_child(_camera)
	_player.global_position = Vector3(0.0, -1.9, 11.0)
	_camera.global_position = Vector3(0.0, -0.35, 13.2)
	_camera.look_at(Vector3(0.0, 0.4, -6.0), Vector3.UP)
	_camera.current = true
	for _i in range(60):
		await _draw_once()

	_hud = _main.get_node("CombatHUD") as CombatHUD
	_root = _hud.get_node("Root") as Control
	print("[HUD] root children:")
	for child in _root.get_children():
		print("[HUD]   %-18s visible=%s" % [String(child.name), str((child as CanvasItem).visible)])

	var previous: float = await _measure("hud_full")
	var status: Control = null
	for child in _root.get_children():
		var control := child as Control
		if control == null or String(control.name) == "BottomVignette":
			continue
		if String(control.name) == "PlayerStatusPanel":
			status = control
			continue
		control.visible = false
		var value: float = await _measure("minus_%s" % String(control.name))
		previous = value
	if status != null:
		for child in status.find_children("*", "Control", true, false):
			var control := child as Control
			var was_visible: bool = control.visible
			control.visible = false
			var label: String = "single_off_%s" % String(control.name)
			var value: float = await _measure(label)
			print("[HUD]   delta %-28s %5.1f" % [label, previous - value])
			control.visible = was_visible
	_hud.visible = false
	await _measure("hud_off_all")
	quit(0)
