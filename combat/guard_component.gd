class_name GuardComponent
extends Node

## Dedicated Directional Guard/Block Component for VEILBOUND
## Manages guard stance, directional damage mitigation, stamina consumption per block, and guard break.

signal guard_started()
signal guard_stopped()
signal guard_broken()
signal attack_blocked(mitigated: float, damage_taken: float, stamina_cost: float)

@export_group("Guard Configuration")
@export var damage_reduction: float = 0.70 # 70% mitigation
@export var guard_angle_degrees: float = 120.0 # 120 degrees arc centered on facing
@export var guard_speed_multiplier: float = 0.55 # Movement speed multiplier while guarding
@export var stamina_cost_per_damage_mitigated: float = 1.5 # 1.5 stamina per point of damage prevented
@export var guard_break_duration: float = 0.8 # 0.8s recovery period where guard is locked out

var is_guarding: bool = false
var is_guard_broken: bool = false
var guard_break_timer: float = 0.0

# Node references
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


## Begins guarding if not broken and not restricted.
## Returns true if guard started successfully, false otherwise.
func start_guard() -> bool:
	_resolve_references()

	if is_guard_broken or guard_break_timer > 0.0:
		return false

	if is_guarding:
		return true

	if _health != null and _health.is_dead():
		return false

	# Cannot start guard if player is currently performing actions
	if _player != null:
		var dodge_comp: Node = _player.get_node_or_null("DodgeComponent")
		if dodge_comp != null and dodge_comp.get("is_dodging") == true:
			return false

		var attack_comp: Node = _player.get_node_or_null("MeleeAttackComponent")
		if attack_comp != null and attack_comp.get("is_attacking") == true:
			return false

	is_guarding = true
	guard_started.emit()
	return true


## Stops guarding and restores normal stance.
func stop_guard() -> void:
	if not is_guarding:
		return

	is_guarding = false
	guard_stopped.emit()


## Resolves directional mitigation for incoming damage.
## Returns dictionary with damage_to_apply, mitigated, blocked, and guard_broken flags.
func resolve_incoming_attack(damage: float, attacker_position: Vector3) -> Dictionary:
	_resolve_references()

	var result := {
		"damage_to_apply": damage,
		"mitigated": 0.0,
		"blocked": false,
		"guard_broken": false,
	}

	if not is_guarding:
		return result

	# Check directional guard arc relative to player facing direction
	if not is_attacker_in_guard_arc(attacker_position):
		# Flank or rear attack: full damage, no block, no stamina cost
		return result

	# Attack is within guard arc: calculate mitigation and stamina cost
	var mitigated_amount: float = damage * damage_reduction
	var net_damage: float = damage - mitigated_amount
	var stamina_cost: float = mitigated_amount * stamina_cost_per_damage_mitigated

	# Check stamina availability
	var paid: bool = false
	if _stamina != null:
		paid = _stamina.try_consume(stamina_cost)
	else:
		paid = true

	if paid:
		# Block SUCCESSFUL
		result["damage_to_apply"] = net_damage
		result["mitigated"] = mitigated_amount
		result["blocked"] = true
		result["guard_broken"] = false
		attack_blocked.emit(mitigated_amount, net_damage, stamina_cost)

		# Visual feedback trigger
		if _player != null:
			var vis: Node3D = _player.get_node_or_null("VisualRoot") as Node3D
			if vis != null and vis.has_method("trigger_block_impact"):
				vis.trigger_block_impact()
	else:
		# Stamina payment FAILED -> GUARD BREAK
		trigger_guard_break()
		# Original unmitigated attack damage applies
		result["damage_to_apply"] = damage
		result["mitigated"] = 0.0
		result["blocked"] = false
		result["guard_broken"] = true

	return result


## Checks if the given world position falls within the player's frontal guard arc.
func is_attacker_in_guard_arc(attacker_position: Vector3) -> bool:
	_resolve_references()
	if _player == null:
		return true

	var visual_root: Node3D = _player.get_node_or_null("VisualRoot") as Node3D
	var facing: Vector3
	if visual_root != null:
		facing = -visual_root.global_transform.basis.z
	else:
		facing = -_player.global_transform.basis.z

	facing.y = 0.0
	if facing.length_squared() < 0.001:
		facing = Vector3.FORWARD
	else:
		facing = facing.normalized()

	var to_attacker: Vector3 = attacker_position - _player.global_position
	to_attacker.y = 0.0

	# If position is at player or unspecified, default to frontal
	if to_attacker.length_squared() < 0.001:
		return true

	to_attacker = to_attacker.normalized()

	var angle_rad: float = facing.angle_to(to_attacker)
	var max_half_angle: float = deg_to_rad(guard_angle_degrees * 0.5)

	return angle_rad <= max_half_angle


## Triggers guard break, ends guard, and locks out re-guarding for recovery period.
func trigger_guard_break() -> void:
	is_guarding = false
	is_guard_broken = true
	guard_break_timer = guard_break_duration
	guard_broken.emit()
	guard_stopped.emit()

	if _player != null:
		var vis: Node3D = _player.get_node_or_null("VisualRoot") as Node3D
		if vis != null and vis.has_method("trigger_guard_break_visual"):
			vis.trigger_guard_break_visual()


func _physics_process(delta: float) -> void:
	if is_guard_broken:
		guard_break_timer = maxf(0.0, guard_break_timer - delta)
		if guard_break_timer <= 0.0:
			is_guard_broken = false


## Clears all guard states safely (e.g. on player death, reset, or interruption).
func clear_guard_state() -> void:
	is_guarding = false
	is_guard_broken = false
	guard_break_timer = 0.0
