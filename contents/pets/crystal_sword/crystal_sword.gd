class_name CapybaraCrystalSword
extends Pet


enum SwordState { IDLE, RUSHING, SLASHING }


export(String) var damage_tracking_id
export(Resource) var weapon_data

# 冲向敌人的参数
export(float) var rush_speed = 20.0
export(float) var rush_acceleration = 3.0
export(float) var rush_stop_distance = 10.0
export(float) var rush_extra_distance = 50.0
export(float) var lost_target_extra_distance = 100.0
export(float, 1.0, 3.0) var rush_max_speed_ratio = 1.75

# 以武器冷却驱动动作速度。0.5表示按攻击频率倍率的平方根增长，避免最低冷却时瞬移。
export(float) var motion_max_cooldown = 150.0
export(float) var motion_min_cooldown = 6.0
export(float, 0.1, 1.0) var motion_cooldown_scaling_power = 0.5

# 击杀后的月牙追斩参数
export(float, 0.0, 1.0) var kill_chain_arc_ratio = 0.45
export(float) var kill_chain_min_arc_height = 30.0
export(float) var kill_chain_max_arc_height = 160.0
export(float, 0.0, 1.0) var kill_chain_momentum_retention = 0.75

# 横斩参数
export(float) var slash_angular_speed = PI * 8.0
export(float) var slash_end_pause = 0.05

# 返回玩家附近的参数
export(float) var home_min_radius = 100.0
export(float) var home_max_radius = 300.0
export(float) var home_rush_speed = 18.0
export(float) var home_rush_acceleration = 2.5
export(float) var home_stop_distance = 18.0
export(float) var home_up_delay = 0.18
export(float) var idle_orbit_speed = 0.8

# 转向速度
export(float) var enemy_turn_speed = 0.20
export(float) var home_turn_speed = 0.14
export(float) var idle_turn_speed = 0.10
export(float) var end_wave_turn_speed = 0.14

# 待机上下浮动
export(float) var idle_float_height = 7.0
export(float) var idle_float_speed = 1.5
export(float) var idle_float_smoothing = 10.0
export(float) var float_return_speed = 12.0

# 剑图片默认剑尖朝右时保持0
export(float) var sprite_angle_offset = 0.0


var _targets_in_range = []
var _attack_target = null
var _attack_destination = Vector2.ZERO

var _base_weapon_stats = WeaponStats.new()
var _current_weapon_stats = WeaponStats.new()
var _damage_tracking_id_hash = Keys.empty_hash
var _state = SwordState.IDLE

# RUSHING同时负责攻击冲刺和返回玩家
var _rush_is_home = false
var _rush_direction = Vector2.ZERO
var _move_speed = 0.0
var _current_rush_speed = 0.0

# 保存场景中配置的初始动作速度，防止reload_data后重复累乘。
var _base_motion_values_cached = false
var _base_rush_speed = 0.0
var _base_rush_acceleration = 0.0
var _base_home_rush_speed = 0.0
var _base_home_rush_acceleration = 0.0
var _base_slash_angular_speed = 0.0
var _base_slash_end_pause = 0.0
var _base_enemy_turn_speed = 0.0
var _base_home_turn_speed = 0.0
var _base_float_return_speed = 0.0

# 击杀或当前目标死亡后，沿二次贝塞尔曲线追斩下一个目标。
var _crescent_rush_active = false
var _crescent_start_position = Vector2.ZERO
var _crescent_control_position = Vector2.ZERO
var _crescent_destination = Vector2.ZERO
var _crescent_progress = 0.0
var _last_kill_chain_frame = -1

# 锁定敌人当前位置，冲到该位置并前冲后完成横斩
var _passed_enemy = false
var _extra_rush_remaining = 0.0
var _extra_rush_should_slash = true

# 横斩
var _slash_rotated_angle = 0.0
var _slash_target_angle = PI * 2.0
var _slash_direction_sign = 1.0
var _slash_end_timer = 0.0

# 玩家附近随机返回位置
var _home_offset = Vector2.ZERO
var _home_destination = Vector2.ZERO

# 返回后延迟恢复朝上
var _waiting_after_home = false
var _recovering_up_after_home = false
var _home_up_wait_timer = 0.0

# 碰撞箱关闭一帧后重新启用
var _hitbox_waiting_enable = false
var _hitbox_reset_frames = 0

# 待机浮动
var _float_time = 0.0
var _sprite_base_y = 0.0

var _capybara_player = null
var capybara_effect = null
var current_mov = Vector2.ZERO
var _rng = RandomNumberGenerator.new()


onready var _range_shape = $TargetTriggerZone/CollisionShape2D
onready var _hitbox = $Hitbox
onready var body_sp = $Animation/Sprite


func init(zone_min_pos: Vector2, zone_max_pos: Vector2, p_players_ref: Array = [], entity_spawner_ref = null) -> void:
	.init(zone_min_pos, zone_max_pos, p_players_ref, entity_spawner_ref)
	_rng.randomize()
	_cache_base_motion_values()
	_damage_tracking_id_hash = Keys.generate_hash(damage_tracking_id)

	if player_index >= 0 and player_index < p_players_ref.size():
		_capybara_player = p_players_ref[player_index]

	_hitbox.disable()
	_hitbox.damage_tracking_key_hash = _damage_tracking_id_hash
	body_sp.flip_h = false
	_sprite_base_y = body_sp.position.y

	if is_instance_valid(_capybara_player):
		_start_home_rush()
	else:
		_enter_idle(false)


func update_data(effect: PetEffect) -> void:
	.update_data(effect)
	_base_weapon_stats = effect.weapon_stats
	capybara_effect = effect
	reload_data()
	_update_motion_values()


func should_data_be_reload() -> bool:
	return true


func reload_data() -> void:
	var args = WeaponServiceInitStatsArgs.new()
	_current_weapon_stats = WeaponService.init_melee_pet_stats(_base_weapon_stats, player_index, args)

	if _range_shape:
		_range_shape.shape.radius = _current_weapon_stats.max_range

	_current_weapon_stats.burning_data.from = self


func _cache_base_motion_values() -> void:
	if _base_motion_values_cached:
		return

	_base_motion_values_cached = true
	_base_rush_speed = rush_speed
	_base_rush_acceleration = rush_acceleration
	_base_home_rush_speed = home_rush_speed
	_base_home_rush_acceleration = home_rush_acceleration
	_base_slash_angular_speed = slash_angular_speed
	_base_slash_end_pause = slash_end_pause
	_base_enemy_turn_speed = enemy_turn_speed
	_base_home_turn_speed = home_turn_speed
	_base_float_return_speed = float_return_speed


func _get_cooldown_motion_multiplier() -> float:
	var cooldown = _current_weapon_stats.cooldown
	var attack_frequency_multiplier = max(min( 30.0 / cooldown, 2.0), 0.3)
	return attack_frequency_multiplier


func _update_motion_values() -> void:
	_cache_base_motion_values()
	var motion_multiplier = _get_cooldown_motion_multiplier()

	rush_speed = _base_rush_speed * motion_multiplier
	rush_acceleration = _base_rush_acceleration * motion_multiplier
	home_rush_speed = _base_home_rush_speed * motion_multiplier
	home_rush_acceleration = _base_home_rush_acceleration * motion_multiplier
	slash_angular_speed = _base_slash_angular_speed * motion_multiplier
	enemy_turn_speed = _base_enemy_turn_speed * motion_multiplier
	home_turn_speed = _base_home_turn_speed * motion_multiplier
	float_return_speed = _base_float_return_speed * motion_multiplier
	slash_end_pause = _base_slash_end_pause / motion_multiplier


func _get_distance_based_rush_speed(distance: float) -> float:
	var minimum_distance = max(rush_stop_distance, 0.0)
	var maximum_distance = max(_current_weapon_stats.max_range, minimum_distance + 1.0)
	var distance_ratio = clamp(
		(distance - minimum_distance) / (maximum_distance - minimum_distance),
		0.0,
		1.0
	)

	distance_ratio = distance_ratio * distance_ratio * (3.0 - 2.0 * distance_ratio)
	var maximum_speed = rush_speed * max(rush_max_speed_ratio, 1.0)
	return lerp(rush_speed, maximum_speed, distance_ratio)


func set_current_stats(stats: Array) -> void:
	if stats.empty():
		return

	_current_weapon_stats = stats[0]

	if _range_shape:
		_range_shape.shape.radius = _current_weapon_stats.max_range

	_current_weapon_stats.burning_data.from = self
	_update_motion_values()


func get_stats() -> Array:
	return [_current_weapon_stats]


func _physics_process(delta: float) -> void:
	var physics_amount = Utils.physics_one(delta)

	if _end_of_wave:
		_process_end_of_wave(delta, physics_amount)
		return

	_clear_invalid_targets()

	match _state:
		SwordState.IDLE:
			_process_idle(delta, physics_amount)
		SwordState.RUSHING:
			_process_rushing(physics_amount)
		SwordState.SLASHING:
			_process_slashing(delta)

	_update_floating(delta)


# =========================================================
# 通用重置
# =========================================================

func _reset_extra_rush() -> void:
	_passed_enemy = false
	_extra_rush_remaining = 0.0
	_extra_rush_should_slash = true


func _reset_crescent_rush() -> void:
	_crescent_rush_active = false
	_crescent_start_position = Vector2.ZERO
	_crescent_control_position = Vector2.ZERO
	_crescent_destination = Vector2.ZERO
	_crescent_progress = 0.0


func _reset_slash_data() -> void:
	_slash_rotated_angle = 0.0
	_slash_target_angle = PI * 2.0
	_slash_direction_sign = 1.0
	_slash_end_timer = 0.0


func _reset_home_recovery() -> void:
	_waiting_after_home = false
	_recovering_up_after_home = false
	_home_up_wait_timer = 0.0


func _clear_attack_hitbox() -> void:
	_cancel_hitbox_enable()
	_hitbox.disable()
	_hitbox.projectiles_on_hit = []


# =========================================================
# 波次结束
# =========================================================

func _process_end_of_wave(delta: float, physics_amount: float) -> void:
	_state = SwordState.IDLE
	_rush_is_home = false
	_attack_target = null
	_move_speed = 0.0
	_reset_extra_rush()
	_reset_crescent_rush()
	_reset_slash_data()
	_reset_home_recovery()
	_clear_attack_hitbox()
	_can_move = true

	var up_rotation = _get_up_rotation()
	_smooth_rotate_to(up_rotation, end_wave_turn_speed, physics_amount)

	if _angle_distance(rotation, up_rotation) <= 0.01:
		rotation = up_rotation

	_update_floating(delta)


# =========================================================
# 待机
# =========================================================

func _process_idle(delta: float, physics_amount: float) -> void:
	_hitbox.disable()
	_cancel_hitbox_enable()

	var target = _get_nearest_target()

	if is_instance_valid(target):
		_can_move = false
		_start_enemy_rush(target)
		return

	_can_move = true
	_update_idle_orbit(delta)

	if _waiting_after_home:
		_home_up_wait_timer += delta

		if _home_up_wait_timer < home_up_delay:
			return

		_waiting_after_home = false
		_recovering_up_after_home = true

	if _recovering_up_after_home:
		var up_rotation = _get_up_rotation()
		_smooth_rotate_to(up_rotation, home_turn_speed, physics_amount)

		if _angle_distance(rotation, up_rotation) <= 0.01:
			rotation = up_rotation
			_recovering_up_after_home = false

		return

	_smooth_rotate_to(_get_up_rotation(), idle_turn_speed, physics_amount)


func _update_idle_orbit(delta: float) -> void:
	if not is_instance_valid(_capybara_player):
		return

	if _home_offset.length_squared() <= 0.001:
		var min_radius = min(home_min_radius, home_max_radius)
		var max_radius = max(home_min_radius, home_max_radius)
		_home_offset = Vector2.RIGHT * ((min_radius + max_radius) * 0.5)

	_home_offset = _home_offset.rotated(idle_orbit_speed * delta)
	global_position = _capybara_player.global_position + _home_offset


func _enter_idle(wait_before_up = false) -> void:
	_state = SwordState.IDLE
	_rush_is_home = false
	_attack_target = null
	_move_speed = 0.0
	_reset_extra_rush()
	_reset_crescent_rush()
	_reset_slash_data()
	_reset_home_recovery()
	_waiting_after_home = wait_before_up
	_clear_attack_hitbox()
	_can_move = true


# =========================================================
# 冲刺
# =========================================================

func _process_rushing(physics_amount: float) -> void:
	if _rush_is_home:
		_process_home_rush(physics_amount)
	elif _crescent_rush_active:
		_process_crescent_rush(physics_amount)
	else:
		_process_enemy_rush(physics_amount)


func _start_enemy_rush(target) -> void:
	if not _target_is_available(target):
		target = _get_nearest_target()

		if not is_instance_valid(target):
			_start_home_rush()
			return

	reload_data()
	_update_motion_values()

	_state = SwordState.RUSHING
	_rush_is_home = false
	_attack_target = target
	_attack_destination = target.global_position
	_can_move = false
	_reset_home_recovery()
	_reset_extra_rush()
	_reset_crescent_rush()

	var offset = _attack_destination - global_position
	_current_rush_speed = _get_distance_based_rush_speed(offset.length())
	_move_speed = max(_move_speed * 0.35, _current_rush_speed * 0.20)

	if offset.length_squared() > 0.001:
		_rush_direction = offset.normalized()

	_prepare_attack_hitbox()


func _try_start_kill_chain(defeated_target) -> bool:
	if _end_of_wave:
		return false

	# died和Hitbox.killed_something可能在同一物理帧先后触发，只开始一次追斩。
	var current_frame = Engine.get_physics_frames()
	if current_frame == _last_kill_chain_frame:
		return false

	var next_target = _get_nearest_target(defeated_target)
	if not is_instance_valid(next_target):
		return false

	_last_kill_chain_frame = current_frame
	_start_crescent_rush(next_target)
	return true


func _start_crescent_rush(target) -> void:
	if not _target_is_available(target):
		target = _get_nearest_target()

		if not is_instance_valid(target):
			return

	reload_data()
	_update_motion_values()

	_state = SwordState.RUSHING
	_rush_is_home = false
	_attack_target = target
	_attack_destination = target.global_position
	_can_move = false
	_reset_home_recovery()
	_reset_extra_rush()
	_reset_slash_data()

	_crescent_rush_active = true
	_crescent_start_position = global_position
	_crescent_destination = _attack_destination
	_crescent_progress = 0.0
	_crescent_control_position = _get_crescent_control_position(
		_crescent_start_position,
		_crescent_destination
	)

	var offset = _crescent_destination - _crescent_start_position
	_current_rush_speed = _get_distance_based_rush_speed(offset.length())
	_move_speed = max(
		_move_speed * kill_chain_momentum_retention,
		_current_rush_speed * 0.20
	)

	if offset.length_squared() > 0.001:
		_rush_direction = offset.normalized()

	_prepare_attack_hitbox()


func _get_crescent_control_position(start_position: Vector2, destination: Vector2) -> Vector2:
	var offset = destination - start_position
	var distance = offset.length()

	if distance <= 0.001:
		return start_position

	var direction = offset / distance
	var perpendicular = Vector2(-direction.y, direction.x)
	var minimum_height = min(kill_chain_min_arc_height, kill_chain_max_arc_height)
	var maximum_height = max(kill_chain_min_arc_height, kill_chain_max_arc_height)
	var arc_height = clamp(distance * kill_chain_arc_ratio, minimum_height, maximum_height)
	# 近距离目标限制弧高，避免轨迹向外绕出过大的圆弧。
	arc_height = min(arc_height, distance)

	var midpoint = (start_position + destination) * 0.5
	var first_control = midpoint + perpendicular * arc_height
	var second_control = midpoint - perpendicular * arc_height
	var current_forward = Vector2.RIGHT.rotated(rotation - sprite_angle_offset)
	var first_direction = (first_control - start_position).normalized()
	var second_direction = (second_control - start_position).normalized()

	# 选择更贴近剑当前朝向的一侧，使追斩衔接自然且仍保持月牙轨迹。
	if current_forward.dot(first_direction) >= current_forward.dot(second_direction):
		return first_control
	return second_control


func _get_crescent_position(progress: float) -> Vector2:
	var inverse_progress = 1.0 - progress
	return (
		_crescent_start_position * inverse_progress * inverse_progress
		+ _crescent_control_position * 2.0 * inverse_progress * progress
		+ _crescent_destination * progress * progress
	)


func _get_crescent_tangent(progress: float) -> Vector2:
	return (
		(_crescent_control_position - _crescent_start_position) * 2.0 * (1.0 - progress)
		+ (_crescent_destination - _crescent_control_position) * 2.0 * progress
	)


func _process_crescent_rush(physics_amount: float) -> void:
	_can_move = false

	if not _ensure_attack_hitbox_enabled():
		return

	_move_speed = min(_move_speed + rush_acceleration * physics_amount, _current_rush_speed)
	var movement_amount = _move_speed * physics_amount
	var tangent = _get_crescent_tangent(_crescent_progress)
	var tangent_length = max(tangent.length(), 0.001)
	var progress_step = movement_amount / tangent_length
	_crescent_progress = min(_crescent_progress + progress_step, 1.0)
	global_position = _get_crescent_position(_crescent_progress)

	tangent = _get_crescent_tangent(_crescent_progress)
	if tangent.length_squared() > 0.001:
		_rush_direction = tangent.normalized()
		rotation = _get_direction_rotation(_rush_direction)

	if _crescent_progress >= 1.0:
		_finish_crescent_rush()


func _finish_crescent_rush() -> void:
	global_position = _crescent_destination
	var end_tangent = _crescent_destination - _crescent_control_position

	if end_tangent.length_squared() > 0.001:
		_rush_direction = end_tangent.normalized()
		rotation = _get_direction_rotation(_rush_direction)

	_crescent_rush_active = false
	_begin_extra_rush(rush_extra_distance, true)


func _process_enemy_rush(physics_amount: float) -> void:
	_can_move = false

	if _passed_enemy:
		_process_extra_enemy_rush(physics_amount)
		return

	# 命中前持续读取目标位置，并让冲刺方向逐渐转向目标。
	# 只修正一部分角度，避免变成瞬间转向的完全追踪。
	if _target_is_available(_attack_target):
		_attack_destination = _attack_target.global_position

	var destination = _attack_destination
	var offset = destination - global_position
	var distance = offset.length()

	if distance > 0.001:
		var target_direction = offset.normalized()
		var tracking_weight = clamp(enemy_turn_speed * physics_amount, 0.0, 1.0)
		var tracking_angle = lerp_angle(_rush_direction.angle(), target_direction.angle(), tracking_weight)
		_rush_direction = Vector2.RIGHT.rotated(tracking_angle)
		_smooth_rotate_to(_get_direction_rotation(_rush_direction), enemy_turn_speed, physics_amount)

	if not _ensure_attack_hitbox_enabled():
		return

	_move_speed = min(_move_speed + rush_acceleration * physics_amount, _current_rush_speed)
	var movement_amount = _move_speed * physics_amount

	if distance <= rush_stop_distance or distance <= movement_amount:
		_reach_enemy_position(destination, distance, movement_amount)
		return

	global_position += _rush_direction * movement_amount


func _reach_enemy_position(destination: Vector2, distance: float, movement_amount: float) -> void:
	global_position = destination
	_begin_extra_rush(rush_extra_distance, true)

	var leftover_distance = max(movement_amount - distance, 0.0)

	if leftover_distance > 0.0 and _extra_rush_remaining > 0.0:
		var extra_step = min(leftover_distance, _extra_rush_remaining)
		global_position += _rush_direction * extra_step
		_extra_rush_remaining -= extra_step

	if _extra_rush_remaining <= 0.001:
		_finish_extra_enemy_rush()


func _begin_extra_rush(distance: float, should_slash: bool) -> void:
	if _rush_direction.length_squared() <= 0.001:
		_rush_direction = Vector2.RIGHT.rotated(rotation - sprite_angle_offset)

	_passed_enemy = true
	_extra_rush_remaining = max(distance, 0.0)
	_extra_rush_should_slash = should_slash


func _start_lost_target_forward_rush() -> void:
	_attack_target = null

	if _rush_direction.length_squared() <= 0.001:
		_rush_direction = Vector2.RIGHT.rotated(rotation - sprite_angle_offset)

	# 保留原函数，但锁定位置模式下不会因目标失效而调用
	_passed_enemy = true
	_extra_rush_remaining = max(_extra_rush_remaining, max(lost_target_extra_distance, 0.0))
	_extra_rush_should_slash = false

	if _extra_rush_remaining <= 0.001:
		_finish_extra_enemy_rush()


func _process_extra_enemy_rush(physics_amount: float) -> void:
	if not _ensure_attack_hitbox_enabled():
		return

	_move_speed = min(_move_speed + rush_acceleration * physics_amount, _current_rush_speed)

	var movement_amount = _move_speed * physics_amount
	var actual_movement = min(movement_amount, _extra_rush_remaining)

	global_position += _rush_direction * actual_movement
	_extra_rush_remaining -= actual_movement

	if _extra_rush_remaining <= 0.001:
		_extra_rush_remaining = 0.0
		_finish_extra_enemy_rush()


func _finish_extra_enemy_rush() -> void:
	if _extra_rush_should_slash:
		_start_slash()
		return

	_attack_target = null
	var next_target = _get_nearest_target()

	if is_instance_valid(next_target):
		_start_enemy_rush(next_target)
	else:
		_start_home_rush()


func _start_home_rush() -> void:
	_state = SwordState.RUSHING
	_rush_is_home = true
	_attack_target = null
	_can_move = false
	_reset_home_recovery()
	_reset_extra_rush()
	_reset_crescent_rush()
	_reset_slash_data()
	_move_speed = max(_move_speed * 0.30, home_rush_speed * 0.20)
	_clear_attack_hitbox()

	if not is_instance_valid(_capybara_player):
		_enter_idle(false)
		return

	var min_radius = min(home_min_radius, home_max_radius)
	var max_radius = max(home_min_radius, home_max_radius)
	var random_angle = _rng.randf_range(0.0, PI * 2.0)
	var random_distance = _rng.randf_range(min_radius, max_radius)

	_home_offset = Vector2.RIGHT.rotated(random_angle) * random_distance
	_home_destination = _capybara_player.global_position + _home_offset


func _process_home_rush(physics_amount: float) -> void:
	_hitbox.disable()
	_cancel_hitbox_enable()

	var target = _get_nearest_target()

	if is_instance_valid(target):
		_start_enemy_rush(target)
		return

	if not is_instance_valid(_capybara_player):
		_enter_idle(false)
		return

	_can_move = false
	_home_destination = _capybara_player.global_position + _home_offset

	var offset = _home_destination - global_position
	var distance = offset.length()

	if distance <= home_stop_distance:
		global_position = _home_destination
		_enter_idle(true)
		return

	var direction = offset.normalized()
	_smooth_rotate_to(_get_direction_rotation(direction), home_turn_speed, physics_amount)
	_move_speed = min(_move_speed + home_rush_acceleration * physics_amount, home_rush_speed)

	var movement_amount = _move_speed * physics_amount

	if movement_amount >= distance:
		global_position = _home_destination
		_enter_idle(true)
		return

	global_position += direction * movement_amount


# =========================================================
# 横斩
# =========================================================

func _start_slash() -> void:
	_state = SwordState.SLASHING
	_rush_is_home = false
	_can_move = false
	_move_speed = 0.0
	_reset_home_recovery()
	_reset_extra_rush()
	_reset_crescent_rush()
	_slash_rotated_angle = 0.0
	_slash_end_timer = 0.0
	_slash_target_angle = _rng.randf_range(PI, PI * 2.0)
	_slash_direction_sign = 1.0 if _rng.randi_range(0, 1) == 0 else -1.0
	_prepare_attack_hitbox()


func _process_slashing(delta: float) -> void:
	_can_move = false

	if not _ensure_attack_hitbox_enabled():
		return

	if _slash_rotated_angle < _slash_target_angle:
		var angle_step = min(slash_angular_speed * delta, _slash_target_angle - _slash_rotated_angle)
		rotation += _slash_direction_sign * angle_step
		_slash_rotated_angle += angle_step
		return

	_slash_end_timer += delta

	if _slash_end_timer >= slash_end_pause:
		_finish_slash()


func _finish_slash() -> void:
	_clear_attack_hitbox()
	_reset_slash_data()

	var previous_target = _attack_target
	_attack_target = null
	var next_target = _get_nearest_target(previous_target)

	if not is_instance_valid(next_target):
		next_target = _get_nearest_target()

	if is_instance_valid(next_target):
		_start_enemy_rush(next_target)
	else:
		_start_home_rush()


# =========================================================
# 待机浮动
# =========================================================

func _update_floating(delta: float) -> void:
	if not is_instance_valid(body_sp):
		return

	var weight = 0.0

	if _can_move:
		_float_time += delta

		var float_angle = _float_time * idle_float_speed * PI * 2.0
		var target_y = _sprite_base_y + sin(float_angle) * idle_float_height

		weight = clamp(idle_float_smoothing * delta, 0.0, 1.0)
		body_sp.position.x = lerp(body_sp.position.x, target_y, weight)
	else:
		weight = clamp(float_return_speed * delta, 0.0, 1.0)
		body_sp.position.x = lerp(body_sp.position.x, _sprite_base_y, weight)


# =========================================================
# 碰撞箱
# =========================================================

func _prepare_attack_hitbox() -> void:
	_hitbox.disable()
	_hitbox.projectiles_on_hit = []
	_hitbox_waiting_enable = true
	_hitbox_reset_frames = 1


func _ensure_attack_hitbox_enabled() -> bool:
	if not _hitbox_waiting_enable:
		return true

	if _hitbox_reset_frames > 0:
		_hitbox_reset_frames -= 1
		return false

	_configure_hitbox()
	_hitbox.enable()
	_hitbox_waiting_enable = false
	return true


func _cancel_hitbox_enable() -> void:
	_hitbox_waiting_enable = false
	_hitbox_reset_frames = 0


func _configure_hitbox() -> void:
	_current_weapon_stats.burning_data.from = self

	var hitbox_args = Hitbox.HitboxArgs.new()
	hitbox_args.set_from_weapon_stats(_current_weapon_stats)

	_hitbox.effect_scale = _current_weapon_stats.effect_scale
	_hitbox.set_damage(_current_weapon_stats.damage, hitbox_args)
	_hitbox.speed_percent_modifier = _current_weapon_stats.speed_percent_modifier
	_hitbox.damage_tracking_key_hash = _damage_tracking_id_hash
	_hitbox.from = self


# =========================================================
# 目标选择
# =========================================================

func _get_nearest_target(excluded_target = null):
	var nearest_target = null
	var nearest_distance_squared = INF
	var target_origin = _capybara_player.global_position if is_instance_valid(_capybara_player) else global_position

	for target in _targets_in_range:
		if not is_instance_valid(target) or target == excluded_target:
			continue

		var distance_squared = target_origin.distance_squared_to(target.global_position)

		if distance_squared < nearest_distance_squared:
			nearest_distance_squared = distance_squared
			nearest_target = target

	return nearest_target


func _target_is_available(target) -> bool:
	return is_instance_valid(target) and target in _targets_in_range


func _clear_invalid_targets() -> void:
	for index in range(_targets_in_range.size() - 1, -1, -1):
		if not is_instance_valid(_targets_in_range[index]):
			_targets_in_range.remove(index)


# =========================================================
# 角度控制
# =========================================================

func _get_direction_rotation(direction: Vector2) -> float:
	return direction.angle() + sprite_angle_offset


func _get_up_rotation() -> float:
	return -PI / 2.0 + sprite_angle_offset


func _smooth_rotate_to(target_rotation: float, turn_speed: float, physics_amount: float) -> void:
	rotation = lerp_angle(rotation, target_rotation, clamp(turn_speed * physics_amount, 0.0, 1.0))


func _angle_distance(from_angle: float, to_angle: float) -> float:
	return abs(wrapf(to_angle - from_angle, -PI, PI))


# =========================================================
# 范围信号
# =========================================================

func _on_TargetTriggerZone_body_entered(body) -> void:
	if not is_instance_valid(body):
		return

	if not (body in _targets_in_range):
		_targets_in_range.push_back(body)

	if body.has_signal("died") and not body.is_connected("died", self, "on_target_died"):
		body.connect("died", self, "on_target_died")

	_can_move = false

	if _state == SwordState.IDLE or (_state == SwordState.RUSHING and _rush_is_home):
		var target = _get_nearest_target()
		if is_instance_valid(target):
			_start_enemy_rush(target)


func _on_TargetTriggerZone_body_exited(body) -> void:
	_targets_in_range.erase(body)

	if is_instance_valid(body) and body.has_signal("died") and body.is_connected("died", self, "on_target_died"):
		body.disconnect("died", self, "on_target_died")

	if _targets_in_range.empty() and _state == SwordState.IDLE:
		_start_home_rush()


func on_target_died(target: Node2D, _args: Entity.DieArgs) -> void:
	var was_attack_target = target == _attack_target
	_targets_in_range.erase(target)

	if was_attack_target:
		_attack_target = null

		if _try_start_kill_chain(target):
			return

	if _state == SwordState.SLASHING:
		return

	if _targets_in_range.empty() and _state == SwordState.IDLE:
		_start_home_rush()


# =========================================================
# 动画和命中
# =========================================================

func update_animation(movement: Vector2) -> void:
	.update_animation(movement)

	if _animation_player.current_animation != "idle" and _animation_player.current_animation != "pet":
		_animation_player.play("idle")

	body_sp.flip_h = false
	current_mov = movement


func _on_Hitbox_hit_something(_thing_hit, _damage_dealt) -> void:
	reload_data()
	_update_motion_values()

	# 普通追踪冲刺一旦命中，就锁定命中瞬间的方向，随后只做直线穿透。
	if _state == SwordState.RUSHING and not _rush_is_home and not _crescent_rush_active and not _passed_enemy:
		_begin_extra_rush(rush_extra_distance, true)


func _on_Hitbox_killed_something(thing_killed) -> void:
	var killed_effects = RunData.get_player_effect(Keys.generate_hash("capybara_reload_turret_when_crystal_sword_killed"), player_index)
	for effect in killed_effects:
		if effect[0] == _damage_tracking_id_hash:
			for turret in _capybara_player.capybara_turrets:
				if turret.has_method("set_instant_shoot") and "capybara_is_spawning" in turret and not turret.capybara_is_spawning:
					turret.set_instant_shoot()
	_try_start_kill_chain(thing_killed)
