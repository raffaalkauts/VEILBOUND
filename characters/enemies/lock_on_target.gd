class_name LockOnTarget
extends Node3D

## Reusable lock-on target representation for enemies and dummies.
## Registers with "lock_on_targets" group, provides target location, and handles health/poise/damage feedback.

signal target_invalidated(target: LockOnTarget)
signal hit_reacted()

## Relative offset for chest/lock-on point from global_position
@export var target_offset: Vector3 = Vector3(0.0, 1.2, 0.0)

## Whether this target is currently active and can be locked onto
@export var is_targetable: bool = true:
	set(value):
		if is_targetable != value:
			is_targetable = value
			if not is_targetable:
				target_invalidated.emit(self)

@onready var health: HealthComponent = get_node_or_null("HealthComponent")
@onready var poise: PoiseComponent = get_node_or_null("PoiseComponent")
@onready var visual_mesh: MeshInstance3D = get_node_or_null("VisualMesh")
@onready var head_visual: MeshInstance3D = get_node_or_null("HeadVisual")

var _original_material: StandardMaterial3D = null
var _flash_material: StandardMaterial3D = null
var _stagger_material: StandardMaterial3D = null
var _flash_timer: float = 0.0

# Base transforms for child visual nodes to avoid transform drift
var _base_visual_mesh_pos: Vector3 = Vector3.ZERO
var _base_visual_mesh_rot: Vector3 = Vector3.ZERO
var _base_head_pos: Vector3 = Vector3.ZERO
var _base_head_rot: Vector3 = Vector3.ZERO
var _recoil_tilt_x: float = 0.0


func _ready() -> void:
	add_to_group("lock_on_targets")
	_setup_health()
	_setup_poise()
	_setup_visuals()


func _setup_health() -> void:
	if health == null:
		health = get_node_or_null("HealthComponent")
	if health == null and get_parent() != null:
		health = get_parent().get_node_or_null("HealthComponent") as HealthComponent
	if health != null:
		if not health.damaged.is_connected(_on_damaged):
			health.damaged.connect(_on_damaged)
		if not health.died.is_connected(_on_died):
			health.died.connect(_on_died)


func _setup_poise() -> void:
	if poise == null:
		poise = get_node_or_null("PoiseComponent")
	if poise == null and get_parent() != null:
		poise = get_parent().get_node_or_null("PoiseComponent") as PoiseComponent
	if poise != null:
		if not poise.stagger_started.is_connected(_on_stagger_started):
			poise.stagger_started.connect(_on_stagger_started)
		if not poise.stagger_ended.is_connected(_on_stagger_ended):
			poise.stagger_ended.connect(_on_stagger_ended)


func _setup_visuals() -> void:
	if visual_mesh == null:
		visual_mesh = get_node_or_null("VisualMesh") as MeshInstance3D
		if visual_mesh == null:
			visual_mesh = get_node_or_null("VisualRoot/VisualMesh") as MeshInstance3D
	if head_visual == null:
		head_visual = get_node_or_null("HeadVisual") as MeshInstance3D
		if head_visual == null:
			head_visual = get_node_or_null("VisualRoot/HeadVisual") as MeshInstance3D

	if visual_mesh != null:
		_base_visual_mesh_pos = visual_mesh.position
		_base_visual_mesh_rot = visual_mesh.rotation

		if visual_mesh.get_active_material(0) != null:
			_original_material = visual_mesh.get_active_material(0).duplicate() as StandardMaterial3D
			visual_mesh.material_override = _original_material

			_flash_material = _original_material.duplicate() as StandardMaterial3D
			_flash_material.albedo_color = Color(1.0, 0.9, 0.9, 1.0)
			_flash_material.emission_enabled = true
			_flash_material.emission = Color(0.9, 0.8, 0.2, 1.0)
			_flash_material.emission_energy_multiplier = 1.5

			_stagger_material = _original_material.duplicate() as StandardMaterial3D
			_stagger_material.albedo_color = Color(1.0, 0.7, 0.4, 1.0)
			_stagger_material.emission_enabled = true
			_stagger_material.emission = Color(1.0, 0.4, 0.1, 1.0)
			_stagger_material.emission_energy_multiplier = 2.5

	if head_visual != null:
		_base_head_pos = head_visual.position
		_base_head_rot = head_visual.rotation


func _process(delta: float) -> void:
	# Material flash countdown
	if _flash_timer > 0.0:
		_flash_timer = maxf(0.0, _flash_timer - delta)
		if _flash_timer <= 0.0:
			_restore_material()

	# Recoil animation smoothly blends back to 0.0 without transform accumulation
	var target_recoil: float = 0.0
	var blend_rate: float = 8.0

	if is_staggered():
		# Maintain distinct slump during active stagger
		target_recoil = deg_to_rad(-16.0)
		blend_rate = 14.0
	else:
		target_recoil = 0.0
		blend_rate = 8.0

	_recoil_tilt_x = move_toward(_recoil_tilt_x, target_recoil, blend_rate * delta)

	# Apply relative to stored baselines
	if visual_mesh != null:
		visual_mesh.position = _base_visual_mesh_pos
		visual_mesh.rotation = _base_visual_mesh_rot
		visual_mesh.rotation.x = _base_visual_mesh_rot.x + _recoil_tilt_x

	if head_visual != null:
		head_visual.position = _base_head_pos
		head_visual.rotation = _base_head_rot
		head_visual.rotation.x = _base_head_rot.x + (_recoil_tilt_x * 1.3)


func _restore_material() -> void:
	if visual_mesh == null:
		return
	if health != null and health.is_dead():
		_apply_dead_visuals()
	elif is_staggered() and _stagger_material != null:
		visual_mesh.material_override = _stagger_material
	elif _original_material != null:
		visual_mesh.material_override = _original_material


func _on_damaged(_amount: float, _current_health: float) -> void:
	# Brief visual flash and subtle recoil on impact
	if visual_mesh != null and _flash_material != null:
		visual_mesh.material_override = _flash_material
		_flash_timer = 0.08

	# Add subtle recoil impulse
	_recoil_tilt_x = deg_to_rad(-6.0)
	hit_reacted.emit()


func _on_stagger_started() -> void:
	# Distinct visual feedback for stagger
	if visual_mesh != null and _stagger_material != null:
		visual_mesh.material_override = _stagger_material
		_flash_timer = 0.18
	_recoil_tilt_x = deg_to_rad(-18.0)


func _on_stagger_ended() -> void:
	_restore_material()


func _on_died() -> void:
	is_targetable = false
	if poise != null:
		poise.clear_state()
	_recoil_tilt_x = 0.0
	_restore_base_transforms()
	_apply_dead_visuals()


func _restore_base_transforms() -> void:
	if visual_mesh != null:
		visual_mesh.position = _base_visual_mesh_pos
		visual_mesh.rotation = _base_visual_mesh_rot
	if head_visual != null:
		head_visual.position = _base_head_pos
		head_visual.rotation = _base_head_rot


func _apply_dead_visuals() -> void:
	if visual_mesh != null:
		var dead_mat: StandardMaterial3D = StandardMaterial3D.new()
		dead_mat.albedo_color = Color(0.28, 0.28, 0.32, 1.0)
		dead_mat.roughness = 0.8
		visual_mesh.material_override = dead_mat


func _exit_tree() -> void:
	target_invalidated.emit(self)
	remove_from_group("lock_on_targets")


## Applies damage through the attached HealthComponent
func take_damage(amount: float) -> void:
	if health != null and not health.is_dead():
		health.take_damage(amount)


## Applies posture damage through the attached PoiseComponent
func apply_posture_damage(amount: float) -> void:
	if poise != null and is_available():
		poise.apply_posture_damage(amount)


## Returns whether the target is currently in a staggered state
func is_staggered() -> bool:
	return poise != null and poise.is_staggered()


## Returns world-space target point for camera tracking and line-of-sight checks
func get_target_point() -> Vector3:
	return global_position + target_offset


## Returns whether this target is currently valid to lock onto and be attacked
func is_available() -> bool:
	var alive: bool = health == null or health.is_alive()
	return is_inside_tree() and is_targetable and alive
