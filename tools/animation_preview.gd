extends Node3D

## Development-only preview for the real production character resources.
## Run with: godot --path . --editor res://tools/animation_preview.tscn
## Player keys: 1-9 select clips, Space pause, Left/Right scrub, Tab switch rig.

const PLAYER_SCENE: PackedScene = preload("res://characters/player/visual/player_character_model.tscn")
const SOLDIER_SCENE: PackedScene = preload("res://characters/enemies/soldier/anime-girl_running_panic.glb")
const SOLDIER_ANIMATIONS: AnimationLibrary = preload("res://characters/enemies/soldier/soldier_animations.tres")

var _player: Node3D
var _soldier: Node3D
var _active_rig: Node3D
var _player_anim: AnimationPlayer
var _soldier_anim: AnimationPlayer
var _label: Label
var _paused: bool = false
var _scrub_speed: float = 0.15

var _player_clips: Array[String] = ["idle", "walk", "sprint", "jump", "fall", "dodge", "attack_1", "attack_2", "attack_3"]
var _soldier_clips: Array[String] = ["Animation", "soldier/idle", "soldier/telegraph", "soldier/attack", "soldier/stagger", "soldier/death"]

func _ready() -> void:
	_create_stage()
	_player = PLAYER_SCENE.instantiate() as Node3D
	_player.position = Vector3(-1.35, 0.0, 0.0)
	add_child(_player)
	_player_anim = _player.find_child("AnimationPlayer", true, false) as AnimationPlayer

	_soldier = SOLDIER_SCENE.instantiate() as Node3D
	_soldier.position = Vector3(1.35, 0.0, 0.0)
	_soldier.rotation.y = PI
	add_child(_soldier)
	_soldier_anim = _soldier.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _soldier_anim != null and not _soldier_anim.has_animation_library("soldier"):
		_soldier_anim.add_animation_library("soldier", SOLDIER_ANIMATIONS)

	_active_rig = _player
	_play_current("idle")
	_create_overlay()
	_update_overlay()

func _create_stage() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("202631")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d9e7ee")
	environment.ambient_light_energy = 1.2
	world_environment.environment = environment
	add_child(world_environment)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45.0, -25.0, 0.0)
	light.light_energy = 1.6
	add_child(light)

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(8.0, 5.0)
	ground.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("38434c")
	ground.material_override = material
	ground.position.y = -0.02
	add_child(ground)

	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 1.7, 6.6)
	camera.look_at(Vector3(0.0, 1.0, 0.0))
	add_child(camera)

func _create_overlay() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	_label = Label.new()
	_label.position = Vector2(24.0, 20.0)
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", Color("e4ddce"))
	canvas.add_child(_label)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed():
		return
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.keycode == KEY_TAB:
			_active_rig = _soldier if _active_rig == _player else _player
			_play_current(_current_clip_name())
		elif key.keycode == KEY_SPACE:
			_paused = not _paused
			_set_active_speed(0.0 if _paused else 1.0)
		elif key.keycode == KEY_LEFT:
			_seek_active(-_scrub_speed)
		elif key.keycode == KEY_RIGHT:
			_seek_active(_scrub_speed)
		else:
			var index := key.keycode - KEY_1
			var clips := _player_clips if _active_rig == _player else _soldier_clips
			if index >= 0 and index < clips.size():
				_play_current(clips[index])
		_update_overlay()

func _play_current(clip_name: String) -> void:
	var anim := _active_animator()
	if anim == null or not anim.has_animation(clip_name):
		return
	anim.play(clip_name, 0.08)
	_set_active_speed(0.0 if _paused else 1.0)
	_update_overlay()

func _seek_active(amount: float) -> void:
	var anim := _active_animator()
	if anim == null or anim.current_animation.is_empty():
		return
	var clip := anim.get_animation(anim.current_animation)
	if clip == null:
		return
	anim.seek(clampf(anim.current_animation_position + amount, 0.0, clip.length), true)

func _set_active_speed(value: float) -> void:
	var anim := _active_animator()
	if anim != null:
		anim.speed_scale = value

func _active_animator() -> AnimationPlayer:
	return _player_anim if _active_rig == _player else _soldier_anim

func _current_clip_name() -> String:
	var anim := _active_animator()
	return anim.current_animation if anim != null else ""

func _update_overlay() -> void:
	if _label == null:
		return
	var anim := _active_animator()
	var rig_name := "PROTAGONIST" if _active_rig == _player else "SOLDIER"
	var clip_name: String = anim.current_animation if anim != null else "<none>"
	var position: float = anim.current_animation_position if anim != null else 0.0
	var length: float = anim.get_animation(clip_name).length if anim != null and not clip_name.is_empty() and anim.has_animation(clip_name) else 0.0
	_label.text = "%s  |  %s  %.2f / %.2f\nTab switch rig | 1-9 clips | Space pause | Left/Right scrub" % [rig_name, clip_name, position, length]
