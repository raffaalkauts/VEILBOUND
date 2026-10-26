extends SceneTree

func _init() -> void:
	var packed = load("res://characters/enemies/soldier/anime-girl_running_panic.glb")
	var inst: Node3D = packed.instantiate()
	root.add_child(inst)
	# NO SCALE APPLIED (1.0)
	inst.rotation.y = PI
	
	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	var head_idx = skel.find_bone("CC_Base_Head_41")
	var toe_idx = skel.find_bone("CC_Base_L_ToeBase_6")
	var r_hand_idx = skel.find_bone("CC_Base_R_Hand_88")
	
	var head_att = BoneAttachment3D.new()
	head_att.bone_name = "CC_Base_Head_41"
	head_att.bone_idx = head_idx
	skel.add_child(head_att)
	
	var toe_att = BoneAttachment3D.new()
	toe_att.bone_name = "CC_Base_L_ToeBase_6"
	toe_att.bone_idx = toe_idx
	skel.add_child(toe_att)
	
	var hand_att = BoneAttachment3D.new()
	hand_att.bone_name = "CC_Base_R_Hand_88"
	hand_att.bone_idx = r_hand_idx
	skel.add_child(hand_att)
	
	await process_frame
	
	print("UNSCALED Soldier Head global pos: ", head_att.global_position)
	print("UNSCALED Soldier Toe global pos: ", toe_att.global_position)
	print("UNSCALED Soldier Hand global pos: ", hand_att.global_position)
	print("Total soldier height: ", head_att.global_position.y - toe_att.global_position.y)
	
	inst.free()
	quit(0)
