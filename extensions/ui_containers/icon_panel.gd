extends "res://ui/menus/shop/icon_panel.gd"

var _capybara_crystallized_icon = load("res://mods-unpacked/Dbear-Capybara/extensions/ui_containers/cp_crystallized_border_icon.png")
var _capybara_crystallized_icon_new = load("res://mods-unpacked/Dbear-Capybara/extensions/ui_containers/cp_crystallized_border_icon_new.png")
var _capybara_crystallized:TextureRect = null
var _capybara_crystal_background = load("res://mods-unpacked/Dbear-Capybara/extensions/ui_containers/cp_crystal_back_ground.png")

func capybara_update_crystal_icon(item_data: Resource) -> void:
	if (item_data is ItemData or item_data is WeaponData) and RunData.capybara_check_crystal(item_data) and not _capybara_crystallized:
		_capybara_crystallized = _curse.duplicate()
		_capybara_crystallized.texture = _capybara_crystallized_icon
		_capybara_crystallized.visible = true
		_capybara_crystallized.show_behind_parent = false
		if RunData.capybara_check_duplicated(item_data):
			_capybara_crystallized.texture = _capybara_crystallized_icon_new
			_capybara_crystallized.show_behind_parent = true
		elif ItemService.capybara_is_character_id(item_data.my_id):
			_capybara_crystallized.texture = _capybara_crystal_background
			_capybara_crystallized.show_behind_parent = true
			
		add_child(_capybara_crystallized)
	if not RunData.capybara_check_crystal(item_data) and _capybara_crystallized:
		_capybara_crystallized.visible = false
	elif _capybara_crystallized and RunData.capybara_check_crystal(item_data):
		_capybara_crystallized.visible = true
	if _capybara_crystallized and _capybara_crystallized.visible and not RunData.capybara_check_duplicated(item_data):
		_capybara_crystallized.texture = _capybara_crystallized_icon
		_capybara_crystallized.show_behind_parent = false
	elif _capybara_crystallized and _capybara_crystallized.visible and RunData.capybara_check_duplicated(item_data):
		_capybara_crystallized.texture = _capybara_crystallized_icon_new
		_capybara_crystallized.show_behind_parent = true
	if _capybara_crystallized and ItemService.capybara_is_character_id(item_data.my_id):
		_capybara_crystallized.texture = _capybara_crystal_background
		_capybara_crystallized.show_behind_parent = false
		


