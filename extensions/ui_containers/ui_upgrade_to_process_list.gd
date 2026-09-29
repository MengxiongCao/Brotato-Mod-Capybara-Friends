extends "res://ui/hud/ui_upgrade_to_process_list.gd"

func remove_element(level: int) -> void :
	.remove_element(level)
	_capybara_divide_node_by_icon()


func _capybara_update_list(icon) -> void :
	var similar_icons: = _get_all_similar_elements(icon)
	var count = similar_icons.size()
	if count > UIItemList.MAX_SIMILAR_ICONS:
		for element in similar_icons:
			element.hide()
		similar_icons[count - 1].show()
		similar_icons[count - 1].set_count(count)
	elif count > 0:
		for node in similar_icons:
			node.set_count(1)

func _capybara_divide_node_by_icon() -> void:
	var icons = []
	var nodes = get_children()
	for node in nodes:
		if not node.texture in icons:
			icons.append(node.texture)
	for icon in icons:
		_capybara_update_list(icon)
