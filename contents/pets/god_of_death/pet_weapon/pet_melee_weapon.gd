extends "res://weapons/melee/melee_weapon.gd"

var args: = WeaponServiceInitStatsArgs.new()
var base_damage = 0
var duplicated_stats:MeleeWeaponStats = null
var capybara_base_stats


func init_stats(at_wave_begin: bool = true) -> void :
	.init_stats()
	capybara_base_stats = stats
	if at_wave_begin:
		_current_cooldown = get_next_cooldown(at_wave_begin)
	reset_cooldown()
	current_stats.max_range = capybara_base_stats.max_range
	_range_shape.shape.radius = capybara_base_stats.max_range + DETECTION_RANGE

func get_next_cooldown(at_wave_begin: bool = false) -> float:
	return stats.cooldown

func reset_cooldown() -> void :
	_current_cooldown = stats.cooldown

func capybara_check_is_pet_weapon() -> bool:
	return true
