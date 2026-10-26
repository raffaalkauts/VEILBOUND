class_name HudAngledBar
extends ProgressBar

@export var cut_size: float = 8.0
@export var background_color: Color = Color(0.02, 0.035, 0.07, 0.86)
@export var fill_start: Color = Color.WHITE
@export var fill_end: Color = Color.WHITE
@export var border_color: Color = Color(0.86, 0.94, 1.0, 0.68)

# Phase 2.8: the gradient fill used to be drawn as one coloured polygon per
# 10-px band, which cost dozens of draw calls per bar every frame. The gradient
# is now baked once into a 1-D gradient texture and mapped to a single polygon
# via per-vertex UVs. Visual result is identical (actually smoother); draw
# volume drops from ~N polygons per bar to one.
var _gradient_texture: GradientTexture1D


func _ready() -> void:
	show_percentage = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	value_changed.connect(_on_value_changed)
	# The angled polygon in _draw() is the only visible surface; the default
	# ProgressBar theme styleboxes are dead draw work otherwise.
	var empty := StyleBoxEmpty.new()
	add_theme_stylebox_override("background", empty)
	add_theme_stylebox_override("fill", empty)
	_ensure_gradient_texture()
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _ensure_gradient_texture() -> void:
	if _gradient_texture != null:
		return
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	gradient.colors = PackedColorArray([fill_start, fill_end])
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	texture.width = 32
	_gradient_texture = texture


func _on_value_changed(_new_value: float) -> void:
	queue_redraw()


func _draw() -> void:
	var width: float = size.x
	var height: float = size.y
	if width <= 1.0 or height <= 1.0:
		return
	var cut: float = minf(cut_size, minf(width, height) * 0.45)
	var background := PackedVector2Array([
		Vector2(cut, 0.0), Vector2(width, 0.0), Vector2(width - cut, height), Vector2(0.0, height),
	])
	draw_colored_polygon(background, background_color)

	var ratio: float = clampf(value / maxf(max_value, 0.001), 0.0, 1.0)
	var fill_width: float = width * ratio
	if fill_width > 0.5:
		var fill_cut: float = minf(cut, fill_width * 0.45)
		var fill_points := PackedVector2Array([
			Vector2(fill_cut, 0.0), Vector2(fill_width, 0.0), Vector2(maxf(0.0, fill_width - fill_cut), height), Vector2(0.0, height),
		])
		if fill_start.is_equal_approx(fill_end):
			draw_colored_polygon(fill_points, fill_start)
		else:
			# One polygon with UV-mapped gradient texture replaces the old
			# band-per-10px loop (which issued up to ~40 draw commands).
			var uvs := PackedVector2Array([
				Vector2(0.0, 0.5), Vector2(1.0, 0.5), Vector2(1.0, 0.5), Vector2(0.0, 0.5),
			])
			var white := PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE])
			draw_polygon(fill_points, white, uvs, _gradient_texture)
		draw_polyline(PackedVector2Array([fill_points[0], fill_points[1], fill_points[2], fill_points[3], fill_points[0]]), Color(fill_end, 0.22), 1.0, true)
	draw_polyline(PackedVector2Array([background[0], background[1], background[2], background[3], background[0]]), border_color, 1.0, true)
