extends SceneTree

func _init() -> void:
	var packed = load("res://characters/player/visual/player_character_model.tscn")
	var inst: PlayerCharacterModel = packed.instantiate()
	root.add_child(inst)
	
	print("Model ready. Testing all 12 animations via PlayerCharacterModel...")
	var anims = ["idle", "walk", "sprint", "jump", "fall", "dodge", "attack_1", "attack_2", "attack_3", "guard", "hit_react", "death"]
	for a in anims:
		var ok = inst.play_animation(a)
		print("  play_animation('", a, "'): ", ok, " current=", inst.anim_player.current_animation)
		
	# Test weapon draw mode
	inst.set_combat_mode(true)
	print("Combat mode true: katana in hand visible=", inst.katana_in_hand.visible, " sheathed_hilt visible=", inst.sheathed_hilt.visible)
	inst.set_combat_mode(false)
	print("Combat mode false: katana in hand visible=", inst.katana_in_hand.visible, " sheathed_hilt visible=", inst.sheathed_hilt.visible)
	
	inst.free()
	quit(0)
