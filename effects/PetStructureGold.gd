class_name PetStructureGold
extends "res://mods-unpacked/Dbear-Capybara/effects/ModEffect.gd"

export(int) var scale_structure := 50
export(int) var scale_gold := -300
export(int) var interval: = 5
export(int) var max_gold: = 25
export(int) var max_weapon_slot: = 12
export(int) var max_work_pets: = 10


static func get_id() -> String:
	return "capybara_pet_structure_gold"


func apply(player_index: int) -> void:
	RunData.get_player_effects(player_index)[custom_key_hash].push_back([value, scale_gold, scale_structure, interval, max_gold, max_weapon_slot, max_work_pets])


func unapply(player_index: int) -> void:
	RunData.get_player_effects(player_index)[custom_key_hash].erase([value, scale_gold, scale_structure, interval, max_gold, max_weapon_slot, max_work_pets])


func get_args(player_index: int) -> Array:

	var gold_scaling_text = ""
	var structure_scaling_text = ""
	var gold_key = "materials"
	var weapon_slot_key = "weapon_slot"
	var gold_gain:int = 1 + RunData.get_nb_structures(player_index) * (scale_structure/100.0)
	var show_plus_prefix := true
	var attack_speed_increase = RunData.get_player_gold(player_index) * (scale_gold/100.0)
	structure_scaling_text = Utils.get_scaling_structures_icon_text(scale_structure / 100.0, show_plus_prefix)

	return [str(value), str(gold_gain), structure_scaling_text, str(scale_gold), tr(gold_key.to_upper()), str(1), str(interval), str(attack_speed_increase), tr(gold_key.to_upper()), tr(weapon_slot_key.to_upper()),str("+"),str(max_gold),str(max_weapon_slot), str(max_work_pets)]


func serialize() -> Dictionary:
	var serialized = .serialize()

	serialized.scale_structure = scale_structure
	serialized.scale_gold = scale_gold
	serialized.interval = interval
	serialized.max_gold = max_gold
	serialized.max_weapon_slot = max_weapon_slot
	serialized.max_work_pets = max_work_pets

	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)

	scale_gold = serialized.get("scale_gold",5)
	scale_structure = serialized.get("scale_structure",50)
	interval = serialized.get("interval",5)
	max_gold = serialized.max_gold
	max_weapon_slot = serialized.max_weapon_slot
	max_work_pets = serialized.max_work_pets
