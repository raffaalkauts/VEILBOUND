extends SceneTree

var _passed: int = 0
var _total: int = 0


func _init() -> void:
	call_deferred("_run")


func _assert_test(name: String, condition: bool) -> void:
	_total += 1
	if condition:
		_passed += 1
		print("[PASS] ", name)
	else:
		print("[FAIL] ", name)


func _run() -> void:
	var main: Node3D = (load("res://main.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(main)
	for _i in range(8):
		await physics_frame
	var player: PlayerController = main.get_node("Player") as PlayerController
	var hud: CombatHUD = main.get_node("CombatHUD") as CombatHUD
	var skills: Node = player.get_node("PlayerSkillComponent")
	_assert_test("Exactly one player HP and stamina bar exists", hud.find_children("HealthBar", "ProgressBar", true, false).size() == 1 and hud.find_children("StaminaBar", "ProgressBar", true, false).size() == 1)
	_assert_test("Player bars do not overlap as separate controls", not hud.health_bar.get_global_rect().intersects(hud.stamina_bar.get_global_rect()))
	_assert_test("Four skills are available", skills.skills.size() == 4)
	var first: String = skills.get_selected_skill().skill_id
	skills.cycle_next()
	_assert_test("E-cycle advances selection without spending stamina", skills.get_selected_skill().skill_id != first and is_equal_approx(player.stamina.get_stamina(), player.stamina.get_max_stamina()))
	var before_cast: float = player.stamina.get_stamina()
	_assert_test("Q-cast consumes selected skill stamina once", skills.try_cast() and is_equal_approx(player.stamina.get_stamina(), before_cast - skills.get_selected_skill().stamina_cost))
	_assert_test("Cooldown rejects immediate duplicate cast", not skills.try_cast())
	for _i in range(300):
		await physics_frame
	_assert_test("Skill cooldown eventually expires", skills.get_cooldown_ratio() <= 0.0)
	main.free()
	print("Skill system tests: %d/%d passed" % [_passed, _total])
	quit(0 if _passed == _total else 1)
