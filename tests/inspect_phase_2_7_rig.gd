extends SceneTree

## Phase 2.7 dev-only probe: real skeleton, bone chain and skin-weight inventory.
## Usage: godot --headless --path . --script res://tests/inspect_phase_2_7_rig.gd

const OUT_DIR: String = "res://.godot/phase_2_7"
const PLAYER_MODEL: String = "res://characters/player/visual/player_character_model.tscn"
const SOLDIER_SCENE: String = "res://characters/enemies/soldier/soldier_enemy.tscn"
const KEYWORDS: Array[String] = [
	"tail", "hair", "ear", "bust", "skirt", "coat", "cloth", "sleeve", "belt", "sash",
	"ribbon", "scarf", "cape", "strap", "pouch", "tassel", "accessory",
]


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	call_deferred("_run")


func _run() -> void:
	await _inspect_model("player", PLAYER_MODEL)
	await _inspect_model("soldier", SOLDIER_SCENE)
	quit(0)


func _inspect_model(label: String, scene_path: String) -> void:
	var packed: PackedScene = load(scene_path) as PackedScene
	if packed == null:
		printerr("MISSING_SCENE ", scene_path)
		return
	var instance: Node = packed.instantiate()
	root.add_child(instance)
	await process_frame
	await process_frame

	var skeleton: Skeleton3D = instance.find_child("Skeleton3D", true, false) as Skeleton3D
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(instance, meshes)
	var lines: Array[String] = []
	lines.append("# %s rig report (%s)" % [label, scene_path])
	if skeleton == null:
		lines.append("NO_SKELETON")
		_write(label, lines)
		instance.queue_free()
		return

	lines.append("skeleton=%s bones=%d" % [skeleton.name, skeleton.get_bone_count()])
	lines.append("skeleton_scale=%s global=%s" % [skeleton.scale, skeleton.global_transform.basis.get_scale()])
	lines.append("")
	lines.append("## Full bone hierarchy")
	var roots: Array[int] = []
	for bone_idx in range(skeleton.get_bone_count()):
		if skeleton.get_bone_parent(bone_idx) < 0:
			roots.append(bone_idx)
	for root_idx: int in roots:
		_dump_tree(skeleton, root_idx, 0, lines)

	lines.append("")
	lines.append("## Weighted bones (sum of skinned vertex weights per bone)")
	var weights: Dictionary = {}
	var surface_report: Array[String] = []
	for mesh_instance: MeshInstance3D in meshes:
		var mesh: Mesh = mesh_instance.mesh
		if mesh == null:
			continue
		var skin: Skin = mesh_instance.skin
		surface_report.append("%s mesh=%s surfaces=%d skin_binds=%d" % [
			mesh_instance.name, mesh.resource_path if mesh.resource_path != "" else mesh.get_class(),
			mesh.get_surface_count(), skin.get_bind_count() if skin != null else 0,
		])
		for surface_idx in range(mesh.get_surface_count()):
			var arrays: Array = mesh.surface_get_arrays(surface_idx)
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bones_var: Variant = arrays[Mesh.ARRAY_BONES]
			var weights_var: Variant = arrays[Mesh.ARRAY_WEIGHTS]
			var bones: PackedInt32Array = PackedInt32Array()
			var vertex_weights: PackedFloat32Array = PackedFloat32Array()
			if bones_var != null:
				bones = bones_var as PackedInt32Array
			if weights_var != null:
				vertex_weights = weights_var as PackedFloat32Array
			var material: Material = mesh.surface_get_material(surface_idx)
			var mat_name: String = material.resource_name if material != null else "<none>"
			if material != null and mat_name == "":
				mat_name = material.resource_path.get_file()
			surface_report.append("  surface=%d verts=%d bones=%d weights=%d material=%s" % [
				surface_idx, verts.size(), bones.size(), vertex_weights.size(), mat_name,
			])
			for vertex_idx in range(verts.size()):
				for influence in range(4):
					var entry: int = vertex_idx * 4 + influence
					if entry >= bones.size() or entry >= vertex_weights.size():
						continue
					var bone_idx: int = bones[entry]
					var weight: float = vertex_weights[entry]
					if bone_idx < 0 or bone_idx >= skeleton.get_bone_count() or weight <= 0.0001:
						continue
					weights[bone_idx] = float(weights.get(bone_idx, 0.0)) + weight
	lines.append("")
	lines.append_array(surface_report)
	lines.append("")
	lines.append("## Secondary-motion candidates (name/parent/children/rest/weighted verts)")
	var candidates: Array[int] = []
	for bone_idx in range(skeleton.get_bone_count()):
		var bone_name: String = skeleton.get_bone_name(bone_idx)
		if _matches(bone_name):
			candidates.append(bone_idx)
	for bone_idx: int in candidates:
		var parent_idx: int = skeleton.get_bone_parent(bone_idx)
		var parent_name: String = skeleton.get_bone_name(parent_idx) if parent_idx >= 0 else "<root>"
		var children: Array[String] = []
		for child_idx in range(skeleton.get_bone_count()):
			if skeleton.get_bone_parent(child_idx) == bone_idx:
				children.append(skeleton.get_bone_name(child_idx))
		lines.append("%s idx=%d parent=%s rest_pos=%s rest_scale=%s children=%s weighted_verts=%.1f" % [
			skeleton.get_bone_name(bone_idx), bone_idx, parent_name,
			skeleton.get_bone_rest(bone_idx).origin,
			skeleton.get_bone_rest(bone_idx).basis.get_scale(),
			children, float(weights.get(bone_idx, 0.0)),
		])

	# Shortest chain walk from every candidate root up/down, so we can see the real chains.
	lines.append("")
	lines.append("## Candidate chains (walk to leaf)")
	var chain_roots: Array[int] = []
	for bone_idx: int in candidates:
		var parent_idx: int = skeleton.get_bone_parent(bone_idx)
		if parent_idx < 0 or not candidates.has(parent_idx):
			chain_roots.append(bone_idx)
	for chain_root: int in chain_roots:
		var chain: Array[String] = []
		var cursor: int = chain_root
		var guard: int = 0
		while cursor >= 0 and guard < 64:
			chain.append("%s(w=%.1f)" % [skeleton.get_bone_name(cursor), float(weights.get(cursor, 0.0))])
			var next_idx: int = -1
			for child_idx in range(skeleton.get_bone_count()):
				if skeleton.get_bone_parent(child_idx) == cursor:
					next_idx = child_idx
					break
			cursor = next_idx
			guard += 1
		lines.append("CHAIN " + " -> ".join(chain))

	_write(label, lines)
	instance.queue_free()


func _matches(bone_name: String) -> bool:
	var lowered: String = bone_name.to_lower()
	for keyword: String in KEYWORDS:
		if lowered.contains(keyword):
			return true
	return false


func _dump_tree(skeleton: Skeleton3D, bone_idx: int, depth: int, lines: Array[String]) -> void:
	var indent: String = "  ".repeat(depth)
	lines.append("%s%s [%d] rest=%s" % [indent, skeleton.get_bone_name(bone_idx), bone_idx, skeleton.get_bone_rest(bone_idx).origin])
	for child_idx in range(skeleton.get_bone_count()):
		if skeleton.get_bone_parent(child_idx) == bone_idx:
			_dump_tree(skeleton, child_idx, depth + 1, lines)


func _collect_meshes(node: Node, out: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		out.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_meshes(child, out)


func _write(label: String, lines: Array[String]) -> void:
	var path: String = OUT_DIR + "/rig_" + label + ".txt"
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("CANNOT_WRITE ", path)
		return
	for line: String in lines:
		file.store_line(line)
	file.close()
	print("RIG_REPORT path=%s lines=%d" % [path, lines.size()])
