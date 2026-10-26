class_name HudCompass
extends Control

const DIRECTIONS: Array[String] = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
const BEARINGS: Array[float] = [0.0, 45.0, 90.0, 135.0, 180.0, 225.0, 270.0, 315.0]
const COMPASS_WIDTH_RATIO: float = 0.92
const COLOR_NORTH: Color = Color("#9FE8FF")
const COLOR_CARDINAL: Color = Color("#A9C1D6")
const COLOR_SHADOW: Color = Color(0.0, 0.0, 0.0, 0.75)

var _heading_degrees: float = 0.0
var _camera: Camera3D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func set_camera(camera: Camera3D) -> void:
	_camera = camera


func set_heading_from_camera(camera: Camera3D) -> void:
	_camera = camera
	if _camera == null or not is_instance_valid(_camera):
		return
	var forward: Vector3 = -_camera.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() <= 0.0001:
		return
	forward = forward.normalized()
	# World -Z is north, +X is east. Positive yaw moves clockwise on screen.
	_heading_degrees = fposmod(rad_to_deg(atan2(forward.x, -forward.z)), 360.0)
	queue_redraw()


func get_heading_degrees() -> float:
	return _heading_degrees


func get_direction_offset_degrees(direction: String) -> float:
	var index := DIRECTIONS.find(direction)
	if index < 0:
		return 0.0
	return _shortest_angle(BEARINGS[index] - _heading_degrees)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _shortest_angle(angle_degrees: float) -> float:
	return fposmod(angle_degrees + 180.0, 360.0) - 180.0


func _draw() -> void:
	var width := size.x
	var height := size.y
	if width <= 1.0 or height <= 1.0:
		return
	var font: Font = ThemeDB.fallback_font
	if font == null:
		return
	var center_x := width * 0.5
	var pixels_per_degree := width / 360.0
	var baseline_y: float = height * 0.5 + (font.get_ascent() - font.get_descent()) * 0.5
	for index in range(DIRECTIONS.size()):
		var offset_degrees := _shortest_angle(BEARINGS[index] - _heading_degrees)
		# Window wraps at the panel edge, exactly like the previous labels.
		if absf(offset_degrees) * pixels_per_degree > COMPASS_WIDTH_RATIO * width * 0.5:
			continue
		var is_north := DIRECTIONS[index] == "N"
		var font_size: int = 24 if is_north else 15
		var color: Color = COLOR_NORTH if is_north else COLOR_CARDINAL
		var text: String = DIRECTIONS[index]
		var text_width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var text_pos := Vector2(center_x + offset_degrees * pixels_per_degree - text_width * 0.5, baseline_y)
		draw_string(font, text_pos + Vector2(1.0, 1.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, COLOR_SHADOW)
		draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
	draw_line(Vector2(center_x, 2.0), Vector2(center_x, size.y - 2.0), COLOR_NORTH, 1.0)
	draw_line(Vector2(center_x - 10.0, size.y - 3.0), Vector2(center_x + 10.0, size.y - 3.0), Color(0.62, 0.91, 1.0, 0.7), 1.0)
