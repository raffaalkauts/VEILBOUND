extends SceneTree

func _init() -> void:
	print("Capturing in-game screenshot of genuine Fox Girl character in arena...")
	var main_scene = load("res://main.tscn")
	var main = main_scene.instantiate()
	root.add_child(main)
	
	# Let rendering and physics initialize
	for _i in range(15):
		await process_frame
		
	var player = main.get_node("Player")
	# Rotate camera slightly to get a dramatic third-person view of the character
	if player and player.camera_pivot:
		player.camera_pivot.rotation_degrees = Vector3(-10, 160, 0)
		player.camera_pivot.position = Vector3(0, 1.3, 0)
		if player.spring_arm:
			player.spring_arm.spring_length = 2.8
			
	for _i in range(10):
		await process_frame
		
	var img: Image = root.get_viewport().get_texture().get_image()
	if img:
		var err = img.save_png("res://screenshot_phase_2_1.png")
		if err == OK:
			print("SUCCESS: In-game screenshot saved to res://screenshot_phase_2_1.png")
		else:
			printerr("Failed to save screenshot: ", err)
	else:
		printerr("Viewport image was null!")
		
	main.free()
	quit(0)
