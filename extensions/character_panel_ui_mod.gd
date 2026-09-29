extends "res://ui/menus/ingame/character_panel_ui.gd"

func apply_items_appearance(all_items: Array) -> void :
	var capybara_potato_texture = load("res://entities/units/player/potato.png")
	var capybara_transparent_texture = load("res://mods-unpacked/Dbear-Capybara/extensions/cp_null.png")
	var capybara_legs = $"%Character"/Legs
	var capybara_potato = $"%Character"/Sprite
	capybara_potato.texture = capybara_potato_texture
	capybara_legs.visible = true
	var capybara_items = []
	var capybara_should_remove = false
	for item in all_items:
		if item is CharacterData:
			if item.my_id == "character_cp_uncle_zhang":
				capybara_should_remove = true
				capybara_items.append(item)
	if capybara_should_remove:
		.apply_items_appearance(capybara_items)
	else:
		.apply_items_appearance(all_items)
	var capybara_hide_potato = false
	for effect in item_data.effects:
		if effect == null or not is_instance_valid(effect):
			continue
		if effect.custom_key_hash == Keys.generate_hash("capybara_hide_potato"):
			capybara_hide_potato = true
	if capybara_hide_potato:
		for item in all_items:
			for app in item.item_appearances:
				var potato = $"%Character"/Sprite
				potato.texture = capybara_transparent_texture
				var legs = $"%Character"/Legs
				legs.visible = false
				return

