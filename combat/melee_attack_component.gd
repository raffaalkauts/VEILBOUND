class_name MeleeAttackComponent
extends Node

## Dedicated Melee Attack Component for VEILBOUND
## Manages 3-hit light katana combo, input buffering, phase timings, stamina costs, and hit detection.

enum AttackPhase {
	NONE,
	STARTUP,
	ACTIVE,
	RECOVERY,
}

signal attack_started(combo_index: int)
signal attack_phase_changed(phase: AttackPhase, combo_index: int)
signal hit_confirmed(target: Node, damage: float, combo_index: int)
signal combo_finished()
signal attack_cancelled()

# Per-attack configuration
class AttackData:
	var damage: float
	var stamina_cost: float
	var startup: float
	var active: float
	var recovery: float
	var poise_damage: float

	func _init(p_dmg: float, p_stam: float, p_startup: float, p_active: float, p_recovery: float, p_poise_dmg: float = 0.0) -> void:
		damage = p_dmg
		stamina_cost = p_stam
		startup = p_startup
		active = p_active
		recovery = p_recovery
		poise_damage = p_poise_dmg

var attacks: Array[AttackData] = [
	AttackData.new(20.0, 12.0, 0.16, 0.12, 0.30, 12.0), # Attack 1: 12 poise damage
	AttackData.new(24.0, 12.0, 0.19, 0.12, 0.34, 18.0), # Attack 2: 18 poise damage
	AttackData.new(32.0, 15.0, 0.24, 0.14, 0.42, 28.0), # Attack 3: 28 poise damage
]

@export var buffer_expiration: float = 0.35
@export var hitbox_range: float = 2.0
@export var hitbox_width: float = 1.8
@export var hitbox_height: float = 1.6

var is_attacking: bool = false
var combo_index: int = 0 # 1, 2, or 3; 0 when idle
var current_phase: AttackPhase = AttackPhase.NONE
var phase_timer: float = 0.0
var attack_timer: float = 0.0

var _has_buffered_attack: bool = false
var _buffer_timer: float = 0.0
var _hit_targets: Array[Node] = []

# Node references
var _player: CharacterBody3D = null
var _stamina: StaminaComponent = null
var _hitbox_area: Area3D = null
var _hitbox_shape: CollisionShape3D = null
var _query_shape: BoxShape3D = null


func _ready() -> void:
	_resolve_references()
	_setup_hitbox()


func _resolve_references() -> void:
	if _player == null:
		_player = get_parent() as CharacterBody3D
	if _player != null:
		if _stamina == null:
			_stamina = _player.get_node_or_null("StaminaComponent") as StaminaComponent


func _setup_hitbox() -> void:
	_resolve_references()
	_query_shape = BoxShape3D.new()
	_query_shape.size = Vector3(hitbox_width, hitbox_height, hitbox_range)

	if _player == null:
		return

	var visual_root: Node3D = _player.get_node_or_null("VisualRoot") as Node3D
	if visual_root == null:
		return

	_hitbox_area = visual_root.get_node_or_null("MeleeHitbox") as Area3D
	if _hitbox_area == null:
		_hitbox_area = Area3D.new()
		_hitbox_area.name = "MeleeHitbox"
		_hitbox_area.collision_layer = 0
		_hitbox_area.collision_mask = 4 # Target layer (enemies/dummies)
		_hitbox_area.monitoring = false
		_hitbox_area.monitorable = false

		_hitbox_shape = CollisionShape3D.new()
		_hitbox_shape.name = "HitboxShape"
		_hitbox_shape.shape = _query_shape
		_hitbox_shape.position = Vector3(0.0, 0.9, -hitbox_range * 0.5)

		_hitbox_area.add_child(_hitbox_shape)
		visual_root.add_child(_hitbox_area)

	_hitbox_area.body_entered.connect(_on_hitbox_body_entered)


## Initiates a light attack or buffers the next combo step.
## Returns true if attack started or successfully buffered, false otherwise.
func try_attack() -> bool:
	_resolve_references()

	if not is_attacking:
		# Start Hit 1
		return _start_attack_step(1)
	else:
		# Currently attacking: check if input buffering is allowed
		return _try_buffer_next_attack()


func _try_buffer_next_attack() -> bool:
	# Reject buffering if already on the final combo hit
	if combo_index >= attacks.size():
		return false

	# Buffer window: only allowed during ACTIVE or RECOVERY (rejected during STARTUP)
	if current_phase == AttackPhase.STARTUP or current_phase == AttackPhase.NONE:
		return false

	_has_buffered_attack = true
	_buffer_timer = buffer_expiration

	# If already in recovery, we can immediately chain into the next step
	if current_phase == AttackPhase.RECOVERY:
		return _execute_buffered_attack()

	return true


func _start_attack_step(step: int) -> bool:
	_resolve_references()

	if step < 1 or step > attacks.size():
		return false

	var data: AttackData = attacks[step - 1]

	# Stamina check (atomic deduction)
	if _stamina != null:
		var can_afford: bool = _stamina.try_consume(data.stamina_cost)
		if not can_afford:
			return false

	is_attacking = true
	combo_index = step
	current_phase = AttackPhase.STARTUP
	phase_timer = 0.0
	attack_timer = 0.0
	_has_buffered_attack = false
	_buffer_timer = 0.0
	_hit_targets.clear()

	_set_hitbox_active(false)

	attack_started.emit(combo_index)
	attack_phase_changed.emit(current_phase, combo_index)
	return true


func _execute_buffered_attack() -> bool:
	_has_buffered_attack = false
	_buffer_timer = 0.0
	return _start_attack_step(combo_index + 1)


func _physics_process(delta: float) -> void:
	if not is_attacking:
		return

	# Buffer countdown
	if _has_buffered_attack:
		_buffer_timer -= delta
		if _buffer_timer <= 0.0:
			_has_buffered_attack = false

	attack_timer += delta
	var remaining_delta: float = delta

	while is_attacking and remaining_delta > 0.0:
		var data: AttackData = attacks[combo_index - 1]

		match current_phase:
			AttackPhase.STARTUP:
				var time_needed: float = data.startup - phase_timer
				if remaining_delta >= time_needed:
					remaining_delta -= time_needed
					current_phase = AttackPhase.ACTIVE
					phase_timer = 0.0
					_set_hitbox_active(true)
					attack_phase_changed.emit(current_phase, combo_index)
					_check_hits()
				else:
					phase_timer += remaining_delta
					remaining_delta = 0.0

			AttackPhase.ACTIVE:
				_check_hits()
				var time_needed: float = data.active - phase_timer
				if remaining_delta >= time_needed:
					remaining_delta -= time_needed
					current_phase = AttackPhase.RECOVERY
					phase_timer = 0.0
					_set_hitbox_active(false)
					attack_phase_changed.emit(current_phase, combo_index)

					if _has_buffered_attack and combo_index < attacks.size():
						_execute_buffered_attack()
				else:
					phase_timer += remaining_delta
					remaining_delta = 0.0

			AttackPhase.RECOVERY:
				var time_needed: float = data.recovery - phase_timer
				if remaining_delta >= time_needed:
					remaining_delta -= time_needed
					end_attack()
				else:
					phase_timer += remaining_delta
					remaining_delta = 0.0


func _check_hits() -> void:
	_resolve_references()
	if _player == null or not is_inside_tree():
		return

	# Use DirectSpaceState physics shape query for instantaneous, reliable hit detection
	var space_state := _player.get_world_3d().direct_space_state
	var visual_root: Node3D = _player.get_node_or_null("VisualRoot") as Node3D
	var yaw: float = visual_root.global_rotation.y if visual_root != null else _player.global_rotation.y
	var xform := Transform3D(Basis(Vector3.UP, yaw), _player.global_position)

	if _query_shape == null:
		_query_shape = BoxShape3D.new()
		_query_shape.size = Vector3(hitbox_width, hitbox_height, hitbox_range)

	var shape_query := PhysicsShapeQueryParameters3D.new()
	shape_query.shape = _query_shape
	shape_query.collision_mask = 4 # Target layer (dummies/enemies)
	# Center box in front of character facing
	var local_center := Vector3(0.0, 0.9, -hitbox_range * 0.5)
	shape_query.transform = xform.translated_local(local_center)
	shape_query.exclude = [_player.get_rid()]

	var results: Array[Dictionary] = space_state.intersect_shape(shape_query, 16)
	for res in results:
		var collider: Object = res.get("collider")
		if collider is Node:
			_process_target_hit(collider as Node)

	# Also check Area3D overlapping bodies if active
	if _hitbox_area != null and _hitbox_area.monitoring:
		var bodies: Array[Node3D] = _hitbox_area.get_overlapping_bodies()
		for body in bodies:
			_process_target_hit(body)


func _on_hitbox_body_entered(body: Node3D) -> void:
	if current_phase == AttackPhase.ACTIVE:
		_process_target_hit(body)


func _process_target_hit(target: Node) -> void:
	if target == null or target == _player:
		return

	if _hit_targets.has(target):
		return

	# Line of sight verification against world obstacles
	if not _has_line_of_sight_to(target):
		return

	var data: AttackData = attacks[combo_index - 1]
	var dmg: float = data.damage
	var poise_dmg: float = data.poise_damage

	# Apply damage to target (either via take_damage or HealthComponent)
	var damaged_target: bool = false
	if target.has_method("take_damage"):
		target.take_damage(dmg)
		damaged_target = true
	else:
		var target_health: HealthComponent = target.get_node_or_null("HealthComponent") as HealthComponent
		if target_health != null and not target_health.is_dead():
			target_health.take_damage(dmg)
			damaged_target = true

	# Apply posture damage if target supports it
	if target.has_method("apply_posture_damage"):
		target.apply_posture_damage(poise_dmg)
	else:
		var target_poise: Node = target.get_node_or_null("PoiseComponent")
		if target_poise != null and target_poise.has_method("apply_posture_damage"):
			target_poise.apply_posture_damage(poise_dmg)

	if damaged_target:
		_hit_targets.append(target)
		hit_confirmed.emit(target, dmg, combo_index)


func _has_line_of_sight_to(target: Node) -> bool:
	if not is_inside_tree() or _player == null:
		return true

	var space_state := _player.get_world_3d().direct_space_state
	var ray_origin: Vector3 = _player.global_position + Vector3(0.0, 1.0, 0.0)
	var target_pos: Vector3 = target.global_position + Vector3(0.0, 1.0, 0.0)
	if target.has_method("get_target_point"):
		target_pos = target.get_target_point()

	var query := PhysicsRayQueryParameters3D.create(
		ray_origin,
		target_pos,
		1, # World obstacles only (Layer 1)
		[_player.get_rid()]
	)

	var result := space_state.intersect_ray(query)
	# If ray hit nothing on Layer 1, line of sight is clear
	return result.is_empty()


func _set_hitbox_active(active: bool) -> void:
	if _hitbox_area != null:
		_hitbox_area.monitoring = active


## Terminates current attack and restores locomotion state.
func end_attack() -> void:
	if not is_attacking:
		return

	is_attacking = false
	combo_index = 0
	current_phase = AttackPhase.NONE
	phase_timer = 0.0
	attack_timer = 0.0
	_has_buffered_attack = false
	_set_hitbox_active(false)
	_hit_targets.clear()

	combo_finished.emit()


## Cancels attack immediately (e.g. hitstun, death).
func cancel_attack() -> void:
	if not is_attacking:
		return

	is_attacking = false
	combo_index = 0
	current_phase = AttackPhase.NONE
	phase_timer = 0.0
	attack_timer = 0.0
	_has_buffered_attack = false
	_set_hitbox_active(false)
	_hit_targets.clear()

	attack_cancelled.emit()


func get_current_damage() -> float:
	if combo_index >= 1 and combo_index <= attacks.size():
		return attacks[combo_index - 1].damage
	return 0.0


func get_current_stamina_cost() -> float:
	if combo_index >= 1 and combo_index <= attacks.size():
		return attacks[combo_index - 1].stamina_cost
	return 0.0


func get_current_poise_damage() -> float:
	if combo_index >= 1 and combo_index <= attacks.size():
		return attacks[combo_index - 1].poise_damage
	return 0.0


func has_buffered_attack() -> bool:
	return _has_buffered_attack
