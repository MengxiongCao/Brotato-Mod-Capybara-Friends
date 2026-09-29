class_name CapybaraProjectilePerInterval
extends "res://items/global/effect.gd"

export (String) var weapon_stats_path = "res://mods-unpacked/Dbear-Capybara/contents/items/curse_scolar_book/curse_scholar_projectile_weapon_stats.tres"
export (int) var interval = 5
export (float) var scale = 10.0
export (int) var max_num = 6
export (String) var tracking_key
export (bool) var target_enemy = false


static func get_id() -> String:
	return "capybara_projectile_per_interval"

func apply(player_index: int) -> void:
	var tracking_key_hash = Keys.generate_hash(tracking_key)
	RunData.get_player_effects(player_index)[custom_key_hash].push_back([key_hash,value,weapon_stats_path,[interval,scale], max_num, tracking_key_hash, target_enemy])


func unapply(player_index: int) -> void:
	var tracking_key_hash = Keys.generate_hash(tracking_key)
	RunData.get_player_effects(player_index)[custom_key_hash].erase([key_hash,value,weapon_stats_path,[interval,scale], max_num, tracking_key_hash, target_enemy])


func get_args(player_index: int) -> Array:
	var projectile_count:int = max_num + Utils.get_stat(key_hash, player_index) * (scale/100.0)
	if projectile_count > value:
		projectile_count = value
	var scaling_stats = [[key_hash,scale/100.0]]
	var weapon_stats:RangedWeaponStats = load(weapon_stats_path)
	for stat in weapon_stats.scaling_stats:
		if not stat[0] is int:
			stat[0] = Keys.generate_hash(stat[0])
	var current_stats = WeaponService.init_ranged_stats(weapon_stats, player_index, true)
	var scaling_text = WeaponService.get_scaling_stats_icon_text(weapon_stats.scaling_stats)
	var scaling_text_count = WeaponService.get_scaling_stats_icon_text(scaling_stats)
	var projectiles = RunData.get_player_effect(Keys.projectiles_hash,player_index)
	return [str(projectile_count + projectiles),scaling_text_count, str(current_stats.damage),  scaling_text, str(current_stats.piercing + 1), str(current_stats.bounce), str(interval), str(value),str(projectiles + projectile_count)]


func serialize() -> Dictionary:
	var serialized = .serialize()
	serialized.weapon_stats_path = weapon_stats_path
	serialized.interval = interval
	serialized.scale = scale
	serialized.max_num = max_num
	serialized.tracking_key = tracking_key
	serialized.target_enemy = target_enemy as bool

	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void :
	.deserialize_and_merge(serialized)

	weapon_stats_path = serialized.weapon_stats_path
	max_num = serialized.get("max_num", 6)
	interval = serialized.get("interval", 5)
	scale = serialized.get("scale", 10)
	tracking_key = serialized.get("tracking_key", "character_cp_monster")
	tracking_key = serialized.get("target_enemy", false)
