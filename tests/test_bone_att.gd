extends SceneTree

func _init() -> void:
	var packed = load("res://assets/characters/protagonist/imported/anime_fox_girl.glb")
	var inst: Node3D = packed.instantiate()
	root.add_child(inst)
	
	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	var att = BoneAttachment3D.new()
	att.name = "RightHandAttachment"
	var b_idx = skel.find_bone("Shibahu_RightHand_0167_217")
	att.bone_name = "Shibahu_RightHand_0167_217"
	att.bone_idx = b_idx
	skel.add_child(att)
	
	var sword_marker = Marker3D.new()
	sword_marker.name = "Katana"
	att.add_child(sword_marker)
	
	print("Attachment bone_name: ", att.bone_name, " bone_idx: ", att.bone_idx)
	print("Attachment transform: ", att.transform)
	
	inst.free()
	quit(0)
