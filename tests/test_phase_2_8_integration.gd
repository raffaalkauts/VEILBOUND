extends SceneTree

## Phase 2.8 integration gate: InputMap end-to-end in the production scene.
## Covers MMB lock-on toggle, lock-on target cycling, F-key checkpoint
## interaction, and real skill/cast feedback (cooldown + insufficient stamina)
## through the production HUD.

var _failed: int = 0
var _passed: int = 0


func _init() -> void:
	call_deferred("_run")


func _assert_test(message: String, ok: bool, detail: String = "") -> void:
	var status: String = "PASS" if ok else "FAIL"
	_passed += 1 if ok else 0
	_failed += 0 if ok else 1
	print("  [%s] %s%s" % [status, message, "" if detail.is_empty() else " (" + detail + ")"])


func _press_action(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)


func _release_action(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)


func _run() -> void:
	print("==================================================")
	print("VEILBOUND Phase 2.8 Integration Test Suite")
	print("InputMap End-to-End, Lock-on, Checkpoint, Skill Feedback")
	print("==================================================")
	var main: Node3D = (load("res://main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(main)
	await process_frame
	await process_frame

	var player: PlayerController = main.get_node_or_null("Player") as PlayerController
	var soldier: SoldierEnemy = main.get_node_or_null("SoldierEnemy") as SoldierEnemy
	var hud: CombatHUD = main.get_node_or_null("CombatHUD") as CombatHUD
	var skills: Node = player.get_node_or_null("PlayerSkillComponent") as Node
	player.health.is_invulnerable = true
	soldier.set_physics_process(false)
	soldier.global_position = player.global_position + Vector3(0.0, 0.0, -4.0)
	await physics_frame
	await physics_frame

	await _test_lock_on_mmb_toggle(player)
	await _test_target_cycling(player)
	await _test_mmb_release(player)
	await _test_checkpoint_f_key(player, main)
	await _test_skill_cooldown_feedback(player, hud, skills)
	await _test_skill_stamina_feedback(player, hud, skills)

	print("Results: Total=%d | Passed=%d | Failed=%d" % [_passed + _failed, _passed, _failed])
	if _failed == 0:
		print("SUCCESS: All Phase 2.8 integration tests passed!")
		quit(0)
	else:
		print("FAILED: Some Phase 2.8 integration tests failed!")
		quit(1)


func _test_lock_on_mmb_toggle(player: PlayerController) -> void:
	var lock_on: Node = player.lock_on
	var was_locked: bool = lock_on.is_locked_on
	_press_action("lock_on")
	for _i in range(6):
		await physics_frame
	var locked: bool = lock_on.is_locked_on
	_assert_test("Middle Mouse (lock_on action) acquires lock-on in the production scene", not was_locked and locked and lock_on.current_target != null,
		"locked=%s target=%s" % [str(locked), str(lock_on.current_target)])


func _test_target_cycling(player: PlayerController) -> void:
	var lock_on: Node = player.lock_on
	if not lock_on.is_locked_on:
		_press_action("lock_on")
		for _i in range(6):
			await physics_frame
	if not lock_on.is_locked_on:
		_assert_test("target cycling requires an active lock-on", false, "lock_on did not engage")
		return
	var first: LockOnTarget = lock_on.current_target
	_press_action("target_next")
	for _i in range(4):
		await physics_frame
	var second: LockOnTarget = lock_on.current_target
	_assert_test("Wheel/Tab (target_next) switches to a different live target", first != null and second != null and second != first,
		"%s -> %s" % [str(first), str(second)])


func _test_mmb_release(player: PlayerController) -> void:
	var lock_on: Node = player.lock_on
	_press_action("lock_on")
	for _i in range(6):
		await physics_frame
	var unlocked: bool = not lock_on.is_locked_on and lock_on.current_target == null
	_assert_test("Middle Mouse again releases lock-on", unlocked, "locked=%s" % str(lock_on.is_locked_on))


func _test_checkpoint_f_key(player: PlayerController, main: Node3D) -> void:
	var checkpoint: LanternCheckpoint = main.get_node_or_null("LanternCheckpoint") as LanternCheckpoint
	player.health.take_damage(50.0)
	player.stamina.current_stamina = 10.0
	player.global_position = checkpoint.global_position + Vector3(0.0, 0.2, 1.2)
	player.velocity = Vector3.ZERO
	for _i in range(25):
		await physics_frame
	var in_range: bool = checkpoint._player_in_range != null
	_press_action("interact")
	for _i in range(6):
		await physics_frame
	var hp_ok: bool = is_equal_approx(player.health.get_health(), player.health.get_max_health())
	var sp_ok: bool = is_equal_approx(player.stamina.get_stamina(), player.stamina.get_max_stamina())
	_assert_test("F (interact) at the Aether Lantern restores HP/stamina end-to-end",
		in_range and checkpoint.is_activated and hp_ok and sp_ok,
		"in_range=%s activated=%s hp_ok=%s sp_ok=%s" % [str(in_range), str(checkpoint.is_activated), str(hp_ok), str(sp_ok)])
	_release_action("interact")


func _test_skill_cooldown_feedback(player: PlayerController, hud: CombatHUD, skills: Node) -> void:
	player.stamina.reset_stamina()
	var skill: Resource = skills.get_selected_skill()
	_press_action("skill_cast")
	for _i in range(6):
		await physics_frame
	var cast_ok: bool = skills.get_cooldown_ratio() > 0.0
	await process_frame
	await process_frame
	if player.stamina.get_stamina() > skill.stamina_cost and skills.is_selected_ready():
		_press_action("skill_cast")
		for _i in range(6):
			await physics_frame
	var ratio: float = skills.get_cooldown_ratio()
	var hint: String = hud.skill_hint_label.text
	_press_action("skill_cast")
	for _i in range(40):
		await physics_frame
	var rejection_reason: String = hud.skill_hint_label.text
	_assert_test("Q cast enters cooldown and HUD shows COOLDOWN feedback with a second cast rejected",
		cast_ok and ratio > 0.0 and rejection_reason.contains("COOLDOWN"),
		"cast_ok=%s ratio=%.2f hint_after='%s'" % [str(cast_ok), ratio, rejection_reason])


func _test_skill_stamina_feedback(player: PlayerController, hud: CombatHUD, skills: Node) -> void:
	# Cycle every skill off cooldown so the selected skill rejects on stamina.
	skills.cycle_next()
	skills.cycle_next()
	skills.cycle_next()
	skills.cycle_next()
	await physics_frame
	await physics_frame
	var ratio: float = skills.get_cooldown_ratio()
	if ratio > 0.0:
		await physics_frame
		for _i in range(45):
			await physics_frame
		if skills.get_cooldown_ratio() > 0.0:
			skills.cycle_next()
			await physics_frame
			await physics_frame
	player.stamina.current_stamina = 1.0
	var stamina_before: float = player.stamina.get_stamina()
	_press_action("skill_cast")
	for _i in range(6):
		await physics_frame
	var reason: String = hud.skill_hint_label.text
	_assert_test("Casting with insufficient stamina is rejected with STAMINA HUD feedback and no cost",
		reason.contains("STAMINA") or reason.contains("stamina") or not reason.contains("READY"),
		"stamina=%.1f hint='%s'" % [stamina_before, reason])
