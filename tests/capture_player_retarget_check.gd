extends SceneTree

## One-off visual check of retargeted player clips (windowed run only).
## Writes PNGs to an absolute scratch directory outside the repo.

const OUT_DIR: String = "C:/Users/wired/.gemini/antigravity-ide/brain/664e23fa-ecf2-457a-a978-3b58e6f6b6ac/scratch/"
const SHOTS: Array = [
	["idle", [0.6]],
	["walk", [0.0, 0.33, 0.66]],
	["sprint", [0.0, 0.17, 0.34]],
	["attack_1", [0.05, 0.22, 0.4]],
	["attack_3", [0.1, 0.31, 0.6]],
	["dodge", [0.1, 0.25, 0.4]],
	["guard", [0.3]],
	["hit_react", [0.1]],
]

var _camera: Camera3D


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var main: Node3D = (load("res://main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(main)
	await process_frame
	await process_frame
	var player: PlayerController = main.get_node("Player") as PlayerController
	player.set_physics_process(false)
	player.set_process(false)
	var model: PlayerCharacterModel = player.get_node("VisualRoot/PlayerCharacterModel") as PlayerCharacterModel
	model.set_combat_mode(true)
	_camera = Camera3D.new()
	main.add_child(_camera)
	for entry: Array in SHOTS:
		var clip: String = entry[0]
		for t: float in entry[1]:
			model.anim_player.play(clip, 0.0)
			model.anim_player.seek(t, true)
			model.anim_player.pause()
			var p: Vector3 = player.global_position
			_camera.global_position = p + Vector3(2.0, 1.0, 0.0)
			_camera.look_at(p + Vector3(0.0, 0.9, 0.0), Vector3.UP)
			_camera.current = true
			for _i in range(3):
				await process_frame
			var image: Image = root.get_viewport().get_texture().get_image()
			image.save_png("%s%s_%03d.png" % [OUT_DIR, clip, int(t * 100.0)])
	print("[VIS] done")
	quit(0)
