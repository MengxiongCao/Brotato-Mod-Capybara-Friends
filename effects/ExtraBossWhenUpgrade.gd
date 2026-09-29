class_name ExtraBossWhenUpgrade
extends "res://mods-unpacked/Dbear-Capybara/effects/ModEffect.gd"

export(int) var value2 := 3
export(int) var max_num := 36
export(int) var stat_gain = 1


static func get_id() -> String:
	return "capybara_extra_boss_when_upgrade"


func _generate_hashes() -> void:
	._generate_hashes()


func apply(player_index: int) -> void:
	RunData.get_player_effects(player_index)[custom_key_hash].push_back([key_hash, value, value2, max_num,stat_gain])


func unapply(player_index: int) -> void:
	RunData.get_player_effects(player_index)[custom_key_hash].erase([key_hash, value, value2, max_num,stat_gain])

func get_args(player_index: int) -> Array:

	var xp = Utils.get_stat(key_hash, player_index)
	var scaling_text = ""
	var scaling_text_2 = ""
	var key_name = ""
	var boss_value = 0
	var weapon_slot_gain = 1
	var gold_gain = 10
	var weapon_slot_name = "weapon_slot"
	var harvesting = "stat_harvesting"

	if key != "":
		assert(key_hash != Keys.empty_hash)
		var xp_gain = value2 * Utils.get_stat(key_hash, player_index) * RunData.get_player_level(player_index) as int
		xp = WeaponService.apply_damage_bonus(xp_gain, player_index)
		var show_plus_prefix := false
		scaling_text = Utils.get_scaling_grades_icon_text((100/value)/100 as float, false)
		boss_value = (RunData.get_player_level(player_index) * (100/value)) / 100 as int
		if boss_value > value2:
			boss_value = value2
	return [str(value), str(boss_value), str(value2), scaling_text, str(stat_gain), str(gold_gain), tr(key.to_upper()), tr(harvesting.to_upper()), str(max_num),str("+")]


func serialize() -> Dictionary:
	var serialized = .serialize()

	serialized.value2 = value2
	serialized.max_num = max_num
	serialized.stat_gain = stat_gain

	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)

	value2 = serialized.value2
	max_num = serialized.max_num
	stat_gain = serialized.stat_gain


func duplicate(subresources := false) -> Resource:
	var duplication = .duplicate(subresources)
	return duplication
