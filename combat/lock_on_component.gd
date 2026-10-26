class_name LockOnComponent
extends Node

## Dedicated Souls-like Lock-On Component for Player
## Handles target acquisition, line-of-sight checks, target switching, and smooth tracking.

signal target_locked(target: LockOnTarget)
signal target_changed(new_target: LockOnTarget, old_target: LockOnTarget)
signal target_unlocked()

@export_group("Targeting Range & Angles")
@export var max_lock_on_distance: float = 16.0
@export var max_unlock_distance: float = 20.0
@export var max_angle_degrees: float = 75.0

@export_group("Tracking Speed")
@export var camera_tracking_speed: float = 8.0
@export var facing_tracking_speed: float = 10.0

@export_group("Collision")
@export var line_of_sight_mask: int = 1 # Layer 1 (World obstacles)

@export_group("Visuals")
@export var reticle_scene: PackedScene = preload("res://combat/lock_on_reticle.tscn")

var current_target: LockOnTarget = null
var is_locked_on: bool:
	get:
		return current_target != null and is_instance_valid(current_target) and current_target.is_available()

# Internal references
var _player: PlayerController
var _camera_pivot: Node3D
var _spring_arm: SpringArm3D
var _camera: Camera3D
var _visual_root: Node3D
var _reticle_instance: Node3D = null


func _ready() -> void:
	_resolve_references()
	_setup_reticle()


func _resolve_references() -> void:
	_player = get_parent() as PlayerController
	if _player != null:
		_camera_pivot = _player.get_node_or_null("CameraPivot")
		_spring_arm = _player.get_node_or_null("CameraPivot/SpringArm3D")
		_camera = _player.get_node_or_null("CameraPivot/SpringArm3D/Camera3D")
		_visual_root = _player.get_node_or_null("VisualRoot")


func _setup_reticle() -> void:
	if reticle_scene != null and _reticle_instance == null:
		_reticle_instance = reticle_scene.instantiate() as Node3D
		if _reticle_instance != null:
			_reticle_instance.visible = false
			# Add reticle to root or tree so it floats freely in world space
			call_deferred("_add_reticle_to_scene")


func _add_reticle_to_scene() -> void:
	if _reticle_instance != null and is_inside_tree():
		get_tree().root.add_child(_reticle_instance)


func _exit_tree() -> void:
	if _reticle_instance != null and is_instance_valid(_reticle_instance):
		_reticle_instance.queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_MIDDLE:
		toggle_lock_on()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("lock_on"):
		toggle_lock_on()
		get_viewport().set_input_as_handled()
	elif is_locked_on:
		if event is InputEventMouseButton and event.is_pressed():
			var mb := event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				cycle_target(1)
				get_viewport().set_input_as_handled()
			elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				cycle_target(-1)
				get_viewport().set_input_as_handled()
		elif event.is_action_pressed("target_next"):
			cycle_target(1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("target_prev"):
			cycle_target(-1)
			get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if not is_locked_on:
		if _reticle_instance != null and _reticle_instance.visible:
			_reticle_instance.visible = false
		return

	# Target validity and distance verification
	if not _is_target_still_valid(current_target):
		unlock()
		return

	# Update reticle position
	if _reticle_instance != null:
		_reticle_instance.visible = true
		_reticle_instance.global_position = current_target.get_target_point() + Vector3(0.0, 0.35, 0.0)
		_reticle_instance.rotate_y(delta * 2.5)

	# Smooth camera tracking toward target
	_track_target_with_camera(delta)

	# Smooth character visual facing toward target
	_track_target_with_facing(delta)


func toggle_lock_on() -> void:
	if is_locked_on:
		unlock()
	else:
		acquire_target()


func acquire_target() -> bool:
	_resolve_references()
	if _player == null or _camera == null:
		return false

	var best_target: LockOnTarget = _find_best_target()
	if best_target != null:
		_set_target(best_target)
		return true

	return false


func unlock() -> void:
	if current_target != null:
		if is_instance_valid(current_target) and current_target.target_invalidated.is_connected(_on_target_invalidated):
			current_target.target_invalidated.disconnect(_on_target_invalidated)
		current_target = null
		if _reticle_instance != null:
			_reticle_instance.visible = false
		target_unlocked.emit()


func cycle_target(direction: int = 1) -> bool:
	if not is_locked_on:
		return false

	var candidates: Array[LockOnTarget] = []
	for node in get_tree().get_nodes_in_group("lock_on_targets"):
		var target := node as LockOnTarget
		if target != null and target != current_target and _is_candidate_valid(target, max_lock_on_distance, false):
			candidates.append(target)

	if candidates.is_empty():
		return false

	# Sort candidates horizontally relative to camera forward
	var cam_basis: Basis = _camera.global_transform.basis
	var cam_right: Vector3 = cam_basis.x
	var cam_forward: Vector3 = -cam_basis.z

	candidates.sort_custom(func(a: LockOnTarget, b: LockOnTarget) -> bool:
		var dir_a: Vector3 = (a.get_target_point() - _camera.global_position).normalized()
		var dir_b: Vector3 = (b.get_target_point() - _camera.global_position).normalized()
		var angle_a: float = atan2(cam_right.dot(dir_a), cam_forward.dot(dir_a))
		var angle_b: float = atan2(cam_right.dot(dir_b), cam_forward.dot(dir_b))
		return angle_a < angle_b
	)

	# Pick next target in desired direction with full circular wrap-around
	var next_target: LockOnTarget = null
	var cur_dir: Vector3 = (current_target.get_target_point() - _camera.global_position).normalized()
	var cur_angle: float = atan2(cam_right.dot(cur_dir), cam_forward.dot(cur_dir))

	if direction > 0:
		for cand in candidates:
			var dir: Vector3 = (cand.get_target_point() - _camera.global_position).normalized()
			var angle: float = atan2(cam_right.dot(dir), cam_forward.dot(dir))
			if angle > cur_angle + 0.05:
				next_target = cand
				break
		if next_target == null:
			next_target = candidates.front()
	else:
		for i in range(candidates.size() - 1, -1, -1):
			var cand := candidates[i]
			var dir: Vector3 = (cand.get_target_point() - _camera.global_position).normalized()
			var angle: float = atan2(cam_right.dot(dir), cam_forward.dot(dir))
			if angle < cur_angle - 0.05:
				next_target = cand
				break
		if next_target == null:
			next_target = candidates.back()

	if next_target != null and next_target != current_target:
		_set_target(next_target)
		return true

	return false


func _set_target(new_target: LockOnTarget) -> void:
	var old_target: LockOnTarget = current_target
	if old_target != null and is_instance_valid(old_target) and old_target.target_invalidated.is_connected(_on_target_invalidated):
		old_target.target_invalidated.disconnect(_on_target_invalidated)

	current_target = new_target
	if current_target != null:
		current_target.target_invalidated.connect(_on_target_invalidated)
		if _reticle_instance != null:
			_reticle_instance.visible = true
			_reticle_instance.global_position = current_target.get_target_point() + Vector3(0.0, 0.35, 0.0)
		if old_target == null:
			target_locked.emit(current_target)
		else:
			target_changed.emit(current_target, old_target)


func _on_target_invalidated(_target: LockOnTarget) -> void:
	unlock()


func _find_best_target() -> LockOnTarget:
	var best_target: LockOnTarget = null
	var best_score: float = 999999.0

	var cam_forward: Vector3 = -_camera.global_transform.basis.z

	for node in get_tree().get_nodes_in_group("lock_on_targets"):
		var candidate := node as LockOnTarget
		if candidate == null or not candidate.is_available():
			continue

		var target_point: Vector3 = candidate.get_target_point()
		var dist: float = _player.global_position.distance_to(target_point)
		if dist > max_lock_on_distance:
			continue

		var to_target_cam: Vector3 = (target_point - _camera.global_position).normalized()
		var angle_deg: float = rad_to_deg(cam_forward.angle_to(to_target_cam))
		if angle_deg > max_angle_degrees:
			continue

		if not _has_line_of_sight(target_point, candidate):
			continue

		# Score: prioritize centered and closer targets
		var score: float = (dist / max_lock_on_distance) * 0.4 + (angle_deg / max_angle_degrees) * 0.6
		if score < best_score:
			best_score = score
			best_target = candidate

	return best_target


func _is_candidate_valid(candidate: LockOnTarget, max_dist: float, check_angle: bool = true) -> bool:
	if candidate == null or not is_instance_valid(candidate) or not candidate.is_available():
		return false

	var target_point: Vector3 = candidate.get_target_point()
	var dist: float = _player.global_position.distance_to(target_point)
	if dist > max_dist:
		return false

	if check_angle and _camera != null:
		var cam_forward: Vector3 = -_camera.global_transform.basis.z
		var to_target_cam: Vector3 = (target_point - _camera.global_position).normalized()
		var angle_deg: float = rad_to_deg(cam_forward.angle_to(to_target_cam))
		if angle_deg > max_angle_degrees:
			return false

	return _has_line_of_sight(target_point, candidate)


func _is_target_still_valid(target: LockOnTarget) -> bool:
	if target == null or not is_instance_valid(target) or not target.is_available():
		return false

	var dist: float = _player.global_position.distance_to(target.get_target_point())
	if dist > max_unlock_distance:
		return false

	return true


func _has_line_of_sight(target_point: Vector3, target_node: Node3D) -> bool:
	if not is_inside_tree() or _player == null:
		return true

	var space_state := _player.get_world_3d().direct_space_state
	var ray_origin: Vector3 = _player.global_position + Vector3(0.0, 1.4, 0.0)

	var query := PhysicsRayQueryParameters3D.create(
		ray_origin,
		target_point,
		line_of_sight_mask,
		[_player.get_rid()]
	)

	var result := space_state.intersect_ray(query)
	if result.is_empty():
		return true

	var collider: Object = result.collider
	# If ray hit the target or any child of target, line of sight is clear
	if collider == target_node or (target_node is Node and target_node.is_ancestor_of(collider as Node)):
		return true

	# Hit a solid world obstacle
	return false


func _track_target_with_camera(delta: float) -> void:
	if _camera_pivot == null or _spring_arm == null or current_target == null:
		return

	var target_pos: Vector3 = current_target.get_target_point()
	var to_target: Vector3 = target_pos - _camera_pivot.global_position

	# Smooth camera horizontal yaw
	var desired_yaw: float = atan2(-to_target.x, -to_target.z)
	_camera_pivot.rotation.y = lerp_angle(_camera_pivot.rotation.y, desired_yaw, camera_tracking_speed * delta)

	# Smooth camera vertical pitch
	var h_dist: float = Vector2(to_target.x, to_target.z).length()
	var desired_pitch: float = atan2(to_target.y, h_dist)
	if _player != null:
		desired_pitch = clampf(desired_pitch, _player.min_pitch, _player.max_pitch)

	_spring_arm.rotation.x = lerp_angle(_spring_arm.rotation.x, desired_pitch, camera_tracking_speed * delta)
	if _player != null:
		_player._camera_pitch = _spring_arm.rotation.x


func _track_target_with_facing(delta: float) -> void:
	if _visual_root == null or current_target == null or _player == null:
		return

	var to_target_h: Vector3 = current_target.get_target_point() - _player.global_position
	to_target_h.y = 0.0
	if to_target_h.length_squared() > 0.01:
		var desired_facing_yaw: float = atan2(-to_target_h.x, -to_target_h.z)
		_visual_root.rotation.y = lerp_angle(_visual_root.rotation.y, desired_facing_yaw, facing_tracking_speed * delta)
