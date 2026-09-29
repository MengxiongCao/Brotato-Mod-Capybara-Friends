extends "res://ui/menus/shop/item_popup.gd"


func will_show_buttons_when_focused(item_data):
	if item_data is ItemData:
		return buttons_enabled
	return .will_show_buttons_when_focused(item_data)


func _update_button_visibilities() -> void:
	if not (_item_data is ItemData):
		._update_button_visibilities()
		return

	_combine_button.hide()
	_combine_button.focus_mode = FOCUS_NONE
	_discard_button.hide()
	_discard_button.focus_mode = FOCUS_NONE

	if buttons_enabled and _focused:
		_cancel_button.show()
		_cancel_button.focus_mode = FOCUS_ALL
	else:
		_cancel_button.hide()
		_cancel_button.focus_mode = FOCUS_NONE


