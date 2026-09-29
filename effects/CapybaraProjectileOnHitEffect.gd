class_name CapybaraProjectileOnHit
extends "res://mods-unpacked/Dbear-Capybara/effects/ModEffect.gd"

export (Resource) var weapon_stats
export (bool) var auto_target_enemy = false
export (Resource) var burning_stats = null


static func get_id() -> String:
	return "capybara_weapon_projectiles_on_hit"

func apply(player_index: int) -> void:
	RunData.get_player_effect(key_hash, player_index).push_back(self)

func unapply(player_index: int) -> void:
	RunData.get_player_effect(key_hash, player_index).erase(self)


func get_args(player_index: int) -> Array:
	var current_stats = WeaponService.init_ranged_stats(weapon_stats, player_index, true)
	var scaling_text = WeaponService.get_scaling_stats_icon_text(current_stats.scaling_stats)
	var current_burning = null
	var scaling_text_burn = null
	if burning_stats:
		current_burning = WeaponService.init_burning_data(burning_stats, player_index, false, false)
		scaling_text_burn = WeaponService.get_scaling_stats_icon_text(current_burning.scaling_stats)
	if current_burning:
		return [str(value), str(current_stats.damage), str(current_stats.piercing + 1), scaling_text, str(current_stats.bounce), "%",str(current_burning.duration),str(current_burning.damage),scaling_text_burn]
	return [str(value), str(current_stats.damage), str(current_stats.piercing + 1), scaling_text, str(current_stats.bounce), "%"]


func serialize() -> Dictionary:
	var serialized = .serialize()

	if weapon_stats != null:
		serialized.weapon_stats = weapon_stats.serialize()
	if burning_stats != null:
		serialized.burning_stats = burning_stats.serialize()

	serialized.auto_target_enemy = auto_target_enemy

	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void :
	.deserialize_and_merge(serialized)

	if serialized.has("weapon_stats"):
		var data = RangedWeaponStats.new()
		data.deserialize_and_merge(serialized.weapon_stats)
		weapon_stats = data
	if serialized.has("burning_stats"):
		var data = BurningData.new()
		data.deserialize_and_merge(serialized.burning_stats)
		burning_stats = data

	auto_target_enemy = serialized.auto_target_enemy
