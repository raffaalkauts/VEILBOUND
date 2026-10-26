class_name HitImpactEffect
extends CPUParticles3D

## Lightweight combat impact particles for hits, blocks, guard breaks, and staggers.
## Uses built-in BoxMesh and unshaded StandardMaterial3D. Optimized for low-end Compatibility renderer.

enum EffectType {
	SLASH,
	GUARD_BLOCK,
	GUARD_BREAK,
	STAGGER
}

@export var auto_start: bool = true
@export var effect_type: EffectType = EffectType.SLASH


func _ready() -> void:
	if auto_start:
		play_effect(effect_type)


func play_effect(type: EffectType = EffectType.SLASH) -> void:
	effect_type = type
	one_shot = true
	explosiveness = 1.0

	var mat := StandardMaterial3D.new()
	mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED

	match type:
		EffectType.SLASH:
			amount = 10
			lifetime = 0.22
			initial_velocity_min = 2.5
			initial_velocity_max = 5.0
			color = Color(1.0, 0.75, 0.2, 1.0)
			mat.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
		EffectType.GUARD_BLOCK:
			amount = 12
			lifetime = 0.20
			initial_velocity_min = 3.0
			initial_velocity_max = 6.0
			color = Color(0.2, 0.85, 1.0, 1.0)
			mat.albedo_color = Color(0.3, 0.9, 1.0, 1.0)
		EffectType.GUARD_BREAK:
			amount = 16
			lifetime = 0.32
			initial_velocity_min = 4.0
			initial_velocity_max = 7.5
			color = Color(0.5, 0.35, 1.0, 1.0)
			mat.albedo_color = Color(0.6, 0.4, 1.0, 1.0)
		EffectType.STAGGER:
			amount = 14
			lifetime = 0.28
			initial_velocity_min = 3.5
			initial_velocity_max = 6.5
			color = Color(1.0, 0.9, 0.3, 1.0)
			mat.albedo_color = Color(1.0, 0.95, 0.4, 1.0)

	var box := BoxMesh.new()
	box.size = Vector3(0.06, 0.06, 0.06)
	box.material = mat
	mesh = box

	emitting = true

	# Auto-free safely when particle burst completes
	var timer := get_tree().create_timer(lifetime + 0.1)
	timer.timeout.connect(queue_free)
