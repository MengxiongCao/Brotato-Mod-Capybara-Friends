class_name CapybaraJuniorSisterText
extends "res://mods-unpacked/Dbear-Capybara/effects/ModEffect.gd"


static func get_id() -> String:
	return "capybara_junior_sister_text"

func get_args(player_index: int) -> Array:
	var args: = WeaponServiceInitStatsArgs.new()
	var effect_thunder = load("res://mods-unpacked/Dbear-Capybara/contents/upgrades/thunder/junior_sister_effect_0.tres")
	var effect_t = RunData.get_player_effect(Keys.generate_hash("capybara_thunder"),player_index)
	var effect_fire = RunData.get_player_effect(Keys.generate_hash("capybara_fire"), player_index)
	var effect_wind = RunData.get_player_effect(Keys.generate_hash("capybara_wind"), player_index)
	var _current_weapon_stats_thunder = WeaponService.init_melee_stats(effect_thunder.stats, player_index, args)
	var exploding_dmg_bonus = (Utils.get_stat(Keys.explosion_damage_hash, player_index) / 100.0)
	var explode_weapon_stats:MeleeWeaponStats = MeleeWeaponStats.new()
	explode_weapon_stats = _current_weapon_stats_thunder
	explode_weapon_stats.damage = max(1, round(_current_weapon_stats_thunder.damage * (1.0 + exploding_dmg_bonus))) as int
	var scaling_stats_t: String = WeaponService.get_scaling_stats_icon_text(explode_weapon_stats.scaling_stats)
	var fire_value = 0
	var wind_value = 0
	var thunder_value = 0
	var burning_data = load("res://mods-unpacked/Dbear-Capybara/contents/upgrades/fire/fire_2_burning_data.tres")
	for effect in effect_fire:
		if effect.custom_key == "fire":
			fire_value += 1
	for effect in effect_wind:
		if effect.custom_key == "wind":
			wind_value += 1
	for effect in effect_t:
		if effect.custom_key == "thunder":
			thunder_value += 1
	var fire_weapon_stats:RangedWeaponStats = load("res://mods-unpacked/Dbear-Capybara/contents/upgrades/fire/sword_wave_effect_projectile.tres")
	var wind_weapon_stats:RangedWeaponStats = load("res://mods-unpacked/Dbear-Capybara/contents/upgrades/wind/projectile_step_effect_projectile.tres")
	var _current_weapon_stats_fire = WeaponService.init_ranged_stats(fire_weapon_stats, player_index, false ,args)
	var scaling_stats_f: String = WeaponService.get_scaling_stats_icon_text(_current_weapon_stats_fire.scaling_stats)
	var _current_weapon_stats_wind = WeaponService.init_ranged_stats(wind_weapon_stats, player_index, false ,args)
	var scaling_stats_w: String = WeaponService.get_scaling_stats_icon_text(_current_weapon_stats_wind.scaling_stats)
	var burning = WeaponService.init_burning_data(burning_data, player_index, false, false)
	var scaling_burn = WeaponService.get_scaling_stats_icon_text(burning_data.scaling_stats)
	return [
	str(thunder_value),
	str(explode_weapon_stats.damage), 
	scaling_stats_t,
	str(fire_value),
	str(_current_weapon_stats_fire.damage),
	scaling_stats_f,
	str(wind_value),
	str(_current_weapon_stats_wind.damage),
	scaling_stats_w,
	str(burning.damage),
	str(burning.duration),
	scaling_burn,
	]
