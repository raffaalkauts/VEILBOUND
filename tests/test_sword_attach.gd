extends SceneTree

func _init() -> void:
	var packed = load("res://assets/characters/protagonist/imported/anime_fox_girl.glb")
	var inst: Node3D = packed.instantiate()
	root.add_child(inst)
	inst.scale = Vector3(0.01, 0.01, 0.01)
	inst.rotation.y = PI
	
	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	var hand_idx = skel.find_bone("Shibahu_RightHand_0167_217")
	print("Right Hand idx: ", hand_idx)
	
	var hand_att = BoneAttachment3D.new()
	hand_att.bone_name = "Shibahu_RightHand_0167_217"
	hand_att.bone_idx = hand_idx
	skel.add_child(hand_att)
	
	var sword = Node3D.new()
	sword.name = "Katana"
	hand_att.add_child(sword)
	
	print("HandAttachment in skel: transform=", hand_att.transform)
	print("Hand global pose: ", skel.get_bone_global_pose(hand_idx))
	
	inst.free()
	quit(0)
