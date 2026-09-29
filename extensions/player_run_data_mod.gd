extends "res://singletons/player_run_data.gd"

static func init_stats(all_null_values: bool = false) -> Dictionary:
	var capybara_raw_stats = .init_stats(all_null_values)
	var capybara_stats = {
		Keys.generate_hash("stat_capybara_gold"):0,
		Keys.generate_hash("stat_capybara_enemies_killed"):0,
		Keys.generate_hash("stat_capybara_wave_time"):0,
		Keys.generate_hash("stat_capybara_crystal"):0,
		Keys.generate_hash("stat_capybara_crystal_state"):0,
		Keys.generate_hash("capybara_character_size"):0,
		Keys.generate_hash("capybara_crystal_turret_energy"):0,
		Keys.generate_hash("capybara_pet_attack_speed"):0,
		Keys.generate_hash("capybara_bonus_damage_against_cursed"):0,
		Keys.generate_hash("capybara_cursed_enemies"):0,
	}
	capybara_raw_stats.merge(capybara_stats)
	
#	if not all_null_values:
#		for stat in ItemService.stats:
#			if stat.stat_name == "stat_capybara_crystal":
#				capybara_raw_stats[Keys.generate_hash(stat.stat_name)] = 60
#	if not all_null_values:
#		for stat in ItemService.stats:
#			if stat.stat_name == "stat_harvesting":
#				capybara_raw_stats[Keys.generate_hash(stat.stat_name)] = 10000
				
	return capybara_raw_stats

static func init_effects() -> Dictionary:
	var capybara_all_stats = init_stats()
	var capybara_raw_effects = .init_effects()
	var capybara_effects = {
		Keys.generate_hash("gain_stats_per_interval"): [],
		Keys.generate_hash("convert_certain_stats"): [],
		Keys.generate_hash("foxfire_count"): [],
		Keys.generate_hash("foxfire_block"): [],
		Keys.generate_hash("extra_bait_every_wave"): [],
		Keys.generate_hash("relive_chance"): [],
		Keys.generate_hash("relive_by_upgrades"): [],
		Keys.generate_hash("gain_gold_when_heal"):[],
		Keys.generate_hash("gain_stats_when_heal"):[],
		Keys.generate_hash("change_way_of_attack"):[],
		Keys.generate_hash("extra_boss_when_upgrade"):[],
		Keys.generate_hash("gain_stats_every_killed_enemy_with_weapon_class"):[],
		Keys.generate_hash("capybara_hide_potato"):[],
		Keys.generate_hash("capybara_every_stat_gain_pet"):[],
		Keys.generate_hash("capybara_darkfish"):[],
		Keys.generate_hash("capybara_curse_rand_item"):[],
		Keys.generate_hash("capybara_curse_random_weapon"):[],
		Keys.generate_hash("capybara_lotus_text"):[],
		Keys.generate_hash("capybara_light_saber_text"):[],
		Keys.generate_hash("capybara_spwan_fairy_when_tree"):[],
		Keys.generate_hash("capybara_move_the_turret_when_pass"):[],
		Keys.generate_hash("capybara_pet_structure_gold"):[],
		Keys.generate_hash("capybara_pet_scaling"):[],
		Keys.generate_hash("capybara_unicorn_effect"):[],
		Keys.generate_hash("capybara_swampman"):[],
		Keys.generate_hash("capybara_all_scaling"):[],
		Keys.generate_hash("capybara_reload_when_dodge"):[],
		Keys.generate_hash("capybara_player_no_hit"):[],
		Keys.generate_hash("capybara_gain_stat_for_every_stat"):[],
		Keys.generate_hash("capybara_projectile_per_interval"):[],
		Keys.generate_hash("capybara_append_new_scale"):[],
		Keys.generate_hash("capybara_holy_sword_of_judgement"):[],
		Keys.generate_hash("capybara_gain_item_when_revive"):[],
		Keys.generate_hash("capybara_gain_crit_damage_bonus_crit_chance"):[],
		Keys.generate_hash("capybara_gain_box_when_crit"):[],
		Keys.generate_hash("cp_projectiles_upgrade"):[],
		Keys.generate_hash("capybara_thunder"):[],
		Keys.generate_hash("capybara_projectiles_on_hit"):[],
		Keys.generate_hash("capybara_fire"):[],
		Keys.generate_hash("capybara_projectile_per_step"):[],
		Keys.generate_hash("capybara_junior_sister"):[],
		Keys.generate_hash("capybara_wind"):[],
		Keys.generate_hash("capybara_round_weapons"):[],
		Keys.generate_hash("capybara_three_weapon_stats"):[],
		Keys.generate_hash("capybara_spawn_turret_for_per_stat"):[],
		Keys.generate_hash("capybara_spawn_tree_every_enemies_killed"):[],
		Keys.generate_hash("capybara_gain_damage_every_healed"):[],
		Keys.generate_hash("capybara_boost_turret_when_nearby"):[],
		Keys.generate_hash("capybara_spawn_gold_burning"):[],
		Keys.generate_hash("capybara_disabled"):[],
		Keys.generate_hash("cp_number_of_enemies_upgrade"):[],
		Keys.generate_hash("capybara_gain_stat_for_enemies_killed"):[],
		Keys.generate_hash("capybara_burning_duration"):0,
		Keys.generate_hash("capybara_burning_can_crit"):0,
		Keys.generate_hash("capybara_no_hurt_tree"):[],
		Keys.generate_hash("capybara_trees_can_attack"):[],
		Keys.generate_hash("capybara_start_with_x_trees"):0,
		Keys.generate_hash("capybara_can_not_level_up"):[],
		Keys.generate_hash("capybara_extra_boss_for_x_enemies"):0,
		Keys.generate_hash("capybara_hit_protection_for_x_enemies"):0,
		Keys.generate_hash("capybara_call_for_love"):[],
		Keys.generate_hash("capybara_charm_time"):0,
		Keys.generate_hash("capybara_charmed_enemies_attack"):[],
		Keys.generate_hash("capybara_no_bounce_decrease"):[],
		Keys.generate_hash("capybara_gain_stat_when_attack_killed_enemies"):[],
		Keys.generate_hash("capybara_spawn_pets_for_x_enemies"):[],
		Keys.generate_hash("capybara_force_limit_item"):[],
		Keys.generate_hash("capybara_wave_time_for_x_items"):[],
		Keys.generate_hash("capybara_gain_stat_for_every_step_after_equip"):[],
		Keys.generate_hash("capybara_burning_spread_for_x_stat"):[],
		Keys.generate_hash("capybara_burning_cooldown_reduction"):[],
		Keys.generate_hash("capybara_pet_cooldown_reduction"):[],
		Keys.generate_hash("capybara_take_time_for_x_shot"):[],
		Keys.generate_hash("capybara_add_item"):[],
		Keys.generate_hash("capybara_turret_projectiles"):0,
		Keys.generate_hash("capybara_turret_piercing"):0,
		Keys.generate_hash("capybara_turret_bounce"):0,
		Keys.generate_hash("capybara_turret_range"):0,
		Keys.generate_hash("gain_stat_capybara_crystal"):0,
		Keys.generate_hash("capybara_crystal_linked_enemies"):[],
		Keys.generate_hash("capybara_crystal_turret_level"):0,
		Keys.generate_hash("capybara_crystal_null"):[],
		Keys.generate_hash("capybara_ranged_melee_attack"):[],
		Keys.generate_hash("capybara_crystallize_with_stat"):[],
		Keys.generate_hash("capybara_stat_when_crystal_level"):[],
		Keys.generate_hash("capybara_projectiles_on_death"):[],
		Keys.generate_hash("capybara_projectiles_on_hit"):[],
		Keys.generate_hash("capybara_crystallize_tier_weapon"):[],
		Keys.generate_hash("capybara_starting_with_all_legendary"):[],
		Keys.generate_hash("capybara_bonus_curse_factor"):0,
		Keys.generate_hash("capybara_special_dodge"):[],
		Keys.generate_hash("capybara_temp_stat_when_dodge"):[],
		Keys.generate_hash("capybara_number_of_merged_characters"):0,
		Keys.generate_hash("capybara_reload_when_crystal_hawk_attack"):[],
		Keys.generate_hash("capybara_gain_stat_when_killed_hunt"):[],
		Keys.generate_hash("capybara_trees_add_proj_to_weapon"):[],
		Keys.generate_hash("capybara_spawn_special_item"):[],
		Keys.generate_hash("capybara_gain_weapons_when_selection"):[],
		Keys.generate_hash("capybara_reload_turret_when_crystal_sword_killed"):[],
		Keys.generate_hash("capybara_stat_shop"):[],
		Keys.generate_hash("capybara_reload_when_consumable"):0,
		Keys.generate_hash("capybara_lose_percent_hp_per_second"):0,
		Keys.generate_hash("capybara_projectile_when_consumable"):[],
		Keys.generate_hash("capybara_reload_when_cursed_killed"):[],
		Keys.generate_hash("capybara_projectile_when_x_cursed_killed"):[],
		Keys.generate_hash("capybara_bonus_curse_enemy"):0,
		Keys.generate_hash("capybara_curse_bosses"):0,
		Keys.generate_hash("capybara_increase_the_chance_of_item"):[],
		Keys.generate_hash("capybara_replace_upgrades_with_limited_items"):0,
		Keys.generate_hash("capybara_price_of_unique"):0,
		}
	var capybara_gain_stat_effects = {}
	for stat in ItemService.stats:
		var key = Keys.generate_hash("gain_" + stat.stat_name)
		if stat.is_primary_stat and not key in capybara_effects:
			capybara_gain_stat_effects[key] = 0
	capybara_effects.merge(capybara_gain_stat_effects)

	capybara_raw_effects.merge(capybara_all_stats)
	capybara_raw_effects.merge(capybara_effects)

	return capybara_raw_effects

func deserialize(data: Dictionary):
	.deserialize(data)
	return self

func duplicate():
	return .duplicate()
