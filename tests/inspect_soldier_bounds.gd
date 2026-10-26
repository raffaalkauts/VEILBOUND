extends SceneTree

func _init() -> void:
	var packed = load("res://characters/enemies/soldier/anime-girl_running_panic.glb")
	var inst: Node3D = packed.instantiate()
	root.add_child(inst)
	
	var meshes = []
	_find_nodes(inst, MeshInstance3D, meshes)
	for m: MeshInstance3D in meshes:
		print("Mesh: ", m.name, " aabb=", m.mesh.get_aabb())
		print("  Parent: ", m.get_parent().name, " parent xform=", m.get_parent().transform)
		print("  Mesh xform=", m.transform)

	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	if skel:
		print("Skel xform=", skel.transform)
		var head_idx = skel.find_bone("CC_Base_Head_41")
		if head_idx != -1:
			print("Head bone rest pose: ", skel.get_bone_rest(head_idx).origin)
		var hip_idx = skel.find_bone("CC_Base_Hip_99")
		if hip_idx != -1:
			print("Hip bone rest pose: ", skel.get_bone_rest(hip_idx).origin)
			
	inst.free()
	quit(0)

func _find_nodes(node: Node, type, arr: Array) -> void:
	if is_instance_of(node, type):
		arr.append(node)
	for child in node.get_children():
		_find_nodes(child, type, arr)
