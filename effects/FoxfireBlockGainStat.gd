class_name FoxFireGainStat
extends "res://mods-unpacked/Dbear-Capybara/effects/ModEffect.gd"

static func get_id() -> String:
	return "capybara_foxfire_block"

func get_args(player_index: int) -> Array:
	return  ["+", str(value), tr(key.to_upper()), str(3)]

func serialize() -> Dictionary:
	var serialized = .serialize()
	return serialized

func deserialize_and_merge(serialized: Dictionary) -> void :
	.deserialize_and_merge(serialized)
