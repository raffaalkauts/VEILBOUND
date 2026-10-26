class_name SkillProjectile
extends Area3D

var _owner: Node3D
var _damage: float
var _poise_damage: float
var _speed: float = 9.0
var _lifetime: float = 1.2
var _hit_targets: Dictionary = {}


func configure(owner_node: Node3D, damage: float, poise_damage: float, _range: float) -> void:
	_owner = owner_node
	_damage = damage
	_poise_damage = poise_damage


func _ready() -> void:
	add_to_group("skill_projectiles")
	collision_layer = 0
	collision_mask = 4
	monitoring = true
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.28
	shape.shape = sphere
	add_child(shape)
	var mesh := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 0.28
	sphere_mesh.height = 0.56
	mesh.mesh = sphere_mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#79D8CE")
	material.emission_enabled = true
	material.emission = Color("#79D8CE")
	material.emission_energy_multiplier = 1.5
	mesh.material_override = material
	add_child(mesh)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += -global_transform.basis.z * _speed * delta
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	if body == _owner or _hit_targets.has(body):
		return
	_hit_targets[body] = true
	if body.has_method("take_damage"):
		body.take_damage(_damage)
	else:
		var health: HealthComponent = body.get_node_or_null("HealthComponent") as HealthComponent
		if health != null:
			health.take_damage(_damage)
	if _poise_damage > 0.0:
		if body.has_method("apply_posture_damage"):
			body.apply_posture_damage(_poise_damage)
		else:
			var poise: PoiseComponent = body.get_node_or_null("PoiseComponent") as PoiseComponent
			if poise != null:
				poise.apply_posture_damage(_poise_damage)
	queue_free()
