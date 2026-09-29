class_name CapybaraFloatingTextShop
extends "res://visual_effects/floating_text/floating_text_manager_shop.gd"

func stat_added(stat: int, value: int, db_mod: float, position: Vector2, pos_sounds: Array = stat_pos_sounds, neg_sounds: Array = stat_neg_sounds, positive_color: bool = false) -> void :
	if stat == Keys.generate_hash("capybara_crystal_jelly"):
		var item_icon = ItemService.get_item_from_id(Keys.generate_hash("item_crystal_jelly")).icon
		display_icon(value, item_icon, pos_sounds, neg_sounds, position, direction, db_mod, positive_color)
	else:
		.stat_added(stat, value, db_mod, position, pos_sounds, neg_sounds, positive_color)
