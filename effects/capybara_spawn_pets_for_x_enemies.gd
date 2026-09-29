class_name CapybaraSpawnPetsForXEnemies
extends "res://mods-unpacked/Dbear-Capybara/effects/ModEffect.gd"

export (Resource) var effect
export (int) var stat_scaled = 10
export (int) var max_num = 10
export (String) var name
var effect_class = null


static func get_id() -> String:
	return "capybara_spawn_pets_for_x_enemies"

func apply(player_index: int) -> void:
	RunData.get_player_effect(key_hash, player_index).push_back(self)

func unapply(player_index: int) -> void:
	RunData.get_player_effect(key_hash, player_index).erase(self)


func get_args(player_index: int) -> Array:
	var count = 0
	if Utils._primary_stat_keys.has(custom_key_hash):
		count = ((Utils.get_stat(custom_key_hash, player_index)/stat_scaled)*value) as int
	if custom_key_hash == Keys.generate_hash("stat_capybara_enemies_killed"):
		count = ((RunData.get_stat(custom_key_hash, player_index)/stat_scaled)*value) as int
	return [str(value), str(stat_scaled), str(count), tr(name),str(max_num)]


func serialize() -> Dictionary:
	var serialized = .serialize()
	if effect != null:
		serialized.effect = effect.serialize()
		serialized.effect_class = effect.get_script().resource_path
	serialized.stat_scaled = stat_scaled
	serialized.max_num = max_num


	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void :
	.deserialize_and_merge(serialized)
	if serialized.has("effect") and serialized.has("effect_class"):
		var capybara_class = load(serialized["effect_class"])
		var data = capybara_class.new()
		data.deserialize_and_merge(serialized.effect)
		effect = data
	stat_scaled = serialized.stat_scaled
	max_num = serialized.max_num
