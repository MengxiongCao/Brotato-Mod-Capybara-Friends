class_name ModEffect
extends "res://items/global/effect.gd"

static func get_id() -> String:
	return "mod_effect"

func get_icon(_player_index: int) -> Texture:
	var capybara_raw_icon = .get_icon(_player_index)
	var capybara_icon:Texture = capybara_raw_icon
	if key_hash == Keys.generate_hash("stat_foxfire"):
		capybara_icon = load("res://mods-unpacked/Dbear-Capybara/icons/cp_stat_foxfire.png")
	elif key_hash == Keys.generate_hash("the_golden"):
		capybara_icon = load("res://mods-unpacked/Dbear-Capybara/icons/cp_material_icon.png")

	return capybara_icon
