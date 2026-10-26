extends SceneTree

func _init() -> void:
	print("--- Testing Soldier Enemy State Transitions and Animations ---")
	var packed = load("res://characters/enemies/soldier/soldier_enemy.tscn")
	var inst: SoldierEnemy = packed.instantiate()
	root.add_child(inst)
	
	await process_frame
	
	print("Soldier state: ", inst.get_state_name())
	print("BodyMesh: ", inst.body_mesh.name if inst.body_mesh else null)
	print("WeaponMesh: ", inst.weapon_mesh.name if inst.weapon_mesh else null)
	print("WeaponMesh parent: ", inst.weapon_mesh.get_parent().name if inst.weapon_mesh else null)
	print("AnimPlayer: ", inst.anim_player.name if inst.anim_player else null)
	
	# Test states
	inst._change_state(SoldierEnemy.State.CHASE)
	print("After CHASE: anim=", inst.anim_player.current_animation)
	
	inst._change_state(SoldierEnemy.State.TELEGRAPH)
	print("After TELEGRAPH: anim=", inst.anim_player.current_animation)
	
	inst._change_state(SoldierEnemy.State.ATTACK)
	print("After ATTACK: anim=", inst.anim_player.current_animation)
	
	inst._change_state(SoldierEnemy.State.STAGGERED)
	print("After STAGGERED: anim=", inst.anim_player.current_animation)
	
	inst._change_state(SoldierEnemy.State.DEAD)
	print("After DEAD: anim=", inst.anim_player.current_animation)
	
	inst.free()
	quit(0)
