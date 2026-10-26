extends SceneTree

## Phase 2.8 secondary-motion runtime audit (dev probe, no assertions).
## Runs the production main.tscn through a scripted locomotion/combat timeline,
## then reports per-chain activity (root/end bones from the real chain config),
## per-phase end-bone deflection, idle settle residual, and the CPU overhead of
## the native SpringBoneSimulator3D groups (on vs off).
## Output is also written to res://.godot/phase_2_8/spring_audit.txt so a killed
## process still leaves partial evidence on disk.

const PHASES: Array[Dictionary] = [
	{"label": "idle", "frames": 60},
	{"label": "sprint", "frames": 90},
	{"label": "hard_turn", "frames": 60},
	{"label": "jump_air", "frames": 45},
	{"label": "landing", "frames": 30},
	{"label": "dodge", "frames": 50},
	{"label": "attack", "frames": 110},
	{"label": "settle_idle", "frames": 60},
]
const REPORT_PATH: String = "res://.godot/phase_2_8/spring_audit.txt"

var _chains_state: Dictionary = {}
var _phase_total: Dictionary = {}
var _out: FileAccess


func _log(line: String) -> void:
	print(line)
	if _out != null:
		_out.store_line(line)
		_out.flush()


func _init() -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/phase_2_8")
	_out = FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	call_deferred("_run")


func _release_actions() -> void:
	for action: String in ["move_forward", "move_back", "move_left", "move_right", "sprint", "jump", "dodge", "guard", "attack"]:
		Input.action_release(action)


func _record_positions(model: Node, chains: Array[Dictionary], phase_label: String, first_frame: bool) -> void:
	var skeleton: Skeleton3D = model.secondary_motion.skeleton
	if skeleton == null:
		return
	var skeleton_transform: Transform3D = skeleton.global_transform
	for chain: Dictionary in chains:
		var end_index: int = int(chain["end_bone"])
		var root_index: int = int(chain["root_bone"])
		var root_pos: Vector3 = (skeleton_transform * skeleton.get_bone_global_pose(root_index)).origin
		var end_pos: Vector3 = (skeleton_transform * skeleton.get_bone_global_pose(end_index)).origin
		# Bend: the end bone position relative to the root cancels rigid body
		# translation, so sprint travel is not misread as chain deflection.
		var bend: Vector3 = end_pos - root_pos
		var id: String = String(chain["id"])
		if not _chains_state.has(id):
			_chains_state[id] = {
				"root_name": String(skeleton.get_bone_name(root_index)),
				"end_name": String(skeleton.get_bone_name(end_index)),
				"prev_bend": bend,
				"phase_start_bend": bend,
			}
		var state: Dictionary = _chains_state[id]
		if first_frame:
			state["phase_start_bend"] = bend
		var phase: Dictionary = _phase_total[phase_label]
		if not phase.has(id):
			phase[id] = {"motion": 0.0, "deflection": 0.0}
		var record: Dictionary = phase[id]
		record["motion"] = maxf(float(record["motion"]), bend.distance_to(Vector3(state["prev_bend"])))
		record["deflection"] = maxf(float(record["deflection"]), (bend - Vector3(state["phase_start_bend"])).length())
		state["prev_bend"] = bend


func _find_model(player: PlayerController) -> Node:
	var visual: Node = player.get_node("VisualRoot")
	for node in visual.find_children("*", "Node", true, false):
		if node.get("secondary_motion") != null:
			return node
	return null


func _timeline_cpu_cost(player: PlayerController, model: Node, springs_on: bool) -> void:
	var secondary: RefCounted = model.secondary_motion
	for group: StringName in secondary.get_group_names():
		secondary.set_group_enabled(group, springs_on)
	var frames_per_phase: int = 40
	var total_usec: int = 0
	for run_index in range(6):
		_release_actions()
		if run_index == 1:
			Input.action_press("move_forward")
			Input.action_press("sprint")
		elif run_index == 2:
			Input.action_press("dodge")
		elif run_index == 3:
			Input.action_press("attack")
		elif run_index == 4:
			player.stamina.reset_stamina()
		for _i in range(frames_per_phase):
			var before: int = Time.get_ticks_usec()
			await physics_frame
			total_usec += Time.get_ticks_usec() - before
	var frames: int = 6 * frames_per_phase
	var label: String = "on" if springs_on else "off"
	_log("[SPRING] cpu_physics_frame_%s=%.3f ms" % [label, float(total_usec) / float(frames) / 1000.0])


func _run() -> void:
	var main: Node = (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	_log("[SPRING] main scene loaded")
	var player: PlayerController = main.get_node("Player") as PlayerController
	var soldier: SoldierEnemy = main.get_node("SoldierEnemy") as SoldierEnemy
	player.health.is_invulnerable = true
	soldier.set_physics_process(false)
	var model: Node = _find_model(player)
	if model == null or model.get("secondary_motion") == null:
		_log("[SPRING] FATAL: production model or secondary motion not found")
		quit(1)
		return
	var secondary: RefCounted = model.secondary_motion
	var chains: Array[Dictionary] = secondary.get_chains()
	_log("[SPRING] chains=%d" % chains.size())
	for group: StringName in secondary.get_group_names():
		var sim: SpringBoneSimulator3D = secondary.get_simulator(group)
		_log("[SPRING]   group %-11s active=%s settings=%d" % [str(group), str(sim.active), sim.get_setting_count()])

	player.stamina.reset_stamina()
	_release_actions()
	_phase_total.clear()
	_chains_state.clear()
	var frame_index: int = 0
	for phase: Dictionary in PHASES:
		var label: String = String(phase["label"])
		_phase_total[label] = {}
		match label:
			"sprint":
				_release_actions()
				Input.action_press("move_forward")
				Input.action_press("sprint")
			"hard_turn":
				_release_actions()
				Input.action_press("move_back")
				Input.action_press("sprint")
			"jump_air":
				_release_actions()
				Input.action_press("move_forward")
				Input.action_press("jump")
			"dodge":
				_release_actions()
				Input.action_press("dodge")
				Input.action_press("move_forward")
			"attack":
				_release_actions()
				Input.action_press("attack")
			_:
				_release_actions()
		if label == "jump_air":
			await physics_frame
			await physics_frame
			Input.action_release("jump")
		var first: bool = true
		for _i in range(int(phase["frames"])):
			await physics_frame
			_record_positions(model, chains, label, first)
			first = false
		_log("[SPRING] phase %-10s done (through frame %d)" % [label, frame_index])
		frame_index += int(phase["frames"])
	_release_actions()

	await _timeline_cpu_cost(player, model, true)
	await _timeline_cpu_cost(player, model, false)

	for chain: Dictionary in chains:
		var id: String = String(chain["id"])
		var settle: Dictionary = _phase_total["settle_idle"]
		var residual: float = 0.0
		if settle.has(id):
			residual = float(settle[id]["motion"])
		var phases := []
		var any_motion: bool = false
		for phase: Dictionary in PHASES:
			var phase_label: String = String(phase["label"])
			var record: Dictionary = _phase_total[phase_label]
			if record.has(id):
				var deflection: float = float(record[id]["deflection"])
				phases.append("%s=%.0fmm" % [phase_label, deflection * 1000.0])
				if deflection > 0.004:
					any_motion = true
			else:
				phases.append("%s=-" % phase_label)
		var state: Dictionary = _chains_state.get(id, {})
		var root_label: String = String(state.get("root_name", str(chain["root_bone"])))
		var end_label: String = String(state.get("end_name", str(chain["end_bone"])))
		_log("[SPRING] %-14s %-11s %s->%s | %s | settle_residual=%.0fmm %s" % [
			id, str(chain["group"]), root_label, end_label,
			" ".join(phases), residual * 1000.0, "ACTIVE" if any_motion else "STIFF",
		])
	_log("[SPRING] audit complete")
	_out.close()
	quit(0)
