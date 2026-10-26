class_name PlayerSkillComponent
extends Node

const SKILL_DEFINITION_SCRIPT: Script = preload("res://combat/skill_definition.gd")

signal selected_skill_changed(skill: Resource, index: int)
signal skill_cast(skill: Resource)
signal cast_rejected(skill: Resource, reason: String)

const PROJECTILE_SCRIPT: Script = preload("res://combat/skill_projectile.gd")
const SKILL_COUNT: int = 4

@export var skills: Array[Resource] = []
@export var selected_index: int = 0

var _cooldowns: Array[float] = []
var _player: PlayerController
var _rift_pending: bool = false
var _rift_direction: Vector3 = Vector3.ZERO
var _rift_distance: float = 0.0
var _pending_melee_skill: Resource = null
var _pending_melee_timer: float = 0.0
var _pending_melee_range: float = 0.0
var _pending_melee_width: float = 0.0
var projectile_spawn_count: int = 0


func _ready() -> void:
	_player = get_parent() as PlayerController
	if skills.is_empty():
		skills = _default_skills()
	_cooldowns.resize(skills.size())
	_cooldowns.fill(0.0)
	selected_index = clampi(selected_index, 0, maxi(0, skills.size() - 1))
	if not skills.is_empty():
		selected_skill_changed.emit(skills[selected_index], selected_index)


func _physics_process(delta: float) -> void:
	for index in range(_cooldowns.size()):
		_cooldowns[index] = maxf(0.0, _cooldowns[index] - delta)
	if _rift_pending and _player != null and is_instance_valid(_player):
		_player.move_and_collide(_rift_direction * _rift_distance)
		_rift_pending = false
	if _pending_melee_skill != null:
		_pending_melee_timer -= delta
		if _pending_melee_timer <= 0.0:
			var active_skill: Resource = _pending_melee_skill
			_pending_melee_skill = null
			if _player != null and is_instance_valid(_player) and _player.health != null and not _player.health.is_dead():
				_hit_area(active_skill, _pending_melee_range, _pending_melee_width)


func _default_skills() -> Array[Resource]:
	return [
		_make_skill("aether_crescent", "Aether Crescent", "Broad resonance sweep", 24.0, 5.0, 22.0, 28.0, 2.8, "attack_1"),
		_make_skill("rift_step", "Rift Step", "Short collision-safe reposition", 22.0, 4.0, 0.0, 0.0, 2.2, "dodge"),
		_make_skill("shatterpoint_thrust", "Shatterpoint Thrust", "Committed posture breaker", 28.0, 6.0, 30.0, 55.0, 3.0, "attack_2"),
		_make_skill("aether_wave", "Aether Wave", "Moving ranged crescent", 30.0, 7.0, 26.0, 18.0, 8.0, "attack_3"),
	]


func _make_skill(id: String, title: String, detail: String, cost: float, cooldown: float, damage: float, poise_damage: float, range: float, animation: String) -> Resource:
	var skill: Resource = SKILL_DEFINITION_SCRIPT.new()
	skill.skill_id = id
	skill.display_name = title
	skill.description = detail
	skill.stamina_cost = cost
	skill.cooldown = cooldown
	skill.damage = damage
	skill.poise_damage = poise_damage
	skill.range = range
	skill.animation_name = animation
	return skill


func get_selected_skill() -> Resource:
	if skills.is_empty():
		return null
	return skills[selected_index]


func get_cooldown_ratio(index: int = selected_index) -> float:
	if index < 0 or index >= skills.size() or skills[index].cooldown <= 0.0:
		return 0.0
	return _cooldowns[index] / skills[index].cooldown


func is_selected_ready() -> bool:
	return not skills.is_empty() and _cooldowns[selected_index] <= 0.0


func cycle_next() -> Resource:
	if skills.is_empty():
		return null
	selected_index = (selected_index + 1) % skills.size()
	selected_skill_changed.emit(skills[selected_index], selected_index)
	return skills[selected_index]


func try_cast() -> bool:
	var skill: Resource = get_selected_skill()
	if skill == null:
		return false
	if _player == null or _player.health == null or _player.health.is_dead():
		return _reject(skill, "DEAD")
	if _player.melee_attack != null and _player.melee_attack.is_attacking:
		return _reject(skill, "BUSY")
	if _pending_melee_skill != null:
		return _reject(skill, "BUSY")
	if _player.guard != null and _player.guard.is_guarding:
		return _reject(skill, "GUARD")
	if _cooldowns[selected_index] > 0.0:
		return _reject(skill, "COOLDOWN")
	if _player.stamina == null or not _player.stamina.try_consume(skill.stamina_cost):
		return _reject(skill, "STAMINA")

	_cooldowns[selected_index] = skill.cooldown
	_execute(skill)
	skill_cast.emit(skill)
	return true


func _reject(skill: Resource, reason: String) -> bool:
	cast_rejected.emit(skill, reason)
	return false


func _execute(skill: Resource) -> void:
	if _player.visual_root != null and _player.visual_root.has_method("play_skill_animation"):
		_player.visual_root.play_skill_animation(skill.animation_name, 0.55)
	match skill.skill_id:
		"aether_crescent":
			_schedule_melee_hit(skill, 2.8, 1.45, 0.18)
		"rift_step":
			_rift_step(skill)
		"shatterpoint_thrust":
			_schedule_melee_hit(skill, 3.0, 0.70, 0.28)
		"aether_wave":
			_spawn_projectile(skill)


func _schedule_melee_hit(skill: Resource, hit_range: float, width: float, startup: float) -> void:
	_pending_melee_skill = skill
	_pending_melee_timer = startup
	_pending_melee_range = hit_range
	_pending_melee_width = width


func _hit_area(skill: Resource, hit_range: float, width: float) -> void:
	var space_state := _player.get_world_3d().direct_space_state
	var shape := BoxShape3D.new()
	shape.size = Vector3(width, 1.8, hit_range)
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.collision_mask = 4
	var facing: Vector3 = -_player.global_transform.basis.z
	var yaw: float = atan2(-facing.x, -facing.z)
	params.transform = Transform3D(Basis(Vector3.UP, yaw), _player.global_position).translated_local(Vector3(0.0, 0.9, -hit_range * 0.5))
	params.exclude = [_player.get_rid()]
	var hit_once: Dictionary = {}
	for result: Dictionary in space_state.intersect_shape(params, 16):
		var target: Node = result.get("collider") as Node
		if target == null or hit_once.has(target):
			continue
		hit_once[target] = true
		_apply_hit(target, skill)


func _apply_hit(target: Node, skill: Resource) -> void:
	if target.has_method("take_damage"):
		target.take_damage(skill.damage)
	else:
		var health: HealthComponent = target.get_node_or_null("HealthComponent") as HealthComponent
		if health != null:
			health.take_damage(skill.damage)
	if skill.poise_damage > 0.0:
		if target.has_method("apply_posture_damage"):
			target.apply_posture_damage(skill.poise_damage)
		else:
			var poise: PoiseComponent = target.get_node_or_null("PoiseComponent") as PoiseComponent
			if poise != null:
				poise.apply_posture_damage(skill.poise_damage)


func _rift_step(skill: Resource) -> void:
	var direction: Vector3 = -_player.global_transform.basis.z
	direction.y = 0.0
	if direction.length_squared() < 0.01:
		return
	direction = direction.normalized()
	_rift_direction = direction
	_rift_distance = skill.range
	_rift_pending = true


func _spawn_projectile(skill: Resource) -> void:
	projectile_spawn_count += 1
	var projectile: Area3D = PROJECTILE_SCRIPT.new()
	projectile.configure(_player, skill.damage, skill.poise_damage, skill.range)
	var scene_root: Node = _player.get_tree().current_scene
	if scene_root == null:
		scene_root = _player.get_tree().root
	scene_root.add_child(projectile)
	var launch_transform: Transform3D = _player.global_transform
	launch_transform.origin += Vector3.UP
	projectile.global_transform = launch_transform
