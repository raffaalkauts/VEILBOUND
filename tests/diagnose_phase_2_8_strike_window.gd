extends SceneTree

## Phase 2.8: verifies the retargeted Soldier attack's strike apex lands
## inside the damage window (ATTACK_ACTIVE_START 0.35 s + 0.12 s duration of
## the 0.65 s retimed clip) by sampling the weapon tip trajectory.

var _out: FileAccess


func _log(line: String) -> void:
	print(line)
	if _out != null:
		_out.store_line(line)
		_out.flush()


func _init() -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/phase_2_8")
	_out = FileAccess.open("res://.godot/phase_2_8/strike_window.txt", FileAccess.WRITE)
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
	var weapon: MeshInstance3D = soldier.weapon_mesh
	if weapon == null:
		weapon = soldier.find_child("WeaponMesh", true, false) as MeshInstance3D
	var ap: AnimationPlayer = soldier.anim_player
	var clip: Animation = ap.get_animation("soldier_ual/attack")
	var length: float = clip.length
	_log("[STRIKE] attack_clip_length=%.3f window=[0.35, 0.47] weapon=%s" % [length, str(weapon)])

	# Weapon tip candidates: AABB endpoints of the weapon mesh (global space),
	# tracked as the extreme point along the soldier's facing direction.
	var aabb: AABB = weapon.get_aabb()
	var candidates: Array[Vector3] = [
		aabb.position, aabb.position + Vector3(aabb.size.x, 0, 0),
		aabb.position + Vector3(0, aabb.size.y, 0), aabb.position + Vector3(0, 0, aabb.size.z),
		aabb.position + aabb.size,
		aabb.position + Vector3(aabb.size.x, aabb.size.y, 0),
		aabb.position + Vector3(aabb.size.x, 0, aabb.size.z),
		aabb.position + Vector3(0, aabb.size.y, aabb.size.z),
	]

	# Forward extent only: the soldier faces -Z, so the strike reach is the
	# most negative local z of the tip across the swing.
	var sample_count: int = 22
	var times: Array[float] = []
	for index in range(sample_count):
		times.append(length * float(index) / float(sample_count - 1))
	var apex_time: float = -1.0
	var apex_forward: float = INF
	for time: float in times:
		ap.play("soldier_ual/attack", 0.0)
		ap.seek(time, true)
		for _i in range(2):
			await process_frame
		var soldier_to_global: Transform3D = soldier.global_transform.affine_inverse()
		var best_forward: float = INF
		var best_corner: Vector3 = Vector3.ZERO
		for corner: Vector3 in candidates:
			var tip_global: Vector3 = weapon.global_transform * corner
			var local: Vector3 = soldier_to_global * tip_global
			if local.z < best_forward:
				best_forward = local.z
				best_corner = local
		_log("[STRIKE] t=%.3f tip_local=(%.2f,%.2f,%.2f) forward=%.2f" % [time, best_corner.x, best_corner.y, best_corner.z, -best_forward])
		if best_forward < apex_forward:
			apex_forward = best_forward
			apex_time = time
	_log("[STRIKE] apex: t=%.3f forward_extent=%.2f in_damage_window=%s" % [
		apex_time, -apex_forward, str(apex_time >= 0.35 and apex_time <= 0.47)])
	_out.close()
	quit(0)
