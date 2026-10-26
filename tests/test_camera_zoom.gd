extends SceneTree

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0


func _init() -> void:
	call_deferred("_run")


func _assert_test(name: String, condition: bool, details: String = "") -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("[PASS] %s" % name)
	else:
		failed_tests += 1
		print("[FAIL] %s %s" % [name, details])


func _run() -> void:
	var main_scene: PackedScene = load("res://main.tscn") as PackedScene
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	await process_frame
	await physics_frame

	var player: PlayerController = main.get_node_or_null("Player") as PlayerController
	var spring_arm: SpringArm3D = player.spring_arm if player != null else null
	_assert_test("Production player has a SpringArm3D camera rig", spring_arm != null)

	if player != null and spring_arm != null:
		spring_arm.spring_length = 4.0
		_send_wheel(player, MOUSE_BUTTON_WHEEL_UP)
		_assert_test("Wheel up zooms camera in", is_equal_approx(spring_arm.spring_length, 3.65), "length=%f" % spring_arm.spring_length)

		_send_wheel(player, MOUSE_BUTTON_WHEEL_DOWN)
		_assert_test("Wheel down zooms camera out", is_equal_approx(spring_arm.spring_length, 4.0), "length=%f" % spring_arm.spring_length)

		spring_arm.spring_length = player.camera_zoom_min
		_send_wheel(player, MOUSE_BUTTON_WHEEL_UP)
		_assert_test("Zoom in clamps at minimum distance", is_equal_approx(spring_arm.spring_length, player.camera_zoom_min))

		spring_arm.spring_length = player.camera_zoom_max
		_send_wheel(player, MOUSE_BUTTON_WHEEL_DOWN)
		_assert_test("Zoom out clamps at maximum distance", is_equal_approx(spring_arm.spring_length, player.camera_zoom_max))

	main.queue_free()
	await process_frame
	print("Camera zoom results: Total=%d | Passed=%d | Failed=%d" % [total_tests, passed_tests, failed_tests])
	quit(1 if failed_tests > 0 else 0)


func _send_wheel(player: PlayerController, button: MouseButton) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	player._unhandled_input(event)
