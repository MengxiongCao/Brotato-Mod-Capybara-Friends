extends "res://ui/menus/shop/shop_item.gd"

func set_shop_item(p_item_data, p_wave_value: int = RunData.current_wave):
	.set_shop_item(p_item_data,p_wave_value)
	for effect in RunData.get_player_effect(Keys.generate_hash("capybara_stat_shop"), player_index):
		var stat_key = effect[0]
		value = ceil(value / 20.0) as int
		var material_icon: Image = ItemService.get_stat_icon(stat_key).get_data()
		var texture: = ImageTexture.new()
		texture.create_from_image(material_icon)
		_button.set_material_icon(texture)
		_button.set_value(value, RunData.get_player_currency(player_index))
	var capybara_unique_price_mod = RunData.get_player_effect(Keys.generate_hash("capybara_price_of_unique"), player_index)/100.0
	if p_item_data is ItemData and p_item_data.max_nb == 1:
		value = max(1.0, value * (1 + capybara_unique_price_mod)) as int
		_button.set_value(value, RunData.get_player_currency(player_index))
	var capybara_cursed_item_icon= load("res://mods-unpacked/Dbear-Capybara/icons/cp_curse_scholar_book.png")
	var capybara_have_cursed_item = RunData.get_player_item(Keys.generate_hash("item_curse_scholar_book"),player_index)
	if capybara_cursed_item_icon != null and capybara_have_cursed_item and item_data.is_cursed and not item_data is WeaponData:
		_button.set_additional_icon(capybara_cursed_item_icon)
