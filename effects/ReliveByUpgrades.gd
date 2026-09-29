class_name ReliveByUpgrades
extends "res://mods-unpacked/Dbear-Capybara/effects/ModEffect.gd"

export(int) var value2 := 10

static func get_id() -> String:
	return "capybara_relive_by_upgrades"


func _generate_hashes() -> void:
	._generate_hashes()

func apply(player_index: int) -> void:
	RunData.get_player_effects(player_index)[custom_key_hash].push_back([key_hash, value, value2])

func unapply(player_index: int) -> void:
	RunData.get_player_effects(player_index)[custom_key_hash].erase([key_hash, value, value2])

func get_args(player_index: int) -> Array:

	var scaling_text = ""
	var scaling_text_2 = ""
	var key_name = ""
	var xp:int
	var gold_gain:int

	if key != "":
		assert(key_hash != Keys.empty_hash)
		xp = value2 * Utils.get_stat(key_hash, player_index) * (1.0 + (Utils.get_stat(Keys.xp_gain_hash, player_index) as float)/100.0 as float)
		gold_gain = value2 * Utils.get_stat(key_hash, player_index) as int
		var show_plus_prefix := false
		scaling_text = Utils.get_scaling_stat_icon_text(key_hash, value2, show_plus_prefix)
		key_name = tr(key.to_upper())

	return [key_name, str(value), str(value2), str(xp), scaling_text, str(gold_gain)]


func serialize() -> Dictionary:
	var serialized = .serialize()

	serialized.value2 = value2

	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)

	value2 = serialized.value2 as int


func duplicate(subresources := false) -> Resource:
	var duplication = .duplicate(subresources)
	return duplication
