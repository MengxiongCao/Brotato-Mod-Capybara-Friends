class_name UnicornEffect
extends "res://effects/items/pet_effect.gd"
export (Resource) var melee_weapon_stats
export (Resource) var ranged_weapon_stats
export (Resource) var ice_cream_stats
export (int) var light_count = 7
export (int) var enemy_needed = 15
export (int) var interval = 3
export (int) var value_gain = 1

static func get_id() -> String:
	return "capybara_unicorn_effect"

func get_args(player_index: int) -> Array:
	var args: = WeaponServiceInitStatsArgs.new()
	var _current_ranged_weapon_stats = WeaponService.init_ranged_pet_stats(ranged_weapon_stats, player_index, false, args)
	var _current_ice_cream_weapon_stats = WeaponService.init_ranged_pet_stats(ice_cream_stats, player_index, false, args)
	var _current_melee_weapon_stats = WeaponService.init_melee_pet_stats(melee_weapon_stats, player_index, args)
	var ranged_scaling_stats_text = WeaponService.get_scaling_stats_icon_text(_current_ranged_weapon_stats.scaling_stats)
	var melee_scaling_stats_text = WeaponService.get_scaling_stats_icon_text(_current_melee_weapon_stats.scaling_stats)
	var ice_cream_scaling_stats_text = WeaponService.get_scaling_stats_icon_text(_current_ice_cream_weapon_stats.scaling_stats)
	var luck_key = "stat_luck"
	return [str(_current_ranged_weapon_stats.damage), ranged_scaling_stats_text, 
	str(_current_melee_weapon_stats.damage),melee_scaling_stats_text, 
	str(light_count),str(enemy_needed),str(interval),str(value_gain),tr(luck_key.to_upper()),
	str(_current_ice_cream_weapon_stats.damage), ice_cream_scaling_stats_text]

func serialize() -> Dictionary:
	var serialized = .serialize()
	serialized.ranged_weapon_stats = ranged_weapon_stats.serialize()
	serialized.melee_weapon_stats = melee_weapon_stats.serialize()
	serialized.ice_cream_stats = ice_cream_stats.serialize()
	serialized.light_count = light_count
	serialized.enemy_needed = enemy_needed
	serialized.interval = interval
	serialized.value_gain = value_gain

	return serialized

func deserialize_and_merge(serialized: Dictionary) -> void :
	.deserialize_and_merge(serialized)

	var ranged_stats = RangedWeaponStats.new()
	var melee_stats = MeleeWeaponStats.new()
	var new_ice_cream_stats = RangedWeaponStats.new()
	ranged_stats.deserialize_and_merge(serialized.ranged_weapon_stats)
	ranged_weapon_stats = ranged_stats
	melee_stats.deserialize_and_merge(serialized.melee_weapon_stats)
	melee_weapon_stats = melee_stats
	new_ice_cream_stats.deserialize_and_merge(serialized.ice_cream_stats)
	ice_cream_stats = new_ice_cream_stats
	light_count = serialized.get("light_count",7)
	enemy_needed = serialized.get("enemy_needed",15)
	value_gain = serialized.get("value_gain",1)
	interval = serialized.get("interval", 3)
	
