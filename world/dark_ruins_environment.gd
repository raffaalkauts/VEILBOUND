extends Node3D

## Dark ruins set dressing.
##
## Rendering notes (Phase 2.7, measured on Intel UHD 620 @ 1152x648):
## - The set is made of ~35 imported GLBs with one material per prop, so the
##   original scene issued one draw per prop surface (plus a shadow pass).
## - Repeated props (walls, pillars, fences, torches, lantern posts) are now
##   collapsed into spatially chunked MultiMesh batches. Each batch keeps the
##   original collision bodies, only the visual MeshInstance3D is hidden.
## - Small props no longer cast shadows. The directional shadow is the single
##   most expensive pass in the entry view and these props contribute almost no
##   readable shadow at gameplay distance.

const SOLID_PROP_GROUP: StringName = &"environment_solid"

## Props whose shadow contribution is below the readability threshold at the
## gameplay camera distance. Large walls, pillars, the gate, the crypt and the
## dead trees keep casting shadows.
const SHADOWLESS_PROP_TOKENS: Array[String] = [
	"gravestone",
	"gravemarker",
	"fence",
	"barrel",
	"crates",
	"rubble",
	"stairs",
	"torch",
	"lantern",
	"column_gltf",
]

## Courtyard/entry boundary. The level is small, so one spatial split is enough
## to keep the two halves independently cullable.
const BATCH_ENTRY_Z: float = 6.0

var _source_meshes: Array[MeshInstance3D] = []
var _batched_sources: Array[MeshInstance3D] = []
var _batches: Array[MultiMeshInstance3D] = []


func _ready() -> void:
	var meshes: Array[MeshInstance3D] = []
	for prop in get_children():
		var solid: bool = prop.is_in_group(SOLID_PROP_GROUP)
		for node in prop.find_children("*", "MeshInstance3D", true, false):
			var mesh_instance: MeshInstance3D = node as MeshInstance3D
			if mesh_instance.mesh == null:
				continue
			if solid:
				mesh_instance.create_trimesh_collision()
			meshes.append(mesh_instance)
	_source_meshes = meshes
	_configure_prop_shadows(meshes)
	_batch_repeated_props(meshes)


## Dev/benchmark switch. Rebuilds the pre-optimization render state (all source
## visuals visible, every prop casting shadows) without touching collisions,
## navigation or the loaded scene layout.
func set_optimized_rendering(enabled: bool) -> void:
	for batch: MultiMeshInstance3D in _batches:
		batch.visible = enabled
	for mesh_instance: MeshInstance3D in _batched_sources:
		mesh_instance.visible = not enabled
	for mesh_instance: MeshInstance3D in _source_meshes:
		if enabled and _is_shadowless(mesh_instance):
			mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		else:
			mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


func _is_shadowless(mesh_instance: MeshInstance3D) -> bool:
	var prop_name: String = String(mesh_instance.get_parent().name).to_lower()
	var mesh_name: String = mesh_instance.mesh.resource_path.get_file().to_lower()
	var haystack: String = prop_name + "|" + mesh_name
	for token: String in SHADOWLESS_PROP_TOKENS:
		if haystack.contains(token):
			return true
	return false


func _configure_prop_shadows(meshes: Array[MeshInstance3D]) -> void:
	for mesh_instance: MeshInstance3D in meshes:
		if _is_shadowless(mesh_instance):
			mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _batch_repeated_props(meshes: Array[MeshInstance3D]) -> void:
	var groups: Dictionary = {}
	for mesh_instance: MeshInstance3D in meshes:
		var mesh: Mesh = mesh_instance.mesh
		if mesh == null or mesh.get_surface_count() != 1:
			continue
		var material: Material = mesh_instance.get_surface_override_material(0)
		if material == null:
			material = mesh.surface_get_material(0)
		var world_position: Vector3 = mesh_instance.global_position
		var chunk: int = 0 if world_position.z < BATCH_ENTRY_Z else 1
		var key: String = "%s|%s|%d|%d" % [
			mesh.resource_path,
			_material_key(material),
			chunk,
			int(mesh_instance.cast_shadow),
		]
		if not groups.has(key):
			groups[key] = []
		(groups[key] as Array).append(mesh_instance)

	var batch_parent: Node3D = self
	var parent_inverse: Transform3D = batch_parent.global_transform.affine_inverse()
	var batch_index: int = 0
	for key: String in groups:
		var list: Array = groups[key]
		if list.size() < 2:
			continue
		var source: MeshInstance3D = list[0] as MeshInstance3D
		var source_mesh: Mesh = source.mesh
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = source_mesh
		multimesh.instance_count = list.size()
		var batch := MultiMeshInstance3D.new()
		batch.name = "Batch_%d_%s" % [batch_index, source_mesh.resource_path.get_file().get_basename()]
		batch.multimesh = multimesh
		var source_material: Material = source.get_surface_override_material(0)
		if source_material == null:
			source_material = source_mesh.surface_get_material(0)
		batch.material_override = source_material
		batch.cast_shadow = source.cast_shadow
		batch_index += 1
		batch_parent.add_child(batch)
		batch.transform = Transform3D.IDENTITY
		_batches.append(batch)
		for instance_index in range(list.size()):
			var mesh_instance: MeshInstance3D = list[instance_index] as MeshInstance3D
			multimesh.set_instance_transform(
				instance_index,
				parent_inverse * mesh_instance.global_transform
			)
			# Collision bodies stay alive as children of the original node; only
			# the duplicated visual is removed from the draw list.
			mesh_instance.visible = false
			_batched_sources.append(mesh_instance)


func _material_key(material: Material) -> String:
	if material == null:
		return "none"
	if material is StandardMaterial3D:
		var standard: StandardMaterial3D = material as StandardMaterial3D
		var texture_path: String = ""
		if standard.albedo_texture != null:
			texture_path = standard.albedo_texture.resource_path
		return "%s|%.3f|%.3f|%d|%d|%.2f" % [
			texture_path,
			standard.roughness,
			standard.metallic,
			standard.cull_mode,
			standard.transparency,
			standard.alpha_scissor_threshold,
		]
	return str(material.get_instance_id())
