extends SceneTree

## Dev-only prototype: verify SpringBoneSimulator3D behavior on the real 211-bone
## protagonist skeleton at its imported 0.01 scale.

const MODEL: String = "res://characters/player/visual/player_character_model.tscn"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var model: Node3D = (load(MODEL) as PackedScene).instantiate() as Node3D
	root.add_child(model)
	await process_frame
	await process_frame
	var skeleton: Skeleton3D = model.find_child("Skeleton3D", true, false) as Skeleton3D
	var anim: AnimationPlayer = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if skeleton == null:
		printerr("NO_SKELETON")
		quit(1)
		return
	print("skeleton_global_basis_scale=", skeleton.global_transform.basis.get_scale())
	var tail_root: int = skeleton.find_bone("Shibahu_Tail1_0199_241")
	var tail_end: int = skeleton.find_bone("Shibahu_Tail7_0205_235")
	var sim := SpringBoneSimulator3D.new()
	sim.name = "PrototypeSpring"
	skeleton.add_child(sim)
	sim.set_setting_count(1)
	sim.set_root_bone(0, tail_root)
	sim.set_end_bone(0, tail_end)
	sim.set_rotation_axis(0, SpringBoneSimulator3D.ROTATION_AXIS_ALL)
	sim.set_stiffness(0, 0.9)
	sim.set_drag(0, 0.45)
	sim.set_gravity(0, 0.25)
	sim.set_radius(0, 0.03)
	sim.set_center_from(0, SpringBoneSimulator3D.CENTER_FROM_WORLD_ORIGIN)
	print("sim_parent=", sim.get_parent().name, " settings=", sim.get_setting_count())
	anim.play("sprint")
	# Move the whole model to generate world-space inertia.
	for frame in range(90):
		model.position.x += 0.06
		await process_frame
		if frame % 15 == 0:
			_print_pose(skeleton, tail_end, "moving f%d" % frame)
	# Stop abruptly and observe settling.
	for frame in range(120):
		await process_frame
		if frame % 20 == 0:
			_print_pose(skeleton, tail_end, "settle f%d" % frame)
	sim.queue_free()
	model.queue_free()
	await process_frame
	quit(0)


func _print_pose(skeleton: Skeleton3D, bone_idx: int, label: String) -> void:
	var global_pose: Transform3D = skeleton.get_bone_global_pose(bone_idx)
	var pose: Quaternion = skeleton.get_bone_pose_rotation(bone_idx)
	print("%s tail7_origin_local=%s pose_quat=%s" % [label, skeleton.get_bone_pose_position(bone_idx), pose])
