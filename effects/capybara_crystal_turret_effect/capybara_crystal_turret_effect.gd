class_name CapybaraCrystalTurretEffect
extends "res://effects/items/turret_effect.gd"


static func get_id() -> String:
	return "capybara_crystal_turret_effect"


func get_args(player_index: int) -> Array:
	_init_stats_args_turret.effects = effects
	var crystal_level = RunData.get_player_effect(Keys.generate_hash("capybara_crystal_turret_level"), player_index)
	var init_stats = WeaponService.init_structure_stats(stats, player_index, _init_stats_args_turret)
	var scaling_stats_text = WeaponService.get_scaling_stats_icon_text(init_stats.scaling_stats)
	return [str(init_stats.damage), scaling_stats_text, str(init_stats.nb_projectiles + crystal_level), str(init_stats.bounce), tr(key.to_upper())]
