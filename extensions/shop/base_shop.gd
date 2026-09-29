extends "res://ui/menus/shop/base_shop.gd"

func _combine_weapon(weapon_data: WeaponData, player_index: int, is_upgrade: bool) -> void:
	if weapon_data == null:
		return
	if RunData.capybara_check_crystal(weapon_data):
		if not is_upgrade:
			return
		var replacement_weapon: WeaponData = null
		for current_weapon in RunData.get_player_weapons_ref(player_index):
			if current_weapon.upgrades_into != null and not RunData.capybara_check_crystal(current_weapon):
				replacement_weapon = current_weapon
				break
		if replacement_weapon == null:
			var player_effects = RunData.get_player_effects(player_index)
			var upgrade_effects = player_effects.get(Keys.upgrade_random_weapon_hash, [])
			for effect in upgrade_effects:
				RunData.add_stat(effect[0], effect[1], player_index)
				RunData.add_tracked_value(player_index, Keys.item_anvil_hash, effect[1])
			return
		weapon_data = replacement_weapon
	var gear_container = _get_gear_container(player_index)
	if not is_instance_valid(gear_container):
		return
	var weapons_container = gear_container.weapons_container
	var elements_container = weapons_container._elements
	var crystal_holder: Control = null
	for weapon_element in elements_container.get_children():
		if weapon_element == null:
			continue
		if not is_instance_valid(weapon_element):
			continue
		if not "item" in weapon_element:
			continue
		if weapon_element.item == null:
			continue
		if not weapon_element.item is WeaponData:
			continue
		if RunData.capybara_check_crystal(weapon_element.item):
			if crystal_holder == null:
				crystal_holder = Control.new()
				crystal_holder.name = "CapybaraCrystalWeaponHolder"
				crystal_holder.visible = false
				add_child(crystal_holder)
			elements_container.remove_child(weapon_element)
			crystal_holder.add_child(weapon_element)
	._combine_weapon(weapon_data, player_index, is_upgrade)
	if crystal_holder != null:
		for crystal_element in crystal_holder.get_children():
			if not is_instance_valid(crystal_element):
				continue
			crystal_holder.remove_child(crystal_element)
			elements_container.add_child(crystal_element)
		crystal_holder.queue_free()
		elements_container.emit_signal("elements_changed")
		elements_container.queue_set_focus_neighbours()


func buy_weapon(item_data: WeaponData, player_index: int) -> void :
	var capybara_can_buy_weapon = false
	if not RunData.has_weapon_slot_available(item_data, player_index):
		var weapons = RunData.get_player_weapons(player_index)
		for weapon in weapons:
			if weapon.my_id == item_data.my_id and item_data.upgrades_into != null and not RunData.capybara_check_crystal(weapon):
				capybara_can_buy_weapon = true
				break
		if not capybara_can_buy_weapon:
			RunData.add_stat(Keys.generate_hash("stat_capybara_crystal"),item_data.tier + 1, player_index)
			var pos = get_global_mouse_position()
			_floating_text_manager.stat_added(Keys.generate_hash("stat_capybara_crystal"), item_data.tier + 1, 0, pos)
			return
	.buy_weapon(item_data, player_index)


func _on_shop_item_focused(shop_item, player_index):
	._on_shop_item_focused(shop_item, player_index)

func _on_shop_item_unfocused(shop_item, player_index):
	._on_shop_item_unfocused(shop_item, player_index)

func _get_shop_items_container(_player_index):
	return ._get_shop_items_container(_player_index)

func buy_item(item_data: ItemData, player_index: int) -> void :
	.buy_item(item_data, player_index)
	for effect in item_data.effects:
		if effect == null or not is_instance_valid(effect):
			continue
		if effect.custom_key_hash == Keys.generate_hash("capybara_crystallize_tier_weapon"):
			var current_weapons = RunData.get_player_weapons(player_index)
			var weapon_to_remove = null
			for weapon in current_weapons:
				if not weapon_to_remove and not RunData.capybara_check_crystal(weapon):
					weapon_to_remove = weapon
				if weapon_to_remove and not RunData.capybara_check_crystal(weapon) and ((weapon.tier > weapon_to_remove.tier or (weapon.tier == weapon_to_remove.tier and weapon.is_cursed))):
					weapon_to_remove = weapon
			if weapon_to_remove:
				var weapon_to_add = RunData.capybara_crystallize_item(weapon_to_remove, player_index)
				RunData.add_weapon(weapon_to_add, player_index)
				RunData.remove_weapon(weapon_to_remove, player_index)
				var weapons_container: = _get_gear_container(player_index).weapons_container
				weapons_container._elements.add_element(weapon_to_add)
				weapons_container._elements.remove_element(weapon_to_remove, 1, true)
				var pos = get_global_mouse_position()
				_floating_text_manager.stat_added(Keys.generate_hash("capybara_crystal_jelly"), 1, 0, pos)
			else:
				RunData.add_stat(effect.key_hash , effect.value, player_index)
				var pos = get_global_mouse_position()
				_floating_text_manager.stat_added(effect.key_hash, effect.value, 0, pos)

func _get_item_popup(player_index):
	return ._get_item_popup(player_index)
