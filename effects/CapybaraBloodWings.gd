class_name CapybaraBloodWings
extends "res://effects/items/pet_effect.gd"
export (Resource) var weapon_stats
export (int) var aura_range = 100
export (int) var blood_need = 10
export (int) var enemies_in_aura = 0

static func get_id() -> String:
	return "capybara_blood_wings"

func get_args(player_index: int) -> Array:
	var args: = WeaponServiceInitStatsArgs.new()
	var _current_weapon_stats = WeaponService.init_ranged_pet_stats(weapon_stats, player_index, false, args)
	var scaling_stats_text = WeaponService.get_scaling_stats_icon_text(_current_weapon_stats.scaling_stats)
	return [str(_current_weapon_stats.damage), scaling_stats_text, 
	str(value),tr(key.to_upper()), str(blood_need),"+",str(RunData.capybara_vampire_queen_enemies_in_aura  * value)]

func serialize() -> Dictionary:
	var serialized = .serialize()
	serialized.aura_range = aura_range
	serialized.blood_need = blood_need
	serialized.weapon_stats = weapon_stats.serialize()
	serialized.enemies_in_aura = enemies_in_aura

	return serialized

func deserialize_and_merge(serialized: Dictionary) -> void :
	.deserialize_and_merge(serialized)

	var stats = RangedWeaponStats.new()
	stats.deserialize_and_merge(serialized.weapon_stats)
	weapon_stats = stats
	aura_range = serialized.get("aura_range",100)
	blood_need = serialized.get("blood_need", 10)
	enemies_in_aura = serialized.enemies_in_aura
