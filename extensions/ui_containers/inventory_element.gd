extends "res://items/global/inventory_element.gd"

var _capybara_crystallized_icon = load("res://mods-unpacked/Dbear-Capybara/extensions/ui_containers/cp_crystallized_border_icon.png")
var _capybara_crystallized_icon_new = load("res://mods-unpacked/Dbear-Capybara/extensions/ui_containers/cp_crystallized_border_icon_new.png")
var _capybara_crystal_background = load("res://mods-unpacked/Dbear-Capybara/extensions/ui_containers/cp_crystal_back_ground.png")
var _capybara_crystallized:TextureRect = null
var capybara_frame = load("res://mods-unpacked/Dbear-Capybara/extensions/ui_containers/capybara_frame.tscn")
onready var capybara_margin_container = $MarginContainer

func set_element(item_data: Resource) -> void :
	.set_element(item_data)	
	if (item_data is ItemData or item_data is WeaponData) and RunData.capybara_check_crystal(item_data):
		_capybara_crystallized = _icon.duplicate()
		_capybara_crystallized.texture = _capybara_crystallized_icon
		_capybara_crystallized.visible = true
		if RunData.capybara_check_duplicated(item_data):
			_capybara_crystallized.texture = _capybara_crystallized_icon_new
			capybara_margin_container.add_child(_capybara_crystallized)
		elif ItemService.capybara_is_character_id(item_data.my_id):
			_capybara_crystallized.texture = _capybara_crystal_background
			_capybara_crystallized.show_behind_parent = false
			add_child(_capybara_crystallized)
		else:
			add_child(_capybara_crystallized)
