extends SceneTree

func _init() -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_E
	event.pressed = true
	print("E event action=", InputMap.event_is_action(event, "skill_next"))
	print("skill_next events=", InputMap.action_get_events("skill_next"))
	print("Q event action=", InputMap.event_is_action(_key(KEY_Q), "skill_cast"))
	quit(0)

func _key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	return event
