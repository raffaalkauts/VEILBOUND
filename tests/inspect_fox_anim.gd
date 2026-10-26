extends SceneTree

func _init() -> void:
	var packed = load("res://assets/characters/protagonist/imported/anime_fox_girl.glb")
	var inst: Node3D = packed.instantiate()
	root.add_child(inst)
	var ap: AnimationPlayer = inst.find_child("AnimationPlayer", true, false)
	if ap:
		var anim = ap.get_animation("Animation")
		print("Anim name: Animation, length: ", anim.length, " loop_mode: ", anim.loop_mode)
		print("Track count: ", anim.get_track_count())
		# Sample bone positions/rotations at time 0, 1, 2, 5, 8
		var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
		for t in [0.0, 1.0, 2.0, 4.0, 6.0, 8.0, 10.0]:
			print("--- Sample at t=", t, " ---")
			# check some key tracks
			for i in range(min(5, anim.get_track_count())):
				var path = anim.track_get_path(i)
				var key_idx = anim.track_find_key(i, t)
				var val = anim.track_get_key_value(i, key_idx)
				print("  Track ", path, " val=", val)
	inst.free()
	quit(0)
