extends "res://ui/menus/run/run_options_panel.gd"


var capybara_crystal_null_button = load("res://mods-unpacked/Dbear-Capybara/extensions/ui_containers/run_options/capybara_crystal_null.tscn")

var capybara_options_container: VBoxContainer = null
var capybara_options_scroll: ScrollContainer = null

var capybara_max_visible_options: int = 5
var capybara_scroll_created: bool = false
var capybara_refresh_pending: bool = false


func _ready() -> void:
	capybara_options_container = _coop_button.get_parent()

	_capybara_set_options_spacing(-1)
	_capybara_create_new_options()

	if is_instance_valid(capybara_options_container):
		if not capybara_options_container.is_connected("child_entered_tree", self, "_capybara_on_option_child_changed"):
			capybara_options_container.connect("child_entered_tree", self, "_capybara_on_option_child_changed")

		if not capybara_options_container.is_connected("child_exiting_tree", self, "_capybara_on_option_child_changed"):
			capybara_options_container.connect("child_exiting_tree", self, "_capybara_on_option_child_changed")

	call_deferred("_capybara_refresh_options_scroll")


func _capybara_set_options_spacing(spacing: int) -> void:
	if not is_instance_valid(capybara_options_container):
		return

	capybara_options_container.add_constant_override("separation", spacing)


func _capybara_create_new_options() -> void:
	if not is_instance_valid(capybara_options_container):
		return

	var new_instance = capybara_crystal_null_button.instance()
	capybara_options_container.add_child(new_instance)


func _capybara_on_option_child_changed(_child: Node) -> void:
	_capybara_request_scroll_refresh()


func _capybara_request_scroll_refresh() -> void:
	if capybara_refresh_pending:
		return

	capybara_refresh_pending = true
	call_deferred("_capybara_refresh_options_scroll")


func _capybara_refresh_options_scroll() -> void:
	capybara_refresh_pending = false

	if not is_instance_valid(capybara_options_container):
		return

	var visible_controls: Array = _capybara_get_visible_option_controls()

	if visible_controls.size() <= capybara_max_visible_options:
		if capybara_scroll_created:
			_capybara_update_content_height()
		return

	_capybara_create_scroll_container()
	_capybara_update_content_height()


func _capybara_get_visible_option_controls() -> Array:
	var result: Array = []

	if not is_instance_valid(capybara_options_container):
		return result

	for child in capybara_options_container.get_children():
		if child is Control and child.visible:
			result.append(child)

	return result


func _capybara_create_scroll_container() -> void:
	if capybara_scroll_created:
		return

	if not is_instance_valid(capybara_options_container):
		return

	var old_parent = capybara_options_container.get_parent()

	if not is_instance_valid(old_parent):
		return

	var old_index: int = capybara_options_container.get_index()

	capybara_options_scroll = ScrollContainer.new()
	capybara_options_scroll.name = "CapybaraOptionsScroll"
	capybara_options_scroll.size_flags_horizontal = capybara_options_container.size_flags_horizontal
	capybara_options_scroll.size_flags_vertical = Control.SIZE_FILL

	old_parent.remove_child(capybara_options_container)
	old_parent.add_child(capybara_options_scroll)
	old_parent.move_child(capybara_options_scroll, old_index)

	capybara_options_scroll.add_child(capybara_options_container)

	capybara_options_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	capybara_options_container.size_flags_vertical = Control.SIZE_FILL

	capybara_scroll_created = true
	_capybara_refresh_character_inventory_focus()


func _capybara_refresh_character_inventory_focus() -> void:
	if not is_instance_valid(_coop_button):
		return

	var current_scene = get_tree().current_scene
	if not is_instance_valid(current_scene):
		return

	var inventory = current_scene.get_node_or_null(
		"MarginContainer/VBoxContainer/Inventories/MarginContainer/Inventory1"
	)
	if not is_instance_valid(inventory):
		return

	# CoopButton 被移入滚动容器后，原版场景中写死的旧路径会失效。
	# 根据节点的实际位置重新生成相对路径，兼容额外选项改变界面层级。
	inventory.focus_neighbour_top = inventory.get_path_to(_coop_button)

	if inventory.has_method("queue_set_focus_neighbours"):
		inventory.queue_set_focus_neighbours()


func _capybara_update_content_height() -> void:
	if not capybara_scroll_created:
		return

	if not is_instance_valid(capybara_options_scroll):
		return

	if not is_instance_valid(capybara_options_container):
		return

	var visible_controls: Array = _capybara_get_visible_option_controls()

	if visible_controls.empty():
		return

	var separation: int = capybara_options_container.get_constant("separation")
	var full_height: float = 0.0
	var visible_height: float = 0.0

	for i in range(visible_controls.size()):
		var child: Control = visible_controls[i]
		var child_height: float = max(child.rect_size.y, child.rect_min_size.y)

		full_height += child_height

		if i < capybara_max_visible_options:
			visible_height += child_height

	if visible_controls.size() > 1:
		full_height += separation * (visible_controls.size() - 1)

	var visible_count: int = min(capybara_max_visible_options, visible_controls.size())

	if visible_count > 1:
		visible_height += separation * (visible_count - 1)

	capybara_options_container.rect_min_size.y = full_height
	capybara_options_scroll.rect_min_size.y = visible_height
