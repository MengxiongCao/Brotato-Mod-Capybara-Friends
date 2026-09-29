class_name CapybaraMeleePetEffect
extends "res://effects/items/pet_effect.gd"

export (Resource) var weapon_stats
export (int) var value2 = 1
export (String) var stat_scaled = "stat_capybara_enemies_killed"
export (String) var stat_to_add = "stat_harvesting"

static func get_id() -> String:
	return "capybara_melee_pet_effect"

func get_args(player_index: int) -> Array:
	var args: = WeaponServiceInitStatsArgs.new()
	var _current_weapon_stats = WeaponService.init_melee_pet_stats(weapon_stats, player_index, args)
	var scaling_stats: String = WeaponService.get_scaling_stats_icon_text(_current_weapon_stats.scaling_stats)

	return [str(_current_weapon_stats.damage), scaling_stats,str(value2),"%",tr(stat_scaled.to_upper()),tr(stat_to_add.to_upper())]

func serialize() -> Dictionary:
	var serialized = .serialize()
	if weapon_stats != null:
		serialized.weapon_stats = weapon_stats.serialize()
	serialized.value2 = value2
	serialized.stat_scaled = stat_scaled
	serialized.stat_to_add = stat_to_add

	return serialized

func deserialize_and_merge(serialized: Dictionary) -> void :
	.deserialize_and_merge(serialized)
	
	if serialized.has("weapon_stats"):
		var stats = MeleeWeaponStats.new()
		stats.deserialize_and_merge(serialized.weapon_stats)
		weapon_stats = stats
	value2 = serialized.value2
	stat_scaled = serialized.stat_scaled
	stat_to_add = serialized.stat_to_add
