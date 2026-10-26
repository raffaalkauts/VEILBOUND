extends Node3D

## Development-only preview for the protagonist's full-body secondary motion.
##
## Uses the real production character model (player_character_model.tscn), so
## every chain, collision primitive and animation comes from the shipping rig.
## Run with:
##   Godot ... --path E:\gamefurr res://tools/secondary_motion_preview.tscn
##
## Controls:
##   1..5   toggle hair / ears / tail / clothing / accessories
##   0      enable all groups
##   C      solo the next chain (real chain inventory, not mock data)
##   X      clear solo, all groups back on
##   A      cycle authored animation
##   R      reset springs onto the authored pose
##   P      apply a gameplay-style impulse
##   Mouse  drag to orbit, wheel to zoom

const MODEL_SCENE: PackedScene = preload("res://characters/player/visual/player_character_model.tscn")
const CLIPS: Array[String] = ["idle", "walk", "sprint", "jump", "dodge", "attack_1", "attack_2", "attack_3", "guard", "hit_react"]
const GROUP_KEYS: Array[StringName] = [&"hair", &"ears", &"tail", &"clothing", &"accessories"]

var _model: PlayerCharacterModel = null
var _turntable: Node3D = null
var _camera: Camera3D = null
var _label: Label = null
var _clip_index: int = 0
var _solo_index: int = -1
var _orbit_yaw: float = 0.0
var _orbit_pitch: float = 0.18
var _orbit_distance: float = 3.1
var _dragging: bool = false


func _ready() -> void:
	_build_stage()
	_model = MODEL_SCENE.instantiate() as PlayerCharacterModel
	_turntable.add_child(_model)
	_model.play_animation("idle", 0.0, true)
	_update_label()


func _build_stage() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.055, 0.06, 0.085)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.60, 0.75)
	env.ambient_light_energy = 0.85
	environment.environment = env
	add_child(environment)

	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-48.0), deg_to_rad(-38.0), 0.0)
	key.light_energy = 1.35
	key.shadow_enabled = true
	add_child(key)

	var fill := OmniLight3D.new()
	fill.position = Vector3(-1.8, 2.0, -1.4)
	fill.light_energy = 1.4
	fill.omni_range = 5.0
	fill.light_color = Color(0.45, 0.6, 0.9)
	add_child(fill)

	var rim := OmniLight3D.new()
	rim.position = Vector3(1.6, 1.7, -2.0)
	rim.light_energy = 1.1
	rim.omni_range = 4.0
	rim.light_color = Color(1.0, 0.72, 0.5)
	add_child(rim)

	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(8.0, 8.0)
	floor_mesh.mesh = plane
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.11, 0.12, 0.15)
	floor_material.roughness = 0.92
	floor_mesh.material_override = floor_material
	add_child(floor_mesh)

	_turntable = Node3D.new()
	_turntable.name = "Turntable"
	add_child(_turntable)

	_camera = Camera3D.new()
	_camera.current = true
	add_child(_camera)
	_update_camera()

	var layer := CanvasLayer.new()
	add_child(layer)
	_label = Label.new()
	_label.position = Vector2(18.0, 16.0)
	_label.add_theme_font_size_override("font_size", 15)
	_label.add_theme_color_override("font_color", Color(0.86, 0.92, 1.0))
	_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	_label.add_theme_constant_override("outline_size", 6)
	layer.add_child(_label)


func _physics_process(delta: float) -> void:
	if _model != null:
		# Keep gameplay transients flowing even while standing still; the
		# authored animation is changed by the A key.
		_model.update_secondary_motion(delta, 0.0, false, false, false)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var sm = _model.secondary_motion if _model != null else null
		if sm == null:
			return
		var key_index: int = int(event.keycode) - int(KEY_1)
		match event.keycode:
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
				var group: StringName = GROUP_KEYS[key_index]
				sm.set_group_enabled(group, not sm.is_group_enabled(group))
			KEY_0:
				_solo_index = -1
				sm.clear_solo()
			KEY_C:
				_solo_next_chain()
			KEY_X:
				_solo_index = -1
				sm.clear_solo()
			KEY_A:
				_clip_index = (_clip_index + 1) % CLIPS.size()
				_model.set_combat_mode(CLIPS[_clip_index].begins_with("attack") or CLIPS[_clip_index] == "guard")
				_model.play_animation(CLIPS[_clip_index], 0.12, true)
			KEY_R:
				_model.reset_pose()
				_model.play_animation(CLIPS[_clip_index], 0.0, true)
			KEY_P:
				sm.apply_impulse(Vector3(3.0, 0.4, 0.0))
			KEY_ESCAPE:
				get_tree().quit()
		_update_label()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_orbit_distance = maxf(1.4, _orbit_distance - 0.2)
			_update_camera()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_orbit_distance = minf(6.0, _orbit_distance + 0.2)
			_update_camera()
	elif event is InputEventMouseMotion and _dragging:
		_orbit_yaw -= event.relative.x * 0.01
		_orbit_pitch = clampf(_orbit_pitch + event.relative.y * 0.006, -0.6, 1.1)
		_update_camera()


func _solo_next_chain() -> void:
	var chains: Array = _model.secondary_motion.get_chains()
	if chains.is_empty():
		return
	_solo_index = (_solo_index + 1) % chains.size()
	_model.secondary_motion.solo_chain(String(chains[_solo_index]["id"]))


func _update_camera() -> void:
	if _camera == null:
		return
	var focus := Vector3(0.0, 1.02, 0.0)
	var offset := Vector3(
		sin(_orbit_yaw) * cos(_orbit_pitch),
		sin(_orbit_pitch),
		cos(_orbit_yaw) * cos(_orbit_pitch)
	) * _orbit_distance
	_camera.global_position = focus + offset
	_camera.look_at(focus, Vector3.UP)


func _update_label() -> void:
	if _label == null or _model == null or _model.secondary_motion == null:
		return
	var sm = _model.secondary_motion
	var enabled: Array[String] = []
	for group: StringName in GROUP_KEYS:
		if sm.is_group_enabled(group):
			enabled.append(String(group))
	var solo_text: String = "all chains"
	var chains: Array = sm.get_chains()
	if _solo_index >= 0 and _solo_index < chains.size():
		var chain: Dictionary = chains[_solo_index]
		solo_text = "solo %s (%s, %d bones)" % [chain["id"], chain["label"], chain.get("bone_names", []).size()]
	_label.text = (
		"VEILBOUND - Full-body secondary motion preview\n"
		+ "Chains: %d   Active groups: %s   View: %s\n" % [sm.chain_count(), ", ".join(PackedStringArray(enabled)), solo_text]
		+ "Clip: %s\n" % CLIPS[_clip_index]
		+ "[1-5] groups  [0] all  [C] next chain  [X] clear solo  [A] animation  [R] reset  [P] impulse\n"
		+ "Drag to orbit  |  Wheel to zoom  |  Esc to quit"
	)
