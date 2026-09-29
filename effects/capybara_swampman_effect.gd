class_name SwampManEffect
extends "res://effects/items/pet_effect.gd"
export (int) var damage_shrink = 25

static func get_id() -> String:
	return "capybara_swampman_effect"

func get_args(player_index: int) -> Array:
	return [str(value), str(damage_shrink), "%"]

func serialize() -> Dictionary:
	var serialized = .serialize()
	serialized.damage_shrink = damage_shrink

	return serialized

func deserialize_and_merge(serialized: Dictionary) -> void :
	.deserialize_and_merge(serialized)
	damage_shrink = serialized.get("damage_shrink",25)
