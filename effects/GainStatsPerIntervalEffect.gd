class_name GainStatsPerIntervalEffect
extends "res://items/global/effect.gd"

export var interval := 1
export var reset_on_moving := false


static func get_id() -> String:
	return "capybara_gain_stats_per_interval"


func apply(player_index: int) -> void:
	RunData.get_player_effects(player_index)[custom_key_hash].push_back([key_hash, value, interval, reset_on_moving])


func unapply(player_index: int) -> void:
	RunData.get_player_effects(player_index)[custom_key_hash].erase([key_hash, value, interval, reset_on_moving])


func _add_custom_args() -> void:
	var interval_as_neutral := CustomArg.new()
	interval_as_neutral.arg_index = 2
	interval_as_neutral.arg_sign = Sign.NEUTRAL
	custom_args.append(interval_as_neutral)

func get_args(_player_index: int) -> Array:
	return [str(value), tr(key.to_upper()), str(interval)]


func serialize() -> Dictionary:
	var serialized = .serialize()
	serialized.interval = interval
	serialized.reset_on_moving = reset_on_moving
	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)
	interval = serialized.get("interval", 5)
	reset_on_moving = serialized.get("reset_on_moving",true)
