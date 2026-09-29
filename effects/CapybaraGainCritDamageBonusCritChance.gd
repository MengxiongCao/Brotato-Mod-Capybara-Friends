class_name CapybaraGainCritDamageBonusCritChance
extends "res://mods-unpacked/Dbear-Capybara/effects/ModEffect.gd"

static func get_id() -> String:
	return "capybara_gain_crit_damage_bonus_crit_chance"


func get_args(player_index: int) -> Array:
	var crit_chance_name = "stat_crit_chance"
	var crit_damage_name = "CAPYBARA_STAT_CRIT_DAMAGE"
	var stat_to_add = ((Utils.get_stat(Keys.stat_crit_chance_hash, player_index) - 100) * value if (Utils.get_stat(Keys.stat_crit_chance_hash, player_index) - 100) * value  > 0 else 0) as int
	
	return [str(1), tr(crit_chance_name.to_upper()), str("+"),tr(crit_damage_name.to_upper()),str(value),str(stat_to_add)]
