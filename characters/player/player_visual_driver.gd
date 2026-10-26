class_name PlayerVisualDriver
extends Node3D

## Visual driver for VEILBOUND Protagonist
## Coordinates state-driven AnimationPlayer playback on the stylized 3D character model
## alongside procedural secondary dynamics, breathing, and combat impact reactions.

@onready var character_model: PlayerCharacterModel = get_node_or_null("PlayerCharacterModel")

# Baseline transforms (restored cleanly on state changes)
var _base_position: Vector3 = Vector3.ZERO
var _base_scale: Vector3 = Vector3.ONE
var _base_rotation_x: float = 0.0
var _base_rotation_z: float = 0.0

# Dynamic visual offsets
var _current_offset: Vector3 = Vector3.ZERO
var _current_scale_offset: Vector3 = Vector3.ZERO
var _current_tilt_x: float = 0.0
var _current_tilt_z: float = 0.0
var _anim_time: float = 0.0
var _last_state: int = -1
var _last_combo_index: int = -1
var _last_requested_animation: String = ""
var _priority_animation: String = ""
var _priority_time_remaining: float = 0.0


func _ready() -> void:
	_base_position = position
	_base_scale = scale
	_base_rotation_x = rotation.x
	_base_rotation_z = rotation.z
	if character_model == null:
		character_model = get_node_or_null("PlayerCharacterModel")


func update_procedural_visuals(state: int, horizontal_speed: float, delta: float, combo_index: int = 1) -> void:
	if character_model == null:
		character_model = get_node_or_null("PlayerCharacterModel")
	_advance_priority_animation(delta)

	# 1. Drive AnimationPlayer clips and secondary model dynamics if model is present
	if character_model != null:
		var is_in_air: bool = (state == PlayerController.LocomotionState.JUMP or state == PlayerController.LocomotionState.FALL)
		var is_guarding: bool = (state == PlayerController.LocomotionState.GUARD)
		var is_attacking: bool = (state == PlayerController.LocomotionState.ATTACK)
		if _priority_animation.is_empty():
			var in_combat: bool = is_attacking or is_guarding
			character_model.set_combat_mode(in_combat)
			_request_state_animation(state, combo_index)

		character_model.update_secondary_motion(delta, horizontal_speed, is_in_air, is_guarding, is_attacking)

	# 2. Drive procedural root tilts and subtle secondary bobbing
	var target_offset: Vector3 = Vector3.ZERO
	var target_scale_offset: Vector3 = Vector3.ZERO
	var target_tilt_x: float = 0.0
	var target_tilt_z: float = 0.0
	var blend_speed: float = 10.0

	match state:
		PlayerController.LocomotionState.IDLE:
			# The imported idle clip owns the stance; avoid moving the collision root.
			blend_speed = 8.0

		PlayerController.LocomotionState.MOVE:
			# Locomotion is in-place skeletal animation; procedural bob caused foot slide.
			blend_speed = 12.0

		PlayerController.LocomotionState.SPRINT:
			blend_speed = 14.0

		PlayerController.LocomotionState.JUMP:
			blend_speed = 14.0

		PlayerController.LocomotionState.FALL:
			blend_speed = 14.0

		PlayerController.LocomotionState.DODGE:
			# Dodge clip provides the full body roll; do not fake it on the root.
			blend_speed = 18.0

		PlayerController.LocomotionState.ATTACK:
			# Attack clips carry the authored silhouette and weapon path.
			blend_speed = 24.0

		PlayerController.LocomotionState.GUARD:
			blend_speed = 16.0

	# Smooth delta-based interpolation to prevent snapping
	_current_offset = _current_offset.lerp(target_offset, blend_speed * delta)
	_current_scale_offset = _current_scale_offset.lerp(target_scale_offset, blend_speed * delta)
	_current_tilt_x = lerpf(_current_tilt_x, target_tilt_x, blend_speed * delta)
	_current_tilt_z = lerpf(_current_tilt_z, target_tilt_z, blend_speed * delta)

	# Apply relative to base transforms without altering facing rotation (rotation.y)
	position = _base_position + _current_offset
	scale = _base_scale + _current_scale_offset
	rotation.x = _base_rotation_x + _current_tilt_x
	rotation.z = _base_rotation_z + _current_tilt_z


func get_base_position() -> Vector3:
	return _base_position


func get_base_scale() -> Vector3:
	return _base_scale


func reset_to_base() -> void:
	_current_offset = Vector3.ZERO
	_current_scale_offset = Vector3.ZERO
	_current_tilt_x = 0.0
	_current_tilt_z = 0.0
	position = _base_position
	scale = _base_scale
	rotation.x = _base_rotation_x
	rotation.z = _base_rotation_z
	if character_model != null:
		character_model.reset_pose()


func trigger_block_impact() -> void:
	# Transient pushback and backward tilt on successful block
	_current_offset.z += 0.08
	_current_tilt_x += deg_to_rad(-6.0)


func trigger_guard_break_visual() -> void:
	# Dramatic transient recoil and stagger tilt on guard break
	_current_offset.z += 0.22
	_current_tilt_x += deg_to_rad(-16.0)
	_current_tilt_z += deg_to_rad(8.0)


func trigger_hit_reaction() -> void:
	_current_offset.z += 0.06
	_current_tilt_x += deg_to_rad(-5.0)
	_begin_priority_animation("hit_react", 0.34)


func play_skill_animation(animation_name: String, duration: float) -> void:
	if character_model == null:
		character_model = get_node_or_null("PlayerCharacterModel")
	if character_model == null or character_model.is_dead():
		return
	# Skills are action states too: draw the hand-mounted katana before the
	# priority clip starts, otherwise the skill animation plays with the scabbard.
	character_model.set_combat_mode(true)
	var clip_duration: float = character_model.get_animation_length(animation_name, duration)
	_begin_priority_animation(animation_name, maxf(duration, clip_duration))


func trigger_stagger_visual() -> void:
	# The imported hero asset has no dedicated stagger clip; hit_react is the
	# closest authored reaction and remains protected from locomotion updates.
	_current_offset.z += 0.10
	_current_tilt_x += deg_to_rad(-8.0)
	_begin_priority_animation("hit_react", 0.40)


func trigger_death_visual() -> void:
	_priority_animation = "death"
	_priority_time_remaining = -1.0
	_last_requested_animation = ""
	if character_model != null:
		character_model.set_dead(true)


func has_character_model() -> bool:
	if character_model == null:
		character_model = get_node_or_null("PlayerCharacterModel")
	return character_model != null


func get_character_model() -> PlayerCharacterModel:
	if character_model == null:
		character_model = get_node_or_null("PlayerCharacterModel")
	return character_model


func _request_state_animation(state: int, combo_index: int) -> void:
	if character_model == null:
		return
	if state == _last_state and combo_index == _last_combo_index and not _last_requested_animation.is_empty():
		return

	_last_state = state
	_last_combo_index = combo_index
	var animation_name: String = "idle"
	var blend_time: float = 0.12
	match state:
		PlayerController.LocomotionState.IDLE:
			animation_name = "idle"
			blend_time = 0.20
		PlayerController.LocomotionState.MOVE:
			animation_name = "walk"
		PlayerController.LocomotionState.SPRINT:
			animation_name = "sprint"
		PlayerController.LocomotionState.JUMP:
			animation_name = "jump"
		PlayerController.LocomotionState.FALL:
			animation_name = "fall"
		PlayerController.LocomotionState.DODGE:
			animation_name = "dodge"
			blend_time = 0.06
		PlayerController.LocomotionState.ATTACK:
			animation_name = "attack_%d" % maxi(combo_index, 1)
			blend_time = 0.04
		PlayerController.LocomotionState.GUARD:
			animation_name = "guard"
			blend_time = 0.10

	if character_model.play_animation(animation_name, blend_time):
		_last_requested_animation = animation_name


func _begin_priority_animation(animation_name: String, duration: float) -> void:
	if character_model == null or character_model.is_dead():
		return
	_priority_animation = animation_name
	_priority_time_remaining = duration
	_last_requested_animation = ""
	character_model.play_animation(animation_name, 0.04, true)


func _advance_priority_animation(delta: float) -> void:
	if _priority_animation.is_empty() or _priority_time_remaining < 0.0:
		return
	_priority_time_remaining = maxf(0.0, _priority_time_remaining - delta)
	if _priority_time_remaining <= 0.0:
		_priority_animation = ""
		_last_requested_animation = ""
		_last_state = -1
