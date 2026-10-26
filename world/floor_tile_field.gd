extends Node3D

## Draws a shared low-poly stone floor mesh as one compatibility-friendly batch.
@export var columns: int = 6
@export var rows: int = 6
@export var start_position: Vector3 = Vector3(-10.0, -0.05, -15.0)
@export var spacing: float = 4.0

const FLOOR_TILE_SCENE: PackedScene = preload("res://assets/environment/ruins/floor_tile_large.gltf.glb")


func _ready() -> void:
	var source: Node3D = FLOOR_TILE_SCENE.instantiate() as Node3D
	var mesh_nodes: Array[Node] = source.find_children("*", "MeshInstance3D", true, false)
	if mesh_nodes.is_empty():
		source.free()
		push_warning("Floor tile field could not find the KayKit floor mesh.")
		return

	var source_mesh: MeshInstance3D = mesh_nodes[0] as MeshInstance3D
	var floor_mesh: MultiMesh = MultiMesh.new()
	floor_mesh.transform_format = MultiMesh.TRANSFORM_3D
	floor_mesh.mesh = source_mesh.mesh
	floor_mesh.instance_count = columns * rows

	var instance_index: int = 0
	for row in range(rows):
		for column in range(columns):
			var turn: float = float((row + column) % 4) * PI * 0.5
			var tile_position: Vector3 = start_position + Vector3(column * spacing, 0.0, row * spacing)
			floor_mesh.set_instance_transform(instance_index, Transform3D(Basis(Vector3.UP, turn), tile_position))
			instance_index += 1

	var batched_tiles: MultiMeshInstance3D = MultiMeshInstance3D.new()
	batched_tiles.name = "StoneFloorBatch"
	batched_tiles.multimesh = floor_mesh
	add_child(batched_tiles)
	source.free()
