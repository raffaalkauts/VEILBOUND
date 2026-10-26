class_name PoiseComponent
extends Node

## Reusable Poise and Stagger Component for VEILBOUND
## Manages posture damage, recovery delay, regeneration, and stagger duration.
## Designed for enemies, bosses, and training dummies.

signal poise_changed(current_poise: float, max_poise: float)
signal stagger_started()
signal stagger_ended()

@export_group("Poise Configuration")
@export var max_poise: float = 100.0:
	set(value):
		var safe_max: float = maxf(value, 1.0)
		if value <= 0.0:
			push_warning("PoiseComponent: max_poise must be > 0. Clamped to 1.0.")
		max_poise = safe_max
		current_poise = clampf(current_poise, 0.0, max_poise)

@export var recovery_delay: float = 2.0 # Seconds after last posture hit before regen begins
@export var recovery_rate: float = 35.0 # Poise regenerated per second
@export var stagger_duration: float = 0.8 # Seconds entity remains staggered

var current_poise: float = 100.0
var _is_staggered: bool = false
var _stagger_timer: float = 0.0
var _recovery_timer: float = 0.0
var _is_dead: bool = false

# Parent reference
var _parent_node: Node = null


func _ready() -> void:
	if max_poise <= 0.0:
		max_poise = 100.0
	current_poise = max_poise
	_is_staggered = false
	_stagger_timer = 0.0
	_recovery_timer = 0.0
	_is_dead = false

	_resolve_references()


func _resolve_references() -> void:
	if _parent_node == null:
		_parent_node = get_parent()
	if _parent_node != null:
		var health: HealthComponent = _parent_node.get_node_or_null("HealthComponent") as HealthComponent
		if health != null and not health.died.is_connected(_on_parent_died):
			health.died.connect(_on_parent_died)


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	# Stagger timer countdown
	if _is_staggered:
		_stagger_timer = maxf(0.0, _stagger_timer - delta)
		if _stagger_timer <= 0.0:
			_end_stagger()
		return

	# Poise regeneration after recovery delay
	if current_poise < max_poise:
		if _recovery_timer > 0.0:
			_recovery_timer = maxf(0.0, _recovery_timer - delta)
		else:
			var prev_poise: float = current_poise
			current_poise = minf(max_poise, current_poise + recovery_rate * delta)
			if not is_equal_approx(prev_poise, current_poise):
				poise_changed.emit(current_poise, max_poise)


## Applies posture damage to the component.
## Clamps poise between 0 and max_poise. Triggers stagger if poise reaches zero.
## Returns true if posture damage was applied, false if rejected.
func apply_posture_damage(amount: float) -> bool:
	if _is_dead or amount <= 0.0 or is_nan(amount):
		return false

	# If already staggered, do not apply new posture damage or trigger duplicate stagger
	if _is_staggered:
		return false

	var prev_poise: float = current_poise
	current_poise = maxf(0.0, current_poise - amount)
	_recovery_timer = recovery_delay

	if not is_equal_approx(prev_poise, current_poise):
		poise_changed.emit(current_poise, max_poise)

	if current_poise <= 0.0 and not _is_staggered:
		_start_stagger()

	return true


func _start_stagger() -> void:
	_is_staggered = true
	_stagger_timer = stagger_duration
	_recovery_timer = 0.0
	stagger_started.emit()


func _end_stagger() -> void:
	_is_staggered = false
	_stagger_timer = 0.0
	_recovery_timer = 0.0
	# Stagger recovery rule: restore poise to max upon exiting stagger
	current_poise = max_poise
	poise_changed.emit(current_poise, max_poise)
	stagger_ended.emit()


## Resets poise to maximum and clears any active stagger.
func reset_poise() -> void:
	var was_staggered: bool = _is_staggered
	_is_staggered = false
	_stagger_timer = 0.0
	_recovery_timer = 0.0
	_is_dead = false
	current_poise = max_poise
	poise_changed.emit(current_poise, max_poise)
	if was_staggered:
		stagger_ended.emit()


## Returns whether the entity is currently staggered.
func is_staggered() -> bool:
	return _is_staggered and not _is_dead


func get_poise() -> float:
	return current_poise


func get_max_poise() -> float:
	return max_poise


## Clears all poise state (e.g. on entity death).
func clear_state() -> void:
	var was_staggered: bool = _is_staggered
	_is_dead = true
	_is_staggered = false
	_stagger_timer = 0.0
	_recovery_timer = 0.0
	if was_staggered:
		stagger_ended.emit()


func _on_parent_died() -> void:
	clear_state()
