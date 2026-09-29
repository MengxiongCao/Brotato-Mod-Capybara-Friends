class_name CapybaraGodOfDeath
extends Pet


# ============================================================
# 基础数据
# ============================================================

export(String) var damage_tracking_id

var _targets_in_range := []
var _current_target := []

var _base_weapon_stats := WeaponStats.new()
var _current_weapon_stats := WeaponStats.new()

var _damage_tracking_id_hash: int = Keys.empty_hash
var _landmine_effect = null

var _cooldown: float = 0.0
var _is_shooting: bool = false

var capybara_bow_recoil := 0

onready var _range_shape = $TargetTriggerZone/CollisionShape2D

var _capybara_player = null

export(Array, Resource) var cp_weapons

var weapons := []
var capybara_effect = null


# ============================================================
# 冲刺参数
# ============================================================

# 冲刺最多持续多少个游戏帧
export(float) var rush_time := 30.0

# 每个游戏帧移动距离
export(float) var rush_speed := 30.0

# 随机落点距离目标的最小距离
export(float) var rush_random_min_distance := 40.0

# 随机落点距离目标的最大距离
export(float) var rush_random_max_distance := 200.0

# 距离落点小于该数值时视为到达
export(float) var rush_arrive_distance := 8.0


var current_rush_time: float = 0.0

# 当前冲刺方向
var rush_dir := Vector2.ZERO

# 本轮冲刺的固定落点
var rush_destination := Vector2.ZERO

# 当前是否已经生成落点
var has_rush_destination := false


# ============================================================
# 节点与其他数据
# ============================================================

onready var _hitbox = $Hitbox
onready var body_sp = $Animation/Sprite

var _owner = null
var capybara_mov := Vector2.ZERO

export(Texture) var mad_t
export(Texture) var normal_t

var enemies_killed := 0


# ============================================================
# 初始化
# ============================================================

func init(
	zone_min_pos: Vector2,
	zone_max_pos: Vector2,
	p_players_ref: Array = [],
	entity_spawner_ref = null
) -> void:
	.init(
		zone_min_pos,
		zone_max_pos,
		p_players_ref,
		entity_spawner_ref
	)

	_movement_behavior._target_player = true

	_damage_tracking_id_hash = Keys.generate_hash(
		damage_tracking_id
	)

	if (
		player_index >= 0
		and player_index < p_players_ref.size()
		and is_instance_valid(p_players_ref[player_index])
	):
		_capybara_player = p_players_ref[player_index]
		_owner = p_players_ref[player_index]

	_hitbox.disable()
	_hitbox.damage_tracking_key_hash = _damage_tracking_id_hash

	_hurtbox.disable()

	if normal_t != null:
		body_sp.texture = normal_t


# ============================================================
# 更新宠物数据
# ============================================================

func update_data(effect: PetEffect) -> void:
	.update_data(effect)

	_base_weapon_stats = effect.weapon_stats
	capybara_effect = effect

	var capybara_args := WeaponServiceInitStatsArgs.new()

	if is_instance_valid(_owner):
		_current_weapon_stats = WeaponService.init_melee_pet_stats(
			_base_weapon_stats,
			player_index,
			capybara_args
		)

		weapons = _owner.capybara_pet_add_weapon(
			cp_weapons,
			global_position,
			_base_weapon_stats.damage,
			_current_weapon_stats.scaling_stats
		)

		for weapon in weapons:
			if not is_instance_valid(weapon):
				continue

			_owner._weapons_container.add_child(weapon)
			weapon.set_as_toplevel(true)

			if not weapon.is_connected(
				"capybara_weapon_hit_something",
				self,
				"capybara_hit_something"
			):
				weapon.connect(
					"capybara_weapon_hit_something",
					self,
					"capybara_hit_something"
				)

	reload_data()

	_cooldown = (
		_current_weapon_stats.cooldown
		* rand_range(0.5, 2.0)
	)


func should_data_be_reload() -> bool:
	return true


func reload_data() -> void:
	if _range_shape:
		_range_shape.shape.radius = (
			_current_weapon_stats.max_range
		)

	_current_weapon_stats.burning_data.from = self


# ============================================================
# 武器命中
# ============================================================

func capybara_hit_something(
	thing_hit,
	damage_dealt
) -> void:
	RunData.add_tracked_value(
		player_index,
		_damage_tracking_id_hash,
		damage_dealt,
		0
	)

	var capybara_args := WeaponServiceInitStatsArgs.new()

	_current_weapon_stats = WeaponService.init_melee_pet_stats(
		_base_weapon_stats,
		player_index,
		capybara_args
	)

	for weapon in weapons:
		if not is_instance_valid(weapon):
			continue
		weapon.stats.cooldown = (
			_current_weapon_stats.cooldown / 8.0
		)
		weapon.stats.max_range = (
			
			_base_weapon_stats.max_range / 4.0
		)

		weapon.init_stats(false)


# ============================================================
# 属性接口
# ============================================================

func set_current_stats(stats: Array) -> void:
	_current_weapon_stats = stats[0]

	if _range_shape:
		_range_shape.shape.radius = (
			_current_weapon_stats.max_range
		)

	_current_weapon_stats.burning_data.from = self


func get_stats() -> Array:
	return [_current_weapon_stats]


# ============================================================
# 主逻辑
# ============================================================

func _physics_process(delta: float) -> void:
	# 更新环绕武器位置
	update_capybara_weapons_position()
	if _end_of_wave:
		if current_rush_time > 0.0:
			finish_rush()

		if normal_t != null:
			body_sp.texture = normal_t

		return

	enemies_killed = RunData.get_stat(
		Keys.generate_hash(
			"stat_capybara_enemies_killed"
		),
		player_index
	)

	# 冷却时间
	_cooldown = max(
		_cooldown - Utils.physics_one(delta),
		0.0
	)

	# ========================================================
	# 未冲刺时重新索敌
	# ========================================================

	if current_rush_time <= 0.0:
		_current_target = Utils.capybara_get_nearest_boss(
			_targets_in_range,
			global_position,
			_current_weapon_stats.min_range
		)

		# 普通移动时，根据移动方向翻转
		if capybara_mov.x > 0.0:
			body_sp.flip_h = false
		elif capybara_mov.x < 0.0:
			body_sp.flip_h = true

		# 满足条件时开始冲刺
		if should_shoot():
			start_rush()
			for weapon in weapons:
				weapon._current_cooldown = 0

	# ========================================================
	# 冲刺移动
	# ========================================================

	if current_rush_time > 0.0:
		update_rush(delta)
	else:
		if not _can_move:
			_can_move = true

		if _is_shooting:
			_is_shooting = false

		if normal_t != null:
			body_sp.texture = normal_t


	# 靠近主人时停止普通移动
	if (
		is_instance_valid(_owner)
		and (
			_owner.global_position
			- global_position
		).length() < 300.0
		and current_rush_time <= 0.0
	):
		_can_move = false


# ============================================================
# 开始冲刺
# ============================================================

func start_rush() -> void:
	if _current_target.size() <= 0:
		return

	var target = _current_target[0]

	if not is_instance_valid(target):
		return

	_is_shooting = true
	_can_move = false

	current_rush_time = rush_time

	_cooldown = _current_weapon_stats.cooldown

	# 仅在冲刺开始时随机一次落点
	rush_destination = get_random_rush_destination(
		target
	)

	has_rush_destination = true

	var direction_to_destination := (
		rush_destination
		- global_position
	)

	if direction_to_destination.length() > 0.001:
		rush_dir = direction_to_destination.normalized()
	else:
		rush_dir = Vector2.ZERO

	# 初始化攻击碰撞数据
	_hitbox.projectiles_on_hit = []

	_current_weapon_stats.burning_data.from = self

	var hitbox_args = (
		Hitbox.HitboxArgs.new().set_from_weapon_stats(_current_weapon_stats)
	)

	_hitbox.effect_scale = (
		_current_weapon_stats.effect_scale
	)

	_hitbox.set_damage(
		_current_weapon_stats.damage,
		hitbox_args
	)

	_hitbox.speed_percent_modifier = (
		_current_weapon_stats.speed_percent_modifier
	)

	_hitbox.from = self


# ============================================================
# 在目标周围生成随机落点
# ============================================================

func get_random_rush_destination(
	target: Node2D
) -> Vector2:
	if not is_instance_valid(target):
		return global_position

	var minimum_distance := max(
		0.0,
		min(
			rush_random_min_distance,
			rush_random_max_distance
		)
	)

	var maximum_distance := max(
		minimum_distance,
		rush_random_max_distance
	)

	var random_angle := rand_range(
		0.0,
		PI * 2.0
	)

	# 使用平方根分布，让点在圆形区域内更均匀
	var minimum_squared := (
		minimum_distance
		* minimum_distance
	)

	var maximum_squared := (
		maximum_distance
		* maximum_distance
	)

	var random_distance := sqrt(
		rand_range(
			minimum_squared,
			maximum_squared
		)
	)

	var random_offset := Vector2(
		cos(random_angle),
		sin(random_angle)
	) * random_distance

	return target.global_position + random_offset


# ============================================================
# 更新冲刺
# ============================================================

func update_rush(delta: float) -> void:
	if not has_rush_destination:
		finish_rush()
		return

	var to_destination = (
		rush_destination
		- global_position
	)

	var remaining_distance = (
		to_destination.length()
	)

	var movement_distance = (
		rush_speed
		* Utils.physics_one(delta)
	)

	# 到达落点或下一步会超过落点
	if remaining_distance <= max(
		rush_arrive_distance,
		movement_distance
	):
		global_position = rush_destination
		finish_rush()
		return

	if remaining_distance > 0.001:
		rush_dir = (
			to_destination
			/ remaining_distance
		)
	else:
		rush_dir = Vector2.ZERO

	global_position += (
		rush_dir
		* movement_distance
	)

	current_rush_time = max(
		0.0,
		current_rush_time
		- Utils.physics_one(delta)
	)

	if mad_t != null:
		body_sp.texture = mad_t

	if rush_dir.x > 0.0:
		body_sp.flip_h = false
	elif rush_dir.x < 0.0:
		body_sp.flip_h = true

	# 冲刺时间耗尽
	if current_rush_time <= 0.0:
		finish_rush()


# ============================================================
# 结束冲刺
# ============================================================

func finish_rush() -> void:
	current_rush_time = 0.0

	has_rush_destination = false

	rush_dir = Vector2.ZERO
	rush_destination = global_position

	_is_shooting = false
	_can_move = true

	if normal_t != null:
		body_sp.texture = normal_t


# ============================================================
# 更新环绕武器位置
# ============================================================

func update_capybara_weapons_position() -> void:
	if weapons.size() <= 0:
		return

	for i in range(weapons.size()):
		var weapon = weapons[i]

		if not is_instance_valid(weapon):
			continue

		var radius := 60.0
		var angle := 0.0

		# 7把及以上，围成完整圆环
		if weapons.size() > 6:
			radius = (
				60.0
				+ float(weapons.size() - 6) * 5.0
			) * 2.0

			angle = (
				float(i)
				* PI * 2.0
				/ float(weapons.size())
			)

			weapon.global_position = (
				global_position
				+ Vector2(
					cos(angle),
					sin(angle)
				) * radius
			)

			continue

		# 1～6把武器的排列
		match weapons.size():
			1:
				angle = PI / 2.0
				radius = 20.0

			2:
				angle = (
					PI * 5.0 / 6.0
					- PI * 2.0 / 3.0
					* float(i)
				)
				radius = 40.0

			3:
				angle = (
					PI * 5.0 / 6.0
					- PI * 2.0 / 3.0
					* float(i)
				)
				radius = 50.0

			4:
				angle = (
					PI * 3.0 / 4.0
					- PI / 2.0
					* float(i)
				)
				radius = 60.0

			5:
				angle = (
					PI * 7.0 / 10.0
					- PI * 2.0 / 5.0
					* float(i)
				)
				radius = 60.0

			6:
				angle = (
					float(i)
					* PI * 2.0
					/ 6.0
				)
				radius = 60.0

		weapon.global_position = (
			global_position
			+ Vector2(
				cos(angle),
				sin(angle)
			) * radius
			+ Vector2(0.0, 20.0)
		)


# ============================================================
# 是否可以开始冲刺
# ============================================================

func should_shoot() -> bool:
	return (
		_cooldown <= 0.0
		and not _is_shooting
		and current_rush_time <= 0.0
		and _current_target.size() > 0
		and is_instance_valid(
			_current_target[0]
		)
		and Utils.is_between(
			_current_target[1],
			_current_weapon_stats.min_range,
			_current_weapon_stats.max_range
		)
	)


# ============================================================
# 敌人进入与离开索敌范围
# ============================================================

func _on_TargetTriggerZone_body_entered(
	body
) -> void:
	if body in _targets_in_range:
		return

	_targets_in_range.push_back(body)

	if not body.is_connected(
		"died",
		self,
		"on_target_died"
	):
		body.connect(
			"died",
			self,
			"on_target_died"
		)


func _on_TargetTriggerZone_body_exited(
	body
) -> void:
	_targets_in_range.erase(body)

	if (
		is_instance_valid(body)
		and body.is_connected(
			"died",
			self,
			"on_target_died"
		)
	):
		body.disconnect(
			"died",
			self,
			"on_target_died"
		)

	if (
		_current_target.size() > 0
		and _current_target[0] == body
		and current_rush_time <= 0.0
	):
		_current_target.clear()


func on_target_died(
	target: Node2D,
	_args: Entity.DieArgs
) -> void:
	_targets_in_range.erase(target)

	if (
		_current_target.size() > 0
		and _current_target[0] == target
		and current_rush_time <= 0.0
	):
		_current_target.clear()

	# 冲刺过程中目标死亡，也继续冲向已经选定的落点


# ============================================================
# 动画
# ============================================================

func update_animation(
	movement: Vector2
) -> void:
	.update_animation(movement)

	capybara_mov = movement

	if not (
		_animation_player.current_animation == "idle"
		or _animation_player.current_animation == "pet"
	):
		_animation_player.play("idle")


# ============================================================
# Hitbox 信号
# ============================================================

func _on_Hitbox_hit_something(
	thing_hit,
	damage_dealt
) -> void:
	pass


func _on_Hitbox_killed_something(
	thing_killed
) -> void:
	pass


# ============================================================
# 宠物属性转换
# ============================================================

func _can_pet() -> void:
	if capybara_effect == null:
		return

	var stat_scaled = capybara_effect.stat_scaled
	var stat_to_add = capybara_effect.stat_to_add

	var percent = (
		capybara_effect.value2
		/ 100.0
	)

	var value_to_add := int(
		RunData.get_stat(
			Keys.generate_hash(stat_scaled),
			player_index
		) * percent
	)

	if stat_scaled == "stat_capybara_enemies_killed":
		value_to_add = int(
			enemies_killed
			* percent
		)

	RunData.add_stat(
		Keys.generate_hash(stat_to_add),
		value_to_add,
		player_index
	)

	if stat_scaled != "stat_capybara_enemies_killed":
		RunData.remove_stat(
			Keys.generate_hash(stat_scaled),
			value_to_add,
			player_index
		)

	RunData.add_tracked_value(
		player_index,
		_damage_tracking_id_hash,
		value_to_add,
		1
	)
