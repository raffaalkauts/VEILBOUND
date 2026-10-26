class_name CombatHUD
extends CanvasLayer

const HUD_ANGLED_PANEL_SCRIPT: Script = preload("res://ui/hud_angled_panel.gd")
const HUD_ANGLED_BAR_SCRIPT: Script = preload("res://ui/hud_angled_bar.gd")
const HUD_DIAMOND_SLOT_SCRIPT: Script = preload("res://ui/hud_diamond_slot.gd")
const HUD_COMPASS_SCRIPT: Script = preload("res://ui/hud_compass.gd")

## Responsive Souls-like HUD. Gameplay components remain authoritative; the
## optional presentation fields only supply non-gameplay labels until matching
## systems exist (FP, rune, quick item, skill, and boss encounter).

const COLOR_BASE: Color = Color("#080E1CE6")
const COLOR_BORDER: Color = Color("#DCF0FFB3")
const COLOR_TEXT: Color = Color("#F7FBFF")
const COLOR_MUTED: Color = Color("#A9C1D6")
const COLOR_ACCENT: Color = Color("#9FE8FF")
const COLOR_HP_START: Color = Color("#3DDC84")
const COLOR_HP_END: Color = Color("#B6FF8A")
const COLOR_HP_TRAIL: Color = Color("#B84D67")
const COLOR_STAMINA_START: Color = Color("#3AA8FF")
const COLOR_STAMINA_END: Color = Color("#8FE3FF")
const COLOR_FP_START: Color = Color("#FFC04D")
const COLOR_FP_END: Color = Color("#FFF0A8")
const COLOR_BOSS_START: Color = Color("#FF3D5E")
const COLOR_BOSS_END: Color = Color("#FF9AA8")
const COLOR_GLOW: Color = Color("#FF8AA8")
const COLOR_SPACE: int = 10
const TRANSITION_STATUS: float = 0.20
const TRANSITION_FAST: float = 0.12

@export var player_path: NodePath = NodePath("../Player")
@export var character_name: String = "KIRIHA"
@export var character_level: int = 42
@export var show_optional_presentation_widgets: bool = false

var player_status_panel: Control
var low_health_accent: Control
var health_bar: ProgressBar
var health_trail_bar: ProgressBar
var health_label: Label
var stamina_bar: ProgressBar
var stamina_trail_bar: ProgressBar
var stamina_label: Label
var fp_bar: ProgressBar
var target_container: Control
var target_name_label: Label
var target_health_bar: ProgressBar
var target_health_trail_bar: ProgressBar
var target_health_label: Label
var skill_name_label: Label
var skill_cost_label: Label
var skill_hint_label: Label
var _skill_component: Node
var compass: Control
var _player_camera: Camera3D

var _connected_health: HealthComponent
var _connected_stamina: StaminaComponent
var _connected_lock_on: LockOnComponent
var _connected_target: LockOnTarget
var _connected_target_health: HealthComponent
var _health_value: float = 0.0
var _stamina_value: float = 0.0
var _target_health_value: float = 0.0
var _has_health_value: bool = false
var _has_stamina_value: bool = false
var _has_target_health_value: bool = false
var _health_tween: Tween
var _stamina_tween: Tween
var _target_health_tween: Tween
var _target_visibility_tween: Tween
var _font: Font


func _ready() -> void:
	_font = _make_font()
	_build_layout()
	_set_mouse_filter_recursive(self)
	_hide_target_immediately()
	var player_node: Node = get_node_or_null(player_path)
	if player_node != null:
		bind_player(player_node)


func _process(_delta: float) -> void:
	if compass != null and _player_camera != null:
		compass.set_heading_from_camera(_player_camera)
	if _skill_component != null and skill_hint_label != null:
		var cooldown_ratio: float = _skill_component.get_cooldown_ratio()
		if cooldown_ratio > 0.0:
			var selected_skill: Resource = _skill_component.get_selected_skill()
			skill_hint_label.text = "COOLDOWN %.1fs" % (selected_skill.cooldown * cooldown_ratio)
		elif skill_hint_label.text.begins_with("COOLDOWN"):
			skill_hint_label.text = "READY"
	if _connected_lock_on == null:
		return
	var live_target: LockOnTarget = _connected_lock_on.current_target
	if not _connected_lock_on.is_locked_on or live_target == null:
		if _connected_target != null:
			unbind_target()
	elif live_target != _connected_target:
		bind_target(live_target)


func _make_font() -> Font:
	var system_font := SystemFont.new()
	system_font.font_names = PackedStringArray(["Rajdhani", "Segoe UI", "Arial"])
	return system_font


func _build_layout() -> void:
	var root := get_node_or_null("Root") as Control
	if root == null:
		root = Control.new()
		root.name = "Root"
		root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(root)
	for child in root.get_children():
		# Free synchronously: a deferred queue_free leaves stale siblings alive
		# until the next frame, so rebuilt panels collide on their names and get
		# auto-renamed to "@PanelContainer@N" (observed at runtime).
		root.remove_child(child)
		child.free()

	_add_vignette(root)
	player_status_panel = _panel(root, "PlayerStatusPanel", 0.025, 0.035, 0.36, 0.32)
	_build_player_status(player_status_panel)
	_build_compass(root)
	_build_location(root)
	_build_rune_counter(root)
	_build_target_panel(root)
	_build_quick_slots(root)
	_build_skill_panel(root)
	_build_currency(root)


func _add_vignette(root: Control) -> void:
	var vignette := ColorRect.new()
	vignette.name = "BottomVignette"
	vignette.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	vignette.anchor_top = 0.65
	vignette.offset_top = 0.0
	vignette.color = Color(0.0, 0.0, 0.02, 0.34)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(vignette)
	root.move_child(vignette, 0)


func _panel(parent: Control, node_name: String, left: float, top: float, right: float, bottom: float) -> Control:
	var panel: Control = HUD_ANGLED_PANEL_SCRIPT.new()
	panel.name = node_name
	panel.unique_name_in_owner = true
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.anchor_left = left
	panel.anchor_top = top
	panel.anchor_right = right
	panel.anchor_bottom = bottom
	panel.offset_left = 0.0
	panel.offset_top = 0.0
	panel.offset_right = 0.0
	panel.offset_bottom = 0.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	panel.owner = get_tree().current_scene
	return panel


func _content(parent: Control, node_name: String) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.name = node_name + "Margin"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 12)
	parent.add_child(margin)
	var stack := VBoxContainer.new()
	stack.name = node_name + "Stack"
	stack.add_theme_constant_override("separation", COLOR_SPACE)
	margin.add_child(stack)
	return stack


func _label(parent: Node, node_name: String, text: String, size: int, color: Color = COLOR_TEXT, uppercase: bool = false) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text.to_upper() if uppercase else text
	label.add_theme_font_override("font", _font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.65))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	if node_name in ["HealthLabel", "TargetNameLabel", "TargetHealthLabel"]:
		label.unique_name_in_owner = true
		label.owner = get_tree().current_scene
	return label


func _bar(parent: Node, node_name: String, height: int, start: Color, finish: Color, trail: bool = false) -> ProgressBar:
	var bar: ProgressBar = HUD_ANGLED_BAR_SCRIPT.new()
	bar.name = node_name
	bar.custom_minimum_size = Vector2(0.0, height)
	bar.fill_start = COLOR_HP_TRAIL if trail else start
	bar.fill_end = COLOR_HP_TRAIL if trail else finish
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.unique_name_in_owner = true
	parent.add_child(bar)
	bar.owner = get_tree().current_scene
	return bar


func _bar_stack(parent: Node, base_name: String, height: int, start: Color, finish: Color) -> Array[ProgressBar]:
	var holder := Control.new()
	holder.name = base_name + "Stack"
	holder.custom_minimum_size = Vector2(0.0, height)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(holder)
	var trail: ProgressBar = _bar(holder, base_name + "TrailBar", height, COLOR_HP_TRAIL, COLOR_HP_TRAIL, true)
	var current: ProgressBar = _bar(holder, base_name + "Bar", height, start, finish)
	for bar: ProgressBar in [trail, current]:
		bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return [trail, current]


func _build_player_status(panel: Control) -> void:
	var stack := _content(panel, "Player")
	var header := HBoxContainer.new()
	header.name = "Header"
	stack.add_child(header)
	var name_label := _label(header, "StatusTitle", character_name, 26, COLOR_TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label(header, "StatusLevel", "Lv. %d" % character_level, 18, COLOR_ACCENT)
	_label(stack, "HealthCaption", "HP", 14, COLOR_ACCENT, true)
	var health_bars: Array[ProgressBar] = _bar_stack(stack, "Health", 22, COLOR_HP_START, COLOR_HP_END)
	health_trail_bar = health_bars[0]
	health_bar = health_bars[1]
	var health_meta := HBoxContainer.new()
	health_meta.name = "HealthMeta"
	stack.add_child(health_meta)
	health_label = _label(health_meta, "HealthLabel", "100 / 100", 14, COLOR_TEXT)
	health_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label(health_meta, "HealthTag", "VITALITY", 12, COLOR_MUTED)
	_label(stack, "StaminaCaption", "STAMINA", 14, COLOR_ACCENT, true)
	var stamina_bars: Array[ProgressBar] = _bar_stack(stack, "Stamina", 14, COLOR_STAMINA_START, COLOR_STAMINA_END)
	stamina_trail_bar = stamina_bars[0]
	stamina_bar = stamina_bars[1]
	var stamina_meta := HBoxContainer.new()
	stack.add_child(stamina_meta)
	stamina_label = _label(stamina_meta, "StaminaLabel", "100 / 100", 14, COLOR_TEXT)
	stamina_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# The prototype has no FP/mana component. Keep the hook available without
	# rendering a fictional resource bar in the live HUD.
	fp_bar = null
	var chips := HBoxContainer.new()
	chips.name = "StatusChips"
	chips.add_theme_constant_override("separation", 8)
	stack.add_child(chips)
	chips.visible = show_optional_presentation_widgets
	_chip(chips, "Poison")
	_chip(chips, "ATK +12%")
	low_health_accent = _label(panel, "LowHealthAccent", "LOW", 10, COLOR_BOSS_END, true)
	low_health_accent.visible = false


func _chip(parent: Node, text: String) -> void:
	var chip := Label.new()
	chip.text = text
	chip.add_theme_font_override("font", _font)
	chip.add_theme_font_size_override("font_size", 16)
	chip.add_theme_color_override("font_color", COLOR_ACCENT)
	chip.add_theme_stylebox_override("normal", _chip_style())
	chip.add_theme_constant_override("outline_size", 1)
	parent.add_child(chip)


func _chip_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.1, 0.18, 0.50)
	style.border_color = COLOR_ACCENT
	style.set_border_width_all(1)
	style.set_content_margin(SIDE_LEFT, 8)
	style.set_content_margin(SIDE_RIGHT, 8)
	style.set_content_margin(SIDE_TOP, 3)
	style.set_content_margin(SIDE_BOTTOM, 3)
	return style


func _build_compass(root: Control) -> void:
	var compass := _panel(root, "Compass", 0.36, 0.035, 0.64, 0.09)
	self.compass = HUD_COMPASS_SCRIPT.new()
	self.compass.name = "HeadingStrip"
	self.compass.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	self.compass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	compass.add_child(self.compass)


func _build_location(root: Control) -> void:
	var panel := _panel(root, "LocationPanel", 0.80, 0.035, 0.975, 0.12)
	panel.visible = show_optional_presentation_widgets
	var stack := _content(panel, "Location")
	_label(stack, "LocationEyebrow", "LINK START", 14, COLOR_ACCENT, true)
	_label(stack, "LocationName", "Lumina Ruins - Floor 3", 18, COLOR_TEXT)


func _build_rune_counter(root: Control) -> void:
	var label := _label(root, "RuneCounter", "1,284", 64, COLOR_TEXT)
	label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	label.anchor_left = 0.5
	label.anchor_right = 0.5
	label.offset_left = -150.0
	label.offset_right = 150.0
	label.offset_top = 82.0
	label.offset_bottom = 160.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.visible = show_optional_presentation_widgets
	label.add_theme_color_override("font_shadow_color", COLOR_GLOW)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)
	label.add_theme_constant_override("shadow_outline_size", 8)


func _build_target_panel(root: Control) -> void:
	target_container = _panel(root, "TargetContainer", 0.15, 0.82, 0.85, 0.955)
	var stack := _content(target_container, "Target")
	var header := HBoxContainer.new()
	stack.add_child(header)
	target_name_label = _label(header, "TargetNameLabel", "THE CRIMSON WARDEN", 28, COLOR_TEXT)
	target_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label(header, "TargetPhaseLabel", "PHASE II", 16, COLOR_BOSS_END)
	var target_bars: Array[ProgressBar] = _bar_stack(stack, "TargetHealth", 18, COLOR_BOSS_START, COLOR_BOSS_END)
	target_health_trail_bar = target_bars[0]
	target_health_bar = target_bars[1]
	var meta := HBoxContainer.new()
	stack.add_child(meta)
	var caption := _label(meta, "TargetHealthCaption", "BOSS VITALITY", 12, COLOR_MUTED, true)
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_health_label = _label(meta, "TargetHealthLabel", "80 / 80", 14, COLOR_TEXT)
	_hide_target_immediately()


func _build_quick_slots(root: Control) -> void:
	var panel := _panel(root, "QuickSlots", 0.025, 0.69, 0.20, 0.975)
	panel.visible = show_optional_presentation_widgets
	var slot_canvas := Control.new()
	slot_canvas.name = "SlotCanvas"
	slot_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(slot_canvas)
	var labels: Array[String] = ["x5", "L", "R", "x3"]
	var positions: Array[Vector2] = [Vector2(0.5, 0.12), Vector2(0.18, 0.5), Vector2(0.82, 0.5), Vector2(0.5, 0.86)]
	for index in range(labels.size()):
		var slot = HUD_DIAMOND_SLOT_SCRIPT.new()
		slot.name = "QuickSlot%d" % index
		slot.slot_text = labels[index]
		slot.active = index == 2
		slot.set_anchors_preset(Control.PRESET_CENTER)
		slot.anchor_left = positions[index].x
		slot.anchor_top = positions[index].y
		slot.anchor_right = positions[index].x
		slot.anchor_bottom = positions[index].y
		slot.offset_left = -35.0
		slot.offset_top = -35.0
		slot.offset_right = 35.0
		slot.offset_bottom = 35.0
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_canvas.add_child(slot)


func _slot_style(active: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.30, 0.40, 0.72) if active else Color(0.03, 0.08, 0.15, 0.76)
	style.border_color = COLOR_ACCENT if active else COLOR_BORDER
	style.set_border_width_all(1)
	return style


func _build_skill_panel(root: Control) -> void:
	var panel := _panel(root, "SkillPanel", 0.205, 0.76, 0.43, 0.975)
	var stack := _content(panel, "Skill")
	_label(stack, "SkillEyebrow", "SWORD SKILL", 18, COLOR_ACCENT, true)
	skill_name_label = _label(stack, "SkillName", "Aether Crescent", 22, COLOR_TEXT)
	skill_cost_label = _label(stack, "SkillCost", "E SELECT  /  Q CAST", 14, COLOR_MUTED)
	skill_hint_label = _label(stack, "SkillHint", "READY", 12, COLOR_ACCENT)


func _build_currency(root: Control) -> void:
	var panel := _panel(root, "CurrencyPanel", 0.80, 0.82, 0.975, 0.955)
	panel.visible = show_optional_presentation_widgets
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(row)
	_label(row, "CurrencyIcon", "◆", 20, COLOR_ACCENT)
	var stack := VBoxContainer.new()
	row.add_child(stack)
	_label(stack, "CurrencyLabel", "COR", 14, COLOR_ACCENT, true)
	_label(stack, "CurrencyValue", "48,920", 36, COLOR_TEXT)


func bind_player(player: Node) -> void:
	if player == null:
		return
	var health_comp: HealthComponent = player.get_node_or_null("HealthComponent") as HealthComponent
	var stamina_comp: StaminaComponent = player.get_node_or_null("StaminaComponent") as StaminaComponent
	var lock_on_comp: LockOnComponent = player.get_node_or_null("LockOnComponent") as LockOnComponent
	_skill_component = player.get_node_or_null("PlayerSkillComponent")
	_player_camera = player.get_node_or_null("CameraPivot/SpringArm3D/Camera3D") as Camera3D
	if health_comp != null:
		bind_health(health_comp)
	if stamina_comp != null:
		bind_stamina(stamina_comp)
	if lock_on_comp != null:
		bind_lock_on(lock_on_comp)
	if _skill_component != null:
		if not _skill_component.selected_skill_changed.is_connected(_on_skill_changed):
			_skill_component.selected_skill_changed.connect(_on_skill_changed)
		if not _skill_component.cast_rejected.is_connected(_on_skill_rejected):
			_skill_component.cast_rejected.connect(_on_skill_rejected)
		if not _skill_component.skill_cast.is_connected(_on_skill_cast):
			_skill_component.skill_cast.connect(_on_skill_cast)
		_on_skill_changed(_skill_component.get_selected_skill(), _skill_component.selected_index)


func bind_health(health_comp: HealthComponent) -> void:
	if _connected_health != null and is_instance_valid(_connected_health) and _connected_health.health_changed.is_connected(_on_health_changed):
		_connected_health.health_changed.disconnect(_on_health_changed)
	_connected_health = health_comp
	_has_health_value = false
	if _connected_health != null:
		if not _connected_health.health_changed.is_connected(_on_health_changed):
			_connected_health.health_changed.connect(_on_health_changed)
		update_health(_connected_health.get_health(), _connected_health.get_max_health())


func bind_stamina(stamina_comp: StaminaComponent) -> void:
	if _connected_stamina != null and is_instance_valid(_connected_stamina) and _connected_stamina.stamina_changed.is_connected(_on_stamina_changed):
		_connected_stamina.stamina_changed.disconnect(_on_stamina_changed)
	_connected_stamina = stamina_comp
	_has_stamina_value = false
	if _connected_stamina != null:
		if not _connected_stamina.stamina_changed.is_connected(_on_stamina_changed):
			_connected_stamina.stamina_changed.connect(_on_stamina_changed)
		update_stamina(_connected_stamina.get_stamina(), _connected_stamina.get_max_stamina())


func update_health(current: float, max_val: float) -> void:
	if health_bar == null:
		return
	health_bar.max_value = max_val
	health_trail_bar.max_value = max_val
	var previous: float = _health_value
	health_bar.value = current
	if not _has_health_value or current >= previous:
		_stop_tween(_health_tween)
		health_trail_bar.value = current
	else:
		_stop_tween(_health_tween)
		health_trail_bar.value = maxf(health_trail_bar.value, previous)
		_health_tween = _animate_trail(health_trail_bar, current, TRANSITION_STATUS)
	_health_value = current
	_has_health_value = true
	health_label.text = "%d / %d" % [roundi(current), roundi(max_val)]
	low_health_accent.visible = max_val > 0.0 and current / max_val <= 0.30


func update_stamina(current: float, max_val: float) -> void:
	if stamina_bar == null:
		return
	stamina_bar.max_value = max_val
	stamina_trail_bar.max_value = max_val
	var previous: float = _stamina_value
	stamina_bar.value = current
	if not _has_stamina_value or current >= previous:
		_stop_tween(_stamina_tween)
		stamina_trail_bar.value = current
	else:
		_stop_tween(_stamina_tween)
		stamina_trail_bar.value = maxf(stamina_trail_bar.value, previous)
		_stamina_tween = _animate_trail(stamina_trail_bar, current, TRANSITION_FAST)
	_stamina_value = current
	_has_stamina_value = true
	if stamina_label != null:
		stamina_label.text = "%d / %d" % [roundi(current), roundi(max_val)]


func _animate_trail(bar: ProgressBar, target_value: float, duration: float) -> Tween:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(bar, "value", target_value, duration)
	return tween


func bind_lock_on(lock_on_comp: LockOnComponent) -> void:
	if _connected_lock_on != null and is_instance_valid(_connected_lock_on):
		for signal_name: String in ["target_locked", "target_changed", "target_unlocked"]:
			var signal_ref: Signal = _connected_lock_on.get(signal_name)
			var callback: Callable = Callable(self, "_on_" + signal_name)
			if signal_ref.is_connected(callback):
				signal_ref.disconnect(callback)
	_connected_lock_on = lock_on_comp
	if _connected_lock_on == null:
		unbind_target()
		return
	_connected_lock_on.target_locked.connect(_on_target_locked)
	_connected_lock_on.target_changed.connect(_on_target_changed)
	_connected_lock_on.target_unlocked.connect(_on_target_unlocked)
	if _connected_lock_on.is_locked_on:
		bind_target(_connected_lock_on.current_target)


func bind_target(target: LockOnTarget) -> void:
	unbind_target()
	if target == null or not is_instance_valid(target) or not target.is_available():
		return
	var target_health: HealthComponent = _get_target_health(target)
	if target_health == null or target_health.is_dead():
		return
	_connected_target = target
	_connected_target_health = target_health
	target_health.health_changed.connect(_on_target_health_changed)
	target_health.died.connect(_on_target_died)
	var target_parent: Node = target.get_parent()
	target_name_label.text = "SOLDIER" if target_parent is SoldierEnemy else target.name.replace("Dummy_", "DUMMY ").to_upper()
	_has_target_health_value = false
	update_target_health(target_health.get_health(), target_health.get_max_health())
	_show_target()


func unbind_target() -> void:
	if _connected_target_health != null and is_instance_valid(_connected_target_health):
		if _connected_target_health.health_changed.is_connected(_on_target_health_changed):
			_connected_target_health.health_changed.disconnect(_on_target_health_changed)
		if _connected_target_health.died.is_connected(_on_target_died):
			_connected_target_health.died.disconnect(_on_target_died)
	_connected_target = null
	_connected_target_health = null
	_has_target_health_value = false
	_hide_target()


func update_target_health(current: float, max_val: float) -> void:
	target_health_bar.max_value = max_val
	target_health_trail_bar.max_value = max_val
	var previous: float = _target_health_value
	target_health_bar.value = current
	if not _has_target_health_value or current >= previous:
		_stop_tween(_target_health_tween)
		target_health_trail_bar.value = current
	else:
		_stop_tween(_target_health_tween)
		target_health_trail_bar.value = maxf(target_health_trail_bar.value, previous)
		_target_health_tween = _animate_trail(target_health_trail_bar, current, TRANSITION_STATUS)
	_target_health_value = current
	_has_target_health_value = true
	target_health_label.text = "%d / %d" % [roundi(current), roundi(max_val)]


func _show_target() -> void:
	_stop_tween(_target_visibility_tween)
	target_container.visible = true
	target_container.modulate.a = 0.0
	_target_visibility_tween = create_tween()
	_target_visibility_tween.tween_property(target_container, "modulate:a", 1.0, 0.16)


func _hide_target() -> void:
	_stop_tween(_target_visibility_tween)
	target_container.visible = false
	target_container.modulate.a = 0.0


func _hide_target_immediately() -> void:
	if target_container != null:
		target_container.visible = false
		target_container.modulate.a = 0.0


func _stop_tween(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()


func _on_health_changed(current: float, max_val: float) -> void:
	update_health(current, max_val)


func _on_stamina_changed(current: float, max_val: float) -> void:
	update_stamina(current, max_val)


func _on_skill_changed(skill: Resource, _index: int) -> void:
	if skill == null:
		return
	skill_name_label.text = skill.display_name
	skill_cost_label.text = "E SELECT  /  Q CAST  /  %d SP" % roundi(skill.stamina_cost)
	skill_hint_label.text = "READY"


func _on_skill_rejected(_skill: Resource, reason: String) -> void:
	if skill_hint_label == null:
		return
	skill_hint_label.text = reason
	skill_hint_label.modulate = Color(1.0, 0.55, 0.55, 1.0)
	var tween := create_tween()
	tween.tween_property(skill_hint_label, "modulate", Color.WHITE, 0.45)


func _on_skill_cast(skill: Resource) -> void:
	if skill_hint_label == null:
		return
	skill_hint_label.text = "CAST  %s" % skill.display_name.to_upper()
	skill_hint_label.modulate = COLOR_ACCENT
	var tween := create_tween()
	tween.tween_interval(0.55)
	tween.tween_callback(func() -> void:
		if _skill_component != null and _skill_component.get_cooldown_ratio() > 0.0:
			skill_hint_label.text = "COOLDOWN"
		else:
			skill_hint_label.text = "READY"
	)


func _on_target_locked(target: LockOnTarget) -> void:
	bind_target(target)


func _on_target_changed(new_target: LockOnTarget, _old_target: LockOnTarget) -> void:
	bind_target(new_target)


func _on_target_unlocked() -> void:
	unbind_target()


func _on_target_health_changed(current: float, max_val: float) -> void:
	update_target_health(current, max_val)


func _on_target_died() -> void:
	unbind_target()


func _get_target_health(target: Node) -> HealthComponent:
	if target == null:
		return null
	var health: HealthComponent = target.get_node_or_null("HealthComponent") as HealthComponent
	if health == null and target.get_parent() != null:
		health = target.get_parent().get_node_or_null("HealthComponent") as HealthComponent
	return health


func _set_mouse_filter_recursive(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_mouse_filter_recursive(child)
