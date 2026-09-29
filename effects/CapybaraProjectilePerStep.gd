class_name CapybaraProjectilePerStep
extends "res://items/global/effect.gd"

export (Resource) var weapon_stats
export (float) var scale = 10.0
export (bool) var target_enemy = false


static func get_id() -> String:
	return "capybara_projectile_per_step"

func apply(player_index: int) -> void:
	RunData.get_player_effects(player_index)[key_hash].push_back(self)


func unapply(player_index: int) -> void:
	RunData.get_player_effects(player_index)[custom_key_hash].erase(self)


func get_args(player_index: int) -> Array:
	var scaling_stats = [[key_hash,scale/100.0]]
	var args = WeaponServiceInitStatsArgs.new()
	for stat in weapon_stats.scaling_stats:
		if not stat[0] is int:
			stat[0] = Keys.generate_hash(stat[0])
	var current_stats = WeaponService.init_ranged_stats(weapon_stats, player_index, true, args)
	var scaling_text = WeaponService.get_scaling_stats_icon_text(weapon_stats.scaling_stats)
	return [str(scale),str(value), str(current_stats.damage),  scaling_text, str(current_stats.piercing + 1), str(current_stats.bounce)]


func serialize() -> Dictionary:
	var serialized = .serialize()
	serialized.weapon_stats = weapon_stats.serialize()
	serialized.scale = scale
	serialized.target_enemy = target_enemy as bool

	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void :
	.deserialize_and_merge(serialized)

	scale = serialized.get("scale", 10)
	var stats = RangedWeaponStats.new()
	stats.deserialize_and_merge(serialized.weapon_stats)
	weapon_stats = stats
	target_enemy = serialized.get("target_enemy", false)
