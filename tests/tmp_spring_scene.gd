extends Node3D

func _ready() -> void:
	var sk: Skeleton3D = $Skeleton3D
	var sim: SpringBoneSimulator3D = $Skeleton3D/Spring
	var count := [0]
	sim.modification_processed.connect(func():
		count[0] += 1
		if count[0] % 10 == 0:
			print("MOD n=", count[0], " b0=", sk.get_bone_pose_rotation(0), " b1=", sk.get_bone_pose_rotation(1))
	)
	sk.skeleton_updated.connect(func():
		if count[0] > 0 and count[0] % 10 == 0:
			print("SKEL_UP n=", count[0], " b0=", sk.get_bone_pose_rotation(0), " b1=", sk.get_bone_pose_rotation(1))
	)
	for i in range(45):
		await get_tree().process_frame
	print("final modifications=", count[0], " b0=", sk.get_bone_pose_rotation(0))
	get_tree().quit(0)
