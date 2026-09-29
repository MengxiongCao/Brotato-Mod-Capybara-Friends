extends "res://weapons/shooting_behaviors/melee_weapon_shooting_behavior.gd"

var _sweep_start_position := Vector2.ZERO
var _sweep_control_position := Vector2.ZERO
var _sweep_end_position := Vector2.ZERO

var _sweep_start_rotation := 0.0
var _sweep_end_rotation := 0.0
var capybara_curve_stat:float = 1.5
var capybara_attack_type:int = 0

func _update_sweep_curve(progress: float) -> void:
	# 使用二次贝塞尔曲线计算位置
	var first_line = _sweep_start_position.linear_interpolate(
		_sweep_control_position,
		progress
	)
	
	var second_line = _sweep_control_position.linear_interpolate(
		_sweep_end_position,
		progress
	)
	
	_parent.sprite.position = first_line.linear_interpolate(
		second_line,
		progress
	)

	# 不要使用 lerp_angle。
	# 因为这里需要经过 rotation = 0，而不是走最短旋转路径。
	_parent.sprite.rotation = lerp(
		_sweep_start_rotation,
		_sweep_end_rotation,
		progress
	)

func shoot(distance: float) -> void :
	var initial_position: Vector2 = _parent.sprite.position
	shooting_data = MeleeShootingData.new(_parent.capybara_base_stats, _parent.player_index)
	_parent.set_shooting(true)
	if capybara_attack_type == 0:
		melee_thrust_attack(initial_position)
	elif capybara_attack_type == 1:
		melee_reverse_sweep_attack(initial_position, distance)
	else:
		melee_special_sweep_attack(initial_position, distance)
	capybara_attack_type = (capybara_attack_type + 1) % 3

func interpolate(property: String, val_a, val_b, duration, tween_trans = Tween.TRANS_EXPO, tween_ease = Tween.EASE_OUT, object = _parent.sprite) -> void :
	_parent.tween.interpolate_property(
		object, 
		property, 
		val_a, 
		val_b, 
		duration, 
		tween_trans, 
		tween_ease
	)


func melee_sweep_attack(initial_position: Vector2, distance: float) -> void :
	_parent._hitbox.player_attack_id = _get_next_attack_id()

	var atk_distance = min(_parent.capybara_base_stats.max_range, max(MIN_SWEEP_DISTANCE, distance))
	shooting_data.update_atk_duration(atk_distance)

	var side_range = atk_distance / 2
	var recoil = _parent.capybara_base_stats.recoil
	var recoil_duration = _parent.capybara_base_stats.recoil_duration
	var sweep_angle = 0.9 * PI
	var sweep_half_duration = 0.2

	var side_a = side_range
	var side_b = - side_range
	var angle_a = sweep_angle
	var angle_b = - sweep_angle

	if not _parent.sprite.flip_v:
		side_a = - side_range
		side_b = side_range
		angle_a = - sweep_angle
		angle_b = sweep_angle

	interpolate("position", initial_position, Vector2(initial_position.x - recoil, initial_position.y + side_a), recoil_duration)
	interpolate("rotation", _parent.sprite.rotation, angle_a, recoil_duration)

	_parent.tween.start()
	yield(_parent.tween, "tween_all_completed")

	SoundManager.play(Utils.get_rand_element(_parent.current_stats.shooting_sounds), _parent.current_stats.sound_db_mod, 0.2)
	_parent.enable_hitbox()

	interpolate("position", _parent.sprite.position, Vector2(initial_position.x + _parent.get_sweep_range(atk_distance) * 0.75, initial_position.y), sweep_half_duration, Tween.TRANS_LINEAR)
	interpolate("rotation", _parent.sprite.rotation, 0, sweep_half_duration, Tween.TRANS_LINEAR)

	_parent.tween.start()
	yield(_parent.tween, "tween_all_completed")

	interpolate("position", _parent.sprite.position, Vector2(initial_position.x - recoil, initial_position.y + side_b), sweep_half_duration, Tween.TRANS_LINEAR)
	interpolate("rotation", _parent.sprite.rotation, angle_b, sweep_half_duration, Tween.TRANS_LINEAR)

	_parent.tween.start()
	yield(_parent.tween, "tween_all_completed")

	if not _parent.stats.deal_dmg_on_return:
		_parent.disable_hitbox()

	interpolate("position", _parent.sprite.position, initial_position, shooting_data.back_duration)
	interpolate("rotation", _parent.sprite.rotation, 0, shooting_data.back_duration)

	_parent.tween.start()
	yield(_parent.tween, "tween_all_completed")

	if _parent.stats.deal_dmg_on_return:
		_parent.disable_hitbox()
	
	_parent.set_shooting(false)

func melee_special_sweep_attack(initial_position: Vector2, distance: float) -> void:
	_parent._hitbox.player_attack_id = _get_next_attack_id()

	var atk_distance = min(
		_parent.capybara_base_stats.max_range,
		max(MIN_SWEEP_DISTANCE, distance)
	)
	
	shooting_data.update_atk_duration(atk_distance)

	var side_range = atk_distance
	var recoil = _parent.capybara_base_stats.recoil
	var recoil_duration = _parent.capybara_base_stats.recoil_duration

	var sweep_angle = 0.9 * PI
	
	# 原来是两个0.1秒的动画，现在合并成一次连续横扫
	var sweep_duration = 0.4

	var side_a = side_range
	var side_b = -side_range
	var angle_a = sweep_angle
	var angle_b = -sweep_angle

	if not _parent.sprite.flip_v:
		side_a = -side_range
		side_b = side_range
		angle_a = -sweep_angle
		angle_b = sweep_angle

	# =========================
	# 1. 蓄力后摆
	# =========================
	interpolate(
		"position",
		initial_position,
		Vector2(
			initial_position.x - recoil,
			initial_position.y + side_a
		),
		recoil_duration,
		Tween.TRANS_SINE,
		Tween.EASE_OUT
	)

	interpolate(
		"rotation",
		_parent.sprite.rotation,
		angle_a,
		recoil_duration,
		Tween.TRANS_SINE,
		Tween.EASE_OUT
	)

	_parent.tween.start()
	yield(_parent.tween, "tween_all_completed")

	SoundManager.play(
		Utils.get_rand_element(_parent.current_stats.shooting_sounds),
		_parent.current_stats.sound_db_mod,
		0.2
	)

	_parent.enable_hitbox()

	# =========================
	# 2. 连续贝塞尔横扫
	# =========================
	_sweep_start_position = Vector2(
		initial_position.x - recoil,
		initial_position.y + side_a
	)

	_sweep_end_position = Vector2(
		initial_position.x - recoil,
		initial_position.y + side_b
	)

	# 控制点越靠右，横扫的弧线越饱满
	_sweep_control_position = Vector2(
		initial_position.x + _parent.get_sweep_range(atk_distance) * capybara_curve_stat,
		initial_position.y
	)

	_sweep_start_rotation = angle_a
	_sweep_end_rotation = angle_b

	_parent.tween.interpolate_method(
		self,
		"_update_sweep_curve",
		0.0,
		1.0,
		sweep_duration,
		Tween.TRANS_SINE,
		Tween.EASE_IN_OUT
	)

	_parent.tween.start()
	yield(_parent.tween, "tween_all_completed")

	# =========================
	# 3. 关闭攻击判定
	# =========================
	if not _parent.stats.deal_dmg_on_return:
		_parent.disable_hitbox()

	# =========================
	# 4. 平滑返回原位
	# =========================
	interpolate(
		"position",
		_parent.sprite.position,
		initial_position,
		shooting_data.back_duration,
		Tween.TRANS_SINE,
		Tween.EASE_IN_OUT
	)

	interpolate(
		"rotation",
		_parent.sprite.rotation,
		0.0,
		shooting_data.back_duration,
		Tween.TRANS_SINE,
		Tween.EASE_IN_OUT
	)

	_parent.tween.start()
	yield(_parent.tween, "tween_all_completed")

	if _parent.stats.deal_dmg_on_return:
		_parent.disable_hitbox()

	_parent.set_shooting(false)

func melee_thrust_attack(initial_position: Vector2) -> void :
	_parent._hitbox.player_attack_id = _get_next_attack_id()

	var recoil = _parent.capybara_base_stats.recoil
	var recoil_duration = _parent.capybara_base_stats.recoil_duration
	var thrust_half_duration = 0.5

	interpolate("position", initial_position, Vector2(initial_position.x - recoil, initial_position.y), recoil_duration)

	_parent.tween.start()
	yield(_parent.tween, "tween_all_completed")

	SoundManager.play(Utils.get_rand_element(_parent.current_stats.shooting_sounds), _parent.current_stats.sound_db_mod, 0.2)
	_parent.enable_hitbox()

	interpolate("position", _parent.sprite.position, Vector2(initial_position.x + _parent.current_stats.max_range, initial_position.y), thrust_half_duration)

	_parent.tween.start()
	yield(_parent.tween, "tween_all_completed")

	if not _parent.stats.deal_dmg_on_return:
		_parent.disable_hitbox()

	interpolate("position", _parent.sprite.position, initial_position, shooting_data.back_duration)

	_parent.tween.start()
	yield(_parent.tween, "tween_all_completed")

	if _parent.stats.deal_dmg_on_return:
		_parent.disable_hitbox()

	_parent.set_shooting(false)

func melee_reverse_sweep_attack(initial_position: Vector2, distance: float) -> void :
	_parent.sprite.flip_v = not _parent.sprite.flip_v
	_parent._hitbox.player_attack_id = _get_next_attack_id()

	var atk_distance = min(
		_parent.capybara_base_stats.max_range,
		max(MIN_SWEEP_DISTANCE, distance)
	)
	
	shooting_data.update_atk_duration(atk_distance)

	var side_range = atk_distance
	var recoil = _parent.capybara_base_stats.recoil
	var recoil_duration = _parent.capybara_base_stats.recoil_duration

	var sweep_angle = 0.9 * PI
	
	# 原来是两个0.1秒的动画，现在合并成一次连续横扫
	var sweep_duration = 0.4

	var side_a = side_range
	var side_b = -side_range
	var angle_a = sweep_angle
	var angle_b = -sweep_angle

	if not _parent.sprite.flip_v:
		side_a = -side_range
		side_b = side_range
		angle_a = -sweep_angle
		angle_b = sweep_angle

	# =========================
	# 1. 蓄力后摆
	# =========================
	interpolate(
		"position",
		initial_position,
		Vector2(
			initial_position.x - recoil,
			initial_position.y + side_a
		),
		recoil_duration,
		Tween.TRANS_SINE,
		Tween.EASE_OUT
	)

	interpolate(
		"rotation",
		_parent.sprite.rotation,
		angle_a,
		recoil_duration,
		Tween.TRANS_SINE,
		Tween.EASE_OUT
	)

	_parent.tween.start()
	yield(_parent.tween, "tween_all_completed")

	SoundManager.play(
		Utils.get_rand_element(_parent.current_stats.shooting_sounds),
		_parent.current_stats.sound_db_mod,
		0.2
	)

	_parent.enable_hitbox()

	# =========================
	# 2. 连续贝塞尔横扫
	# =========================
	_sweep_start_position = Vector2(
		initial_position.x - recoil,
		initial_position.y + side_a
	)

	_sweep_end_position = Vector2(
		initial_position.x - recoil,
		initial_position.y + side_b
	)

	# 控制点越靠右，横扫的弧线越饱满
	_sweep_control_position = Vector2(
		initial_position.x + _parent.get_sweep_range(atk_distance) * capybara_curve_stat,
		initial_position.y
	)

	_sweep_start_rotation = angle_a
	_sweep_end_rotation = angle_b

	_parent.tween.interpolate_method(
		self,
		"_update_sweep_curve",
		0.0,
		1.0,
		sweep_duration,
		Tween.TRANS_SINE,
		Tween.EASE_IN_OUT
	)

	_parent.tween.start()
	yield(_parent.tween, "tween_all_completed")

	# =========================
	# 3. 关闭攻击判定
	# =========================
	if not _parent.stats.deal_dmg_on_return:
		_parent.disable_hitbox()

	# =========================
	# 4. 平滑返回原位
	# =========================
	interpolate(
		"position",
		_parent.sprite.position,
		initial_position,
		shooting_data.back_duration,
		Tween.TRANS_SINE,
		Tween.EASE_IN_OUT
	)

	interpolate(
		"rotation",
		_parent.sprite.rotation,
		0.0,
		shooting_data.back_duration,
		Tween.TRANS_SINE,
		Tween.EASE_IN_OUT
	)

	_parent.tween.start()
	yield(_parent.tween, "tween_all_completed")

	if _parent.stats.deal_dmg_on_return:
		_parent.disable_hitbox()

	_parent.set_shooting(false)
	_parent.sprite.flip_v = not _parent.sprite.flip_v
