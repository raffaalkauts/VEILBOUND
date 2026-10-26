class_name DodgeComponent
extends Node

## Dedicated Souls-like Dodge Component for Player
## Manages dodge initiation, directional translation, invulnerability window, and locomotion state.

signal dodge_started(direction: Vector3)
signal dodge_ended
signal iframe_started
signal iframe_ended

@export_group("Dodge Configuration")
@export var dodge_duration: float = 0.50
@export var stamina_cost: float = 25.0
@export var dodge_speed: float = 8.5
@export var iframe_startup: float = 0.04
@export var iframe_duration: float = 0.18
@export var fallback_to_backward: bool = true

var is_dodging: bool = false
var dodge_time: float = 0.0
var dodge_direction: Vector3 = Vector3.ZERO
var _iframe_active: bool = false

# Parent references
var _player: CharacterBody3D = null
var _health: HealthComponent = null
var _stamina: StaminaComponent = null


func _ready() -> void:
	_resolve_references()


func _resolve_references() -> void:
	if _player == null:
		_player = get_parent() as CharacterBody3D
	if _player != null:
		if _health == null:
			_health = _player.get_node_or_null("HealthComponent") as HealthComponent
		if _stamina == null:
			_stamina = _player.get_node_or_null("StaminaComponent") as StaminaComponent


## Attempts to start a dodge in the given direction.
## Consumes stamina atomically; returns true if dodge started, false otherwise.
func try_dodge(direction: Vector3) -> bool:
	_resolve_references()

	if is_dodging:
		return false

	if _stamina != null:
		var can_afford: bool = _stamina.try_consume(stamina_cost)
		if not can_afford:
			return false

	# Ensure normalized horizontal direction
	var clean_dir: Vector3 = Vector3(direction.x, 0.0, direction.z)
	if clean_dir.length_squared() > 0.001:
		clean_dir = clean_dir.normalized()
	else:
		clean_dir = get_fallback_direction()

	is_dodging = true
	dodge_time = 0.0
	dodge_direction = clean_dir
	_iframe_active = false

	# If startup is zero, start i-frame immediately
	if iframe_startup <= 0.0 and iframe_duration > 0.0:
		_set_iframe(true)

	dodge_started.emit(dodge_direction)
	return true


func _physics_process(delta: float) -> void:
	if not is_dodging:
		return

	dodge_time += delta

	# Process i-frame window
	var in_iframe_window: bool = (
		dodge_time >= iframe_startup
		and dodge_time < (iframe_startup + iframe_duration)
	)

	if in_iframe_window != _iframe_active:
		_set_iframe(in_iframe_window)

	# Check end of dodge
	if dodge_time >= dodge_duration:
		end_dodge()


func _set_iframe(active: bool) -> void:
	_iframe_active = active
	_resolve_references()
	if _health != null:
		_health.set_invulnerable(active)
	if active:
		iframe_started.emit()
	else:
		iframe_ended.emit()


## Ends the dodge action, restores normal state, and clears invulnerability.
func end_dodge() -> void:
	if not is_dodging:
		return

	is_dodging = false
	dodge_time = 0.0
	_set_iframe(false)
	dodge_ended.emit()


## Cancels the dodge immediately (e.g. death or interruption).
func cancel_dodge() -> void:
	end_dodge()


## Computes current dodge horizontal velocity for physics integration
func get_dodge_velocity_xz() -> Vector3:
	if not is_dodging:
		return Vector3.ZERO

	# Smooth deceleration profile over the dodge duration
	var progress: float = clampf(dodge_time / dodge_duration, 0.0, 1.0)
	var speed_multiplier: float = 1.0 - progress * 0.4
	return dodge_direction * (dodge_speed * speed_multiplier)


## Returns the default fallback direction when no input is provided
func get_fallback_direction() -> Vector3:
	_resolve_references()
	if _player != null:
		var vis: Node3D = _player.get_node_or_null("VisualRoot") as Node3D
		if vis != null:
			var facing: Vector3 = -vis.global_transform.basis.z
			facing.y = 0.0
			if facing.length_squared() > 0.001:
				facing = facing.normalized()
				return -facing if fallback_to_backward else facing

	return Vector3.BACK if fallback_to_backward else Vector3.FORWARD


func is_iframe_active() -> bool:
	return _iframe_active
