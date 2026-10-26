class_name HudAngledPanel
extends PanelContainer

@export var cut_size: float = 14.0
@export var fill_color: Color = Color(0.03, 0.055, 0.11, 0.58)
@export var border_color: Color = Color(0.86, 0.94, 1.0, 0.68)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var width: float = size.x
	var height: float = size.y
	if width <= 1.0 or height <= 1.0:
		return
	var cut: float = minf(cut_size, minf(width, height) * 0.35)
	var points := PackedVector2Array([
		Vector2(cut, 0.0), Vector2(width, 0.0), Vector2(width - cut, height), Vector2(0.0, height),
	])
	draw_colored_polygon(points, fill_color)
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), border_color, 1.0, true)
