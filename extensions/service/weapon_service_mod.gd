extends "res://singletons/weapon_service.gd"

func init_base_stats(from_stats: WeaponStats, player_index: int, args: WeaponServiceInitStatsArgs = _init_stats_args_service, is_structure: = false, is_special_spawn: = false, is_pet: = false) -> WeaponStats:
	var capybara_stats = WeaponStats.new()
	for effect in args.effects:
		if effect is WeaponGainStatForEveryStatEffect:
			if effect.increased_stat_name == "":
				if effect.key == "stat_attack_speed":
					effect.increased_stat_name = "attack_speed_mod"
				elif effect.key == "stat_damage":
					effect.increased_stat_name = "damage"
				elif effect.key == "stat_range":
					effect.increased_stat_name = "max_range"
	capybara_stats = from_stats.duplicate()
	if (not is_pet) and (not is_structure):
		capybara_stats.scaling_stats = _capybara_apply_weapon_scaling_stat_effects(from_stats.scaling_stats, player_index)
	var capybara_change_way_of_attack = RunData.get_player_effect(Keys.generate_hash("change_way_of_attack"), player_index)
	if capybara_change_way_of_attack.size() >0:
		capybara_stats.max_range = capybara_init_range(from_stats.max_range, 200)
		capybara_stats.min_range = 0
	capybara_stats = .init_base_stats(capybara_stats, player_index, args, is_structure, is_special_spawn, is_pet)
	var capybara_crit_effects = RunData.get_player_effect(Keys.generate_hash("capybara_gain_crit_damage_bonus_crit_chance"),player_index)
	if capybara_crit_effects.size() > 0:
		for linked_stat in capybara_crit_effects:
			if capybara_stats.crit_chance * 100.0 > 100:
				var amount_to_add = ((capybara_stats.crit_chance * 100.0 - 100) * linked_stat[1])/100.0 as float
				capybara_stats.crit_damage += amount_to_add
	if is_pet:
		var pet_attack_speed_modify = 0
		var base_per = RunData.get_player_effect(Keys.generate_hash("capybara_pet_attack_speed"), player_index)/100.0
		var effects = RunData.get_player_effect(Keys.generate_hash("capybara_pet_cooldown_reduction"), player_index)
		for effect in effects:
			var per = effect[1]/100.0
			pet_attack_speed_modify += (Utils.get_stat(effect[0], player_index) * per)/100.0
		capybara_stats.cooldown = max(6, capybara_stats.cooldown / max(0.1, (1 + pet_attack_speed_modify + base_per))) as int
		
	return capybara_stats

func capybara_init_range(current_range:int, apply_range:int) -> int:
	return current_range + apply_range
	

func sum_scaling_stat_values(p_scaling_stats: Array, player_index: int) -> float:
	var capybara_value = .sum_scaling_stat_values(p_scaling_stats, player_index)
	for scaling_stat in p_scaling_stats:
		assert (scaling_stat[0] is int)
		if scaling_stat[0] == Keys.generate_hash("stat_capybara_gold"):
			capybara_value += RunData.get_player_gold(player_index) * scaling_stat[1]
		elif scaling_stat[0] == Keys.generate_hash("stat_capybara_enemies_killed"):
			capybara_value += RunData.get_stat(scaling_stat[0], player_index) * scaling_stat[1]
	return capybara_value

func _apply_beast_master_weapon_scaling_stat_effects(scaling_stats: Array, player_index: int) -> Array:
	var capybara_scaling_stats = ._apply_beast_master_weapon_scaling_stat_effects(scaling_stats, player_index)
	for effect in RunData.get_player_effect(Keys.generate_hash("capybara_pet_scaling"), player_index):
		var damage_stats = [effect[0]]
		var new_scaling_stats = scaling_stats.duplicate(true)
		if new_scaling_stats.size() > 0:
			var value = new_scaling_stats[0][1]
			for stats in new_scaling_stats:
				damage_stats.erase(stats[0])

			for stat_name in damage_stats:
				var new_value = value
				if stat_name == Keys.generate_hash("stat_capybara_gold"):
					new_value = value/10.0
				new_scaling_stats.push_back([stat_name, new_value])

			return new_scaling_stats
	return capybara_scaling_stats

func _capybara_apply_weapon_scaling_stat_effects(scaling_stats: Array, player_index: int) -> Array:
	if RunData.get_player_effect(Keys.generate_hash("capybara_all_scaling"), player_index).size() > 0:
		
		var damage_stats = Utils.convert_to_hash_array(["stat_melee_damage", "stat_ranged_damage", "stat_elemental_damage", "stat_engineering"])
		var new_scaling_stats = scaling_stats.duplicate(true)
		if new_scaling_stats.size() > 0:
			var value = new_scaling_stats[0][1]
			for stat in new_scaling_stats:
				if stat[1] > value:
					value = stat[1]
			for stats in new_scaling_stats:
				damage_stats.erase(stats[0])

			for stat_name in damage_stats:
				new_scaling_stats.push_back([stat_name, value])

			return new_scaling_stats
	if RunData.get_player_effect(Keys.generate_hash("capybara_append_new_scale"), player_index).size() > 0:
		var new_scaling_stats = []
		for effect in RunData.get_player_effect(Keys.generate_hash("capybara_append_new_scale"), player_index):
			var damage_stats = [effect[0]]
			new_scaling_stats = scaling_stats.duplicate(true)
			if new_scaling_stats.size() > 0:
				var value = new_scaling_stats[0][1]
				for stat in new_scaling_stats:
					if stat[1] > value:
						value = stat[1]
				for stats in new_scaling_stats:
					damage_stats.erase(stats[0])

				for stat_name in damage_stats:
					new_scaling_stats.push_back([stat_name, value])

			return new_scaling_stats
	return scaling_stats
#func capybara_erase_scaling_stats_to_damage(damage: int, p_scaling_stats: Array, player_index: int) -> int:
#	return max(1, damage - floor(sum_scaling_stat_values(p_scaling_stats, player_index))) as int

func _set_common_ranged_stats(new_stats: RangedWeaponStats, from_stats: RangedWeaponStats, player_index: int):
	._set_common_ranged_stats(new_stats, from_stats, player_index)
	var capybara_gain_stat_for_every_stat = RunData.get_player_effect(Keys.generate_hash("capybara_gain_stat_for_every_stat"), player_index)
	for effect in capybara_gain_stat_for_every_stat:
		if effect[0] == Keys.piercing_hash:
			var piercing_to_add = int(float(Utils.get_stat(effect[2], player_index))/effect[3])
			new_stats.piercing += piercing_to_add
		elif effect[0] == Keys.bounce_hash:
			var bounce_to_add = int(float(Utils.get_stat(effect[2], player_index))/effect[3])
			new_stats.bounce += bounce_to_add
	var capybara_no_bounce = RunData.get_player_effect(Keys.generate_hash("capybara_no_bounce_decrease"), player_index)
	if capybara_no_bounce.size() > 0:
		new_stats.bounce_dmg_reduction = 0
	if new_stats.projectile_spread <= 0:
		new_stats.projectile_spread += from_stats.nb_projectiles * 0.1


func get_scaling_stats_icon_text(p_scaling_stats: Array) -> String:
	for i in p_scaling_stats.size():
		if not p_scaling_stats[i][0] is int:
			p_scaling_stats[i][0] = Keys.generate_hash(p_scaling_stats[i][0])
	return .get_scaling_stats_icon_text(p_scaling_stats)

func manage_capybara_spawn_projectile(
	entity_from, 
	weapon_stats: RangedWeaponStats, 
	direction: float, 
	auto_target_enemy: bool, 
	entity_spawner_ref: EntitySpawner, 
	from: Node, 
	args: WeaponServiceSpawnProjectileArgs = _default_spawn_projectile_args
) -> Node:
	var pos = entity_from.global_position

	if weapon_stats.shooting_sounds.size() > 0:
		SoundManager2D.play(Utils.get_rand_element(weapon_stats.shooting_sounds), pos, weapon_stats.sound_db_mod, 0.2)

	if auto_target_enemy:
		var all_enemies = entity_spawner_ref.get_all_enemies(false)
		var target = Utils.get_nearest_no_max(all_enemies, pos, 0)

		if target[0] != null and is_instance_valid(target[0]):
			direction = (target[0].global_position - pos).angle() + rand_range(-PI*(1-weapon_stats.accuracy), PI*(1-weapon_stats.accuracy))

	args.deferred = true
	args.knockback_direction = Vector2(cos(direction), sin(direction))
	var projectile = spawn_projectile(pos, weapon_stats, direction, from, args)

	return projectile

func manage_capybara_spawn_protect_projectile(
	entity_from, 
	weapon_stats: RangedWeaponStats, 
	direction: float, 
	auto_target_enemy: bool, 
	entity_spawner_ref: EntitySpawner, 
	from: Node, 
	args: WeaponServiceSpawnProjectileArgs = _default_spawn_projectile_args
) -> Node:
	var pos = entity_from.global_position

	if weapon_stats.shooting_sounds.size() > 0:
		SoundManager2D.play(Utils.get_rand_element(weapon_stats.shooting_sounds), pos, weapon_stats.sound_db_mod, 0.2)

	if auto_target_enemy:
		var all_enemies = entity_spawner_ref.get_all_enemies(false)
		var target = Utils.get_nearest_no_max(all_enemies, from.global_position, 0)

		if target[0] != null and is_instance_valid(target[0]):
			direction = (target[0].global_position - pos).angle() + rand_range(-PI*(1-weapon_stats.accuracy), PI*(1-weapon_stats.accuracy))

	args.deferred = true
	args.knockback_direction = Vector2(cos(direction), sin(direction))
	var projectile = spawn_projectile(pos, weapon_stats, direction, from, args)

	return projectile

func manage_capybara_spawn_sword_projectile(
	entity_from, 
	pos_from,
	weapon_stats: RangedWeaponStats, 
	direction: float, 
	auto_target_enemy: bool, 
	entity_spawner_ref: EntitySpawner, 
	from: Node, 
	args: WeaponServiceSpawnProjectileArgs = _default_spawn_projectile_args
) -> Node:
#	var rand_r = rand_range(300, 500)
#	var rand_a = rand_range(0, 2*PI)
#	var x = rand_r * cos(rand_a)
#	var y = rand_r * sin(rand_a)
#	if entity_from is Player:
#		entity_from._entity_spawner_ref
#	x = clamp(x, entity_spawner_ref._zone_min_pos.x, entity_spawner_ref._zone_max_pos.x)
#	y = clamp(y, entity_spawner_ref._zone_min_pos.y, entity_spawner_ref._zone_max_pos.y)
#	var rand_v = Vector2(x, y)
	var pos = pos_from.global_position

	if weapon_stats.shooting_sounds.size() > 0:
		SoundManager2D.play(Utils.get_rand_element(weapon_stats.shooting_sounds), pos, weapon_stats.sound_db_mod, 0.2)

	if auto_target_enemy:
		var all_enemies = entity_spawner_ref.get_all_enemies(false)
		var target = Utils.get_nearest_no_max(all_enemies, from.global_position, 0)

		if target[0] != null and is_instance_valid(target[0]):
			direction = (target[0].global_position - pos).angle() + rand_range(-PI*(1-weapon_stats.accuracy), PI*(1-weapon_stats.accuracy))

	args.deferred = true
	args.knockback_direction = Vector2(cos(direction), sin(direction))
	var projectile = spawn_projectile(pos, weapon_stats, direction, from, args)

	return projectile

func init_burning_data(base_burning_data: BurningData, player_index: int, is_structure: bool = false, is_pet: bool = false) -> BurningData:
	var capybara_burning_data = .init_burning_data(base_burning_data, player_index, is_structure, is_pet)
	var capybara_burning_duration = RunData.get_player_effect(Keys.generate_hash("capybara_burning_duration"), player_index)
	var new_capybara_burning_data = capybara_burning_data.duplicate()
	new_capybara_burning_data.duration = max(1, capybara_burning_duration + new_capybara_burning_data.duration)
	var capybara_burning_spread = RunData.get_player_effect(Keys.generate_hash("capybara_burning_spread_for_x_stat"), player_index)
	for effect in capybara_burning_spread:
		var scaled = 0
		if effect[2] == Keys.structure_hash:
			scaled = RunData.get_nb_structures(player_index)
		else:
			scaled = RunData.get_stat(effect[2], player_index)
		var add = (effect[1] * scaled / effect[3]) as int
		new_capybara_burning_data.spread += add
	return new_capybara_burning_data

func init_structure_stats(from_stats: RangedWeaponStats, player_index: int, args: WeaponServiceInitStatsArgs = _init_stats_args_service) -> RangedWeaponStats:
	var capybara_structure_stats = .init_structure_stats(from_stats, player_index, args)
	if capybara_structure_stats is RangedWeaponStats:
		var nb = RunData.get_player_effect(Keys.generate_hash("capybara_turret_projectiles"), player_index)
		capybara_structure_stats.nb_projectiles += nb
		capybara_structure_stats.projectile_spread += 0.1 * nb
		var ex_r = RunData.get_player_effect(Keys.generate_hash("capybara_turret_range"), player_index)
		capybara_structure_stats.max_range += ex_r
		var ex_pier = RunData.get_player_effect(Keys.generate_hash("capybara_turret_piercing"), player_index)
		capybara_structure_stats.piercing += ex_pier
		var ex_b = RunData.get_player_effect(Keys.generate_hash("capybara_turret_bounce"), player_index)
		capybara_structure_stats.bounce += ex_b
		
	return capybara_structure_stats
