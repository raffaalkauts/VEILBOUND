extends SceneTree

## Phase 2.8 HUD visual capture at three resolutions (windowed run).
## Same frozen entry station as the perf probes so the composition is stable.

const OUT_PATHS: Dictionary = {
	Vector2i(1152, 648): "res://screenshot_phase_2_8_hud_1152x648.png",
	Vector2i(1280, 720): "res://screenshot_phase_2_8_hud_1280x720.png",
	Vector2i(1920, 1080): "res://screenshot_phase_2_8_hud_1920x1080.png",
}

var _main: Node3D
var _camera: Camera3D


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1152, 648))
	_main = (load("res://main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(_main)
	await process_frame
	await process_frame
	var player: PlayerController = _main.get_node("Player") as PlayerController
	var soldier: SoldierEnemy = _main.get_node("SoldierEnemy") as SoldierEnemy
	player.health.is_invulnerable = true
	soldier.set_physics_process(false)
	_camera = Camera3D.new()
	_camera.far = 250.0
	_main.add_child(_camera)
	_player_station(player)
	for _i in range(30):
		await process_frame
	for resolution: Vector2i in OUT_PATHS:
		DisplayServer.window_set_size(resolution)
		for _i in range(12):
			await process_frame
		var image: Image = _camera.get_viewport().get_texture().get_image()
		image.save_png(OUT_PATHS[resolution])
		print("[CAPTURE] %s size=%s" % [OUT_PATHS[resolution], str(image.get_size())])
	quit(0)


func _player_station(player: PlayerController) -> void:
	player.global_position = Vector3(0.0, -1.9, 11.0)
	player.velocity = Vector3.ZERO
	_camera.global_position = Vector3(0.0, -0.35, 13.2)
	_camera.look_at(Vector3(0.0, 0.4, -6.0), Vector3.UP)
	_camera.current = true
