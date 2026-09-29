extends "res://singletons/text.gd"

# 在调用原版 Text.text() 前处理需要重写的参数，调用后再处理特殊颜色标签。
const CAPYBARA_SPECIAL_TEXT_COLOR_RULES := {
	"EFFECT_STAT_CAPYBARA_CRYSTAL": {0: "B7AFC9"},
	"EFFECT_CRYSTALLIZE_TIER_WEAPON": {0: "B7AFC9",1: "B7AFC9"},
}
const CAPYBARA_WEAPON_TIER_ROMAN := ["I", "II", "III", "IV"]

var capybara_keys_needing_percent: = {
	"effect_capybara_burning_cooldown_reduction" :[0],
	"effect_capybara_pet_cooldown_reduction":[0],
	"effect_capybara_x_hit":[2],
	"effect_capybara_bounce_hit":[2],
	"effect_capybara_break_on_hit":[0],
	"effect_capybara_bonus_curse_factor":[0],
	"effect_capybara_crystal_hawk":[2],
	"effect_capybara_spawn_special_item":[0],
	"effect_capybara_spawn_special_item_no_max":[0],
	"effect_lose_percent_hp_per_second":[0],
	"effect_enemy_chance_fruit_drops":[0],
	"effect_capybara_bonus_curse_enemy":[0],
	"EFFECT_CAPYBARA_INCREASE_THE_CHANCE_OF_ITEM".to_lower():[0],
	"EFFECT_CAPYBARA_INCREASE_THE_CHANCE_OF_ITEM_SUM".to_lower():[0],
	"effect_capybara_price_of_unique":[0],
}

var capybara_keys_needing_operator: = {
	"effect_capybara_bonus_curse_factor":[0],
	"effect_turretato": [2],
	"effect_capybara_increase_wave_time": [0],
	"effect_stat_capybara_crystal":[0],
	"effect_capybara_turret_projectiles":[0],
	"capybara_turret_range":[0],
	"effect_cp_crystal_turret_up":[0],
	"effect_stat_when_crystal_level":[0],
	"effect_capybara_turret_bounce":[0],
	"effect_capybara_turret_piercing":[0],
	"effect_capybara_pet_attack_speed":[0],
	"effect_capybara_crystal_turret_energy":[0],
	"effect_crystallize_tier_weapon":[0],
	"effect_temp_stat_when_dodge":[0],
	"effect_capybara_gain_stat_when_killed_hunt":[0],
	"effect_enemy_chance_fruit_drops":[0],
	"effect_capybara_bonus_curse_enemy":[0],
	"effect_capybara_bonus_damage_against_cursed":[0],
	"EFFECT_CAPYBARA_INCREASE_THE_CHANCE_OF_ITEM".to_lower():[0],
	"EFFECT_CAPYBARA_INCREASE_THE_CHANCE_OF_ITEM_SUM".to_lower():[0],
	"effect_capybara_price_of_unique":[0],
	
}

func get_args_needing_percent(key: String) -> Array:
	var cp_nd_per = .get_args_needing_percent(key)
	if capybara_keys_needing_percent.has(key):
		return capybara_keys_needing_percent[key]
	return cp_nd_per

func get_args_needing_operator(key: String) -> Array:
	var capybara_keys_op = .get_args_needing_operator(key)
	if capybara_keys_needing_operator.has(key):
		return capybara_keys_needing_operator[key]
	return capybara_keys_op


func text(key: String, args: Array = [], arg_signs: Array = []) -> String:
	var capybara_args: Array = args
	var capybara_arg_signs: Array = arg_signs
	if key.to_upper() == "EFFECT_CURSED_STARTING_ITEM" or key.to_upper() == "EFFECT_STARTING_ITEM":
		capybara_args = capybara_format_cursed_starting_weapon_args(args, not arg_signs.empty())
		if capybara_args.size() > 1 and args.size() > 1 and capybara_args[1] != args[1] and arg_signs.size() > 1:
			capybara_arg_signs = arg_signs.duplicate()
			capybara_arg_signs[1] = Sign.NEUTRAL

	var capybara_text: String = .text(key, capybara_args, capybara_arg_signs)

	return capybara_apply_special_text_colors(key, capybara_text)


func capybara_format_cursed_starting_weapon_args(capybara_args: Array, capybara_colored: bool) -> Array:
	var capybara_result: Array = capybara_args.duplicate()
	if capybara_result.size() < 2:
		return capybara_result

	var capybara_weapon_key = str(capybara_result[1]).to_upper()
	if not capybara_weapon_key.begins_with("WEAPON_"):
		return capybara_result

	for capybara_tier_index in range(CAPYBARA_WEAPON_TIER_ROMAN.size()):
		var capybara_tier_suffix = "_" + str(capybara_tier_index + 1)
		if not capybara_weapon_key.ends_with(capybara_tier_suffix):
			continue

		var capybara_base_key = capybara_weapon_key.substr(0, capybara_weapon_key.length() - capybara_tier_suffix.length())
		var capybara_weapon_name = tr(capybara_base_key) + " " + CAPYBARA_WEAPON_TIER_ROMAN[capybara_tier_index]
		if capybara_tier_index <= 0:
			capybara_weapon_name = tr(capybara_base_key)
		if capybara_colored:
			var capybara_tier_color = ItemService.get_color_from_tier(capybara_tier_index).to_html()
			if capybara_tier_index > 0:
				capybara_weapon_name = "[color=#" + capybara_tier_color + "]" + capybara_weapon_name + "[/color]"
		capybara_result[1] = capybara_weapon_name
		break

	return capybara_result


func capybara_apply_special_text_colors(
	key: String,
	capybara_text: String
) -> String:
	if not CAPYBARA_SPECIAL_TEXT_COLOR_RULES.has(key):
		return capybara_text

	var capybara_rules: Dictionary = CAPYBARA_SPECIAL_TEXT_COLOR_RULES[key]
	for capybara_color_index in capybara_rules:
		capybara_text = capybara_replace_color_at_index(
			capybara_text,
			int(capybara_color_index),
			str(capybara_rules[capybara_color_index])
		)

	return capybara_text


func capybara_replace_color_at_index(capybara_text: String,capybara_target_index: int,capybara_new_color: String )-> String:
	var capybara_tag := "[color=#"
	var capybara_search_position := 0
	var capybara_color_index := 0

	while true:
		var capybara_tag_position := capybara_text.find(
			capybara_tag,
			capybara_search_position
		)
		if capybara_tag_position == -1:
			return capybara_text

		var capybara_color_start := (
			capybara_tag_position
			+ capybara_tag.length()
		)
		var capybara_color_end := capybara_text.find(
			"]",
			capybara_color_start
		)
		if capybara_color_end == -1:
			return capybara_text

		if capybara_color_index == capybara_target_index:
			return (
				capybara_text.substr(0, capybara_color_start)
				+ capybara_new_color
				+ capybara_text.substr(
					capybara_color_end,
					capybara_text.length() - capybara_color_end
				)
			)

		capybara_search_position = capybara_color_end + 1
		capybara_color_index += 1
	return capybara_text
