class_name CameraImpulseComponent
extends Node

## Camera impulse component applying transient screen-space projection offsets via Camera3D.h_offset and Camera3D.v_offset.
## Decays smoothly to 0 with zero accumulated drift.
## Does not alter CameraPivot, SpringArm3D, or CharacterBody3D transforms.

@export var max_h_offset: float = 0.20
@export var max_v_offset: float = 0.20
@export var decay_rate: float = 6.0

var _camera: Camera3D = null
var _trauma: float = 0.0
var _shake_timer: float = 0.0


func _ready() -> void:
	_resolve_camera()


func _resolve_camera() -> void:
	if _camera != null and is_instance_valid(_camera):
		return
	var parent: Node = get_parent()
	if parent != null:
		if parent is Camera3D:
			_camera = parent as Camera3D
		elif "camera" in parent and parent.camera != null:
			_camera = parent.camera as Camera3D
		else:
			_camera = parent.get_node_or_null("CameraPivot/SpringArm3D/Camera3D") as Camera3D


func add_trauma(amount: float) -> void:
	_resolve_camera()
	_trauma = clampf(_trauma + amount, 0.0, 1.0)


func get_trauma() -> float:
	return _trauma


func reset_impulse() -> void:
	_trauma = 0.0
	_shake_timer = 0.0
	if _camera != null and is_instance_valid(_camera):
		_camera.h_offset = 0.0
		_camera.v_offset = 0.0


func _physics_process(delta: float) -> void:
	if _camera == null:
		_resolve_camera()
		if _camera == null:
			return

	if _trauma > 0.0:
		_shake_timer += delta * 40.0
		var intensity: float = _trauma * _trauma
		_camera.h_offset = sin(_shake_timer * 1.7) * max_h_offset * intensity
		_camera.v_offset = cos(_shake_timer * 2.3) * max_v_offset * intensity

		_trauma = maxf(0.0, _trauma - decay_rate * delta)
		if _trauma <= 0.0:
			reset_impulse()
	else:
		if _camera.h_offset != 0.0 or _camera.v_offset != 0.0:
			_camera.h_offset = 0.0
			_camera.v_offset = 0.0
