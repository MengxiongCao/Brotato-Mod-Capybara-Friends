class_name CapybaraThreeWeaponStats
extends "res://mods-unpacked/Dbear-Capybara/effects/ModEffect.gd"

export (Resource) var weapon_stats
export (Resource) var weapon_stats_1
export (Resource) var weapon_stats_2
export (Resource) var burning_stats


static func get_id() -> String:
	return "capybara_three_weapon_stats"

func apply(player_index: int) -> void:
	RunData.get_player_effect(key_hash, player_index).push_back(self)

func unapply(player_index: int) -> void:
	RunData.get_player_effect(key_hash, player_index).erase(self)


func get_args(player_index: int) -> Array:
	var current_stats = WeaponService.init_ranged_stats(weapon_stats, player_index, true)
	var scaling_text = WeaponService.get_scaling_stats_icon_text(current_stats.scaling_stats)
	var current_stats_1 = WeaponService.init_ranged_stats(weapon_stats_1, player_index, true)
	var scaling_text_1 = WeaponService.get_scaling_stats_icon_text(current_stats_1.scaling_stats)
	var current_stats_2 = WeaponService.init_ranged_stats(weapon_stats_2, player_index, true)
	var scaling_text_2 = WeaponService.get_scaling_stats_icon_text(current_stats_2.scaling_stats)
	var current_burning = WeaponService.init_burning_data(burning_stats, player_index, false, false)
	var scaling_text_burn = WeaponService.get_scaling_stats_icon_text(current_burning.scaling_stats)
	return [str(value), 
	str(current_stats.damage), 
	str(current_stats.piercing + 1), 
	str(current_stats.bounce),
	scaling_text, 
	str(current_stats_1.damage), 
	str(current_stats_1.piercing + 1), 
	str(current_stats_1.bounce),
	scaling_text_1, 
	str(current_stats_2.damage), 
	str(current_stats_2.piercing + 1), 
	str(current_stats_2.bounce),
	scaling_text_2, 
	str(current_burning.duration),
	str(current_burning.damage),
	scaling_text_burn,
	 "%",]


func serialize() -> Dictionary:
	var serialized = .serialize()

	if weapon_stats != null:
		serialized.weapon_stats = weapon_stats.serialize()
	if weapon_stats_1 != null:
		serialized.weapon_stats_1 = weapon_stats_1.serialize()
	if weapon_stats_2 != null:
		serialized.weapon_stats_2 = weapon_stats_2.serialize()
	if burning_stats != null:
		serialized.burning_stats = burning_stats.serialize()


	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void :
	.deserialize_and_merge(serialized)

	if serialized.has("weapon_stats"):
		var data = RangedWeaponStats.new()
		data.deserialize_and_merge(serialized.weapon_stats)
		weapon_stats = data
	if serialized.has("weapon_stats_1"):
		var data = RangedWeaponStats.new()
		data.deserialize_and_merge(serialized.weapon_stats_1)
		weapon_stats_1 = data
	if serialized.has("weapon_stats_2"):
		var data = RangedWeaponStats.new()
		data.deserialize_and_merge(serialized.weapon_stats_2)
		weapon_stats_2 = data
	if serialized.has("burning_stats"):
		var data = BurningData.new()
		data.deserialize_and_merge(serialized.burning_stats)
		burning_stats = data
