extends "res://ui/menus/shop/item_description.gd"

var capybara_expend_indefinitely = true

func _ready() -> void:
	capybara_expend_indefinitely = expand_indefinitely
	._ready()

func _generate_description_effects(player_index, effects: Array, colored: bool = true, activate_tab: bool = true):
	var capybara_valid_effects = _capybara_get_valid_effects(effects)
	._generate_description_effects(player_index, capybara_valid_effects, colored, activate_tab)
	if _check_is_capybara_custom_item(player_index):
		var capybara_effect = get_effects()
		for child in capybara_effect.get_children():
			child.queue_free()

		for effect in capybara_valid_effects:
			var line: EffectLine = effect_line.instance()
			capybara_effect.add_child(line)
			line._display_effect(player_index, effect, colored, activate_tab)
		if item.tracking_text != "[EMPTY]":
			var line: EffectLine = effect_line.instance()
			capybara_effect.add_child(line)
			line._display_special_text(_capybara_get_tracking_text(player_index), null)

func _capybara_get_valid_effects(effects: Array) -> Array:
	var capybara_valid_effects = []
	for effect in effects:
		if effect == null or not is_instance_valid(effect) or not effect.has_method("get_text"):
			continue
		if effect.custom_key == "GMO_COMBINES":
			continue
		capybara_valid_effects.append(effect)
	return capybara_valid_effects

func _check_is_capybara_custom_item(player_index) -> bool:
	if item == null or not is_instance_valid(item) or player_index < 0 or player_index >= RunData.tracked_item_effects.size():
		return false
	for track_id_hash in RunData.capybara_tracking_effects:
		if not RunData.tracked_item_effects[player_index].has(track_id_hash):
			continue
		var item_effect = RunData.tracked_item_effects[player_index][track_id_hash]
		if item.my_id_hash == track_id_hash and item_effect is Array:
			return true
	return false

func _capybara_get_tracking_text(player_index) -> String:
	var capybara_text = ""
	var my_id_hash = item.my_id_hash
	var my_id = item.my_id
	var tracking_text = item.tracking_text
	if player_index != RunData.DUMMY_PLAYER_INDEX and RunData.tracked_item_effects[player_index].has(item.my_id_hash) and item.tracking_text != "[EMPTY]":
		var item_effect = RunData.tracked_item_effects[player_index][my_id_hash]
		if item_effect is Array:
			for i in item_effect.size():
				var tracked_count = item_effect[i]

				var tracking_text_to_use = tracking_text

				if my_id_hash == Keys.generate_hash("item_unicorn_cake") and i == 1:
					tracking_text_to_use = "stats_gained"
				elif my_id_hash == Keys.generate_hash("item_capybara_angel") and i == 1:
					tracking_text_to_use = "enemies_charmed"
				elif my_id_hash == Keys.generate_hash("item_capybara_soul_wheat") and i == 1:
					tracking_text_to_use = "stats_gained"
				elif my_id.begins_with("item_cp_crystal_turret") and i == 1:
					tracking_text_to_use = "xp_gained"

				capybara_text += "\n[color=#" + Utils.SECONDARY_FONT_COLOR.to_html() + "]" + Text.text(tracking_text_to_use.to_upper(), [Text.get_formatted_number(tracked_count)]) + "[/color]"
	return capybara_text

func set_item(item_data: ItemParentData, player_index: int, item_count: = 1) -> void:
	if RunData.shop_effects_checked and item_data is WeaponData and item_data.effects.size() > 4:
		expand_indefinitely = false
	elif item_data is ItemData and not item_data is CharacterData and item_data.effects.size() > 9:
		expand_indefinitely = false
	else:
		expand_indefinitely = capybara_expend_indefinitely

	.set_item(item_data, player_index, item_count)

	_capybara_update_category_text(item_data)

	icon_panel.capybara_update_crystal_icon(item_data)
	_vbox_container.visible = show_details and expand_indefinitely
	_scroll_container.visible = show_details and not expand_indefinitely

func _capybara_update_category_text(item_data: ItemParentData) -> void:
	if not is_instance_valid(item_data) or not is_instance_valid(_category):
		return

	if item_data.has_meta("capybara_character_display_item"):
		_category.text = tr("CAPYBARA_MERGED_CHARACTER")
