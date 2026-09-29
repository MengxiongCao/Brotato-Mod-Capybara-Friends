extends Line2D

# ============================================================
# 节点路径
# ============================================================

# 当前结构：
#
# Sprite
# ├── TrailSocket       Position2D
# └── capybara_line_effect
#
export(NodePath) var socket_path := NodePath("../TrailSocket")

# Line2D 的父节点就是 Sprite，所以默认写 ".."
export(NodePath) var visual_sprite_path := NodePath("..")


# ============================================================
# 翻转修正
# ============================================================

# 开启后，自动处理 Sprite.flip_h 和 Sprite.flip_v。
export(bool) var compensate_sprite_flip := true

# 翻转发生时清空旧轨迹，避免新旧两个刀尖位置被连起来。
export(bool) var clear_on_flip := true

# 默认使用 Sprite 显示矩形的中心作为翻转轴。
# 能自动适配 centered、offset、region 和帧动画。
export(bool) var use_sprite_rect_center_as_flip_pivot := true

# 不使用 Sprite 矩形中心时，手动指定翻转中心。
export(Vector2) var manual_flip_pivot := Vector2.ZERO


# ============================================================
# 更新方式
# ============================================================

# 武器外观、AnimationPlayer、flip_h 通常在普通帧更新，
# 因此默认使用 _process。
#
# 武器完全在 _physics_process 中更新时可以开启。
export(bool) var sample_in_physics := false


# ============================================================
# 轨迹参数
# ============================================================

export(bool) var trail_enabled := true

export(int) var max_points := 28

# 移动超过这个距离才记录新点。
export(float) var min_point_distance := 0.8

# 每段最大长度，移动过快时自动插值补点。
export(float) var max_segment_length := 12.0

# 超过这个距离视为瞬移，直接清空旧轨迹。
export(float) var max_jump_distance := 180.0

# 轨迹点存活时间。
export(float) var max_lifetime := 0.25

export(float) var trail_width := 10.0

# 尾端宽度倍率。
export(float, 0.0, 1.0) var end_width := 0.15


# ============================================================
# 颜色和呼吸效果
# ============================================================

export(Gradient) var trail_gradient

export(float) var flow_speed := 3.8

export(float, 0.0, 1.0) var pulse_strength := 0.12

export(float, 0.0, 1.0) var base_alpha := 0.9


# ============================================================
# 内部变量
# ============================================================

var _socket: Node2D = null
var _visual_sprite: Sprite = null

# 轨迹数据始终保存为世界坐标。
var _world_points := []
var _point_ages := []

var _time := 0.0

var _last_flip_h := false
var _last_flip_v := false

# 用于检测 scale.x 正负导致的矩阵镜像。
var _last_transform_mirror_sign := 1


# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	_socket = get_node_or_null(socket_path) as Node2D
	_visual_sprite = get_node_or_null(visual_sprite_path) as Sprite

	if _socket == null:
		push_error(
			"WeaponTrail: 找不到 TrailSocket，路径为："
			+ str(socket_path)
		)
		_disable_trail_node()
		return

	if _visual_sprite == null:
		push_error(
			"WeaponTrail: 找不到 Sprite，路径为："
			+ str(visual_sprite_path)
		)
		_disable_trail_node()
		return

	# Line2D 不再继承父节点的旋转、缩放和翻转。
	set_as_toplevel(true)

	# 清除启用 top-level 前继承到的局部变换。
	global_transform = Transform2D()

	width = trail_width
	joint_mode = Line2D.LINE_JOINT_ROUND
	begin_cap_mode = Line2D.LINE_CAP_ROUND
	end_cap_mode = Line2D.LINE_CAP_ROUND

	_setup_gradient()
	_setup_width_curve()

	_last_flip_h = _visual_sprite.flip_h
	_last_flip_v = _visual_sprite.flip_v
	_last_transform_mirror_sign = _get_transform_mirror_sign()

	set_process(not sample_in_physics)
	set_physics_process(sample_in_physics)

	clear_points()


func _disable_trail_node() -> void:
	set_process(false)
	set_physics_process(false)
	visible = false


# ============================================================
# 帧更新
# ============================================================

func _process(delta: float) -> void:
	_update_trail(delta)


func _physics_process(delta: float) -> void:
	_update_trail(delta)


func _update_trail(delta: float) -> void:
	if not trail_enabled:
		_age_points(delta)
		_update_line()
		return

	if not is_instance_valid(_socket):
		clear_trail()
		return

	if not is_instance_valid(_visual_sprite):
		clear_trail()
		return

	_time += delta

	# 确保本帧修改过的位置、旋转和缩放已更新。
	_visual_sprite.force_update_transform()
	_socket.force_update_transform()

	var current_flip_h := _visual_sprite.flip_h
	var current_flip_v := _visual_sprite.flip_v
	var current_mirror_sign := _get_transform_mirror_sign()

	var flip_changed := (
		current_flip_h != _last_flip_h
		or current_flip_v != _last_flip_v
		or current_mirror_sign != _last_transform_mirror_sign
	)

	var socket_world_position := _get_corrected_socket_world_position()

	# 翻转的一瞬间，原来的刀尖轨迹与新刀尖轨迹不应相连。
	if flip_changed and clear_on_flip:
		clear_trail()
		_insert_world_point(socket_world_position)
	else:
		_sample_world_position(socket_world_position)

	_last_flip_h = current_flip_h
	_last_flip_v = current_flip_v
	_last_transform_mirror_sign = current_mirror_sign

	_age_points(delta)
	_update_line()
	_update_energy()


# ============================================================
# 获取修正后的刀尖世界坐标
# ============================================================

func _get_corrected_socket_world_position() -> Vector2:
	# 先取得 TrailSocket 相对于 Sprite 的局部位置。
	#
	# Sprite.flip_h 不会改变子节点的 Transform，
	# 因此这里得到的是编辑器中未翻转时的位置。
	var socket_local_position := _visual_sprite.to_local(
		_socket.global_position
	)

	if compensate_sprite_flip:
		var flip_pivot := _get_flip_pivot()

		if _visual_sprite.flip_h:
			socket_local_position.x = (
				flip_pivot.x * 2.0
				- socket_local_position.x
			)

		if _visual_sprite.flip_v:
			socket_local_position.y = (
				flip_pivot.y * 2.0
				- socket_local_position.y
			)

	# 使用 Sprite 的原始矩阵把修正后的局部坐标转换成世界坐标。
	#
	# 不读取 global_scale，也不手动计算 rotation，
	# 避免负缩放分解导致的 Y 轴和 180 度问题。
	return _visual_sprite.global_transform.xform(
		socket_local_position
	)


func _get_flip_pivot() -> Vector2:
	if not use_sprite_rect_center_as_flip_pivot:
		return manual_flip_pivot

	var sprite_rect: Rect2 = _visual_sprite.get_rect()

	return (
		sprite_rect.position
		+ sprite_rect.size * 0.5
	)


# ============================================================
# 检测 Transform 矩阵是否发生镜像
# ============================================================

func _get_transform_mirror_sign() -> int:
	var sprite_transform: Transform2D = _visual_sprite.global_transform

	# Transform2D 的两个基向量叉积相当于二维行列式。
	# 小于 0 代表矩阵中存在奇数次镜像。
	var determinant := sprite_transform.x.cross(
		sprite_transform.y
	)

	if determinant < 0.0:
		return -1

	return 1


# ============================================================
# 采样世界坐标
# ============================================================

func _sample_world_position(new_position: Vector2) -> void:
	if _world_points.empty():
		_insert_world_point(new_position)
		return

	var newest_position: Vector2 = _world_points[0]
	var distance := newest_position.distance_to(new_position)

	# 瞬移时不连接远距离位置。
	if distance > max_jump_distance:
		clear_trail()
		_insert_world_point(new_position)
		return

	if distance < min_point_distance:
		return

	# 移动过快时自动补点。
	if (
		max_segment_length > 0.0
		and distance > max_segment_length
	):
		var segment_count := int(
			ceil(distance / max_segment_length)
		)

		for segment_index in range(1, segment_count + 1):
			var ratio := (
				float(segment_index)
				/ float(segment_count)
			)

			var interpolated_position := (
				newest_position.linear_interpolate(
					new_position,
					ratio
				)
			)

			_insert_world_point(interpolated_position)

		return

	_insert_world_point(new_position)


func _insert_world_point(world_position: Vector2) -> void:
	_world_points.insert(0, world_position)
	_point_ages.insert(0, 0.0)

	while _world_points.size() > max_points:
		_world_points.pop_back()
		_point_ages.pop_back()


# ============================================================
# 生命周期
# ============================================================

func _age_points(delta: float) -> void:
	for index in range(_point_ages.size()):
		_point_ages[index] += delta

	while (
		_point_ages.size() > 0
		and _point_ages.back() >= max_lifetime
	):
		_point_ages.pop_back()
		_world_points.pop_back()


# ============================================================
# 更新 Line2D
# ============================================================

func _update_line() -> void:
	if _world_points.size() < 2:
		clear_points()
		return

	var local_points := PoolVector2Array()

	# Line2D 的 points 使用局部坐标，因此绘制前必须把保存的
	# 世界坐标转换到当前 Line2D 的局部空间。:contentReference[oaicite:2]{index=2}
	var inverse_transform := global_transform.affine_inverse()

	for world_position in _world_points:
		local_points.append(
			inverse_transform.xform(world_position)
		)

	points = local_points


# ============================================================
# 动态能量
# ============================================================

func _update_energy() -> void:
	var pulse := (
		sin(_time * flow_speed)
		* pulse_strength
	)

	self_modulate.a = clamp(
		base_alpha + pulse,
		0.0,
		1.0
	)


# ============================================================
# 渐变
# ============================================================

func _setup_gradient() -> void:
	if trail_gradient != null:
		gradient = trail_gradient.duplicate()
		return

	var default_gradient := Gradient.new()

	default_gradient.set_color(
		0,
		Color(0.95, 0.45, 1.0, 0.95)
	)

	default_gradient.set_color(
		1,
		Color(0.25, 0.15, 0.45, 0.0)
	)

	gradient = default_gradient


func _setup_width_curve() -> void:
	var curve := Curve.new()

	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(0.55, 0.75))
	curve.add_point(Vector2(1.0, end_width))

	width_curve = curve


# ============================================================
# 外部控制
# ============================================================

func start_trail(clear_old_points: bool = true) -> void:
	if clear_old_points:
		clear_trail()

	trail_enabled = true
	visible = true


func stop_trail(clear_immediately: bool = false) -> void:
	trail_enabled = false

	if clear_immediately:
		clear_trail()


func clear_trail() -> void:
	_world_points.clear()
	_point_ages.clear()
	clear_points()


func set_socket(new_socket: Node2D) -> void:
	if new_socket == _socket:
		return

	clear_trail()
	_socket = new_socket


func _exit_tree() -> void:
	clear_trail()
