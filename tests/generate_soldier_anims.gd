extends SceneTree

static var _soldier_rest_quats: Dictionary = {}

func _init() -> void:
	print("--- Generating accurate Soldier Enemy animations with arms down ---")
	var packed = load("res://characters/enemies/soldier/anime-girl_running_panic.glb")
	var inst: Node3D = packed.instantiate()
	root.add_child(inst)
	
	var ap: AnimationPlayer = inst.find_child("AnimationPlayer", true, false)
	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	var path_to_skel = inst.get_path_to(skel)
	
	for i in range(skel.get_bone_count()):
		var bname = skel.get_bone_name(i)
		_soldier_rest_quats[bname] = skel.get_bone_rest(i).basis.get_rotation_quaternion()
		
	var lib = AnimationLibrary.new()
	lib.add_animation("idle", _create_idle(path_to_skel))
	lib.add_animation("telegraph", _create_telegraph(path_to_skel))
	lib.add_animation("attack", _create_attack(path_to_skel))
	lib.add_animation("stagger", _create_stagger(path_to_skel))
	lib.add_animation("death", _create_death(path_to_skel))
	
	ResourceSaver.save(lib, "res://characters/enemies/soldier/soldier_animations.tres")
	print("Saved soldier_animations.tres successfully")
	
	inst.free()
	quit(0)

static func _bone_q(bone_name: String, x_deg: float, y_deg: float, z_deg: float) -> Quaternion:
	var delta = Quaternion.from_euler(Vector3(deg_to_rad(x_deg), deg_to_rad(y_deg), deg_to_rad(z_deg)))
	if _soldier_rest_quats.has(bone_name):
		return (_soldier_rest_quats[bone_name] as Quaternion) * delta
	return delta

static func _add_rot(anim: Animation, skel_path: NodePath, bone_name: String, times: Array, eulers: Array) -> void:
	var t = anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(t, String(skel_path) + ":" + bone_name)
	for i in range(times.size()):
		var eul: Vector3 = eulers[i]
		var q = _bone_q(bone_name, eul.x, eul.y, eul.z)
		anim.rotation_track_insert_key(t, times[i], q)

# In bind pose, arms are horizontal (T-pose).
# To bring arms down to natural sides: R_Arm Z = -70 deg, L_Arm Z = +70 deg.
static func _create_idle(skel_path: NodePath) -> Animation:
	var a = Animation.new()
	a.length = 2.0
	a.loop_mode = Animation.LOOP_LINEAR
	_add_rot(a, skel_path, "CC_Base_R_Upperarm_90", [0.0, 1.0, 2.0],
		[Vector3(0, 0, -70), Vector3(0, 0, -68), Vector3(0, 0, -70)])
	_add_rot(a, skel_path, "CC_Base_L_Upperarm_66", [0.0, 1.0, 2.0],
		[Vector3(0, 0, 70), Vector3(0, 0, 68), Vector3(0, 0, 70)])
	_add_rot(a, skel_path, "CC_Base_R_Forearm_89", [0.0, 1.0, 2.0],
		[Vector3(15, 0, 0), Vector3(15, 0, 0), Vector3(15, 0, 0)])
	_add_rot(a, skel_path, "CC_Base_L_Forearm_63", [0.0, 1.0, 2.0],
		[Vector3(15, 0, 0), Vector3(15, 0, 0), Vector3(15, 0, 0)])
	_add_rot(a, skel_path, "CC_Base_Spine01_97", [0.0, 1.0, 2.0],
		[Vector3.ZERO, Vector3(2, 0, 0), Vector3.ZERO])
	return a

static func _create_telegraph(skel_path: NodePath) -> Animation:
	var a = Animation.new()
	a.length = 0.65
	a.loop_mode = Animation.LOOP_NONE
	# Raise right arm up high with weapon, left arm balances
	_add_rot(a, skel_path, "CC_Base_R_Upperarm_90", [0.0, 0.35, 0.65],
		[Vector3(0, 0, -70), Vector3(-45, 20, 25), Vector3(-65, 30, 35)])
	_add_rot(a, skel_path, "CC_Base_R_Forearm_89", [0.0, 0.35, 0.65],
		[Vector3(15, 0, 0), Vector3(45, 0, 0), Vector3(60, 0, 0)])
	_add_rot(a, skel_path, "CC_Base_L_Upperarm_66", [0.0, 0.35, 0.65],
		[Vector3(0, 0, 70), Vector3(0, 0, 45), Vector3(-20, 0, 40)])
	_add_rot(a, skel_path, "CC_Base_Spine01_97", [0.0, 0.35, 0.65],
		[Vector3.ZERO, Vector3(-5, -12, 0), Vector3(-8, -18, 0)])
	return a

static func _create_attack(skel_path: NodePath) -> Animation:
	var a = Animation.new()
	a.length = 0.5
	a.loop_mode = Animation.LOOP_NONE
	# Downward/forward strike
	_add_rot(a, skel_path, "CC_Base_R_Upperarm_90", [0.0, 0.15, 0.5],
		[Vector3(-65, 30, 35), Vector3(35, -20, -45), Vector3(0, 0, -70)])
	_add_rot(a, skel_path, "CC_Base_R_Forearm_89", [0.0, 0.15, 0.5],
		[Vector3(60, 0, 0), Vector3(15, 0, 0), Vector3(15, 0, 0)])
	_add_rot(a, skel_path, "CC_Base_L_Upperarm_66", [0.0, 0.15, 0.5],
		[Vector3(-20, 0, 40), Vector3(20, 0, 50), Vector3(0, 0, 70)])
	_add_rot(a, skel_path, "CC_Base_Spine01_97", [0.0, 0.15, 0.5],
		[Vector3(-8, -18, 0), Vector3(12, 15, 0), Vector3.ZERO])
	return a

static func _create_stagger(skel_path: NodePath) -> Animation:
	var a = Animation.new()
	a.length = 0.8
	a.loop_mode = Animation.LOOP_NONE
	_add_rot(a, skel_path, "CC_Base_R_Upperarm_90", [0.0, 0.15, 0.8],
		[Vector3(0, 0, -70), Vector3(-20, 0, -40), Vector3(0, 0, -70)])
	_add_rot(a, skel_path, "CC_Base_L_Upperarm_66", [0.0, 0.15, 0.8],
		[Vector3(0, 0, 70), Vector3(-20, 0, 40), Vector3(0, 0, 70)])
	_add_rot(a, skel_path, "CC_Base_Spine01_97", [0.0, 0.15, 0.8],
		[Vector3.ZERO, Vector3(-22, 5, 0), Vector3.ZERO])
	_add_rot(a, skel_path, "CC_Base_Head_41", [0.0, 0.15, 0.8],
		[Vector3.ZERO, Vector3(-18, -8, 0), Vector3.ZERO])
	return a

static func _create_death(skel_path: NodePath) -> Animation:
	var a = Animation.new()
	a.length = 1.0
	a.loop_mode = Animation.LOOP_NONE
	_add_rot(a, skel_path, "CC_Base_R_Upperarm_90", [0.0, 0.4, 1.0],
		[Vector3(0, 0, -70), Vector3(20, 0, -50), Vector3(30, 0, -40)])
	_add_rot(a, skel_path, "CC_Base_L_Upperarm_66", [0.0, 0.4, 1.0],
		[Vector3(0, 0, 70), Vector3(20, 0, 50), Vector3(30, 0, 40)])
	_add_rot(a, skel_path, "CC_Base_Spine01_97", [0.0, 0.4, 1.0],
		[Vector3.ZERO, Vector3(-30, 0, 0), Vector3(-65, 0, 20)])
	return a
