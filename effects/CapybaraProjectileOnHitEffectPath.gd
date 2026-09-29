class_name CapybaraProjectileOnHitPath
extends "res://mods-unpacked/Dbear-Capybara/effects/ModEffect.gd"

export (String) var weapon_stats
export (bool) var auto_target_enemy = false


static func get_id() -> String:
	return "capybara_weapon_projectiles_on_hit_path"

func apply(player_index: int) -> void:
	RunData.get_player_effect(key_hash, player_index).push_back([value, weapon_stats, auto_target_enemy])

func unapply(player_index: int) -> void:
	RunData.get_player_effect(key_hash, player_index).erase([value, weapon_stats, auto_target_enemy])

func get_args(player_index: int) -> Array:
	var r_weapon_stats:RangedWeaponStats = load(weapon_stats)
	var current_stats = WeaponService.init_ranged_stats(r_weapon_stats, player_index, true)
	
	for stat in r_weapon_stats.scaling_stats:
		if not stat[0] is int:
			stat[0] = Keys.generate_hash(stat[0])
	var scaling_text = WeaponService.get_scaling_stats_icon_text(r_weapon_stats.scaling_stats)
	return [str(value), str(current_stats.damage), str(current_stats.piercing + 1), scaling_text, str(current_stats.bounce), "%"]


func serialize() -> Dictionary:
	var serialized = .serialize()

	serialized.weapon_stats = weapon_stats

	serialized.auto_target_enemy = auto_target_enemy

	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void :
	.deserialize_and_merge(serialized)

	weapon_stats = serialized.weapon_stats

	auto_target_enemy = serialized.auto_target_enemy
