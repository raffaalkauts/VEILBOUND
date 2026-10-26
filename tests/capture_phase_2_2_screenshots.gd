extends SceneTree

func _init() -> void:
	print("Capturing Phase 2.2 in-game screenshots...")
	var main_scene = load("res://main.tscn")
	var main: Node3D = main_scene.instantiate()
	root.add_child(main)
	
	# Wait for rendering to settle
	for _i in range(25):
		await process_frame
		
	var player = main.get_node("Player")
	var soldier = main.get_node("SoldierEnemy")
	
	# 1. Capture Player Idle with sheathed katana and dummy
	if player and player.camera_pivot:
		player.camera_pivot.rotation_degrees = Vector3(-8, 165, 0)
		player.camera_pivot.position = Vector3(0, 1.25, 0)
		if player.spring_arm:
			player.spring_arm.spring_length = 2.4
			
	for _i in range(15):
		await process_frame
		
	var img1 = root.get_viewport().get_texture().get_image()
	if img1:
		img1.save_png("res://screenshot_phase_2_2_idle.png")
		print("Saved screenshot_phase_2_2_idle.png")
		
	# 2. Capture Combat / Katana Draw
	if player:
		var driver = player.visual_root
		var model = driver.get_character_model()
		model.set_combat_mode(true)
		model.play_animation("attack_1")
		if player.camera_pivot:
			player.camera_pivot.rotation_degrees = Vector3(-5, 140, 0)
			
	for _i in range(15):
		await process_frame
		
	var img2 = root.get_viewport().get_texture().get_image()
	if img2:
		img2.save_png("res://screenshot_phase_2_2_combat.png")
		print("Saved screenshot_phase_2_2_combat.png")
		
	# 3. Capture Soldier Enemy
	if player and soldier:
		soldier.global_position = player.global_position + Vector3(0, 0, -2.2)
		soldier.visual_root.rotation.y = 0.0 # Facing camera
		soldier._change_state(SoldierEnemy.State.TELEGRAPH)
		if soldier.anim_player:
			soldier.anim_player.seek(0.5, true)
		if player.camera_pivot:
			player.camera_pivot.rotation_degrees = Vector3(-12, 180, 0)
			player.camera_pivot.position = Vector3(0, 1.4, 0)
			player.spring_arm.spring_length = 3.6
			
	for _i in range(15):
		await process_frame
		
	var img3 = root.get_viewport().get_texture().get_image()
	if img3:
		img3.save_png("res://screenshot_phase_2_2_soldier.png")
		print("Saved screenshot_phase_2_2_soldier.png")

	# 4. Capture Martial Training Dummy
	var dummy = main.get_node_or_null("Dummy_Center")
	if player and dummy:
		player.camera_pivot.rotation_degrees = Vector3(-10, 10, 0)
		player.camera_pivot.position = Vector3(0, 1.3, 0)
		player.spring_arm.spring_length = 3.5

	for _i in range(15):
		await process_frame

	var img4 = root.get_viewport().get_texture().get_image()
	if img4:
		img4.save_png("res://screenshot_phase_2_2_dummy.png")
		print("Saved screenshot_phase_2_2_dummy.png")
		
	main.free()
	quit(0)
