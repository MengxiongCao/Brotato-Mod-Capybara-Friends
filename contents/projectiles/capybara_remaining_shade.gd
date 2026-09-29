extends Node2D

export(NodePath) var target_sprite_path := NodePath("../Sprite")

export(float) var spawn_interval := 0.035
export(float) var life_time := 0.22

export(float, 0.0, 1.0) var start_alpha := 0.65
export(float, 0.0, 1.0) var end_alpha := 0.0

export(float) var end_scale := 0.90
export(Color) var ghost_color := Color(0.78, 0.55, 1.0, 1.0)

export(int) var max_ghosts := 14


var _target: Sprite = null
var _timer := 0.0
var _ghosts := []


func _ready() -> void:
	_target = get_node_or_null(target_sprite_path) as Sprite

	if _target == null:
		push_error(
			"GhostTrail: missing Sprite target: "
			+ str(target_sprite_path)
		)
		set_process(false)
		return


func _process(delta: float) -> void:
	if not is_instance_valid(_target):
		_clear_all_ghosts()
		set_process(false)
		return

	_timer += delta

	# 使用 while，避免帧率较低时漏生成残影
	while _timer >= spawn_interval:
		_timer -= spawn_interval
		_spawn_ghost()

	_update_ghosts(delta)


# ============================================================
# 生成残影
# ============================================================

func _spawn_ghost() -> void:
	if not is_instance_valid(_target):
		return

	var target_parent := _target.get_parent() as Node2D

	if target_parent == null:
		return

	# 保存生成这一刻的世界变换。
	# 后面即使武器父节点移动，也会将残影固定在这个世界位置。
	var captured_world_transform: Transform2D = _target.global_transform

	var ghost := Sprite.new()

	# ========================================================
	# 复制 Sprite 图像参数
	# ========================================================

	ghost.texture = _target.texture

	ghost.hframes = _target.hframes
	ghost.vframes = _target.vframes
	ghost.frame = _target.frame

	ghost.region_enabled = _target.region_enabled

	if ghost.region_enabled:
		ghost.region_rect = _target.region_rect

	ghost.centered = _target.centered
	ghost.offset = _target.offset

	ghost.flip_h = _target.flip_h
	ghost.flip_v = _target.flip_v

	# ========================================================
	# 添加为 Sprite 的兄弟节点
	# ========================================================

	# 必须在 add_child 前记录本体的节点位置
	var target_index := _target.get_index()

	target_parent.add_child(ghost)

	# 将残影移动到本体前面。
	#
	# 相同 z_index 时：
	# 残影先绘制，本体后绘制，因此本体会盖住残影。
	target_parent.move_child(ghost, target_index)

	# ========================================================
	# 绘制层级
	# ========================================================

	# 始终保持为 0，不接触战争迷雾层级
	ghost.z_index = 0

	# 继承父节点最终 Z，与原武器保持同一个 Canvas 层级
	ghost.z_as_relative = true

	# 残影与本体是兄弟节点，不使用 show_behind_parent
	ghost.show_behind_parent = false

	# 非常重要：
	# 不能使用 set_as_toplevel(true)，否则会改变绘制顺序
	ghost.set_as_toplevel(false)

	# 将捕获的世界变换转换为当前父节点下的局部变换
	_apply_world_transform(ghost, captured_world_transform)

	# ========================================================
	# 颜色
	# ========================================================

	var color := ghost_color
	color.a = start_alpha
	ghost.modulate = color

	_ghosts.append({
		"node": ghost,
		"time": 0.0,
		"world_transform": captured_world_transform
	})

	_limit_ghost_count()


# ============================================================
# 更新残影
# ============================================================

func _update_ghosts(delta: float) -> void:
	for index in range(_ghosts.size() - 1, -1, -1):
		var ghost_data: Dictionary = _ghosts[index]
		var ghost: Sprite = ghost_data["node"]

		if not is_instance_valid(ghost):
			_ghosts.remove(index)
			continue

		ghost_data["time"] += delta

		var progress := clamp(
			ghost_data["time"] / max(life_time, 0.001),
			0.0,
			1.0
		)

		# ====================================================
		# 透明度
		# ====================================================

		var color: Color = ghost.modulate

		color.a = lerp(
			start_alpha,
			end_alpha,
			progress
		)

		ghost.modulate = color

		# ====================================================
		# 缩放
		# ====================================================

		var scale_multiplier = lerp(
			1.0,
			end_scale,
			progress
		)

		var captured_world_transform: Transform2D = (
			ghost_data["world_transform"]
		)

		# 复制一份，不能直接修改字典里保存的初始变换
		var display_world_transform := captured_world_transform

		# 只缩放基向量，不缩放 origin。
		# 这样残影以自身中心缩小，不会往世界原点偏移。
		display_world_transform.x *= scale_multiplier
		display_world_transform.y *= scale_multiplier

		# 每帧重新转换局部变换。
		#
		# 残影没有使用 top-level，因此父武器移动时，
		# 必须反向补偿父节点变换，才能留在原来的世界位置。
		_apply_world_transform(
			ghost,
			display_world_transform
		)

		if progress >= 1.0:
			ghost.queue_free()
			_ghosts.remove(index)


# ============================================================
# 世界变换转父节点局部变换
# ============================================================

func _apply_world_transform(
	node: Node2D,
	world_transform: Transform2D
) -> void:
	if not is_instance_valid(node):
		return

	var node_parent := node.get_parent() as Node2D

	if node_parent == null:
		node.global_transform = world_transform
		return

	# local_transform = parent_global_inverse × world_transform
	node.transform = (
		node_parent.global_transform.affine_inverse()
		* world_transform
	)


# ============================================================
# 限制数量
# ============================================================

func _limit_ghost_count() -> void:
	while _ghosts.size() > max_ghosts:
		var oldest_data: Dictionary = _ghosts[0]
		var oldest_ghost: Sprite = oldest_data["node"]

		if is_instance_valid(oldest_ghost):
			oldest_ghost.queue_free()

		_ghosts.remove(0)


# ============================================================
# 清理
# ============================================================

func _clear_all_ghosts() -> void:
	for ghost_data in _ghosts:
		var ghost: Sprite = ghost_data["node"]

		if is_instance_valid(ghost):
			ghost.queue_free()

	_ghosts.clear()


func _exit_tree() -> void:
	_clear_all_ghosts()
