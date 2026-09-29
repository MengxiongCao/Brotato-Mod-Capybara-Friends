extends "res://singletons/utils.gd"

const CAPYBARA_CRYSTAL_MAX_RATE:float = 10.0
const CAPYBARA_CRYSTAL_CHANCE_RATE:float = 10.0
const CAPYBARA_CRYSTAL_RATE:float = 3.0
const CAPYBARA_DETERIORATE:int = 4
const CAPYBARA_DETERIORATE_THRESHHOLD:int = 25
const CAPYBARA_WEAKEN_MAX_RATE:int = 100
const CAPYBARA_CRYSTALLIZATION_CAP_CHANCE = 66.0
const CAPYBARA_MAX_PER_DAMAGE_AGAINSR_ENEMY = 60.0
const CAPYBARA_MAX_PER_DAMAGE_AGAINSR_BOSS = 15.0
const CAPYBARA_DAMAGE_TAKEN_TO_BREAK = 6.0
const CAPYBARA_ITEM_CRYSTALLIZATION_CAP_CHANCE = 50.0
const CAPYBARA_CRYSTALLIZED_CAP_NB:int = 3
const CAPYBARA_MUTATION_CAP_CHANCE:int = 100
const CAPYBARA_MUTATION_CAP_BOOST:int = 300

func get_scaling_grades_icon_text(scaling: float = 1.0, show_plus_prefix: bool = true) -> String:
	var grade_icon_path = "res://mods-unpacked/Dbear-Capybara/icons/cp_upgrade_icon.png"
	var grade_small_icon: Texture = load(grade_icon_path)
	var w = 21 * ProgressData.settings.font_size
	var prefix = "+" if show_plus_prefix and scaling > 0.0 else ""
	var color = "white" if scaling > 0.0 else "#f6617c"
	var scaling_text = "[color=%s]%s%s%%[/color]" % [color, prefix, str(round(scaling * 100.0))]
	return "%s[img=%sx%s]%s[/img]" % [scaling_text, w, w, grade_icon_path]

func get_scaling_structures_icon_text(scaling: float = 1.0, show_plus_prefix: bool = true) -> String:
	var grade_icon_path = "res://mods-unpacked/Dbear-Capybara/icons/cp_turret_icon.png"
	var grade_small_icon: Texture = load(grade_icon_path)
	var w = 21 * ProgressData.settings.font_size
	var prefix = "+" if show_plus_prefix and scaling > 0.0 else ""
	var color = "white" if scaling > 0.0 else "#f6617c"
	var scaling_text = "[color=%s]%s%s%%[/color]" % [color, prefix, str(round(scaling * 100.0))]
	return "%s[img=%sx%s]%s[/img]" % [scaling_text, w, w, grade_icon_path]

func get_scaling_gold_icon_text(scaling: float = 1.0, show_plus_prefix: bool = true) -> String:
	var grade_icon_path = "res://mods-unpacked/Dbear-Capybara/icons/cp_material_icon.png"
	var grade_small_icon: Texture = load(grade_icon_path)
	var w = 21 * ProgressData.settings.font_size
	var prefix = "+" if show_plus_prefix and scaling > 0.0 else ""
	var color = "white" if scaling > 0.0 else "#f6617c"
	var scaling_text = "[color=%s]%s%s%%[/color]" % [color, prefix, str(round(scaling * 100.0))]
	return "%s[img=%sx%s]%s[/img]" % [scaling_text, w, w, grade_icon_path]

func capybara_get_nearest_boss(targets: Array, from: Vector2, min_distance: = 0, max_range: int = LARGE_NUMBER) -> Array:
	var nearest_target: = []
	min_distance = min_distance * min_distance
	max_range = max_range * max_range

	for target in targets:
		var dist_to_target = target.global_position.distance_squared_to(from)
		if target is Boss and is_instance_valid(target):
			nearest_target = [target, sqrt(dist_to_target)]
			return nearest_target
		if is_between(dist_to_target, min_distance, max_range) and (nearest_target.size() == 0 or dist_to_target < nearest_target[1]):
			nearest_target = [target, dist_to_target]

	
	if nearest_target.size() > 0:
		nearest_target[1] = sqrt(nearest_target[1])
	return nearest_target

func capybara_get_rand_enemy(targets:Array, from:Vector2) -> Array:
	var rand_target = []
	var rand = get_rand_element(targets)
	if rand and is_instance_valid(rand):
		var dist_to_target = rand.global_position.distance_squared_to(from)
		return [rand, sqrt(dist_to_target)]
	return rand_target

# 传入 get_all_enemies(false) 可搜索全场未被魅惑的敌人，返回 [敌人节点, 距离] 或 []。
func capybara_get_highest_health_enemy(capybara_targets: Array, capybara_from: Vector2) -> Array:
	var capybara_best_enemy: Enemy = null
	var capybara_highest_health: int = 0
	var capybara_best_distance_squared: float = 0.0
	for capybara_enemy in capybara_targets:
		if not is_instance_valid(capybara_enemy) or not (capybara_enemy is Enemy):
			continue
		if capybara_enemy.dead or capybara_enemy.is_queued_for_deletion() or not capybara_enemy.is_inside_tree():
			continue
		if not is_instance_valid(capybara_enemy.current_stats) or capybara_enemy.current_stats.health <= 0:
			continue
		var capybara_health: int = capybara_enemy.current_stats.health
		var capybara_distance_squared: float = capybara_enemy.global_position.distance_squared_to(capybara_from)
		if capybara_health > capybara_highest_health or (capybara_health == capybara_highest_health and capybara_distance_squared < capybara_best_distance_squared):
			capybara_best_enemy = capybara_enemy
			capybara_highest_health = capybara_health
			capybara_best_distance_squared = capybara_distance_squared
	if capybara_best_enemy == null:
		return []
	return [capybara_best_enemy, sqrt(capybara_best_distance_squared)]

func get_stat(stat_hsh:int, player_index: int) -> float:
	if stat_hsh == Keys.generate_hash("stat_capybara_enemies_killed"):
		return RunData.get_stat(stat_hsh, player_index)
	if stat_hsh == Keys.generate_hash("capybara_pet_attack_speed"):
		var pet_attack_speed_modify = 0
		var effects = RunData.get_player_effect(Keys.generate_hash("capybara_pet_cooldown_reduction"), player_index)
		for effect in effects:
			var per = effect[1]/100.0
			pet_attack_speed_modify += (Utils.get_stat(effect[0], player_index) * per)
		if effects.size() > 0:
			return .get_stat(stat_hsh, player_index) + pet_attack_speed_modify
	elif stat_hsh == Keys.pickup_range_hash or stat_hsh == Keys.generate_hash("capybara_bonus_damage_against_cursed"):
		var stat_value = .get_stat(stat_hsh, player_index)
		return RunData.get_player_effects(player_index)[stat_hsh] + TempStats.get_stat(stat_hsh, player_index) + LinkedStats.get_stat(stat_hsh, player_index)
#	if stat_hsh == Keys.generate_hash("stat_capybara_wave_time"):
#		var effects = get_player_effects(player_index)
#		return effects[Keys.generate_hash("capybara_wave_time")]
	return .get_stat(stat_hsh, player_index)

func get_curse_factor(value: float, max_val: float = 100.0) -> float:
	var capybara_bonus_curse_factor = 0
	var capybara_max_val = 100.0
	var capybara_check_item_curse_value = 0.0
	var capybara_check_item_curse = false
	for dlc_data in ProgressData.available_dlcs:
		if "max_curse_item_chance" in dlc_data:
			capybara_check_item_curse_value = dlc_data.max_curse_item_chance
			break
	if capybara_check_item_curse_value * 100.0 == max_val:
		capybara_check_item_curse = true
#	if max_val >= 100.0:
#		capybara_max_val *= 2
	for player_index in RunData.get_player_count():
		capybara_bonus_curse_factor += RunData.get_player_effect(Keys.generate_hash("capybara_bonus_curse_factor"),player_index)
		if not capybara_check_item_curse:
			capybara_bonus_curse_factor += RunData.get_player_effect(Keys.generate_hash("capybara_bonus_curse_enemy"),player_index)
	if not capybara_check_item_curse:
		capybara_bonus_curse_factor *= 2
		capybara_max_val *= 2
	return min(.get_curse_factor(value, max_val) + capybara_bonus_curse_factor, capybara_max_val)

func is_stat_key(key: int) -> bool:
	return .is_stat_key(key) or key == Keys.generate_hash("stat_fantasy_holy") or key == Keys.generate_hash("stat_capybara_crystal_state")

func capybara_get_factor(value: float, max_val: float = 100.0) -> float:
	return max_val * (1.0 - 1.0 / (1.0 + value / 500.0))
