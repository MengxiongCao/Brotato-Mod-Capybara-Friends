class_name CapybaraGainItemWhenReviveEffect
extends "res://mods-unpacked/Dbear-Capybara/effects/ModEffect.gd"

export (String) var item_name = "res://mods-unpacked/Dbear-Capybara/contents/items/holy_sword_of_judge_ment/holy_sword_of_judgement_data.tres"

static func get_id() -> String:
	return "capybara_gain_item_when_revive_effect"


func apply(player_index: int) -> void:
	RunData.get_player_effects(player_index)[custom_key_hash].push_back([key_hash, value, item_name])


func unapply(player_index: int) -> void:
	RunData.get_player_effects(player_index)[custom_key_hash].erase([key_hash, value, item_name])


func get_args(player_index: int) -> Array:
	var name = load(item_name).my_id
	return [str(value), tr(name.to_upper())]


func serialize() -> Dictionary:
	var serialized = .serialize()

	serialized.item_name = item_name

	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)

	item_name = serialized.item_name
