class_name CrystallizedEnemyEffectBehavior
extends "res://effect_behaviors/enemy_effect_behavior.gd"


var capybara_damage_taken: int = 0

# 以capybara_link_laser为模板创建的连线池
var capybara_link_laser_pool: Array = []


onready var crystal_particles = $CrystalParticles
onready var capybara_link_laser = $capybara_link_laser


export(Color) var crystal_outline
export(Array, AudioStream) var break_sound = []
export(Resource) var break_particles

# 是否将本次伤害传递给所有其他晶化敌人
export(bool) var damage_all_crystallized_enemies = true


func init(parent: Enemy) -> EnemyEffectBehavior:
	var _self = .init(parent)
	return self


func _ready() -> void:
	crystal_particles.visible = false
	_capybara_initialize_laser_pool()


# =========================================================
# 初始化连线池
# =========================================================

func _capybara_initialize_laser_pool() -> void:
	capybara_link_laser_pool.clear()

	if not is_instance_valid(capybara_link_laser):
		push_error(
			"CrystallizedEnemyEffectBehavior：找不到capybara_link_laser节点"
		)
		return

	if not capybara_link_laser.has_method("set_targets"):
		push_error(
			"CrystallizedEnemyEffectBehavior：capybara_link_laser没有挂载CapybaraLinkLaser脚本"
		)
		return

	capybara_link_laser_pool.append(capybara_link_laser)

	if capybara_link_laser.has_method("clear_targets_immediately"):
		capybara_link_laser.clear_targets_immediately()


# =========================================================
# 受到伤害
# =========================================================

func on_taken_damage(args: TakeDamageArgs) -> int:
	var player_index = args.from_player_index

	# 判断这次伤害是否由晶化连锁产生
	# 连锁伤害不会再次向其他敌人扩散，避免无限递归
	var is_linked_damage = args.has_meta(
		"capybara_crystal_link_damage"
	)

	if args.hitbox:
		var valid_player = (
			player_index >= 0
			and player_index < RunData.get_player_count()
		)

		var should_change_crystal_level = false

		if valid_player:
			var crystal_chance = min(
				Utils.CAPYBARA_CRYSTALLIZATION_CAP_CHANCE,
				Utils.get_stat(
					Keys.generate_hash("stat_capybara_crystal"),
					player_index
				)
			)

			should_change_crystal_level = Utils.get_chance_success(
				crystal_chance / 100.0
			)
			
			var crystallize_with_stat = RunData.get_player_effect(Keys.generate_hash("capybara_crystallize_with_stat"), player_index)
			if args.hitbox:
				for effect in crystallize_with_stat:
					for stat in args.hitbox.scaling_stats:
						if stat[0] == effect[0]:
							should_change_crystal_level = true
						if should_change_crystal_level:
							break

		# 达到破碎层数后，下次受到攻击必定触发
		if capybara_damage_taken == Utils.CAPYBARA_DAMAGE_TAKEN_TO_BREAK:
			should_change_crystal_level = true

		if should_change_crystal_level:
			_capybara_change_crystal_level(
				args,
				player_index
			)

	# 普通武器伤害才负责创建整张连线网络和扩散伤害
	# 连锁伤害只正常处理目标自身的受伤逻辑
	
	if RunData.get_player_effect(Keys.generate_hash("capybara_crystal_linked_enemies"), player_index).size() > 0:
		if not is_linked_damage:
			if _capybara_enemy_is_crystallized(_parent):
				_capybara_connect_all_crystallized_enemies(
					_parent
				)

				if damage_all_crystallized_enemies and args.hitbox:
					_capybara_damage_all_crystallized_enemies(
						_parent,
						args
					)
			else:
				_capybara_clear_all_link_lasers()

	return HitType.NORMAL


# =========================================================
# 改变当前敌人的晶化层数
# =========================================================

func _capybara_change_crystal_level(
	args: TakeDamageArgs,
	player_index: int
) -> void:
	crystal_particles.visible = true

	capybara_damage_taken = (
		capybara_damage_taken + 1
	) % int(
		Utils.CAPYBARA_DAMAGE_TAKEN_TO_BREAK + 1
	)

	# 晶化层数归零，代表晶体破碎
	if capybara_damage_taken == 0:
		_capybara_break_crystal(
			args,
			player_index
		)
		return

	# 必须先设置为true，再获取所有晶化敌人
	_parent.capybara_is_crystallized = true

	crystal_particles.amount = capybara_damage_taken

	var particle_size = 1.0 + 0.1 * capybara_damage_taken
	var sprite_modify = (
		_parent.sprite.texture.get_size().x / 100.0
	) - 1.0

	var y_pos = Vector2(
		0,
		-_parent.sprite.texture.get_size().y / 4.0
	)

	particle_size *= 1.0 + sprite_modify / 3.0

	crystal_particles.scale = Vector2(
		particle_size,
		particle_size
	)

	crystal_particles.position = y_pos

	if not _parent.has_outline(crystal_outline):
		_parent.add_outline(crystal_outline)


# =========================================================
# 晶体破碎
# =========================================================

func _capybara_break_crystal(
	args: TakeDamageArgs,
	player_index: int
) -> void:
	if break_sound.size() > 0:
		SoundManager.play(
			Utils.get_rand_element(break_sound),
			-5,
			0.2
		)

	var main = _parent.get_tree().current_scene

	var y_pos = Vector2(
		0,
		-_parent.sprite.texture.get_size().y / 4.0
	)

	var modify = max(
		0.0,
		_parent.sprite.texture.get_size().x / 100.0 - 1.0
	)

	var particle_size = 1.0 + modify / 2.0

	if is_instance_valid(main):
		main._capybara_break_particles(
			break_particles,
			_parent.global_position + y_pos,
			particle_size
		)

	capybara_manage_break_damage(
		args,
		player_index
	)

	crystal_particles.visible = false
	_parent.capybara_is_crystallized = false

	if _parent.has_outline(crystal_outline):
		_parent.remove_outline(crystal_outline)

	# 当前敌人不再晶化，它管理的所有连线开始淡出
	_capybara_clear_all_link_lasers()


# =========================================================
# 获取场上全部晶化敌人
# =========================================================

func _capybara_get_all_crystallized_enemies() -> Array:
	var crystallized_enemies: Array = []

	if not is_instance_valid(_parent):
		return crystallized_enemies

	if not is_instance_valid(_parent._entity_spawner_ref):
		return crystallized_enemies

	var all_enemies = _parent._entity_spawner_ref.get_all_enemies()

	for enemy in all_enemies:
		if _capybara_enemy_is_crystallized(enemy):
			crystallized_enemies.append(enemy)

	return crystallized_enemies


func _capybara_enemy_is_crystallized(enemy) -> bool:
	if not is_instance_valid(enemy):
		return false

	if enemy.is_queued_for_deletion():
		return false

	if "dead" in enemy:
		if enemy.dead:
			return false

	if not "capybara_is_crystallized" in enemy:
		return false

	if enemy.capybara_is_crystallized == false:
		return false

	return true


# =========================================================
# 将全部晶化敌人按照最近距离排列
# =========================================================

func _capybara_order_crystallized_enemies(
	start_enemy: Enemy,
	crystallized_enemies: Array
) -> Array:
	var ordered_enemies: Array = []
	var remaining_enemies: Array = crystallized_enemies.duplicate()

	if not _capybara_enemy_is_crystallized(start_enemy):
		return ordered_enemies

	ordered_enemies.append(start_enemy)
	remaining_enemies.erase(start_enemy)

	var current_enemy = start_enemy

	while remaining_enemies.size() > 0:
		var nearest_enemy = null
		var nearest_distance = INF

		for possible_enemy in remaining_enemies:
			if not _capybara_enemy_is_crystallized(
				possible_enemy
			):
				continue

			var distance_value = (
				current_enemy.global_position.distance_squared_to(
					possible_enemy.global_position
				)
			)

			if distance_value < nearest_distance:
				nearest_distance = distance_value
				nearest_enemy = possible_enemy

		if not is_instance_valid(nearest_enemy):
			break

		ordered_enemies.append(nearest_enemy)
		remaining_enemies.erase(nearest_enemy)
		current_enemy = nearest_enemy

	return ordered_enemies


# =========================================================
# 连接全部晶化敌人
# =========================================================

func _capybara_connect_all_crystallized_enemies(
	start_enemy: Enemy
) -> void:
	var crystallized_enemies = (
		_capybara_get_all_crystallized_enemies()
	)

	if crystallized_enemies.size() < 2:
		_capybara_clear_all_link_lasers()
		return

	var ordered_enemies = (
		_capybara_order_crystallized_enemies(
			start_enemy,
			crystallized_enemies
		)
	)

	if ordered_enemies.size() < 2:
		_capybara_clear_all_link_lasers()
		return

	# N个敌人需要N-1条连线
	var required_laser_count = ordered_enemies.size() - 1

	_capybara_ensure_laser_count(
		required_laser_count
	)

	for i in range(capybara_link_laser_pool.size()):
		var laser = capybara_link_laser_pool[i]

		if not is_instance_valid(laser):
			continue

		if i < required_laser_count:
			var enemy_a = ordered_enemies[i]
			var enemy_b = ordered_enemies[i + 1]

			laser.set_targets(
				enemy_a,
				enemy_b
			)
		else:
			# 多余的旧连线逐渐淡出
			if laser.has_method("clear_targets"):
				laser.clear_targets()


# =========================================================
# 扩充连线池
# =========================================================

func _capybara_ensure_laser_count(
	required_count: int
) -> void:
	if not is_instance_valid(capybara_link_laser):
		return

	while capybara_link_laser_pool.size() < required_count:
		var new_laser = capybara_link_laser.duplicate()

		if not is_instance_valid(new_laser):
			break

		add_child(new_laser)

		if new_laser.has_method(
			"clear_targets_immediately"
		):
			new_laser.clear_targets_immediately()

		capybara_link_laser_pool.append(
			new_laser
		)


# =========================================================
# 清除所有连线
# =========================================================

func _capybara_clear_all_link_lasers() -> void:
	for laser in capybara_link_laser_pool:
		if not is_instance_valid(laser):
			continue

		if laser.has_method("clear_targets"):
			laser.clear_targets()


# =========================================================
# 对其他所有晶化敌人传递一次伤害
# =========================================================

func _capybara_damage_all_crystallized_enemies(
	source_enemy: Enemy,
	args: TakeDamageArgs
) -> void:
	if not args.hitbox:
		return

	if args.has_meta("capybara_crystal_link_damage"):
		return

	var crystallized_enemies = (
		_capybara_get_all_crystallized_enemies()
	)

	if crystallized_enemies.size() < 2:
		return

	# 使用meta防止其他敌人再次把伤害传回所有目标
	args.set_meta(
		"capybara_crystal_link_damage",
		true
	)

	for enemy in crystallized_enemies:
		if enemy == source_enemy:
			continue

		if not _capybara_enemy_is_crystallized(enemy):
			continue

		enemy.take_damage(
			args.hitbox.damage,
			args
		)

	args.remove_meta(
		"capybara_crystal_link_damage"
	)


# =========================================================
# 晶化破碎伤害
# =========================================================

func capybara_manage_break_damage(
	args: TakeDamageArgs,
	player_index: int
) -> void:
	if is_instance_valid(get_tree()):
		yield(
			get_tree().create_timer(0.1),
			"timeout"
		)

	if not is_instance_valid(_parent):
		return

	if _parent.dead:
		return

	if player_index < 0:
		return

	if player_index >= RunData.get_player_count():
		return

	var player_crystal_stat = Utils.get_stat(
		Keys.generate_hash("stat_capybara_crystal"),
		player_index
	)

	var per = min(
		player_crystal_stat/Utils.CAPYBARA_CRYSTAL_RATE,
		Utils.CAPYBARA_MAX_PER_DAMAGE_AGAINSR_ENEMY
	) / 100.0

	if _parent is Boss:
		var boss_decrease = float(
			Utils.CAPYBARA_MAX_PER_DAMAGE_AGAINSR_ENEMY
		) / float(
			Utils.CAPYBARA_MAX_PER_DAMAGE_AGAINSR_BOSS
		)

		per = min(
			player_crystal_stat,
			Utils.CAPYBARA_MAX_PER_DAMAGE_AGAINSR_BOSS
		) / (
			100.0 * boss_decrease
		)

	var damage_value = int(
		_parent.max_stats.health * per
	)

	var new_args = TakeDamageArgs.new(
		args.from_player_index,
		null
	)

	new_args.set_meta(
		"capybara_crystal_break",
		true
	)

	_parent.take_damage(
		damage_value,
		new_args
	)


func should_add_on_spawn() -> bool:
	return true
