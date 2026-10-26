class_name CombatFeedbackCoordinator
extends Node

## Centralized coordination layer for combat visual, camera, and audio feedback.
## Subscribes to combat signals and ensures each event triggers feedback once without duplicate execution.

signal feedback_triggered(event_name: String, details: Dictionary)

@export var hit_particles_enabled: bool = true
@export var camera_shake_enabled: bool = true
@export var audio_enabled: bool = true

@export var impact_effect_scene: PackedScene = preload("res://vfx/hit_impact_effect.tscn")

var camera_impulse: CameraImpulseComponent = null
var audio_manager: AudioFeedbackManager = null
var _player: PlayerController = null


func _ready() -> void:
	_resolve_subcomponents()
	if _player == null and get_parent() is PlayerController:
		bind_player(get_parent() as PlayerController)


func _resolve_subcomponents() -> void:
	if camera_impulse == null:
		camera_impulse = get_node_or_null("CameraImpulseComponent") as CameraImpulseComponent
	if camera_impulse == null and _player != null:
		camera_impulse = _player.get_node_or_null("CameraImpulseComponent") as CameraImpulseComponent

	if audio_manager == null:
		audio_manager = get_node_or_null("AudioFeedbackManager") as AudioFeedbackManager
	if audio_manager == null and _player != null:
		audio_manager = _player.get_node_or_null("AudioFeedbackManager") as AudioFeedbackManager


func bind_player(player: PlayerController) -> void:
	if player == null:
		return
	_player = player
	_resolve_subcomponents()

	# Connect attack hit confirmation
	if _player.melee_attack != null:
		if not _player.melee_attack.hit_confirmed.is_connected(_on_player_hit_confirmed):
			_player.melee_attack.hit_confirmed.connect(_on_player_hit_confirmed)

	# Connect guard signals
	if _player.guard != null:
		if not _player.guard.attack_blocked.is_connected(_on_player_attack_blocked):
			_player.guard.attack_blocked.connect(_on_player_attack_blocked)
		if not _player.guard.guard_broken.is_connected(_on_player_guard_broken):
			_player.guard.guard_broken.connect(_on_player_guard_broken)

	# Connect player incoming damage
	if _player.health != null:
		if not _player.health.damaged.is_connected(_on_player_damaged):
			_player.health.damaged.connect(_on_player_damaged)


func _on_player_hit_confirmed(target: Node, damage: float, combo_index: int) -> void:
	# 1. Camera impulse
	if camera_shake_enabled and camera_impulse != null:
		camera_impulse.add_trauma(0.12 + combo_index * 0.05)

	# 2. Target hit reaction & flash
	if target != null and is_instance_valid(target):
		if target.has_method("trigger_hit_flash"):
			target.trigger_hit_flash()
		elif target.has_method("hit_reacted"):
			target.hit_reacted()

		# Check if target posture was broken into stagger by this strike
		var is_staggered: bool = false
		if target.has_method("is_staggered"):
			is_staggered = target.is_staggered()
		elif target.get_node_or_null("PoiseComponent") != null:
			var poise: PoiseComponent = target.get_node_or_null("PoiseComponent") as PoiseComponent
			is_staggered = poise.is_staggered()

		if is_staggered:
			trigger_stagger_feedback(target)
		else:
			_spawn_impact_particles(target.global_position + Vector3(0, 1.1, 0), HitImpactEffect.EffectType.SLASH)

	# 3. Audio hook
	if audio_enabled and audio_manager != null:
		audio_manager.play_hit(combo_index)

	feedback_triggered.emit("hit_confirmed", {"target": target, "damage": damage, "combo": combo_index})


func _on_player_attack_blocked(mitigated: float, damage_taken: float, stamina_cost: float) -> void:
	# 1. Camera impulse
	if camera_shake_enabled and camera_impulse != null:
		camera_impulse.add_trauma(0.18)

	# 2. Visual particles at player's shield position
	if _player != null:
		var spawn_pos: Vector3 = _player.global_position + (-_player.global_transform.basis.z * 0.8) + Vector3(0, 1.1, 0)
		_spawn_impact_particles(spawn_pos, HitImpactEffect.EffectType.GUARD_BLOCK)

	# 3. Audio hook
	if audio_enabled and audio_manager != null:
		audio_manager.play_guard_block()

	feedback_triggered.emit("guard_blocked", {"mitigated": mitigated, "cost": stamina_cost})


func _on_player_guard_broken() -> void:
	# 1. Major camera impulse
	if camera_shake_enabled and camera_impulse != null:
		camera_impulse.add_trauma(0.40)

	# 2. Visual guard break shatter effect
	if _player != null:
		var spawn_pos: Vector3 = _player.global_position + Vector3(0, 1.2, 0)
		_spawn_impact_particles(spawn_pos, HitImpactEffect.EffectType.GUARD_BREAK)

	# 3. Audio hook
	if audio_enabled and audio_manager != null:
		audio_manager.play_guard_break()

	feedback_triggered.emit("guard_broken", {})


func _on_player_damaged(_amount: float, _current: float) -> void:
	# Camera impulse on incoming damage taken
	if camera_shake_enabled and camera_impulse != null:
		camera_impulse.add_trauma(0.20)

	if audio_enabled and audio_manager != null:
		audio_manager.play_player_hurt()

	feedback_triggered.emit("player_damaged", {"amount": _amount})


func trigger_stagger_feedback(target: Node) -> void:
	# 1. Major camera impulse
	if camera_shake_enabled and camera_impulse != null:
		camera_impulse.add_trauma(0.28)

	# 2. Stagger visual particles
	var pos: Vector3 = target.global_position + Vector3(0, 1.2, 0) if target != null else Vector3.ZERO
	_spawn_impact_particles(pos, HitImpactEffect.EffectType.STAGGER)

	# 3. Target stagger flash
	if target != null and is_instance_valid(target) and target.has_method("trigger_stagger_flash"):
		target.trigger_stagger_flash()

	# 4. Audio hook
	if audio_enabled and audio_manager != null:
		audio_manager.play_stagger()

	feedback_triggered.emit("stagger", {"target": target})


func trigger_death_feedback(target: Node) -> void:
	if audio_enabled and audio_manager != null:
		audio_manager.play_enemy_death()

	feedback_triggered.emit("death", {"target": target})


func _spawn_impact_particles(world_pos: Vector3, type: HitImpactEffect.EffectType) -> void:
	if not hit_particles_enabled or impact_effect_scene == null:
		return

	var fx: HitImpactEffect = impact_effect_scene.instantiate() as HitImpactEffect
	if fx != null:
		fx.auto_start = false
		var scene_root: Node = get_tree().current_scene if get_tree() != null else null
		if scene_root != null:
			scene_root.add_child(fx)
		else:
			add_child(fx)

		fx.global_position = world_pos
		fx.play_effect(type)
