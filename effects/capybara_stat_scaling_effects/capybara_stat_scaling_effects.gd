class_name CapybaraScalingStatsEffect
extends "res://mods-unpacked/Dbear-Capybara/effects/ModEffect.gd"

export (int) var base = 10
export (bool) var operate = true
export (int) var cap = 5


static func get_id() -> String:
	return "effect_capybara_scaling_stats"


func apply(player_index: int) -> void:
	RunData.get_player_effects(player_index)[custom_key_hash].push_back([value, key_hash, base, cap, operate])


func unapply(player_index: int) -> void:
	RunData.get_player_effects(player_index)[custom_key_hash].erase([value, key_hash, base, cap, operate])


func get_args(player_index: int) -> Array:
	var show_plus = true
	var capped = false
	var final = 0
	if operate and value < 0:
		final = max(cap, base + value * Utils.get_stat(key_hash, player_index)/100.0)
		if final <= cap:
			capped = true
	elif operate and value >= 0:
		final = min(base + value * Utils.get_stat(key_hash, player_index)/100.0, cap)
		if final >= cap:
			capped = true
	else:
		final = value * Utils.get_stat(key_hash, player_index)/100.0
		show_plus = false
	var scaling_text = Utils.get_scaling_stat_icon_text(key_hash, value/100.0, show_plus)
	if capped:
		return [str(final as int), scaling_text, "|",str(cap)]
	return [str(final as int), scaling_text, "",""]


func serialize() -> Dictionary:
	var serialized = .serialize()

	serialized.base = base
	serialized.cap = cap
	serialized.operate = operate

	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)

	base = serialized.base
	cap = serialized.cap
	operate = serialized.operate
