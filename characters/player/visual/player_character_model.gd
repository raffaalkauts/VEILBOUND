class_name PlayerCharacterModel
extends Node3D

const UAL_SCENE: PackedScene = preload("res://assets/animations/quaternius/universal_animation_library_standard.glb")
const SECONDARY_MOTION_SCRIPT = preload("res://characters/player/visual/player_secondary_motion.gd")

## Stylized 3D Character Model for VEILBOUND Protagonist
## Genuine imported 3D anime fox-girl model with full humanoid armature,
## 211 bones, PBR textures, fox ears, bushy tail, and functional katana equipment.

@onready var anim_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
@onready var fox_mesh: Node3D = get_node_or_null("FoxGirlMesh")
@onready var skeleton: Skeleton3D = null

# Equipment references
@onready var equipment_root: Node3D = get_node_or_null("EquipmentRoot")
@onready var katana_in_hand: Node3D = get_node_or_null("EquipmentRoot/KatanaInHand")
@onready var sheathed_hilt: MeshInstance3D = get_node_or_null("EquipmentRoot/SheathedHilt")
@onready var scabbard: MeshInstance3D = get_node_or_null("EquipmentRoot/Scabbard")

# Full-body secondary motion (native SpringBoneSimulator3D chains).
var secondary_motion: RefCounted = null

# Bone attachments
var hand_attachment: BoneAttachment3D = null
var hip_attachment: BoneAttachment3D = null

var _is_dead: bool = false
var _is_weapon_drawn: bool = false
var _ual_retargeted: bool = false


## The spring simulators must be children of the Skeleton3D before it enters
## the tree, otherwise Skeleton3D builds its modifier list without them.
func _enter_tree() -> void:
	var spring_skeleton: Skeleton3D = find_child("Skeleton3D", true, false) as Skeleton3D
	if spring_skeleton == null:
		return
	secondary_motion = SECONDARY_MOTION_SCRIPT.new()
	if not secondary_motion.setup(spring_skeleton):
		push_warning("Player secondary motion could not find the expected bone chains.")
		secondary_motion = null


func _ready() -> void:
	_resolve_nodes()
	# The protagonist has a non-standard 211-bone rest pose. The inspected
	# Quaternius source rig is retained in the project for provenance, but its
	# generic rest-pose correction is not applied at runtime: it produced an
	# arms-out pose on this skinned target. The target-compatible library below
	# remains authoritative until a verified humanoid BoneMap retarget is ready.
	_retarget_quaternius_clips()
	_setup_bone_attachments()
	_hide_display_props()
	set_combat_mode(false)
	play_animation("idle")


func _resolve_nodes() -> void:
	if anim_player == null:
		anim_player = get_node_or_null("AnimationPlayer") as AnimationPlayer
	if anim_player == null:
		anim_player = find_child("AnimationPlayer", false, false) as AnimationPlayer
	if anim_player != null and not anim_player.has_animation("idle"):
		var lib: AnimationLibrary = load("res://characters/player/visual/player_animations.tres") as AnimationLibrary
		if lib != null:
			if anim_player.has_animation_library(""):
				anim_player.remove_animation_library("")
			anim_player.add_animation_library("", lib)
	if fox_mesh == null:
		fox_mesh = find_child("FoxGirlMesh", true, false) as Node3D
	if skeleton == null and fox_mesh != null:
		skeleton = fox_mesh.find_child("Skeleton3D", true, false) as Skeleton3D
	if equipment_root == null:
		equipment_root = find_child("EquipmentRoot", true, false) as Node3D
	if katana_in_hand == null:
		katana_in_hand = find_child("KatanaInHand", true, false) as Node3D
	if sheathed_hilt == null:
		sheathed_hilt = find_child("SheathedHilt", true, false) as MeshInstance3D
	if scabbard == null:
		scabbard = find_child("Scabbard", true, false) as MeshInstance3D

	if skeleton != null:
		# Secondary motion is configured in _enter_tree by PlayerSecondaryMotion.
		pass


## Runtime retarget of Quaternius UAL clips onto this rig (global-rotation
## transfer, see UalRetargeter). jump/fall intentionally remain the authored
## clips from player_animations.tres (Phase 2.6 gate contract).
## Attack clips are warped so the swing apex lands inside the damage window
## defined by MeleeAttackComponent.attacks (startup/active/recovery).
func _retarget_quaternius_clips() -> void:
	if _ual_retargeted or anim_player == null or skeleton == null:
		return
	var source_instance := UAL_SCENE.instantiate() as Node3D
	if source_instance == null:
		return
	add_child(source_instance)
	source_instance.visible = false
	var source_player := source_instance.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var source_skeleton := source_instance.find_child("Skeleton3D", true, false) as Skeleton3D
	if source_player == null or source_skeleton == null or not source_player.has_animation_library(""):
		source_instance.queue_free()
		return
	var source_library := source_player.get_animation_library("")
	var target_library := anim_player.get_animation_library("")
	if target_library == null:
		source_instance.queue_free()
		return
	var retargeter := UalRetargeter.new()
	retargeter.setup(skeleton, self, Callable(self, "_map_ual_bone"), {
		"thigh_r": "Shibahu_RightUpLeg_0193_232",
		"thigh_l": "Shibahu_LeftUpLeg_0189_228",
		"head": "Shibahu_Head_05_130",
		"hips": "Shibahu_Hips_00_245",
	}, "Shibahu_Hips_00_245")
	# target clip -> [source clip, loop, total length (0 = keep), apex source time, apex target time]
	# Apex source time 0.875 s is the Sword_Attack swing apex (57% of 1.533 s,
	# measured in Phase 2.8 strike-window probe).
	var clip_map: Dictionary = {
		"idle": ["Idle", true, 0.0, 0.0, 0.0],
		"walk": ["Walk", true, 0.0, 0.0, 0.0],
		"sprint": ["Sprint", true, 0.0, 0.0, 0.0],
		"dodge": ["Roll", false, 0.5, 0.0, 0.0],
		"attack_1": ["Sword_Attack", false, 0.58, 0.875, 0.22],
		"attack_2": ["Sword_Attack", false, 0.65, 0.875, 0.25],
		"attack_3": ["Sword_Attack", false, 0.80, 0.875, 0.31],
		"guard": ["Sword_Idle", true, 0.0, 0.0, 0.0],
		"hit_react": ["Hit_Chest", false, 0.25, 0.0, 0.0],
		"death": ["Death01", false, 0.0, 0.0, 0.0],
	}
	for target_name: String in clip_map:
		var spec: Array = clip_map[target_name]
		var source_name: String = spec[0]
		if not source_library.has_animation(source_name):
			continue
		var retargeted: Animation = retargeter.retarget(source_library.get_animation(source_name), source_name, source_skeleton, source_player)
		if retargeted == null or retargeted.get_track_count() == 0:
			continue
		var total_length: float = spec[2]
		if total_length > 0.0:
			if float(spec[3]) > 0.0:
				UalRetargeter.warp(retargeted, spec[3], spec[4], total_length)
			else:
				UalRetargeter.retime(retargeted, total_length)
		retargeted.loop_mode = Animation.LOOP_LINEAR if spec[1] else Animation.LOOP_NONE
		if target_library.has_animation(target_name):
			target_library.remove_animation(target_name)
		target_library.add_animation(target_name, retargeted)
	_ual_retargeted = true
	source_instance.queue_free()


func _map_ual_bone(source_bone: String) -> String:
	var normalized := source_bone.trim_prefix("DEF-")
	var left := normalized.ends_with(".L")
	if left or normalized.ends_with(".R"):
		normalized = normalized.substr(0, normalized.length() - 2)
	match normalized:
		"hips": return "Shibahu_Hips_00_245"
		"spine.001": return "Shibahu_Spine_01_224"
		"spine.002": return "Shibahu_Spine1_02_223"
		"spine.003": return "Shibahu_Spine2_03_222"
		"neck": return "Shibahu_Neck_04_131"
		"head": return "Shibahu_Head_05_130"
		"shoulder": return "Shibahu_LeftShoulder_099_156" if left else "Shibahu_RightShoulder_0164_221"
		"upper_arm": return "Shibahu_LeftArm_0100_155" if left else "Shibahu_RightArm_0165_220"
		"forearm": return "Shibahu_LeftForeArm_0101_154" if left else "Shibahu_RightForeArm_0166_219"
		"hand": return "Shibahu_LeftHand_0102_152" if left else "Shibahu_RightHand_0167_217"
		"thigh": return "Shibahu_LeftUpLeg_0189_228" if left else "Shibahu_RightUpLeg_0193_232"
		"shin": return "Shibahu_LeftLeg_0190_227" if left else "Shibahu_RightLeg_0194_231"
		"foot": return "Shibahu_LeftFoot_0191_226" if left else "Shibahu_RightFoot_0195_230"
		_: return ""


func _hide_display_props() -> void:
	if fox_mesh != null:
		var base_mesh: Node = fox_mesh.find_child("base_mesh_1", true, false)
		if base_mesh is Node3D:
			(base_mesh as Node3D).visible = false
		var cube_mesh: Node = fox_mesh.find_child("Cube_286", true, false)
		if cube_mesh is Node3D:
			(cube_mesh as Node3D).visible = false


func _setup_bone_attachments() -> void:
	if skeleton == null:
		return

	# Right hand attachment for drawn Katana
	var r_hand_idx: int = skeleton.find_bone("Shibahu_RightHand_0167_217")
	if r_hand_idx != -1 and hand_attachment == null:
		hand_attachment = BoneAttachment3D.new()
		hand_attachment.name = "RightHandAttachment"
		hand_attachment.bone_name = "Shibahu_RightHand_0167_217"
		hand_attachment.bone_idx = r_hand_idx
		skeleton.add_child(hand_attachment)

		if katana_in_hand != null and katana_in_hand.get_parent() != hand_attachment:
			katana_in_hand.reparent(hand_attachment)
			# Scale is 100 inside the 0.01-scaled skeleton to restore 1.0 unit meter scale
			katana_in_hand.scale = Vector3(100.0, 100.0, 100.0)
			katana_in_hand.position = Vector3(0.0, 0.0, 0.0)
			# The katana mesh is authored along local +Y. Align that axis with
			# gameplay forward (-Z); +90deg X pointed the blade into the floor.
			katana_in_hand.rotation = Vector3(1.105, 0.0, 0.0)  # blade forward/~63deg up; see tests/inspect_player_katana_grip.gd

	# Left hip attachment for Sheathed Scabbard and Hilt
	var hip_idx: int = skeleton.find_bone("Shibahu_Hips_00_245")
	if hip_idx != -1 and hip_attachment == null:
		hip_attachment = BoneAttachment3D.new()
		hip_attachment.name = "HipAttachment"
		hip_attachment.bone_name = "Shibahu_Hips_00_245"
		hip_attachment.bone_idx = hip_idx
		skeleton.add_child(hip_attachment)

		if scabbard != null and scabbard.get_parent() != hip_attachment:
			scabbard.reparent(hip_attachment)
			scabbard.scale = Vector3(100.0, 100.0, 100.0)
			scabbard.position = Vector3(16.0, -2.0, 4.0)
			scabbard.rotation = Vector3(deg_to_rad(25.0), deg_to_rad(-15.0), deg_to_rad(30.0))

		if sheathed_hilt != null and sheathed_hilt.get_parent() != hip_attachment:
			sheathed_hilt.reparent(hip_attachment)
			sheathed_hilt.scale = Vector3(100.0, 100.0, 100.0)
			sheathed_hilt.position = Vector3(20.0, 22.0, -20.0)
			sheathed_hilt.rotation = Vector3(deg_to_rad(25.0), deg_to_rad(-15.0), deg_to_rad(30.0))


## Plays an animation if present in AnimationPlayer, handles missing clips safely
func play_animation(anim_name: String, blend_time: float = 0.15, force_restart: bool = false) -> bool:
	_resolve_nodes()
	if anim_player == null or _is_dead:
		return false
	if anim_player.has_animation(anim_name):
		if force_restart or anim_player.current_animation != anim_name:
			anim_player.play(anim_name, blend_time)
		return true
	return false


func get_animation_length(anim_name: String, fallback: float = 0.0) -> float:
	_resolve_nodes()
	if anim_player == null or not anim_player.has_animation(anim_name):
		return fallback
	var animation := anim_player.get_animation(anim_name)
	return animation.length if animation != null else fallback


## Toggles weapon draw: katana in hand vs sheathed on hip
func set_combat_mode(drawn: bool) -> void:
	_resolve_nodes()
	_is_weapon_drawn = drawn
	if katana_in_hand != null:
		katana_in_hand.visible = drawn
	if sheathed_hilt != null:
		sheathed_hilt.visible = not drawn
	if scabbard != null:
		scabbard.visible = not drawn


func is_weapon_drawn() -> bool:
	return _is_weapon_drawn


## Feeds locomotion/combat transients into the native spring chains.
## The authored animation still owns the body pose; the simulators only add
## inertia and follow-through on top of it.
func update_secondary_motion(delta: float, horizontal_speed: float, is_in_air: bool, is_guarding: bool, is_attacking: bool) -> void:
	if _is_dead or secondary_motion == null:
		return
	secondary_motion.update(delta, horizontal_speed, is_in_air, is_guarding, is_attacking)


func trigger_hit_react() -> void:
	if _is_dead:
		return
	_resolve_nodes()
	if secondary_motion != null:
		secondary_motion.apply_impulse(Vector3(0.0, 0.15, 0.55))
	if anim_player != null and anim_player.has_animation("hit_react"):
		anim_player.play("hit_react", 0.05)


func set_dead(dead: bool) -> void:
	_is_dead = dead
	if _is_dead:
		set_combat_mode(false)
		_resolve_nodes()
		if secondary_motion != null:
			secondary_motion.reset()
		if anim_player != null and anim_player.has_animation("death"):
			anim_player.play("death", 0.1)


func is_dead() -> bool:
	return _is_dead


func reset_pose() -> void:
	_is_dead = false
	_resolve_nodes()
	if secondary_motion != null:
		secondary_motion.reset()
	set_combat_mode(false)
	if anim_player != null and anim_player.has_animation("idle"):
		anim_player.play("idle", 0.1)
