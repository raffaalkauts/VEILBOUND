extends SceneTree

func _init() -> void:
	var inst: Node3D = Node3D.new()
	inst.name = "PlayerCharacterModel"
	root.add_child(inst)
	
	var fox_mesh = load("res://assets/characters/protagonist/imported/anime_fox_girl.glb").instantiate()
	fox_mesh.name = "FoxGirlMesh"
	fox_mesh.scale = Vector3(0.01, 0.01, 0.01)
	fox_mesh.rotation.y = PI
	inst.add_child(fox_mesh)
	
	var skel: Skeleton3D = fox_mesh.find_child("Skeleton3D", true, false)
	var hand_idx = skel.find_bone("Shibahu_RightHand_0167_217")
	
	var hand_att = BoneAttachment3D.new()
	hand_att.bone_name = "Shibahu_RightHand_0167_217"
	hand_att.bone_idx = hand_idx
	skel.add_child(hand_att)
	
	var katana = Node3D.new()
	katana.name = "KatanaInHand"
	katana.scale = Vector3(100.0, 100.0, 100.0)
	hand_att.add_child(katana)
	
	# Check katana global scale and position
	print("Katana local scale: ", katana.scale)
	# Wait for a frame or process transform
	print("FoxMesh global scale: ", fox_mesh.global_transform.basis.get_scale())
	print("HandAtt scale: ", hand_att.scale)
	print("Katana global scale: ", katana.global_transform.basis.get_scale())
	
	inst.free()
	quit(0)
