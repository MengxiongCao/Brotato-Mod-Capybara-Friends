extends "res://ui/menus/ingame/upgrades_ui_player_container.gd"

var capybara_reject_crystal:ButtonWithIcon = null
var capybara_crystal_null_upgrade = load("res://mods-unpacked/Dbear-Capybara/contents/upgrades/crystal_null/upgrade_crystal_turret_data.tres")

func show_item(item_data):
	.show_item(item_data)
	var capybara_cursed_item_icon = load("res://mods-unpacked/Dbear-Capybara/icons/cp_curse_scholar_book.png")
	var capybara_have_cursed_item = RunData.get_player_item(Keys.generate_hash("item_curse_scholar_book"),player_index)
	if capybara_cursed_item_icon != null and capybara_have_cursed_item and item_data.is_cursed:
		_take_button.icon = capybara_cursed_item_icon

func show_upgrades_for_level(level: int) -> void:
	var _capybara_label = get_node_or_null("UpgradesContainer/Title")

	if _capybara_label and level < 0:
		if _capybara_label is Label:
			_capybara_label.text = "CAPYBARA_CRYSTAL_STATE_UP"

			if RunData.current_wave == 1 and RunData.get_stat(Keys.generate_hash("stat_capybara_crystal"), player_index) <= 0:
				_capybara_label.text = "CAPYBARA_CHOOSE_CRYSTAL"

	if _capybara_label and level > 0:
		_capybara_label.text = "LEVEL_UP"

	.show_upgrades_for_level(level)

	var cp_upgrades = ItemService.get_upgrades(level, 4, _old_upgrades, player_index)
	var is_same_upgrade = capybara_check_is_same_upgrade(_old_upgrades, cp_upgrades) and level > 0 and not (ItemService.capybara_crystal_path(player_index) >= 3 and level < 0)
	var is_first_crystal_choice = level < 0 and ItemService.capybara_crystal_path(player_index) <= 0
	_reroll_button.visible = not is_same_upgrade

	if is_first_crystal_choice:
		# 隐藏原重随按钮，让复制出来的按钮占据原按钮的位置
		_reroll_button.visible = false

		var button_parent = _reroll_button.get_parent()
		var reroll_button_index = _reroll_button.get_index()

		if not is_instance_valid(capybara_reject_crystal):
			capybara_reject_crystal = _reroll_button.duplicate()
			capybara_reject_crystal.name = "capybara_reject_crystal"

			button_parent.add_child(capybara_reject_crystal)

			# 将拒绝按钮移动到原重随按钮的位置
			button_parent.move_child(capybara_reject_crystal, reroll_button_index)

			if capybara_reject_crystal.is_connected("pressed", self, "_on_RerollButton_pressed"):
				capybara_reject_crystal.disconnect("pressed", self, "_on_RerollButton_pressed")

			capybara_reject_crystal.connect("pressed", self, "_capybara_on_crystal_rejected")

		elif capybara_reject_crystal.get_parent() == null:
			button_parent.add_child(capybara_reject_crystal)
			button_parent.move_child(capybara_reject_crystal, reroll_button_index)

		capybara_reject_crystal.visible = true

		# 不要在文字前添加空格，否则会产生视觉偏移
		capybara_reject_crystal.set_text(tr("CAPYBARA_REJECT_CRYSTAL"))
		capybara_reject_crystal.set_material_icon(capybara_crystal_null_upgrade.icon, Color.white)

	else:
		if is_instance_valid(capybara_reject_crystal):
			capybara_reject_crystal.visible = false

		_reroll_button.visible = not is_same_upgrade

func capybara_check_is_item_add(upgrade_data:UpgradeData, player_index:int, add_item: = false) -> bool:
	for effect in upgrade_data.effects:
		if effect == null or not is_instance_valid(effect):
			continue
		print(effect.key, effect.custom_key)
		if effect.custom_key_hash == Keys.generate_hash("capybara_add_item"):
			if add_item:
				var item_to_add = ItemService.get_item_from_id(effect.key_hash)
				RunData.add_item(item_to_add, player_index)
			return true
	return false

func capybara_check_is_same_upgrade(old_upgrades:Array , new_upgrades:Array) -> bool:
	if old_upgrades.size() != new_upgrades.size():
		return false
	var number = old_upgrades.size()
	var all_check = []
	for i in number:
		if old_upgrades[i].my_id == new_upgrades[i].my_id and old_upgrades[i].tier == new_upgrades[i].tier:
			all_check.append(true)
		else:
			all_check.append(false)
	for i in number:
		if not all_check[i]:
			return false
	return true

func _capybara_on_crystal_rejected() -> void:
	_on_choose_button_pressed(capybara_crystal_null_upgrade)
