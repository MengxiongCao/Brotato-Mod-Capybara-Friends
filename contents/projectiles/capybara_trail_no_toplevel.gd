extends Line2D

export var max_points := 16
export var trail_width := 10.0
export var min_point_distance := 6.0
export var max_jump_distance := 160.0
export var max_segment_length := 20.0
export(Gradient) var trail_gradient
export var end_width = 1

var _global_points := []


func _ready() -> void:
	set_as_toplevel(false)

	position = Vector2.ZERO
	rotation = 0
	scale = Vector2.ONE

	width = trail_width
	joint_mode = Line2D.LINE_JOINT_ROUND
	begin_cap_mode = Line2D.LINE_CAP_ROUND
	end_cap_mode = Line2D.LINE_CAP_ROUND

	_setup_gradient()
	_setup_width_curve()


func _process(delta: float) -> void:
	var new_global_pos = get_parent().global_position

	if _global_points.size() > 0:
		var last_pos = _global_points[0]
		var diff = new_global_pos - last_pos
		var dist = diff.length()

		if dist < min_point_distance:
			_update_line_points()
			return

		if dist > max_jump_distance:
			_global_points.clear()
		else:
			if dist > max_segment_length:
				new_global_pos = last_pos + diff.normalized() * max_segment_length

	_global_points.insert(0, new_global_pos)

	while _global_points.size() > max_points:
		_global_points.remove(_global_points.size() - 1)

	_update_line_points()


func _update_line_points() -> void:
	var local_points := []
	var inv := get_global_transform().affine_inverse()

	for p in _global_points:
		local_points.append(inv.xform(p))

	points = PoolVector2Array(local_points)


func _setup_gradient() -> void:
	if trail_gradient:
		gradient = trail_gradient
	else:
		var g := Gradient.new()
		g.set_color(0, Color(1.0, 0.92, 0.55, 0.85))
		g.set_color(1, Color(1.0, 0.78, 0.25, 0.0))
		gradient = g


func _setup_width_curve() -> void:
	var c := Curve.new()
	c.add_point(Vector2(0.0, 1.0))
	c.add_point(Vector2(1.0, end_width))
	width_curve = c
