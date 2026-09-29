class_name CapybaraLinkLaser
extends Line2D


# 是否在没有目标且淡出完成后隐藏
export(bool) var hide_when_no_target = true

# 连线淡出所需时间
export(float, 0.01, 10.0) var fade_duration = 0.35

# 连线正常显示时的透明度
export(float, 0.0, 1.0) var initial_alpha = 1.0

# 激光沿宽度方向的渐变色
# 渐变左端对应线条的一侧
# 渐变右端对应线条的另一侧
export(Gradient) var laser_gradient

# 宽度渐变纹理的分辨率
# 越大越平滑，一般128到256已经足够
export(int, 8, 512) var capybara_width_gradient_resolution = 256

# 是否反转宽度渐变方向
export(bool) var capybara_reverse_width_gradient = false

# 两端圆形相对于线宽的半径倍率
export(float, 0.5, 3.0) var endpoint_radius_scale = 0.75

# 两端圆形的最小半径
export(float, 0.0, 100.0) var endpoint_min_radius = 3.0

# 外层光晕相对于内部圆形的倍率
export(float, 1.0, 4.0) var endpoint_glow_scale = 1.45

# 外层光晕透明度
export(float, 0.0, 1.0) var endpoint_glow_alpha = 0.7

# 端点圆形的多边形边数
# 越大越圆滑，但绘制开销也越高
export(int, 8, 128) var endpoint_circle_segments = 32

# 两个连接点的位置偏移
export(Vector2) var target_a_offset = Vector2.ZERO
export(Vector2) var target_b_offset = Vector2.ZERO


var target_a: Node2D = null
var target_b: Node2D = null

var has_valid_targets = false

# 淡出状态
var _is_fading = false
var _fade_elapsed_time = 0.0
var _fade_start_alpha = 1.0

# 运行时生成的宽度渐变纹理
var capybara_width_gradient_texture: ImageTexture = null


func _ready() -> void:
	has_valid_targets = false
	_is_fading = false
	_fade_elapsed_time = 0.0

	_apply_laser_gradient()
	_set_line_alpha(0.0)

	if hide_when_no_target:
		visible = false


# =========================================================
# 宽度方向渐变
# =========================================================

func _apply_laser_gradient() -> void:
	# 清除Line2D原生渐变。
	# 原生gradient固定沿线条长度方向变化。
	gradient = null

	# 纹理颜色会与default_color相乘，
	# 因此这里保持纯白色。
	default_color = Color(1.0, 1.0, 1.0, 1.0)

	if laser_gradient == null:
		texture = null
		capybara_width_gradient_texture = null
		update()
		return

	capybara_width_gradient_texture = _capybara_create_width_gradient_texture()

	texture = capybara_width_gradient_texture

	# X方向沿线条长度拉伸，
	# Y方向对应线条宽度。
	texture_mode = Line2D.LINE_TEXTURE_STRETCH

	update()


func _capybara_create_width_gradient_texture() -> ImageTexture:
	var capybara_resolution = max(capybara_width_gradient_resolution, 2)

	# 图片宽度只需要2像素。
	# 两列颜色完全一致，避免沿激光长度方向产生颜色变化。
	#
	# 图片高度对应Line2D的宽度方向。
	var capybara_image = Image.new()

	capybara_image.create(
		2,
		capybara_resolution,
		false,
		Image.FORMAT_RGBA8
	)

	capybara_image.lock()

	for capybara_y in range(capybara_resolution):
		var capybara_offset = float(capybara_y) / float(capybara_resolution - 1)

		if capybara_reverse_width_gradient:
			capybara_offset = 1.0 - capybara_offset

		var capybara_color = laser_gradient.interpolate(capybara_offset)

		# 两列使用相同颜色，
		# 所以颜色不会沿长度方向发生变化。
		capybara_image.set_pixel(
			0,
			capybara_y,
			capybara_color
		)

		capybara_image.set_pixel(
			1,
			capybara_y,
			capybara_color
		)

	capybara_image.unlock()

	var capybara_texture = ImageTexture.new()

	capybara_texture.create_from_image(
		capybara_image,
		Texture.FLAG_FILTER
	)

	return capybara_texture


# 在运行时修改laser_gradient后，
# 可以调用这个函数重新生成纹理
func capybara_rebuild_width_gradient() -> void:
	_apply_laser_gradient()


func _get_width_gradient_color(offset: float) -> Color:
	if laser_gradient == null:
		return default_color

	var capybara_offset = clamp(offset, 0.0, 1.0)

	if capybara_reverse_width_gradient:
		capybara_offset = 1.0 - capybara_offset

	return laser_gradient.interpolate(capybara_offset)


# =========================================================
# 绘制两端渐变圆形光点
# =========================================================

func _draw() -> void:
	if points.size() < 2:
		return

	var radius = max(
		width * endpoint_radius_scale,
		endpoint_min_radius
	)

	var glow_radius = radius * endpoint_glow_scale

	var point_a = points[0]
	var point_b = points[points.size() - 1]

	var line_direction = point_b - point_a
	var gradient_axis = Vector2.UP

	if line_direction.length_squared() > 0.0001:
		line_direction = line_direction.normalized()

		# 取激光方向的垂直方向。
		# 这就是Line2D的宽度方向。
		gradient_axis = Vector2(
			-line_direction.y,
			line_direction.x
		)

	# 先绘制外层渐变光晕
	_draw_gradient_endpoint_circle(
		point_a,
		glow_radius,
		endpoint_glow_alpha,
		gradient_axis
	)

	_draw_gradient_endpoint_circle(
		point_b,
		glow_radius,
		endpoint_glow_alpha,
		gradient_axis
	)

	# 再绘制内部渐变圆形
	_draw_gradient_endpoint_circle(
		point_a,
		radius,
		1.0,
		gradient_axis
	)

	_draw_gradient_endpoint_circle(
		point_b,
		radius,
		1.0,
		gradient_axis
	)


func _draw_gradient_endpoint_circle(center: Vector2, radius: float, alpha_multiplier: float, gradient_axis: Vector2) -> void:
	if radius <= 0.0:
		return

	var safe_alpha = clamp(alpha_multiplier, 0.0, 1.0)

	# 没有设置渐变时，使用普通纯色圆形。
	if laser_gradient == null:
		var fallback_color = default_color
		fallback_color.a *= safe_alpha

		draw_circle(
			center,
			radius,
			fallback_color
		)

		return

	# 渐变纹理尚未生成时，
	# 暂时使用渐变中间颜色。
	if capybara_width_gradient_texture == null:
		var fallback_color = _get_width_gradient_color(0.5)
		fallback_color.a *= safe_alpha

		draw_circle(
			center,
			radius,
			fallback_color
		)

		return

	var segments = max(endpoint_circle_segments, 8)

	var circle_points = PoolVector2Array()
	var circle_uvs = PoolVector2Array()

	circle_points.resize(segments)
	circle_uvs.resize(segments)

	var safe_gradient_axis = gradient_axis

	if safe_gradient_axis.length_squared() <= 0.0001:
		safe_gradient_axis = Vector2.UP
	else:
		safe_gradient_axis = safe_gradient_axis.normalized()

	for i in range(segments):
		var angle = PI * 2.0 * float(i) / float(segments)

		var offset = Vector2(
			cos(angle),
			sin(angle)
		) * radius

		circle_points[i] = center + offset

		# 将圆周上的点投影到激光宽度方向。
		#
		# 投影范围：
		# -radius 到 radius
		#
		# 转换为纹理UV范围：
		# 0.0 到 1.0
		var projection = offset.dot(safe_gradient_axis)

		var gradient_offset = (
			projection / radius + 1.0
		) * 0.5

		gradient_offset = clamp(
			gradient_offset,
			0.0,
			1.0
		)

		# 纹理X方向的两列颜色完全相同，
		# 因此X固定使用0.5。
		#
		# Y方向对应输入的laser_gradient。
		circle_uvs[i] = Vector2(
			0.5,
			gradient_offset
		)

	var polygon_color = Color(
		1.0,
		1.0,
		1.0,
		safe_alpha
	)

	draw_colored_polygon(
		circle_points,
		polygon_color,
		circle_uvs,
		capybara_width_gradient_texture
	)


# =========================================================
# 设置两个连接目标
# =========================================================

func set_targets(p_target_a: Node2D, p_target_b: Node2D) -> bool:
	if not _target_is_alive(p_target_a):
		clear_targets()
		return false

	if not _target_is_alive(p_target_b):
		clear_targets()
		return false

	if p_target_a == p_target_b:
		clear_targets()
		return false

	target_a = p_target_a
	target_b = p_target_b

	has_valid_targets = true

	# 取消之前的淡出
	_is_fading = false
	_fade_elapsed_time = 0.0
	_fade_start_alpha = initial_alpha

	visible = true
	_set_line_alpha(initial_alpha)

	_update_line_points()

	return true


# 兼容之前使用的函数名
func _capybara_get_enemies_targeted(enemy_a: Enemy, enemy_b: Enemy) -> Array:
	var enemies = []

	if set_targets(enemy_a, enemy_b):
		enemies.append(enemy_a)
		enemies.append(enemy_b)

	return enemies


# =========================================================
# 每个物理帧更新
# =========================================================

func _physics_process(delta: float) -> void:
	if has_valid_targets:
		if not _targets_are_valid():
			_start_fade_out()
			return

		_update_line_points()
		return

	if _is_fading:
		_process_fade_out(delta)


func _targets_are_valid() -> bool:
	if not _target_is_alive(target_a):
		return false

	if not _target_is_alive(target_b):
		return false

	return true


# 判断目标是否有效且没有死亡
func _target_is_alive(target) -> bool:
	if not is_instance_valid(target):
		return false

	if target.is_queued_for_deletion():
		return false

	if "dead" in target:
		if target.dead:
			return false

	# 没有结晶属性，也不能继续连线
	if not ("capybara_is_crystallized" in target):
		return false

	# 目标没有结晶时终止连线
	if target.capybara_is_crystallized == false:
		return false

	return true


# =========================================================
# 更新连线位置
# =========================================================

func _update_line_points() -> void:
	if not _targets_are_valid():
		return

	# 目标位置是世界坐标，
	# Line2D的points使用局部坐标。
	var point_a = to_local(
		target_a.global_position + target_a_offset
	)

	var point_b = to_local(
		target_b.global_position + target_b_offset
	)

	points = PoolVector2Array([
		point_a,
		point_b
	])

	# 刷新两端圆形位置
	update()


# =========================================================
# 淡出
# =========================================================

func _start_fade_out() -> void:
	if _is_fading:
		return

	has_valid_targets = false

	target_a = null
	target_b = null

	_is_fading = true
	_fade_elapsed_time = 0.0

	# 从当前透明度开始淡出
	_fade_start_alpha = self_modulate.a

	if _fade_start_alpha <= 0.0:
		_finish_fade_out()
		return

	visible = true


func _process_fade_out(delta: float) -> void:
	if not _is_fading:
		return

	_fade_elapsed_time += delta

	var safe_duration = max(
		fade_duration,
		0.001
	)

	var fade_progress = clamp(
		_fade_elapsed_time / safe_duration,
		0.0,
		1.0
	)

	var current_alpha = lerp(
		_fade_start_alpha,
		0.0,
		fade_progress
	)

	_set_line_alpha(current_alpha)

	if fade_progress >= 1.0:
		_finish_fade_out()


func _finish_fade_out() -> void:
	_is_fading = false
	_fade_elapsed_time = 0.0
	_fade_start_alpha = 0.0

	_set_line_alpha(0.0)

	# 淡出完成后再清除线段
	clear_points()
	update()

	if hide_when_no_target:
		visible = false


func _set_line_alpha(alpha_value: float) -> void:
	var line_color = self_modulate

	line_color.a = clamp(
		alpha_value,
		0.0,
		1.0
	)

	self_modulate = line_color

	# 两端圆形也需要重新绘制
	update()


# =========================================================
# 主动取消连线
# =========================================================

func clear_targets() -> void:
	# 不立即清除points，
	# 让现有线条保留并逐渐淡出。
	_start_fade_out()


# 立即清除，不播放淡出
func clear_targets_immediately() -> void:
	target_a = null
	target_b = null

	has_valid_targets = false
	_is_fading = false

	_fade_elapsed_time = 0.0
	_fade_start_alpha = 0.0

	_set_line_alpha(0.0)
	clear_points()
	update()

	if hide_when_no_target:
		visible = false
