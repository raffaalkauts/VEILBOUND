class_name HudDiamondSlot
extends Control

@export var slot_text: String = ""
@export var active: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := Label.new()
	label.text = slot_text
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color("#9FE8FF") if active else Color("#F7FBFF"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var half: float = minf(size.x, size.y) * 0.45
	var points := PackedVector2Array([
		center + Vector2(0.0, -half), center + Vector2(half, 0.0),
		center + Vector2(0.0, half), center + Vector2(-half, 0.0),
	])
	draw_colored_polygon(points, Color(0.12, 0.30, 0.40, 0.72) if active else Color(0.03, 0.08, 0.15, 0.76))
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), Color("#9FE8FF") if active else Color("#DCF0FFB3"), 1.0, true)
