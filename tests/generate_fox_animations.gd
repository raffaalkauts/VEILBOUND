extends SceneTree

# Script to build and test all 12 skeletal animations for the fox girl character
const SKEL_REL_PATH = "FoxGirlMesh/Sketchfab_model/root/GLTF_SceneRootNode/Sketchfab_model_285/Shibahu_skechfab_fbx_284/Object_2_283/RootNode_282/Shibahu_Reference_281/Object_40_280/GLTF_created_0/Skeleton3D"

static var _rest_quats: Dictionary = {}

func _init() -> void:
	print("--- Generating anatomically accurate PlayerCharacterModel animations ---")
	_cache_rest_quaternions()
	var lib = build_player_animation_library()
	print("Built library with ", lib.get_animation_list().size(), " animations:")
	for anim_name in lib.get_animation_list():
		var a = lib.get_animation(anim_name)
		print("  ", anim_name, ": len=", a.length, " loop=", a.loop_mode, " tracks=", a.get_track_count())
	var err = ResourceSaver.save(lib, "res://characters/player/visual/player_animations.tres")
	print("Saved player_animations.tres: ", err)
	quit(0 if err == OK else 1)

static func _cache_rest_quaternions() -> void:
	if not _rest_quats.is_empty():
		return
	var packed = load("res://assets/characters/protagonist/imported/anime_fox_girl.glb")
	var inst: Node3D = packed.instantiate()
	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	for i in range(skel.get_bone_count()):
		var bname = skel.get_bone_name(i)
		_rest_quats[bname] = skel.get_bone_rest(i).basis.get_rotation_quaternion()
	inst.free()

static func build_player_animation_library() -> AnimationLibrary:
	_cache_rest_quaternions()
	var lib = AnimationLibrary.new()
	lib.add_animation("idle", _create_idle_anim())
	lib.add_animation("walk", _create_walk_anim())
	lib.add_animation("sprint", _create_sprint_anim())
	lib.add_animation("jump", _create_jump_anim())
	lib.add_animation("fall", _create_fall_anim())
	lib.add_animation("dodge", _create_dodge_anim())
	lib.add_animation("attack_1", _create_attack_1_anim())
	lib.add_animation("attack_2", _create_attack_2_anim())
	lib.add_animation("attack_3", _create_attack_3_anim())
	lib.add_animation("guard", _create_guard_anim())
	lib.add_animation("hit_react", _create_hit_react_anim())
	lib.add_animation("death", _create_death_anim())
	return lib

static func _bone_q(bone_name: String, x_deg: float, y_deg: float, z_deg: float) -> Quaternion:
	var delta = Quaternion.from_euler(Vector3(deg_to_rad(x_deg), deg_to_rad(y_deg), deg_to_rad(z_deg)))
	if _rest_quats.has(bone_name):
		return (_rest_quats[bone_name] as Quaternion) * delta
	return delta

static func _add_rot_track(anim: Animation, bone_name: String, times: Array, eulers: Array) -> void:
	var track = anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(track, SKEL_REL_PATH + ":" + bone_name)
	for i in range(times.size()):
		var eul: Vector3 = eulers[i]
		var q = _bone_q(bone_name, eul.x, eul.y, eul.z)
		anim.rotation_track_insert_key(track, times[i], q)

# --- 1. IDLE ---
static func _create_idle_anim() -> Animation:
	var a = Animation.new()
	a.length = 2.0
	a.loop_mode = Animation.LOOP_LINEAR
	# Breathing on spine
	_add_rot_track(a, "Shibahu_Spine_01_224", [0.0, 1.0, 2.0], [Vector3.ZERO, Vector3(2, 0, 0), Vector3.ZERO])
	_add_rot_track(a, "Shibahu_Spine1_02_223", [0.0, 1.0, 2.0], [Vector3.ZERO, Vector3(1.5, 0, 0), Vector3.ZERO])
	# Subtle arm sway
	_add_rot_track(a, "Shibahu_RightArm_0165_220", [0.0, 1.0, 2.0], [Vector3.ZERO, Vector3(0, 0, -2), Vector3.ZERO])
	_add_rot_track(a, "Shibahu_LeftArm_0100_155", [0.0, 1.0, 2.0], [Vector3.ZERO, Vector3(0, 0, 2), Vector3.ZERO])
	_add_rot_track(a, "Shibahu_Head_05_130", [0.0, 1.0, 2.0], [Vector3.ZERO, Vector3(-1, 0, 0), Vector3.ZERO])
	return a

# --- 2. WALK ---
static func _create_walk_anim() -> Animation:
	var a = Animation.new()
	a.length = 0.8
	a.loop_mode = Animation.LOOP_LINEAR
	_add_rot_track(a, "Shibahu_LeftUpLeg_0189_228", [0.0, 0.2, 0.4, 0.6, 0.8],
		[Vector3(20, 0, 0), Vector3.ZERO, Vector3(-20, 0, 0), Vector3.ZERO, Vector3(20, 0, 0)])
	_add_rot_track(a, "Shibahu_RightUpLeg_0193_232", [0.0, 0.2, 0.4, 0.6, 0.8],
		[Vector3(-20, 0, 0), Vector3.ZERO, Vector3(20, 0, 0), Vector3.ZERO, Vector3(-20, 0, 0)])
	_add_rot_track(a, "Shibahu_LeftLeg_0190_227", [0.0, 0.2, 0.4, 0.6, 0.8],
		[Vector3(5, 0, 0), Vector3(25, 0, 0), Vector3(5, 0, 0), Vector3(10, 0, 0), Vector3(5, 0, 0)])
	_add_rot_track(a, "Shibahu_RightLeg_0194_231", [0.0, 0.2, 0.4, 0.6, 0.8],
		[Vector3(5, 0, 0), Vector3(10, 0, 0), Vector3(5, 0, 0), Vector3(25, 0, 0), Vector3(5, 0, 0)])
	_add_rot_track(a, "Shibahu_RightArm_0165_220", [0.0, 0.4, 0.8],
		[Vector3(15, 0, 0), Vector3(-15, 0, 0), Vector3(15, 0, 0)])
	_add_rot_track(a, "Shibahu_LeftArm_0100_155", [0.0, 0.4, 0.8],
		[Vector3(-15, 0, 0), Vector3(15, 0, 0), Vector3(-15, 0, 0)])
	_add_rot_track(a, "Shibahu_Spine_01_224", [0.0, 0.4, 0.8],
		[Vector3(0, 3, 0), Vector3(0, -3, 0), Vector3(0, 3, 0)])
	return a

# --- 3. SPRINT ---
static func _create_sprint_anim() -> Animation:
	var a = Animation.new()
	a.length = 0.55
	a.loop_mode = Animation.LOOP_LINEAR
	_add_rot_track(a, "Shibahu_Spine_01_224", [0.0, 0.275, 0.55],
		[Vector3(12, 5, 0), Vector3(12, -5, 0), Vector3(12, 5, 0)])
	_add_rot_track(a, "Shibahu_LeftUpLeg_0189_228", [0.0, 0.275, 0.55],
		[Vector3(35, 0, 0), Vector3(-30, 0, 0), Vector3(35, 0, 0)])
	_add_rot_track(a, "Shibahu_RightUpLeg_0193_232", [0.0, 0.275, 0.55],
		[Vector3(-30, 0, 0), Vector3(35, 0, 0), Vector3(-30, 0, 0)])
	_add_rot_track(a, "Shibahu_LeftLeg_0190_227", [0.0, 0.15, 0.275, 0.42, 0.55],
		[Vector3(10, 0, 0), Vector3(55, 0, 0), Vector3(10, 0, 0), Vector3(20, 0, 0), Vector3(10, 0, 0)])
	_add_rot_track(a, "Shibahu_RightLeg_0194_231", [0.0, 0.15, 0.275, 0.42, 0.55],
		[Vector3(10, 0, 0), Vector3(20, 0, 0), Vector3(10, 0, 0), Vector3(55, 0, 0), Vector3(10, 0, 0)])
	_add_rot_track(a, "Shibahu_RightArm_0165_220", [0.0, 0.275, 0.55],
		[Vector3(35, 0, -10), Vector3(-35, 0, -10), Vector3(35, 0, -10)])
	_add_rot_track(a, "Shibahu_RightForeArm_0166_219", [0.0, 0.275, 0.55],
		[Vector3(40, 0, 0), Vector3(25, 0, 0), Vector3(40, 0, 0)])
	_add_rot_track(a, "Shibahu_LeftArm_0100_155", [0.0, 0.275, 0.55],
		[Vector3(-35, 0, 10), Vector3(35, 0, 10), Vector3(-35, 0, 10)])
	_add_rot_track(a, "Shibahu_LeftForeArm_0101_154", [0.0, 0.275, 0.55],
		[Vector3(25, 0, 0), Vector3(40, 0, 0), Vector3(25, 0, 0)])
	return a

# --- 4. JUMP ---
static func _create_jump_anim() -> Animation:
	var a = Animation.new()
	a.length = 0.5
	a.loop_mode = Animation.LOOP_NONE
	_add_rot_track(a, "Shibahu_Spine_01_224", [0.0, 0.15, 0.5],
		[Vector3(-5, 0, 0), Vector3(-10, 0, 0), Vector3(-4, 0, 0)])
	_add_rot_track(a, "Shibahu_LeftUpLeg_0189_228", [0.0, 0.2, 0.5],
		[Vector3.ZERO, Vector3(-20, 0, 0), Vector3(-12, 0, 0)])
	_add_rot_track(a, "Shibahu_RightUpLeg_0193_232", [0.0, 0.2, 0.5],
		[Vector3.ZERO, Vector3(-22, 0, 0), Vector3(-14, 0, 0)])
	_add_rot_track(a, "Shibahu_LeftLeg_0190_227", [0.0, 0.2, 0.5],
		[Vector3.ZERO, Vector3(35, 0, 0), Vector3(25, 0, 0)])
	_add_rot_track(a, "Shibahu_RightLeg_0194_231", [0.0, 0.2, 0.5],
		[Vector3.ZERO, Vector3(35, 0, 0), Vector3(25, 0, 0)])
	_add_rot_track(a, "Shibahu_RightArm_0165_220", [0.0, 0.2, 0.5],
		[Vector3.ZERO, Vector3(25, 0, -20), Vector3(15, 0, -15)])
	_add_rot_track(a, "Shibahu_LeftArm_0100_155", [0.0, 0.2, 0.5],
		[Vector3.ZERO, Vector3(-25, 0, 20), Vector3(-15, 0, 15)])
	return a

# --- 5. FALL ---
static func _create_fall_anim() -> Animation:
	var a = Animation.new()
	a.length = 0.5
	a.loop_mode = Animation.LOOP_LINEAR
	_add_rot_track(a, "Shibahu_Spine_01_224", [0.0, 0.25, 0.5],
		[Vector3(5, 0, 0), Vector3(7, 0, 0), Vector3(5, 0, 0)])
	_add_rot_track(a, "Shibahu_LeftUpLeg_0189_228", [0.0, 0.5], [Vector3(-10, 0, 5), Vector3(-10, 0, 5)])
	_add_rot_track(a, "Shibahu_RightUpLeg_0193_232", [0.0, 0.5], [Vector3(-10, 0, -5), Vector3(-10, 0, -5)])
	_add_rot_track(a, "Shibahu_LeftLeg_0190_227", [0.0, 0.5], [Vector3(20, 0, 0), Vector3(20, 0, 0)])
	_add_rot_track(a, "Shibahu_RightLeg_0194_231", [0.0, 0.5], [Vector3(20, 0, 0), Vector3(20, 0, 0)])
	_add_rot_track(a, "Shibahu_RightArm_0165_220", [0.0, 0.25, 0.5],
		[Vector3(20, 0, -25), Vector3(25, 0, -28), Vector3(20, 0, -25)])
	_add_rot_track(a, "Shibahu_LeftArm_0100_155", [0.0, 0.25, 0.5],
		[Vector3(-20, 0, 25), Vector3(-25, 0, 28), Vector3(-20, 0, 25)])
	return a

# --- 6. DODGE ---
static func _create_dodge_anim() -> Animation:
	var a = Animation.new()
	a.length = 0.5
	a.loop_mode = Animation.LOOP_NONE
	_add_rot_track(a, "Shibahu_Spine_01_224", [0.0, 0.15, 0.35, 0.5],
		[Vector3.ZERO, Vector3(30, 0, 0), Vector3(20, 0, 0), Vector3.ZERO])
	_add_rot_track(a, "Shibahu_LeftUpLeg_0189_228", [0.0, 0.2, 0.5],
		[Vector3.ZERO, Vector3(30, 0, 0), Vector3.ZERO])
	_add_rot_track(a, "Shibahu_RightUpLeg_0193_232", [0.0, 0.2, 0.5],
		[Vector3.ZERO, Vector3(30, 0, 0), Vector3.ZERO])
	_add_rot_track(a, "Shibahu_LeftLeg_0190_227", [0.0, 0.2, 0.5],
		[Vector3.ZERO, Vector3(45, 0, 0), Vector3.ZERO])
	_add_rot_track(a, "Shibahu_RightLeg_0194_231", [0.0, 0.2, 0.5],
		[Vector3.ZERO, Vector3(45, 0, 0), Vector3.ZERO])
	_add_rot_track(a, "Shibahu_RightArm_0165_220", [0.0, 0.2, 0.5],
		[Vector3.ZERO, Vector3(20, 10, -10), Vector3.ZERO])
	return a

# --- 7. ATTACK 1 (Diagonal Slash) ---
static func _create_attack_1_anim() -> Animation:
	var a = Animation.new()
	a.length = 0.58
	a.loop_mode = Animation.LOOP_NONE
	_add_rot_track(a, "Shibahu_RightArm_0165_220", [0.0, 0.16, 0.28, 0.58],
		[Vector3.ZERO, Vector3(-45, 30, -35), Vector3(35, -45, 30), Vector3.ZERO])
	_add_rot_track(a, "Shibahu_RightForeArm_0166_219", [0.0, 0.16, 0.28, 0.58],
		[Vector3.ZERO, Vector3(50, 0, 0), Vector3(15, 0, 0), Vector3.ZERO])
	_add_rot_track(a, "Shibahu_RightHand_0167_217", [0.0, 0.16, 0.28, 0.58],
		[Vector3.ZERO, Vector3(20, -15, 0), Vector3(-25, 20, 0), Vector3.ZERO])
	_add_rot_track(a, "Shibahu_Spine_01_224", [0.0, 0.16, 0.28, 0.58],
		[Vector3.ZERO, Vector3(0, -20, 0), Vector3(8, 25, 0), Vector3.ZERO])
	_add_rot_track(a, "Shibahu_LeftArm_0100_155", [0.0, 0.16, 0.28, 0.58],
		[Vector3.ZERO, Vector3(10, 0, 15), Vector3(-25, 0, 25), Vector3.ZERO])
	return a

# --- 8. ATTACK 2 (Horizontal Cleave) ---
static func _create_attack_2_anim() -> Animation:
	var a = Animation.new()
	a.length = 0.65
	a.loop_mode = Animation.LOOP_NONE
	_add_rot_track(a, "Shibahu_RightArm_0165_220", [0.0, 0.19, 0.31, 0.65],
		[Vector3.ZERO, Vector3(25, -45, 25), Vector3(-35, 45, -30), Vector3.ZERO])
	_add_rot_track(a, "Shibahu_RightForeArm_0166_219", [0.0, 0.19, 0.31, 0.65],
		[Vector3.ZERO, Vector3(40, 0, 0), Vector3(10, 0, 0), Vector3.ZERO])
	_add_rot_track(a, "Shibahu_RightHand_0167_217", [0.0, 0.19, 0.31, 0.65],
		[Vector3.ZERO, Vector3(0, -30, 15), Vector3(0, 30, -15), Vector3.ZERO])
	_add_rot_track(a, "Shibahu_Spine_01_224", [0.0, 0.19, 0.31, 0.65],
		[Vector3.ZERO, Vector3(5, 22, 0), Vector3(5, -28, 0), Vector3.ZERO])
	return a

# --- 9. ATTACK 3 (Overhead Heavy Finisher) ---
static func _create_attack_3_anim() -> Animation:
	var a = Animation.new()
	a.length = 0.8
	a.loop_mode = Animation.LOOP_NONE
	_add_rot_track(a, "Shibahu_RightArm_0165_220", [0.0, 0.24, 0.38, 0.8],
		[Vector3.ZERO, Vector3(-70, 15, 10), Vector3(45, -10, -5), Vector3.ZERO])
	_add_rot_track(a, "Shibahu_RightForeArm_0166_219", [0.0, 0.24, 0.38, 0.8],
		[Vector3.ZERO, Vector3(65, 0, 0), Vector3(10, 0, 0), Vector3.ZERO])
	_add_rot_track(a, "Shibahu_LeftArm_0100_155", [0.0, 0.24, 0.38, 0.8],
		[Vector3.ZERO, Vector3(-60, -15, -10), Vector3(35, 10, 5), Vector3.ZERO])
	_add_rot_track(a, "Shibahu_Spine_01_224", [0.0, 0.24, 0.38, 0.8],
		[Vector3.ZERO, Vector3(-15, 0, 0), Vector3(25, 0, 0), Vector3.ZERO])
	return a

# --- 10. GUARD (Two-Handed Defensive Stance) ---
static func _create_guard_anim() -> Animation:
	var a = Animation.new()
	a.length = 0.5
	a.loop_mode = Animation.LOOP_LINEAR
	_add_rot_track(a, "Shibahu_RightArm_0165_220", [0.0, 0.5],
		[Vector3(30, -25, 15), Vector3(30, -25, 15)])
	_add_rot_track(a, "Shibahu_RightForeArm_0166_219", [0.0, 0.5],
		[Vector3(55, 0, 0), Vector3(55, 0, 0)])
	_add_rot_track(a, "Shibahu_LeftArm_0100_155", [0.0, 0.5],
		[Vector3(-25, 20, 20), Vector3(-25, 20, 20)])
	_add_rot_track(a, "Shibahu_LeftForeArm_0101_154", [0.0, 0.5],
		[Vector3(60, 0, 0), Vector3(60, 0, 0)])
	_add_rot_track(a, "Shibahu_Spine_01_224", [0.0, 0.5],
		[Vector3(8, 0, 0), Vector3(8, 0, 0)])
	return a

# --- 11. HIT REACT ---
static func _create_hit_react_anim() -> Animation:
	var a = Animation.new()
	a.length = 0.25
	a.loop_mode = Animation.LOOP_NONE
	_add_rot_track(a, "Shibahu_Spine_01_224", [0.0, 0.08, 0.25],
		[Vector3.ZERO, Vector3(-18, 5, 0), Vector3.ZERO])
	_add_rot_track(a, "Shibahu_Head_05_130", [0.0, 0.08, 0.25],
		[Vector3.ZERO, Vector3(-15, -8, 0), Vector3.ZERO])
	_add_rot_track(a, "Shibahu_RightArm_0165_220", [0.0, 0.08, 0.25],
		[Vector3.ZERO, Vector3(15, 0, -20), Vector3.ZERO])
	return a

# --- 12. DEATH ---
static func _create_death_anim() -> Animation:
	var a = Animation.new()
	a.length = 1.0
	a.loop_mode = Animation.LOOP_NONE
	_add_rot_track(a, "Shibahu_Spine_01_224", [0.0, 0.4, 1.0],
		[Vector3.ZERO, Vector3(-35, 10, 0), Vector3(-70, 20, 15)])
	_add_rot_track(a, "Shibahu_LeftUpLeg_0189_228", [0.0, 0.4, 1.0],
		[Vector3.ZERO, Vector3(-25, 0, 15), Vector3(-50, 0, 30)])
	_add_rot_track(a, "Shibahu_RightUpLeg_0193_232", [0.0, 0.4, 1.0],
		[Vector3.ZERO, Vector3(-25, 0, -15), Vector3(-50, 0, -30)])
	_add_rot_track(a, "Shibahu_RightArm_0165_220", [0.0, 0.4, 1.0],
		[Vector3.ZERO, Vector3(25, 0, -35), Vector3(50, 0, -50)])
	_add_rot_track(a, "Shibahu_LeftArm_0100_155", [0.0, 0.4, 1.0],
		[Vector3.ZERO, Vector3(-25, 0, 35), Vector3(-50, 0, 50)])
	return a
