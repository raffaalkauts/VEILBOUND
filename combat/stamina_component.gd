class_name StaminaComponent
extends Node

## Reusable Stamina Component with consumption, regeneration delay, and exhaustion tracking.

signal stamina_changed(current_stamina: float, max_stamina: float)
signal exhausted
signal recovered

@export var max_stamina: float = 100.0:
	set(value):
		var safe_max: float = maxf(value, 1.0)
		if value <= 0.0:
			push_warning("StaminaComponent: max_stamina must be greater than zero. Clamped to 1.0.")
		max_stamina = safe_max
		current_stamina = minf(current_stamina, max_stamina)

@export var regen_rate: float = 25.0
@export var regen_delay: float = 1.0

var current_stamina: float = 100.0
var _regen_timer: float = 0.0
var _is_exhausted: bool = false


func _ready() -> void:
	if max_stamina <= 0.0:
		max_stamina = 1.0
	current_stamina = max_stamina
	_regen_timer = 0.0
	_is_exhausted = false


func _physics_process(delta: float) -> void:
	if _regen_timer > 0.0:
		_regen_timer = maxf(0.0, _regen_timer - delta)
		return

	if current_stamina < max_stamina:
		var previous_stamina: float = current_stamina
		current_stamina = minf(max_stamina, current_stamina + regen_rate * delta)

		if current_stamina != previous_stamina:
			stamina_changed.emit(current_stamina, max_stamina)

		if _is_exhausted and current_stamina > 0.0:
			_is_exhausted = false
			recovered.emit()


## Tries to consume a fixed stamina cost (e.g. actions, dodges, attacks).
## Returns true if affordable; does NOT partially subtract on failure.
func try_consume(amount: float) -> bool:
	if amount <= 0.0 or is_nan(amount):
		return false

	if current_stamina < amount:
		return false

	current_stamina = maxf(0.0, current_stamina - amount)
	_regen_timer = regen_delay
	stamina_changed.emit(current_stamina, max_stamina)

	if current_stamina <= 0.0 and not _is_exhausted:
		_is_exhausted = true
		exhausted.emit()

	return true


## Consumes stamina continuously over time (e.g. sprinting).
## Returns true if stamina remains available; false if depleted.
func consume_continuous(rate: float, delta: float) -> bool:
	if rate <= 0.0 or delta <= 0.0:
		return current_stamina > 0.0

	if current_stamina <= 0.0:
		if not _is_exhausted:
			_is_exhausted = true
			exhausted.emit()
		return false

	var amount: float = rate * delta
	var actual_consume: float = minf(amount, current_stamina)
	current_stamina = maxf(0.0, current_stamina - actual_consume)
	_regen_timer = regen_delay

	if actual_consume > 0.0:
		stamina_changed.emit(current_stamina, max_stamina)

	if current_stamina <= 0.0 and not _is_exhausted:
		_is_exhausted = true
		exhausted.emit()

	return current_stamina > 0.0


## Manually restores stamina.
func restore(amount: float) -> void:
	if amount <= 0.0 or is_nan(amount):
		return

	if current_stamina >= max_stamina:
		return

	var previous: float = current_stamina
	current_stamina = minf(max_stamina, current_stamina + amount)

	if current_stamina != previous:
		stamina_changed.emit(current_stamina, max_stamina)

	if _is_exhausted and current_stamina > 0.0:
		_is_exhausted = false
		recovered.emit()


## Resets stamina to full and clears delay/exhaustion.
func reset_stamina() -> void:
	current_stamina = max_stamina
	_regen_timer = 0.0
	_is_exhausted = false
	stamina_changed.emit(current_stamina, max_stamina)


func is_exhausted() -> bool:
	return _is_exhausted or current_stamina <= 0.0


func get_stamina() -> float:
	return current_stamina


func get_max_stamina() -> float:
	return max_stamina


func get_stamina_ratio() -> float:
	return current_stamina / max_stamina if max_stamina > 0.0 else 0.0


func get_regen_timer() -> float:
	return _regen_timer
