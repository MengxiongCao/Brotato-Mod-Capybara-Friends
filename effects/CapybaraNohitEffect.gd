class_name CapybaraNohitEffect
extends "res://effects/weapons/null_effect.gd"

export (int) var interval: = 5
export (int) var time_to_shoot_sword_wave = 15
export (Resource) var weapon_stats

static func get_id() -> String:
	return "capybara_no_hit_effect"

func get_args(player_index: int) -> Array:
	var current_stats = WeaponService.init_ranged_stats(weapon_stats, player_index, true)
	var scaling_text = WeaponService.get_scaling_stats_icon_text(weapon_stats.scaling_stats)
	return [str(value), str(interval), str(time_to_shoot_sword_wave), str(current_stats.damage), str(current_stats.piercing + 1), scaling_text, str(current_stats.bounce), "%"]

func serialize() -> Dictionary:
	var serialized = .serialize()
	serialized.interval = interval
	serialized.time_to_shoot_sword_wave = time_to_shoot_sword_wave
	if weapon_stats != null:
		serialized.weapon_stats = weapon_stats.serialize()
	return serialized

func deserialize_and_merge(serialized: Dictionary) -> void :
	.deserialize_and_merge(serialized)
	interval = serialized.get("interval", 5)
	time_to_shoot_sword_wave = serialized.get("time_to_shoot_sword_wave", 15)
	if serialized.has("weapon_stats"):
		var data = RangedWeaponStats.new()
		data.deserialize_and_merge(serialized.weapon_stats)
		weapon_stats = data
