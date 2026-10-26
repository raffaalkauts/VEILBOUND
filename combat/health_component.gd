class_name HealthComponent
extends Node

## Reusable Health Component for player and enemy entities.
## Zero maximum health is NOT permitted; max_health is clamped to minimum 1.0.

signal health_changed(current_health: float, max_health: float)
signal damaged(amount: float, current_health: float)
signal healed(amount: float, current_health: float)
signal died

@export var max_health: float = 100.0:
	set(value):
		var safe_max: float = maxf(value, 1.0)
		if value <= 0.0:
			push_warning("HealthComponent: max_health must be greater than zero. Clamped to 1.0.")
		max_health = safe_max
		current_health = minf(current_health, max_health)

var current_health: float = 100.0
var _is_dead: bool = false
var is_invulnerable: bool = false


func _ready() -> void:
	if max_health <= 0.0:
		max_health = 1.0
	current_health = max_health
	_is_dead = false
	is_invulnerable = false


## Sets whether this entity is currently immune to incoming damage (e.g. dodge i-frames).
func set_invulnerable(enabled: bool) -> void:
	# Dead entities cannot be made invulnerable
	if _is_dead:
		is_invulnerable = false
		return
	is_invulnerable = enabled


## Inflicts damage, reducing health and emitting damaged/died signals.
## Rejects negative or zero amounts. Ignores damage if dead or invulnerable.
func take_damage(amount: float) -> void:
	if _is_dead or is_invulnerable or amount <= 0.0 or is_nan(amount):
		return

	var previous_health: float = current_health
	current_health = maxf(0.0, current_health - amount)
	var actual_damage: float = previous_health - current_health

	if actual_damage > 0.0:
		damaged.emit(actual_damage, current_health)
		health_changed.emit(current_health, max_health)

	if current_health <= 0.0 and not _is_dead:
		_is_dead = true
		is_invulnerable = false
		died.emit()


## Restores health up to max_health.
## Rejects negative or zero amounts. Ignores healing if dead.
func heal(amount: float) -> void:
	if _is_dead or amount <= 0.0 or is_nan(amount):
		return

	if current_health >= max_health:
		return

	var previous_health: float = current_health
	current_health = minf(max_health, current_health + amount)
	var actual_heal: float = current_health - previous_health

	if actual_heal > 0.0:
		healed.emit(actual_heal, current_health)
		health_changed.emit(current_health, max_health)


## Resets health back to max_health and clears the dead state.
func reset_health() -> void:
	current_health = max_health
	_is_dead = false
	is_invulnerable = false
	health_changed.emit(current_health, max_health)


func is_alive() -> bool:
	return not _is_dead and current_health > 0.0


func is_dead() -> bool:
	return _is_dead


func get_health() -> float:
	return current_health


func get_max_health() -> float:
	return max_health


func get_health_ratio() -> float:
	return current_health / max_health if max_health > 0.0 else 0.0
