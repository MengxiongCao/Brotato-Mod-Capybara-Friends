class_name CapybaraSpawnSomethingWhenTreeDie
extends "res://mods-unpacked/Dbear-Capybara/effects/ModEffect.gd"

export (Resource) var effect
export (int) var stat_scaled = 1


static func get_id() -> String:
	return "capybara_spawn_something_when_tree_die"

func apply(player_index: int) -> void:
	RunData.get_player_effect(key_hash, player_index).push_back(self)

func unapply(player_index: int) -> void:
	RunData.get_player_effect(key_hash, player_index).erase(self)


func get_args(player_index: int) -> Array:
	var count = 0
	var current_stats = WeaponService.init_ranged_stats(effect.stats, player_index, true)
	var scaling_text = WeaponService.get_scaling_stats_icon_text(current_stats.scaling_stats)
	if Utils._primary_stat_keys.has(custom_key_hash):
		count = ((Utils.get_stat(custom_key_hash, player_index)/value)*stat_scaled) as int
		
	return [str(value), str(current_stats.damage), str(current_stats.piercing + 1), scaling_text, str(current_stats.bounce), "%",
	"","+"+str(count),tr(custom_key.to_upper()),str(stat_scaled),tr((effect.tracking_key).to_upper())]


func serialize() -> Dictionary:
	var serialized = .serialize()

	if effect != null:
		serialized.effect = effect.serialize()
	serialized.stat_scaled = stat_scaled


	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void :
	.deserialize_and_merge(serialized)

	if serialized.has("effect"):
		var data = TurretEffect.new()
		data.deserialize_and_merge(serialized.effect)
		effect = data
	stat_scaled = serialized.stat_scaled
