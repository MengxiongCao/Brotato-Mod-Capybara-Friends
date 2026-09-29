extends Line2D

export var max_points := 16
export var trail_width := 10.0
export var min_point_distance := 6.0
export var max_jump_distance := 160.0
export var max_segment_length := 20.0
export(Gradient) var trail_gradient
export var end_width := 0.2

var _points_global := []
onready var _target := get_parent()


func _ready() -> void:
	set_as_toplevel(true)  # ⭐关键

	width = trail_width
	joint_mode = Line2D.LINE_JOINT_ROUND
	begin_cap_mode = Line2D.LINE_CAP_ROUND
	end_cap_mode = Line2D.LINE_CAP_ROUND

	_setup_gradient()
	_setup_width_curve()


func _process(_delta: float) -> void:
	if _target == null:
		return

	var new_pos = _target.global_position

	# 没有点直接加入
	if _points_global.size() == 0:
		_points_global.append(new_pos)
		_update_line()
		return

	var last = _points_global[0]
	var diff = new_pos - last
	var dist = diff.length()

	# 太近不更新
	if dist < min_point_distance:
		_update_line()
		return

	# 跳跃太远 -> 重置
	if dist > max_jump_distance:
		_points_global.clear()
		_points_global.append(new_pos)
		_update_line()
		return

	# 限制最大步长（防抖）
	if dist > max_segment_length:
		new_pos = last + diff.normalized() * max_segment_length

	_points_global.insert(0, new_pos)

	while _points_global.size() > max_points:
		_points_global.pop_back()

	_update_line()


func _update_line() -> void:
	points = _points_global  # ⭐关键：直接用 global


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
