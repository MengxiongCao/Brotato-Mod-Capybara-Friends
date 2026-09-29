extends "res://ui/menus/shop/shop_items_container.gd"


func _can_weapon_be_bought(shop_item):
	var cp_can_combine = false
	var cp_weapons = RunData.get_player_weapons_ref(player_index)
	for weapon in cp_weapons:
		if weapon.my_id_hash == shop_item.item_data.my_id_hash and weapon.upgrades_into and not RunData.capybara_check_crystal(weapon):
			cp_can_combine = true
	if RunData.has_weapon_slot_available(shop_item.item_data, player_index):
		cp_can_combine = true
	return ._can_weapon_be_bought(shop_item) and cp_can_combine
