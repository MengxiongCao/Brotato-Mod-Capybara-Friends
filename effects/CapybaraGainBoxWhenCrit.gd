class_name CapybaraGainBoxWhenCrit
extends "res://items/global/effect.gd"

export (int) var cap_chance = 5

static func get_id() -> String:
	return "capybara_gain_box_when_crit"

func apply(player_index: int) -> void:
	RunData.get_player_effects(player_index)[custom_key_hash].push_back([key_hash, value, cap_chance])


func unapply(player_index: int) -> void:
	RunData.get_player_effects(player_index)[custom_key_hash].erase([key_hash, value, cap_chance])

func get_args(player_index: int) -> Array:

	var dmg = value
	var scaling_text = ""
	var chance = 0.0

	if key != "":
		assert(key_hash != Keys.empty_hash)

		var show_plus_prefix := false
		scaling_text = Utils.get_scaling_stat_icon_text(key_hash, value / 100.0, show_plus_prefix)
		chance = (value * (Utils.get_stat(key_hash, player_index)/100.0)) as int
		if chance > cap_chance:
			chance = cap_chance

	return [str(chance), scaling_text, "%", str(cap_chance)]

func serialize() -> Dictionary:
	var serialized = .serialize()

	serialized.cap_chance = cap_chance

	return serialized

func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)

	cap_chance = serialized.cap_chance
