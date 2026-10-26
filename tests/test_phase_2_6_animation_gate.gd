extends SceneTree

func _init() -> void:
	var passed: int = 0
	var failed: int = 0
	var player_library: AnimationLibrary = load("res://characters/player/visual/player_animations.tres") as AnimationLibrary
	var player_required: Array[String] = ["idle", "walk", "sprint", "jump", "fall", "dodge", "attack_1", "attack_2", "attack_3", "guard", "hit_react", "death"]
	for clip_name: String in player_required:
		if player_library != null and player_library.has_animation(clip_name):
			passed += 1
		else:
			failed += 1
			printerr("MISSING_PLAYER_CLIP ", clip_name)

	var soldier_library: AnimationLibrary = load("res://characters/enemies/soldier/soldier_animations.tres") as AnimationLibrary
	var soldier_required: Array[String] = ["idle", "telegraph", "attack", "stagger", "death"]
	for clip_name: String in soldier_required:
		if soldier_library != null and soldier_library.has_animation(clip_name):
			passed += 1
		else:
			failed += 1
			printerr("MISSING_SOLDIER_CLIP ", clip_name)

	var player_scene: PackedScene = load("res://characters/player/player.tscn") as PackedScene
	var soldier_scene: PackedScene = load("res://characters/enemies/soldier/soldier_enemy.tscn") as PackedScene
	var player: Node = player_scene.instantiate()
	var soldier: Node = soldier_scene.instantiate()
	root.add_child(player)
	root.add_child(soldier)
	await process_frame
	var player_model: PlayerCharacterModel = player.get_node("VisualRoot/PlayerCharacterModel") as PlayerCharacterModel
	var soldier_anim: AnimationPlayer = soldier.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if player_model != null and player_model.anim_player != null and player_model.anim_player.has_animation("idle"):
		passed += 1
	else:
		failed += 1
		printerr("PLAYER_RUNTIME_ANIMATION_PLAYER_MISSING")
	if soldier_anim != null and soldier_anim.has_animation("soldier/attack"):
		passed += 1
	else:
		failed += 1
		printerr("SOLDIER_RUNTIME_ATTACK_MISSING")
	var jump_animation: Animation = player_model.anim_player.get_animation("jump") if player_model != null and player_model.anim_player != null else null
	if jump_animation != null and jump_animation.get_track_count() == 7:
		var right_arm_track: int = _find_track(jump_animation, "Shibahu_RightArm_0165_220")
		var left_arm_track: int = _find_track(jump_animation, "Shibahu_LeftArm_0100_155")
		if _track_is_constant(jump_animation, right_arm_track) and _track_is_constant(jump_animation, left_arm_track):
			passed += 1
		else:
			failed += 1
			printerr("JUMP_ARMS_NOT_STABILIZED")
	else:
		failed += 1
		printerr("JUMP_CLIP_INVALID")
	if player_model != null and player_model.skeleton != null and player_model.secondary_motion != null:
		var secondary = player_model.secondary_motion
		var bust_bone: int = -1
		for chain: Dictionary in secondary.get_chains():
			if chain["group"] == &"accessories" and String(chain["label"]).begins_with("bust L"):
				bust_bone = int(chain["root_bone"])
		var latest: Array[Quaternion] = [Quaternion.IDENTITY]
		var sample := func() -> void:
			latest[0] = player_model.skeleton.get_bone_pose_rotation(bust_bone)
		player_model.skeleton.skeleton_updated.connect(sample)
		for _i in range(10):
			await process_frame
		var bust_before: Quaternion = latest[0]
		secondary.apply_impulse(Vector3(5.0, 0.0, 0.0))
		for _i in range(16):
			await process_frame
		var bust_after: Quaternion = latest[0]
		player_model.skeleton.skeleton_updated.disconnect(sample)
		if bust_bone >= 0 and bust_before.angle_to(bust_after) > deg_to_rad(0.05):
			passed += 1
		else:
			failed += 1
			printerr("SECONDARY_BUST_SPRING_NOT_MOVING")
	else:
		failed += 1
		printerr("PLAYER_SECONDARY_SKELETON_MISSING")

	print("PHASE_2_6_ANIMATION_GATE passed=%d failed=%d" % [passed, failed])
	player.free()
	soldier.free()
	quit(1 if failed > 0 else 0)

func _find_track(animation: Animation, bone_name: String) -> int:
	for index in range(animation.get_track_count()):
		if String(animation.track_get_path(index)).contains(bone_name):
			return index
	return -1

func _track_is_constant(animation: Animation, track_index: int) -> bool:
	if track_index < 0 or animation.track_get_key_count(track_index) < 2:
		return false
	var first: Quaternion = animation.track_get_key_value(track_index, 0) as Quaternion
	for key_index in range(1, animation.track_get_key_count(track_index)):
		var value: Quaternion = animation.track_get_key_value(track_index, key_index) as Quaternion
		if not value.is_equal_approx(first):
			return false
	return true
