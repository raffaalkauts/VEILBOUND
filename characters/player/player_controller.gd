class_name PlayerController
extends CharacterBody3D

## Locomotion state enumeration
enum LocomotionState {
	IDLE,
	MOVE,
	SPRINT,
	JUMP,
	FALL,
	DODGE,
	ATTACK,
	GUARD,
}

## Signals
signal state_changed(previous_state: LocomotionState, new_state: LocomotionState)

## Current locomotion state
@export_group("State")
@export var current_state: LocomotionState = LocomotionState.IDLE

## Movement parameters
@export_group("Movement")
@export var walk_speed: float = 4.0
@export var sprint_speed: float = 6.5
@export var ground_acceleration: float = 20.0
@export var ground_deceleration: float = 24.0
@export var air_acceleration: float = 6.0
@export var jump_velocity: float = 5.0
@export var rotation_speed: float = 12.0

## Camera parameters
@export_group("Camera")
@export var mouse_sensitivity: float = 0.002
@export var min_pitch: float = deg_to_rad(-80.0)
@export var max_pitch: float = deg_to_rad(60.0)
@export var camera_zoom_min: float = 2.0
@export var camera_zoom_max: float = 5.0
@export var camera_zoom_step: float = 0.35

## Combat parameters & components
@export_group("Combat")
@export var sprint_stamina_cost: float = 18.0

## Node references
@onready var visual_root: Node3D = get_node_or_null("VisualRoot")
@onready var camera_pivot: Node3D = get_node_or_null("CameraPivot")
@onready var spring_arm: SpringArm3D = get_node_or_null("CameraPivot/SpringArm3D")
@onready var camera: Camera3D = get_node_or_null("CameraPivot/SpringArm3D/Camera3D")
@onready var lock_on: LockOnComponent = get_node_or_null("LockOnComponent")
@onready var health: HealthComponent = get_node_or_null("HealthComponent")
@onready var stamina: StaminaComponent = get_node_or_null("StaminaComponent")
@onready var dodge: DodgeComponent = get_node_or_null("DodgeComponent")
@onready var melee_attack: MeleeAttackComponent = get_node_or_null("MeleeAttackComponent")
@onready var guard: GuardComponent = get_node_or_null("GuardComponent")
@onready var skills: Node = get_node_or_null("PlayerSkillComponent")
@onready var camera_impulse: CameraImpulseComponent = get_node_or_null("CameraImpulseComponent")
@onready var audio_manager: AudioFeedbackManager = get_node_or_null("AudioFeedbackManager")
@onready var feedback_coordinator: CombatFeedbackCoordinator = get_node_or_null("CombatFeedbackCoordinator")

var _camera_pitch: float = 0.0


func _ready() -> void:
	_resolve_nodes()
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if health != null:
		if not health.died.is_connected(_on_died):
			health.died.connect(_on_died)
		if not health.damaged.is_connected(_on_damaged):
			health.damaged.connect(_on_damaged)
	if feedback_coordinator != null:
		feedback_coordinator.bind_player(self)


func _on_died() -> void:
	if guard != null:
		guard.clear_guard_state()
	if visual_root != null and visual_root.has_method("trigger_death_visual"):
		visual_root.trigger_death_visual()


func _on_damaged(_amount: float, _current: float) -> void:
	if visual_root != null and visual_root.has_method("trigger_hit_reaction"):
		visual_root.trigger_hit_reaction()


func _resolve_nodes() -> void:
	if visual_root == null:
		visual_root = get_node_or_null("VisualRoot")
	if camera_pivot == null:
		camera_pivot = get_node_or_null("CameraPivot")
	if spring_arm == null:
		spring_arm = get_node_or_null("CameraPivot/SpringArm3D")
	if camera == null:
		camera = get_node_or_null("CameraPivot/SpringArm3D/Camera3D")
	if lock_on == null:
		lock_on = get_node_or_null("LockOnComponent")
	if health == null:
		health = get_node_or_null("HealthComponent")
	if stamina == null:
		stamina = get_node_or_null("StaminaComponent")
	if dodge == null:
		dodge = get_node_or_null("DodgeComponent")
	if melee_attack == null:
		melee_attack = get_node_or_null("MeleeAttackComponent")
	if guard == null:
		guard = get_node_or_null("GuardComponent")
	if skills == null:
		skills = get_node_or_null("PlayerSkillComponent")
	if camera_impulse == null:
		camera_impulse = get_node_or_null("CameraImpulseComponent")
	if audio_manager == null:
		audio_manager = get_node_or_null("AudioFeedbackManager")
	if feedback_coordinator == null:
		feedback_coordinator = get_node_or_null("CombatFeedbackCoordinator")
		if feedback_coordinator != null:
			feedback_coordinator.bind_player(self)


func _unhandled_input(event: InputEvent) -> void:
	_resolve_nodes()
	var is_locked: bool = lock_on != null and lock_on.is_locked_on

	# Mouse escape & recapture handling
	if event is InputEventKey and event.is_pressed() and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return

	# Handle wheel zoom before mouse recapture so the first scroll works after Escape.
	if not is_locked and event.is_action_pressed("camera_zoom_in"):
		_change_camera_zoom(-camera_zoom_step)
		get_viewport().set_input_as_handled()
		return
	if not is_locked and event.is_action_pressed("camera_zoom_out"):
		_change_camera_zoom(camera_zoom_step)
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton and event.is_pressed():
		# Do not guard or attack if mouse was uncaptured; click recaptures mouse
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED and DisplayServer.get_name() != "headless":
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			get_viewport().set_input_as_handled()
			return

	# Debug incoming damage actions
	if event.is_action_pressed("debug_damage"):
		var facing_dir: Vector3 = _get_facing_direction()
		var frontal_pos: Vector3 = global_position + facing_dir * 2.0
		apply_incoming_damage(15.0, frontal_pos)

	if event.is_action_pressed("debug_rear_damage"):
		var facing_dir: Vector3 = _get_facing_direction()
		var rear_pos: Vector3 = global_position - facing_dir * 2.0
		apply_incoming_damage(15.0, rear_pos)

	if event.is_action_pressed("skill_next"):
		if skills != null:
			skills.cycle_next()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("skill_cast"):
		if skills != null:
			skills.try_cast()
		get_viewport().set_input_as_handled()
		return

	# Light attack initiation / input buffering
	if event.is_action_pressed("attack"):
		_initiate_attack()

	# Dodge initiation
	if event.is_action_pressed("dodge"):
		_initiate_dodge()

	# Guard initiation / release
	if event.is_action_pressed("guard"):
		_initiate_guard()
	elif event.is_action_released("guard"):
		_stop_guard()

	# Only free-orbit camera when unlocked
	if event is InputEventMouseMotion:
		if not is_locked and (Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED or DisplayServer.get_name() == "headless"):
			var motion: InputEventMouseMotion = event as InputEventMouseMotion
			if camera_pivot != null:
				camera_pivot.rotate_y(-motion.relative.x * mouse_sensitivity)
			if spring_arm != null:
				_camera_pitch = clampf(_camera_pitch - motion.relative.y * mouse_sensitivity, min_pitch, max_pitch)
				spring_arm.rotation.x = _camera_pitch


func _change_camera_zoom(delta: float) -> void:
	if spring_arm == null:
		return
	var minimum: float = minf(camera_zoom_min, camera_zoom_max)
	var maximum: float = maxf(camera_zoom_min, camera_zoom_max)
	spring_arm.spring_length = clampf(spring_arm.spring_length + delta, minimum, maximum)


func _initiate_guard() -> void:
	if guard == null:
		return
	if health != null and health.is_dead():
		return
	if dodge != null and dodge.is_dodging:
		return
	if melee_attack != null and melee_attack.is_attacking:
		return
	guard.start_guard()


func _stop_guard() -> void:
	if guard != null:
		guard.stop_guard()


func _initiate_attack() -> void:
	if melee_attack == null:
		return
	if health != null and health.is_dead():
		return
	if dodge != null and dodge.is_dodging:
		return

	# Stop guard when initiating an attack so they do not overlap
	if guard != null and guard.is_guarding:
		guard.stop_guard()

	# When starting a new attack chain unlocked, face movement direction or camera forward
	var is_locked: bool = lock_on != null and lock_on.is_locked_on
	if not is_locked and not melee_attack.is_attacking and visual_root != null:
		var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		var cam_basis: Basis = camera_pivot.global_transform.basis if camera_pivot != null else global_transform.basis
		var cam_forward: Vector3 = -cam_basis.z
		cam_forward.y = 0.0
		cam_forward = cam_forward.normalized()
		var cam_right: Vector3 = cam_basis.x
		cam_right.y = 0.0
		cam_right = cam_right.normalized()

		var move_dir: Vector3 = (cam_right * input_vector.x + cam_forward * -input_vector.y)
		if move_dir.length_squared() > 0.01:
			visual_root.rotation.y = atan2(-move_dir.x, -move_dir.z)
		elif cam_forward.length_squared() > 0.01:
			visual_root.rotation.y = atan2(-cam_forward.x, -cam_forward.z)

	melee_attack.try_attack()


func _initiate_dodge() -> void:
	if dodge == null or dodge.is_dodging:
		return
	if health != null and health.is_dead():
		return
	if melee_attack != null and melee_attack.is_attacking:
		return

	# Stop guard when initiating dodge so they do not overlap
	if guard != null and guard.is_guarding:
		guard.stop_guard()

	# Directional input relative to camera horizontal yaw
	var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	var cam_basis: Basis = camera_pivot.global_transform.basis if camera_pivot != null else global_transform.basis
	var cam_forward: Vector3 = -cam_basis.z
	cam_forward.y = 0.0
	cam_forward = cam_forward.normalized()

	var cam_right: Vector3 = cam_basis.x
	cam_right.y = 0.0
	cam_right = cam_right.normalized()

	var desired_dir: Vector3 = (cam_right * input_vector.x + cam_forward * -input_vector.y)
	if desired_dir.length_squared() > 1.0:
		desired_dir = desired_dir.normalized()

	var is_locked: bool = lock_on != null and lock_on.is_locked_on
	if not is_locked and desired_dir.length_squared() > 0.001 and visual_root != null:
		visual_root.rotation.y = atan2(-desired_dir.x, -desired_dir.z)

	dodge.try_dodge(desired_dir)


## Centralized incoming-damage routing entry point.
## Enforces dodge i-frame priority, directional guard mitigation, and HealthComponent damage.
func apply_incoming_damage(amount: float, attacker_position: Vector3 = Vector3.ZERO) -> Dictionary:
	_resolve_nodes()

	var result := {
		"applied_damage": 0.0,
		"mitigated": 0.0,
		"blocked": false,
		"guard_broken": false,
		"ignored_by_iframe": false,
	}

	if health == null or health.is_dead() or amount <= 0.0:
		return result

	# 1. Dodge invulnerability / i-frames take precedence over guard
	if health.is_invulnerable or (dodge != null and dodge._iframe_active):
		result["ignored_by_iframe"] = true
		return result

	# 2. GuardComponent directional resolution
	var damage_to_deal: float = amount
	if guard != null and guard.is_guarding:
		var guard_res: Dictionary = guard.resolve_incoming_attack(amount, attacker_position)
		damage_to_deal = guard_res["damage_to_apply"]
		result["mitigated"] = guard_res["mitigated"]
		result["blocked"] = guard_res["blocked"]
		result["guard_broken"] = guard_res["guard_broken"]

	# 3. Apply resulting damage to HealthComponent
	if damage_to_deal > 0.0:
		var health_before: float = health.get_health()
		health.take_damage(damage_to_deal)
		result["applied_damage"] = health_before - health.get_health()

	return result


func _get_facing_direction() -> Vector3:
	var facing: Vector3
	if visual_root != null:
		facing = -visual_root.global_transform.basis.z
	else:
		facing = -global_transform.basis.z
	facing.y = 0.0
	if facing.length_squared() < 0.001:
		return Vector3.FORWARD
	return facing.normalized()


func _physics_process(delta: float) -> void:
	_resolve_nodes()

	# If dead, ensure guard state is cleared
	if health != null and health.is_dead():
		if guard != null and (guard.is_guarding or guard.is_guard_broken):
			guard.clear_guard_state()

	var is_dodging: bool = dodge != null and dodge.is_dodging
	var is_attacking: bool = melee_attack != null and melee_attack.is_attacking
	var is_guarding: bool = guard != null and guard.is_guarding

	# Guard cannot overlap with dodge or attack
	if (is_dodging or is_attacking) and is_guarding:
		guard.stop_guard()
		is_guarding = false

	# Gravity & Jump (Jump disallowed while dodging, attacking, or guarding)
	var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if velocity.y < 0.0:
			velocity.y = 0.0
		if not is_dodging and not is_attacking and not is_guarding and Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity

	if is_dodging:
		# During dodge: velocity is driven by DodgeComponent, sprint is disallowed
		var dodge_vel: Vector3 = dodge.get_dodge_velocity_xz()
		velocity.x = dodge_vel.x
		velocity.z = dodge_vel.z
	elif is_attacking:
		# During attack: normal locomotion input is restricted, decelerate toward zero
		velocity.x = move_toward(velocity.x, 0.0, ground_deceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, ground_deceleration * delta)
	else:
		# Directional input relative to camera horizontal yaw
		var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

		var cam_basis: Basis = camera_pivot.global_transform.basis if camera_pivot != null else global_transform.basis
		var cam_forward: Vector3 = -cam_basis.z
		cam_forward.y = 0.0
		cam_forward = cam_forward.normalized()

		var cam_right: Vector3 = cam_basis.x
		cam_right.y = 0.0
		cam_right = cam_right.normalized()

		var move_direction: Vector3 = (cam_right * input_vector.x + cam_forward * -input_vector.y)
		if move_direction.length_squared() > 1.0:
			move_direction = move_direction.normalized()

		# Sprint selection & stamina consumption (sprint disallowed while guarding)
		var wants_sprint: bool = not is_guarding and Input.is_action_pressed("sprint") and is_on_floor() and move_direction.length_squared() > 0.001
		var is_sprinting: bool = false
		if wants_sprint:
			if stamina != null:
				if not stamina.is_exhausted() and stamina.get_stamina() > 0.0:
					var has_stamina: bool = stamina.consume_continuous(sprint_stamina_cost, delta)
					is_sprinting = has_stamina
			else:
				is_sprinting = true

		var target_speed: float
		if is_guarding:
			var speed_mult: float = guard.guard_speed_multiplier if guard != null else 0.55
			target_speed = walk_speed * speed_mult
		elif is_sprinting:
			target_speed = sprint_speed
		else:
			target_speed = walk_speed

		# Acceleration & Deceleration
		var target_velocity_xz: Vector3 = move_direction * target_speed
		var current_velocity_xz: Vector3 = Vector3(velocity.x, 0.0, velocity.z)

		var accel: float
		if not is_on_floor():
			accel = air_acceleration
		elif move_direction.length_squared() > 0.001:
			accel = ground_acceleration
		else:
			accel = ground_deceleration

		current_velocity_xz = current_velocity_xz.move_toward(target_velocity_xz, accel * delta)
		velocity.x = current_velocity_xz.x
		velocity.z = current_velocity_xz.z

		# Facing: Lock-on takes precedence; when unlocked, guard faces camera forward, normal movement faces travel
		var is_locked: bool = lock_on != null and lock_on.is_locked_on
		if not is_locked:
			if is_guarding and visual_root != null:
				if cam_forward.length_squared() > 0.001:
					var target_yaw: float = atan2(-cam_forward.x, -cam_forward.z)
					visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_yaw, rotation_speed * delta)
			elif move_direction.length_squared() > 0.001 and visual_root != null:
				var target_yaw: float = atan2(-move_direction.x, -move_direction.z)
				visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_yaw, rotation_speed * delta)

	# Physics movement with physical collision
	move_and_slide()

	# Update locomotion state after move_and_slide()
	_update_locomotion_state()

	# Drive procedural visual feedback on VisualRoot
	if visual_root != null and visual_root.has_method("update_procedural_visuals"):
		var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
		var combo_idx: int = melee_attack.combo_index if melee_attack != null else 1
		visual_root.update_procedural_visuals(current_state, horizontal_speed, delta, combo_idx)


func _update_locomotion_state() -> void:
	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	var new_state: LocomotionState

	if dodge != null and dodge.is_dodging:
		new_state = LocomotionState.DODGE
	elif melee_attack != null and melee_attack.is_attacking:
		new_state = LocomotionState.ATTACK
	elif not is_on_floor():
		if velocity.y > 0.0:
			new_state = LocomotionState.JUMP
		else:
			new_state = LocomotionState.FALL
	elif guard != null and guard.is_guarding:
		new_state = LocomotionState.GUARD
	else:
		if horizontal_speed < 0.1:
			new_state = LocomotionState.IDLE
		elif horizontal_speed > walk_speed + 0.5:
			new_state = LocomotionState.SPRINT
		else:
			new_state = LocomotionState.MOVE

	if new_state != current_state:
		var previous_state: LocomotionState = current_state
		current_state = new_state
		state_changed.emit(previous_state, current_state)


func get_locomotion_state_name() -> String:
	match current_state:
		LocomotionState.IDLE:
			return "IDLE"
		LocomotionState.MOVE:
			return "MOVE"
		LocomotionState.SPRINT:
			return "SPRINT"
		LocomotionState.JUMP:
			return "JUMP"
		LocomotionState.FALL:
			return "FALL"
		LocomotionState.DODGE:
			return "DODGE"
		LocomotionState.ATTACK:
			return "ATTACK"
		LocomotionState.GUARD:
			return "GUARD"
		_:
			return "UNKNOWN"

