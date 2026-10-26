extends SceneTree

func _init() -> void:
	var packed = load("res://characters/enemies/soldier/anime-girl_running_panic.glb")
	var inst: Node3D = packed.instantiate()
	root.add_child(inst)
	inst.rotation.y = PI
	
	var skel: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	var hand_idx = skel.find_bone("CC_Base_R_Hand_88")
	
	var hand_att = BoneAttachment3D.new()
	hand_att.name = "RightHandAttachment"
	hand_att.bone_name = "CC_Base_R_Hand_88"
	hand_att.bone_idx = hand_idx
	skel.add_child(hand_att)
	
	var weapon = Node3D.new()
	weapon.name = "SoldierWeapon"
	# In soldier skeleton, basis is unscaled or scaled by internal glb
	hand_att.add_child(weapon)
	
	await process_frame
	
	print("Soldier weapon global pos: ", weapon.global_position)
	print("Soldier weapon global scale: ", weapon.global_transform.basis.get_scale())
	
	inst.free()
	quit(0)
