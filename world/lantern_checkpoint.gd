class_name LanternCheckpoint
extends Area3D

## Signal emitted when the player activates or rests at this lantern
signal checkpoint_activated(checkpoint_position: Vector3)

@export var prompt_text: String = "[E] Commune with Aether Lantern"
@export var activated_text: String = "✦ Aether Lantern Rekindled — Resonance Restored ✦"
@export var is_activated: bool = false
@export var heal_on_activate: bool = true

@export var unlit_color: Color = Color(0.9, 0.45, 0.15, 1.0)
@export var aether_color: Color = Color(0.2, 0.85, 0.95, 1.0)

const RESPAWN_DELAY_SECONDS: float = 1.25

@onready var prompt_label: Label3D = $PromptLabel3D
@onready var aether_light: OmniLight3D = $AetherLight3D
@onready var respawn_point: Marker3D = $RespawnPoint

var _player_in_range: PlayerController = null
var _registered_player: PlayerController = null
var _respawn_in_progress: bool = false
var _banner_timer: float = 0.0


func _ready() -> void:
	collision_layer = 64 # Layer 7: Interactable
	collision_mask = 2   # Mask 2: Player
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	if prompt_label != null:
		prompt_label.visible = false
		prompt_label.text = prompt_text
		prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		prompt_label.no_depth_test = true

	_update_visuals()


func _process(delta: float) -> void:
	if _banner_timer > 0.0:
		_banner_timer -= delta
		if _banner_timer <= 0.0:
			if _player_in_range != null and prompt_label != null:
				prompt_label.text = "[E] Rest at Aether Lantern"
				prompt_label.modulate = Color.WHITE
			elif prompt_label != null:
				prompt_label.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if _player_in_range != null and event.is_action_pressed("interact"):
		activate_checkpoint(_player_in_range)


func activate_checkpoint(player: PlayerController) -> void:
	if player == null:
		return

	_registered_player = player
	if player.health != null and not player.health.died.is_connected(_on_player_died):
		player.health.died.connect(_on_player_died)

	# Restore Health & Stamina
	if heal_on_activate:
		if player.health != null and not player.health.is_dead():
			player.health.heal(player.health.max_health)
		if player.stamina != null:
			player.stamina.reset_stamina()

	is_activated = true
	_update_visuals()
	checkpoint_activated.emit(global_position)

	if prompt_label != null:
		prompt_label.text = activated_text
		prompt_label.modulate = aether_color
		prompt_label.visible = true
		_banner_timer = 3.5


func _on_player_died() -> void:
	if not is_activated or _respawn_in_progress or _registered_player == null:
		return
	_respawn_in_progress = true
	await get_tree().create_timer(RESPAWN_DELAY_SECONDS).timeout
	if is_instance_valid(_registered_player):
		_respawn_player(_registered_player)
	_respawn_in_progress = false


func _respawn_player(player: PlayerController) -> void:
	if player.health != null:
		player.health.reset_health()
	if player.stamina != null:
		player.stamina.reset_stamina()
	if player.guard != null:
		player.guard.clear_guard_state()
	if player.dodge != null:
		player.dodge.cancel_dodge()
	player.velocity = Vector3.ZERO
	player.global_position = respawn_point.global_position
	if player.visual_root != null and player.visual_root.has_method("reset_to_base"):
		player.visual_root.call("reset_to_base")


func _update_visuals() -> void:
	if aether_light != null:
		if is_activated:
			aether_light.light_color = aether_color
			aether_light.light_energy = 2.4
			aether_light.omni_range = 6.0
		else:
			aether_light.light_color = unlit_color
			aether_light.light_energy = 0.8
			aether_light.omni_range = 3.0


func _on_body_entered(body: Node3D) -> void:
	if body is PlayerController or body.is_in_group("player"):
		_player_in_range = body as PlayerController
		if prompt_label != null:
			prompt_label.visible = true
			if _banner_timer <= 0.0:
				prompt_label.modulate = Color.WHITE
				prompt_label.text = prompt_text if not is_activated else "[E] Rest at Aether Lantern"


func _on_body_exited(body: Node3D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if prompt_label != null and _banner_timer <= 0.0:
			prompt_label.visible = false
