class_name ConvertCertainStats
extends "res://items/global/effect.gd"

export(int) var max_stat: = 8
export(String) var to_stat: = "weapon_slot"
export(int) var to_value: = 1

var to_stat_hash: int = Keys.weapon_slot_hash

static func get_id() -> String:
	return "capybara_convert_certain_stats"


func _generate_hashes() -> void:
	._generate_hashes()
	to_stat_hash = Keys.generate_hash(to_stat)


func apply(player_index: int) -> void:
	to_stat_hash = Keys.generate_hash(to_stat)
	RunData.get_player_effects(player_index)[custom_key_hash].push_back([key_hash,value,to_stat_hash,max_stat,to_value])


func unapply(player_index: int) -> void:
	to_stat_hash = Keys.generate_hash(to_stat)
	RunData.get_player_effects(player_index)[custom_key_hash].erase([key_hash,value,to_stat_hash,max_stat,to_value])


func get_args(_player_index: int) -> Array:
	return [str(max_stat), tr(key.to_upper()), tr(to_stat.to_upper()), str(value), str(to_value)]


func serialize() -> Dictionary:
	var serialized = .serialize()

	serialized.max_stat = max_stat
	serialized.to_stat = to_stat
	serialized.to_value = to_value

	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)

	max_stat = serialized.max_stat as int
	to_stat = serialized.to_stat
	to_stat_hash = Keys.generate_hash(to_stat)
	to_value = serialized.to_value as int


func duplicate(subresources := false) -> Resource:
	var duplication = .duplicate(subresources)

	if to_stat_hash == Keys.empty_hash and to_stat != "":
		to_stat_hash = Keys.generate_hash(to_stat)

	duplication.to_stat_hash = to_stat_hash

	return duplication
