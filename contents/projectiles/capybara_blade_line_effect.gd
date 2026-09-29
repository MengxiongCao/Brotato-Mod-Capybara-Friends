class_name BladeRibbonTrail
extends Node2D


export(NodePath) var root_socket_path = NodePath("../TrailRootSocket")
export(NodePath) var tip_socket_path = NodePath("../TrailTipSocket")
export(NodePath) var visual_sprite_path = NodePath("..")

export(bool) var compensate_sprite_flip = true
export(bool) var clear_on_flip = true

export(bool) var use_sprite_rect_center_as_flip_pivot = true
export(Vector2) var manual_flip_pivot = Vector2.ZERO

export(bool) var sample_in_physics = false
export(bool) var trail_enabled = true

export(int) var max_sections = 24

export(float) var min_section_distance = 1.0
export(float) var max_section_distance = 14.0
export(float) var max_jump_distance = 180.0

export(float) var max_lifetime = 0.22
export(float) var blade_width_scale = 1.0

# 刀光从当前刀刃处保持完整宽度，沿拖尾方向逐渐变窄。
export(bool) var taper_enabled = true

# 拖尾最末端保留的宽度比例。
# 0.0为完全尖点，0.03到0.08会形成较稳定的尖尾。
export(float, 0.0, 1.0) var taper_end_width_ratio = 0.04

# 宽度递减曲线。
# 1.0为线性，数值越大越靠近末端才快速收尖。
export(float, 0.1, 4.0) var taper_power = 1.5

export(Gradient) var trail_gradient

export(float) var flow_speed = 4.0
export(float, 0.0, 1.0) var pulse_strength = 0.12
export(float, 0.0, 1.0) var base_alpha = 0.9

# 面积过小的三角形不绘制。
export(float) var minimum_triangle_area = 0.05

# 任意两点距离过小时不绘制，防止尖尾生成退化三角形。
export(float) var minimum_triangle_edge_length = 0.01

# 相对面积阈值。用于过滤“很长但几乎共线”的极薄三角形。
export(float) var minimum_triangle_relative_area = 0.000001

# 根部和尖端距离过小时，不记录该截面
export(float) var minimum_blade_width = 0.5

# 自动调整相邻截面的根部和尖端顺序
export(bool) var fix_crossed_sections = true


var _root_socket: Node2D = null
var _tip_socket: Node2D = null
var _visual_sprite: Sprite = null

var _world_root_points = []
var _world_tip_points = []
var _section_ages = []

var _time = 0.0

var _last_flip_h = false
var _last_flip_v = false
var _last_transform_mirror_sign = 1


func _ready() -> void:
	_root_socket = get_node_or_null(root_socket_path) as Node2D
	_tip_socket = get_node_or_null(tip_socket_path) as Node2D
	_visual_sprite = get_node_or_null(visual_sprite_path) as Sprite

	if _root_socket == null:
		push_error("BladeRibbonTrail：找不到 TrailRootSocket，路径：" + str(root_socket_path))
		_disable_trail()
		return

	if _tip_socket == null:
		push_error("BladeRibbonTrail：找不到 TrailTipSocket，路径：" + str(tip_socket_path))
		_disable_trail()
		return

	if _visual_sprite == null:
		push_error("BladeRibbonTrail：找不到 Sprite，路径：" + str(visual_sprite_path))
		_disable_trail()
		return

	# 使用世界坐标绘制，不继承父节点的旋转和缩放
	set_as_toplevel(true)
	global_transform = Transform2D()

	_setup_gradient()

	_last_flip_h = _visual_sprite.flip_h
	_last_flip_v = _visual_sprite.flip_v
	_last_transform_mirror_sign = _get_transform_mirror_sign()

	set_process(not sample_in_physics)
	set_physics_process(sample_in_physics)

	clear_trail()


func _disable_trail() -> void:
	set_process(false)
	set_physics_process(false)
	visible = false
	clear_trail()


func _process(delta: float) -> void:
	_update_trail(delta)


func _physics_process(delta: float) -> void:
	_update_trail(delta)


func _update_trail(delta: float) -> void:
	if not is_instance_valid(_visual_sprite):
		visible = false
		clear_trail()
		return

	if not _is_visual_sprite_rendered():
		visible = false
		clear_trail()
		return

	visible = true

	if not trail_enabled:
		_age_sections(delta)
		update()
		return

	if not is_instance_valid(_root_socket):
		clear_trail()
		return

	if not is_instance_valid(_tip_socket):
		clear_trail()
		return

	_time += delta

	_visual_sprite.force_update_transform()
	_root_socket.force_update_transform()
	_tip_socket.force_update_transform()

	var current_flip_h = _visual_sprite.flip_h
	var current_flip_v = _visual_sprite.flip_v
	var current_mirror_sign = _get_transform_mirror_sign()

	var flip_changed = (
		current_flip_h != _last_flip_h
		or current_flip_v != _last_flip_v
		or current_mirror_sign != _last_transform_mirror_sign
	)

	var root_world_position = _get_corrected_socket_world_position(_root_socket)
	var tip_world_position = _get_corrected_socket_world_position(_tip_socket)

	if not _is_valid_vector(root_world_position):
		clear_trail()
		return

	if not _is_valid_vector(tip_world_position):
		clear_trail()
		return

	var section_center = (root_world_position + tip_world_position) * 0.5
	var section_half_vector = (
		(tip_world_position - root_world_position)
		* 0.5
		* blade_width_scale
	)

	root_world_position = section_center - section_half_vector
	tip_world_position = section_center + section_half_vector

	if flip_changed and clear_on_flip:
		clear_trail()
		_insert_world_section(root_world_position, tip_world_position)
	else:
		_sample_world_section(root_world_position, tip_world_position)

	_last_flip_h = current_flip_h
	_last_flip_v = current_flip_v
	_last_transform_mirror_sign = current_mirror_sign

	_age_sections(delta)
	update()


func _is_visual_sprite_rendered() -> bool:
	if _visual_sprite.texture == null or not _visual_sprite.is_visible_in_tree():
		return false

	var effective_alpha = 1.0
	var current_node: Node = _visual_sprite
	while current_node != null:
		if current_node is CanvasItem:
			var canvas_item = current_node as CanvasItem
			effective_alpha *= canvas_item.modulate.a * canvas_item.self_modulate.a
			if effective_alpha <= 0.001:
				return false
		current_node = current_node.get_parent()

	return true


func _get_corrected_socket_world_position(socket: Node2D) -> Vector2:
	var socket_local_position = _visual_sprite.to_local(socket.global_position)

	if compensate_sprite_flip:
		var flip_pivot = _get_flip_pivot()

		if _visual_sprite.flip_h:
			socket_local_position.x = flip_pivot.x * 2.0 - socket_local_position.x

		if _visual_sprite.flip_v:
			socket_local_position.y = flip_pivot.y * 2.0 - socket_local_position.y

	return _visual_sprite.global_transform.xform(socket_local_position)


func _get_flip_pivot() -> Vector2:
	if not use_sprite_rect_center_as_flip_pivot:
		return manual_flip_pivot

	var sprite_rect: Rect2 = _visual_sprite.get_rect()
	return sprite_rect.position + sprite_rect.size * 0.5


func _get_transform_mirror_sign() -> int:
	var sprite_transform = _visual_sprite.global_transform
	var determinant = sprite_transform.x.cross(sprite_transform.y)

	if determinant < 0.0:
		return -1

	return 1


func _sample_world_section(new_root_position: Vector2, new_tip_position: Vector2) -> void:
	if not _is_valid_vector(new_root_position):
		return

	if not _is_valid_vector(new_tip_position):
		return

	if _world_root_points.empty() or _world_tip_points.empty():
		_insert_world_section(new_root_position, new_tip_position)
		return

	var newest_root: Vector2 = _world_root_points[0]
	var newest_tip: Vector2 = _world_tip_points[0]

	var root_distance = newest_root.distance_to(new_root_position)
	var tip_distance = newest_tip.distance_to(new_tip_position)
	var movement_distance = max(root_distance, tip_distance)

	# 突然发生较大位移时，认为是传送或位置重置
	if movement_distance > max_jump_distance:
		clear_trail()
		_insert_world_section(new_root_position, new_tip_position)
		return

	if movement_distance < min_section_distance:
		return

	# 高速运动时补充中间截面
	if max_section_distance > 0.0 and movement_distance > max_section_distance:
		var section_count = int(ceil(movement_distance / max_section_distance))
		section_count = max(section_count, 1)

		for section_index in range(1, section_count + 1):
			var ratio = float(section_index) / float(section_count)

			var interpolated_root = newest_root.linear_interpolate(
				new_root_position,
				ratio
			)

			var interpolated_tip = newest_tip.linear_interpolate(
				new_tip_position,
				ratio
			)

			_insert_world_section(interpolated_root, interpolated_tip)

		return

	_insert_world_section(new_root_position, new_tip_position)


func _insert_world_section(root_position: Vector2, tip_position: Vector2) -> void:
	if not _is_valid_vector(root_position):
		return

	if not _is_valid_vector(tip_position):
		return

	var new_root = root_position
	var new_tip = tip_position

	var safe_minimum_width = max(minimum_blade_width, 0.0)
	var minimum_width_squared = safe_minimum_width * safe_minimum_width

	if new_root.distance_squared_to(new_tip) < minimum_width_squared:
		return

	if not _world_root_points.empty() and not _world_tip_points.empty():
		var newest_root: Vector2 = _world_root_points[0]
		var newest_tip: Vector2 = _world_tip_points[0]

		# 比较两种连接顺序，防止相邻截面发生交叉
		if fix_crossed_sections:
			var normal_cost = (
				newest_root.distance_squared_to(new_root)
				+ newest_tip.distance_squared_to(new_tip)
			)

			var swapped_cost = (
				newest_root.distance_squared_to(new_tip)
				+ newest_tip.distance_squared_to(new_root)
			)

			if swapped_cost < normal_cost:
				var temporary_point = new_root
				new_root = new_tip
				new_tip = temporary_point

		var root_same = newest_root.distance_squared_to(new_root) < 0.0001
		var tip_same = newest_tip.distance_squared_to(new_tip) < 0.0001

		# 完全相同的截面不重复添加
		if root_same and tip_same:
			return

	_world_root_points.insert(0, new_root)
	_world_tip_points.insert(0, new_tip)
	_section_ages.insert(0, 0.0)

	var safe_max_sections = max(max_sections, 2)

	while _world_root_points.size() > safe_max_sections:
		_world_root_points.pop_back()
		_world_tip_points.pop_back()
		_section_ages.pop_back()


func _age_sections(delta: float) -> void:
	var safe_lifetime = max(max_lifetime, 0.001)
	var section_count = min(
		_section_ages.size(),
		min(_world_root_points.size(), _world_tip_points.size())
	)

	# 数组长度意外不一致时，删除多出的数据
	while _section_ages.size() > section_count:
		_section_ages.pop_back()

	while _world_root_points.size() > section_count:
		_world_root_points.pop_back()

	while _world_tip_points.size() > section_count:
		_world_tip_points.pop_back()

	for index in range(_section_ages.size()):
		_section_ages[index] += delta

	while _section_ages.size() > 0 and _section_ages.back() >= safe_lifetime:
		_section_ages.pop_back()
		_world_root_points.pop_back()
		_world_tip_points.pop_back()


func _draw() -> void:
	if trail_gradient == null:
		return
	if "visible" in get_parent() and "modulate" in get_parent() and (not get_parent().visible or get_parent().modulate.a <= 0.1):
		return

	var section_count = min(
		_world_root_points.size(),
		min(_world_tip_points.size(), _section_ages.size())
	)

	if section_count < 2:
		return

	var safe_lifetime = max(max_lifetime, 0.001)
	var pulse = sin(_time * flow_speed) * pulse_strength
	var pulse_alpha = clamp(base_alpha + pulse, 0.0, 1.0)
	var inverse_transform = global_transform.affine_inverse()

	for index in range(section_count - 2, -1, -1):
		var next_index = index + 1

		var root_a: Vector2 = inverse_transform.xform(
			_world_root_points[index]
		)

		var tip_a: Vector2 = inverse_transform.xform(
			_world_tip_points[index]
		)

		var root_b: Vector2 = inverse_transform.xform(
			_world_root_points[next_index]
		)

		var tip_b: Vector2 = inverse_transform.xform(
			_world_tip_points[next_index]
		)

		if not _is_valid_vector(root_a):
			continue

		if not _is_valid_vector(tip_a):
			continue

		if not _is_valid_vector(root_b):
			continue

		if not _is_valid_vector(tip_b):
			continue

		# 绘制阶段再次检查，避免相邻截面交叉
		if fix_crossed_sections:
			var normal_cost = (
				root_a.distance_squared_to(root_b)
				+ tip_a.distance_squared_to(tip_b)
			)

			var swapped_cost = (
				root_a.distance_squared_to(tip_b)
				+ tip_a.distance_squared_to(root_b)
			)

			if swapped_cost < normal_cost:
				var temporary_point = root_b
				root_b = tip_b
				tip_b = temporary_point

		# index为0的是最新截面，也就是刀刃当前的完整起始宽度。
		# index越大越靠近旧拖尾，宽度越小，最终形成尖尾。
		if taper_enabled:
			var progress_denominator = max(section_count - 1, 1)
			var taper_progress_a = float(index) / float(progress_denominator)
			var taper_progress_b = float(next_index) / float(progress_denominator)

			var width_ratio_a = _get_taper_width_ratio(taper_progress_a)
			var width_ratio_b = _get_taper_width_ratio(taper_progress_b)

			var center_a = (root_a + tip_a) * 0.5
			var half_width_a = (tip_a - root_a) * 0.5 * width_ratio_a
			root_a = center_a - half_width_a
			tip_a = center_a + half_width_a

			var center_b = (root_b + tip_b) * 0.5
			var half_width_b = (tip_b - root_b) * 0.5 * width_ratio_b
			root_b = center_b - half_width_b
			tip_b = center_b + half_width_b

		var age_a = clamp(
			_section_ages[index] / safe_lifetime,
			0.0,
			1.0
		)

		var age_b = clamp(
			_section_ages[next_index] / safe_lifetime,
			0.0,
			1.0
		)

		var color_a: Color = trail_gradient.interpolate(age_a)
		var color_b: Color = trail_gradient.interpolate(age_b)

		color_a.a *= pulse_alpha
		color_b.a *= pulse_alpha

		_draw_ribbon_section(
			root_a,
			tip_a,
			root_b,
			tip_b,
			color_a,
			color_b
		)


func _get_taper_width_ratio(progress: float) -> float:
	var safe_progress = clamp(progress, 0.0, 1.0)
	var safe_end_width = clamp(taper_end_width_ratio, 0.0, 1.0)
	var safe_power = max(taper_power, 0.01)

	var shaped_progress = pow(safe_progress, safe_power)

	return lerp(
		1.0,
		safe_end_width,
		shaped_progress
	)


func _draw_ribbon_section(
	root_a: Vector2,
	tip_a: Vector2,
	root_b: Vector2,
	tip_b: Vector2,
	color_a: Color,
	color_b: Color
) -> void:
	# 方案A：
	# root_a、tip_a、tip_b
	# root_a、tip_b、root_b
	var area_a1 = _get_triangle_area(root_a, tip_a, tip_b)
	var area_a2 = _get_triangle_area(root_a, tip_b, root_b)
	var quality_a = min(area_a1, area_a2)

	# 方案B：
	# root_a、tip_a、root_b
	# tip_a、tip_b、root_b
	var area_b1 = _get_triangle_area(root_a, tip_a, root_b)
	var area_b2 = _get_triangle_area(tip_a, tip_b, root_b)
	var quality_b = min(area_b1, area_b2)

	# 选择退化程度较低的对角线
	if quality_b > quality_a:
		_draw_triangle_safe(
			root_a,
			tip_a,
			root_b,
			color_a,
			color_a,
			color_b
		)

		_draw_triangle_safe(
			tip_a,
			tip_b,
			root_b,
			color_a,
			color_b,
			color_b
		)
	else:
		_draw_triangle_safe(
			root_a,
			tip_a,
			tip_b,
			color_a,
			color_a,
			color_b
		)

		_draw_triangle_safe(
			root_a,
			tip_b,
			root_b,
			color_a,
			color_b,
			color_b
		)


func _draw_triangle_safe(
	point_a: Vector2,
	point_b: Vector2,
	point_c: Vector2,
	color_a: Color,
	color_b: Color,
	color_c: Color
) -> void:
	if not _is_valid_vector(point_a):
		return

	if not _is_valid_vector(point_b):
		return

	if not _is_valid_vector(point_c):
		return

	var edge_ab: Vector2 = point_b - point_a
	var edge_bc: Vector2 = point_c - point_b
	var edge_ca: Vector2 = point_a - point_c

	var edge_ab_squared: float = edge_ab.length_squared()
	var edge_bc_squared: float = edge_bc.length_squared()
	var edge_ca_squared: float = edge_ca.length_squared()

	var safe_minimum_edge: float = max(
		minimum_triangle_edge_length,
		0.000001
	)
	var minimum_edge_squared: float = (
		safe_minimum_edge * safe_minimum_edge
	)

	# 尖尾收缩后，两个顶点可能几乎重合。
	# 这种三角形不交给绘制服务器。
	if edge_ab_squared <= minimum_edge_squared:
		return

	if edge_bc_squared <= minimum_edge_squared:
		return

	if edge_ca_squared <= minimum_edge_squared:
		return

	var signed_area: float = edge_ab.cross(point_c - point_a)

	if is_nan(signed_area) or is_inf(signed_area):
		return

	var triangle_area: float = abs(signed_area)

	if triangle_area < max(minimum_triangle_area, 0.0):
		return

	# 只检查绝对面积还不够。
	# 很长但几乎共线的三角形仍可能让Godot的多边形三角化失败。
	var maximum_edge_squared: float = max(
		edge_ab_squared,
		max(edge_bc_squared, edge_ca_squared)
	)

	if maximum_edge_squared <= 0.0:
		return

	var relative_area: float = triangle_area / maximum_edge_squared

	if relative_area < max(minimum_triangle_relative_area, 0.0):
		return

	var triangle = PoolVector2Array([
		point_a,
		point_b,
		point_c
	])

	var triangle_colors = PoolColorArray([
		color_a,
		color_b,
		color_c
	])

	# draw_polygon会先对多边形执行三角化。
	# 尖尾处的极薄三角形可能导致triangulation failed。
	# 这里已经明确只有三个点，直接绘制三角形基本图元即可。
	draw_primitive(
		triangle,
		triangle_colors,
		PoolVector2Array()
	)


func _get_triangle_area(point_a: Vector2, point_b: Vector2, point_c: Vector2) -> float:
	var edge_ab = point_b - point_a
	var edge_ac = point_c - point_a

	# 返回的是三角形实际面积的两倍，
	# 这里只用于判断是否退化
	return abs(edge_ab.cross(edge_ac))


func _is_valid_vector(value: Vector2) -> bool:
	if is_nan(value.x) or is_nan(value.y):
		return false

	if is_inf(value.x) or is_inf(value.y):
		return false

	return true


func _setup_gradient() -> void:
	if trail_gradient != null:
		trail_gradient = trail_gradient.duplicate()
		return

	trail_gradient = Gradient.new()

	trail_gradient.set_color(
		0,
		Color(1.0, 0.85, 1.0, 0.95)
	)

	trail_gradient.set_color(
		1,
		Color(0.35, 0.15, 0.75, 0.0)
	)


func start_trail(clear_old_sections: bool = true) -> void:
	if clear_old_sections:
		clear_trail()

	trail_enabled = true
	visible = true


func stop_trail(clear_immediately: bool = false) -> void:
	trail_enabled = false

	if clear_immediately:
		clear_trail()


func clear_trail() -> void:
	_world_root_points.clear()
	_world_tip_points.clear()
	_section_ages.clear()

	update()


func set_sockets(new_root_socket: Node2D, new_tip_socket: Node2D) -> void:
	clear_trail()

	_root_socket = new_root_socket
	_tip_socket = new_tip_socket


func _exit_tree() -> void:
	clear_trail()
