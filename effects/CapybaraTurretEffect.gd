class_name CapybaraTurretEffect
extends "res://effects/items/turret_effect.gd"

static func get_id() -> String:
	return "capybara_turret"

func get_args(player_index: int) -> Array:
	if is_spawning:
		var spawn_cd = WeaponService.apply_structure_attack_speed_effects(stats.cooldown, player_index)
		return [str(stepify(spawn_cd / 60.0, 0.1))]

	_init_stats_args_turret.effects = effects
	var init_stats = WeaponService.init_structure_stats(stats, player_index, _init_stats_args_turret)

	if is_burning:
		var scaling_stats_text = WeaponService.get_scaling_stats_icon_text(init_stats.burning_data.scaling_stats)
		return [str(init_stats.burning_data.duration),str(value), str(init_stats.burning_data.damage), scaling_stats_text, tr(key.to_upper())]
	else:
		var scaling_stats_text = WeaponService.get_scaling_stats_icon_text(stats.scaling_stats)
		return [str(init_stats.damage), scaling_stats_text,str(value), str(init_stats.nb_projectiles), str(init_stats.bounce), tr(key.to_upper())]
