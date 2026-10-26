extends SceneTree

## Dev probe: directly compares transferred bone GLOBAL rotations on the
## production Soldier against the aligned source rig's rotations, per mapped
## bone, for clips Idle and Death01 at t=0.75.

const UAL_SCENE: PackedScene = preload("res://assets/animations/quaternius/universal_animation_library_standard.glb")

var _out: FileAccess


func _log(line: String) -> void:
	print(line)
	if _out != null:
		_out.store_line(line)
		_out.flush()


func _init() -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/phase_2_8")
	_out = FileAccess.open("res://.godot/phase_2_8/rotation_diff.txt", FileAccess.WRITE)
	call_deferred("_run")


func _run() -> void:
	var main: Node3D = (load("res://main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(main)
	await process_frame
	await process_frame
	var player: PlayerController = main.get_node("Player") as PlayerController
	var soldier: SoldierEnemy = main.get_node("SoldierEnemy") as SoldierEnemy
	player.health.is_invulnerable = true
	soldier.set_physics_process(false)
	var target_skeleton: Skeleton3D = soldier.skeleton
	var align: Quaternion = soldier._ual_align_cache
	if not soldier._ual_align_valid:
		_log("[DIFF] align invalid; aborting")
		quit(1)
		return

	# The build already freed the original source instance; instantiate a fresh copy.
	var source_player: AnimationPlayer = null
	var source_skeleton: Skeleton3D = null
	var source_instance: Node3D = UAL_SCENE.instantiate() as Node3D
	source_instance.name = "Phase28UALProbeSource"
	soldier.add_child(source_instance)
	source_instance.visible = false
	source_player = source_instance.find_child("AnimationPlayer", true, false) as AnimationPlayer
	source_skeleton = source_instance.find_child("Skeleton3D", true, false) as Skeleton3D
	_log("[DIFF] fresh source player=%s anims=%s" % [str(source_player), str(source_player.get_animation_list().slice(0, 30))])

	var pairs: Dictionary = {
		"hips": ["DEF-hips", "CC_Base_Pelvis_30"],
		"spine002": ["DEF-spine.002", "CC_Base_Spine01_97"],
		"spine003": ["DEF-spine.003", "CC_Base_Spine02_96"],
		"neck": ["DEF-neck", "CC_Base_NeckTwist02_42"],
		"head": ["DEF-head", "CC_Base_Head_41"],
		"uarm_r": ["DEF-upper_arm.R", "CC_Base_R_Upperarm_90"],
		"forearm_r": ["DEF-forearm.R", "CC_Base_R_Forearm_89"],
		"hand_r": ["DEF-hand.R", "CC_Base_R_Hand_88"],
		"thigh_r": ["DEF-thigh.R", "CC_Base_R_Thigh_29"],
		"shin_r": ["DEF-shin.R", "CC_Base_R_Calf_28"],
		"foot_r": ["DEF-foot.R", "CC_Base_R_Foot_24"],
	}
	var target_player: AnimationPlayer = soldier.anim_player
	var samples: Dictionary = {"Idle": [0.5, 0.75], "Death01": [0.75]}
	var target_clip_names: Dictionary = {"Idle": "soldier_ual/idle", "Death01": "soldier_ual/death"}
	for source_name: String in samples:
		var target_name: String = target_clip_names[source_name]
		if not target_player.has_animation(target_name):
			_log("[DIFF] missing %s" % target_name)
			continue
		for time: float in samples[source_name]:
			target_player.play(target_name)
			var target_anim: Animation = target_player.get_animation(target_name)
			target_player.seek(time * target_anim.length, true)
			await process_frame
			source_player.play(source_name)
			source_player.seek(time * source_player.get_animation(source_name).length, true)
			source_player.advance(0.0)
			for pair_name: String in pairs:
				var src_idx: int = source_skeleton.find_bone(String(pairs[pair_name][0]))
				var tgt_idx: int = target_skeleton.find_bone(String(pairs[pair_name][1]))
				if src_idx < 0 or tgt_idx < 0:
					_log("[DIFF] %s: bone missing src=%d tgt=%d" % [pair_name, src_idx, tgt_idx])
					continue
				var src_global: Quaternion = source_skeleton.get_bone_global_pose(src_idx).basis.get_rotation_quaternion()
				var tgt_global: Quaternion = target_skeleton.get_bone_global_pose(tgt_idx).basis.get_rotation_quaternion()
				var residual: Quaternion = (align.inverse() * tgt_global) * src_global.inverse()
				var anisotropic: float = residual.get_angle()
				# Also compare child-direction (bone limb axis) in model space.
				_log("[DIFF] %s t=%.2f %-9s residual_angle=%6.1f deg" % [source_name, time, pair_name, rad_to_deg(anisotropic)])
	_log("[DIFF] done")
	_out.close()
	quit(0)
