extends "res://ui/menus/upgrades/upgrade_ui.gd"


const CAPYBARA_ITEM_DESCRIPTION_SCALE: float = 1.0
const CAPYBARA_ITEM_DESCRIPTION_SIZE: Vector2 = Vector2(300.0, 400.0)
const CAPYBARA_ITEM_DESCRIPTION_OFFSET: float = 10.0

var capybara_frame = load("res://mods-unpacked/Dbear-Capybara/extensions/ui_containers/capybara_frame.tscn")
var capybara_item_description_scene = load("res://ui/menus/shop/item_description.tscn")

var capybara_is_item_add_upgrade: bool = false
var capybara_effect_description = null
var capybara_item_add_description_data = null
var capybara_upgrade_player_index: int = 0
var capybara_item_add_description_panel = null
var capybara_item_add_description = null
var capybara_description_move = 0.3


func _ready() -> void:
	_capybara_setup_focus()


func set_upgrade(p_upgrade_data: UpgradeData, player_index: int) -> void:
	.set_upgrade(p_upgrade_data, player_index)

	capybara_upgrade_player_index = player_index
	_capybara_hide_item_add_description()
	capybara_is_item_add_upgrade = capybara_check_is_item_add(p_upgrade_data, player_index)
	capybara_item_add_description_data = _capybara_get_item_add_description_data(p_upgrade_data)

	var frame_node = get_node_or_null("capybara_crystal_upgrade")

	if capybara_is_item_add_upgrade:
		if not is_instance_valid(frame_node):
			frame_node = capybara_frame.instance()
			frame_node.name = "capybara_crystal_upgrade"
			add_child(frame_node)
		else:
			frame_node.visible = true
	else:
		if is_instance_valid(frame_node):
			frame_node.visible = false

	if not is_instance_valid(capybara_effect_description):
		capybara_effect_description = _capybara_get_effect_description()

	call_deferred("_capybara_update_special_display")


func capybara_check_is_item_add(upgrade_data: UpgradeData, player_index: int, add_item = false) -> bool:
	for effect in upgrade_data.effects:
		if effect == null or not is_instance_valid(effect):
			continue
		if effect.custom_key_hash == Keys.generate_hash("capybara_add_item"):
			if add_item:
				if ItemService.is_item_id(effect.key_hash):
					var item_to_add = ItemService.get_item_from_id(effect.key_hash)
					RunData.add_item(item_to_add, player_index)
			return true

	return false


func _capybara_get_item_add_description_data(upgrade_data: UpgradeData):
	for effect in upgrade_data.effects:
		if effect == null or not is_instance_valid(effect):
			continue
		if effect.custom_key_hash != Keys.generate_hash("capybara_add_item"):
			continue

		if ItemService.is_item_id(effect.key_hash):
			return ItemService.get_item_from_id(effect.key_hash)

		if ItemService.capybara_is_character_id(effect.key):
			return ItemService.capybara_get_character_from_id(effect.key)

	return null


func _capybara_get_effect_description():
	if not is_instance_valid(_upgrade_description):
		return null

	# 这里只查找当前 UpgradeUI 内部的效果描述。
	# 最好最终换成你的真实节点路径。
	var node = _upgrade_description.find_node("Effects", true, false)

	if is_instance_valid(node):
		return node

	node = _upgrade_description.find_node("EffectsContainer", true, false)

	if is_instance_valid(node):
		return node

	node = _upgrade_description.find_node("EffectDescription", true, false)

	if is_instance_valid(node):
		return node

	return null


func _capybara_setup_focus() -> void:
	if not is_instance_valid(button):
		return

	if not button.is_connected("focus_entered", self, "_capybara_on_focus_entered"):
		button.connect("focus_entered", self, "_capybara_on_focus_entered")

	if not button.is_connected("focus_exited", self, "_capybara_on_focus_exited"):
		button.connect("focus_exited", self, "_capybara_on_focus_exited")


func _capybara_on_focus_entered() -> void:
	if not capybara_is_item_add_upgrade:
		return

	_capybara_show_item_add_description()
	_capybara_set_effect_visible(true)


func _capybara_on_focus_exited() -> void:
	if not capybara_is_item_add_upgrade:
		return

	_capybara_hide_item_add_description()
	_capybara_set_effect_visible(not RunData.is_coop_run)


func _capybara_update_special_display() -> void:
	if not is_instance_valid(capybara_effect_description):
		capybara_effect_description = _capybara_get_effect_description()

	# 普通升级保持原版
	if not capybara_is_item_add_upgrade:
		_capybara_hide_item_add_description()
		_capybara_set_effect_visible(true)
		return

	if button.has_focus() and is_instance_valid(capybara_item_add_description_data):
		_capybara_show_item_add_description()
	else:
		_capybara_hide_item_add_description()

	_capybara_set_effect_visible(not RunData.is_coop_run or button.has_focus())


func _capybara_show_item_add_description() -> void:
	if not is_instance_valid(capybara_item_add_description_data):
		return

	_capybara_ensure_item_add_description()
	if not is_instance_valid(capybara_item_add_description_panel):
		return
	if not is_instance_valid(capybara_item_add_description):
		return

	if capybara_item_add_description.item != capybara_item_add_description_data:
		capybara_item_add_description.set_item(
			capybara_item_add_description_data,
			capybara_upgrade_player_index
		)

	var panel_style = get_stylebox("panel")
	if panel_style != null:
		panel_style = panel_style.duplicate()
		ItemService.change_panel_stylebox_from_tier(
			panel_style,
			capybara_item_add_description_data.tier
		)
		capybara_item_add_description_panel.add_stylebox_override("panel", panel_style)

	capybara_item_add_description_panel.visible = true
	_capybara_position_item_add_description()
	call_deferred("_capybara_position_item_add_description")


func _capybara_ensure_item_add_description() -> void:
	if is_instance_valid(capybara_item_add_description_panel):
		return
	if capybara_item_description_scene == null:
		return

	capybara_item_add_description_panel = PanelContainer.new()
	capybara_item_add_description_panel.name = "capybara_item_add_description_panel"
	capybara_item_add_description_panel.rect_position = Vector2(0,-300)
	capybara_item_add_description_panel.set_as_toplevel(true)

	capybara_item_add_description = capybara_item_description_scene.instance()
	capybara_item_add_description.name = "capybara_item_add_description"
	capybara_item_add_description.expand_indefinitely = false
	if RunData.is_coop_run:
		capybara_item_add_description.expand_indefinitely = true
	capybara_item_add_description.show_details = true
	capybara_item_add_description_panel.add_child(capybara_item_add_description)

	add_child(capybara_item_add_description_panel)
	capybara_item_add_description_panel.visible = false


func _capybara_position_item_add_description() -> void:
	if not is_instance_valid(capybara_item_add_description_panel):
		return

	var description_scale = _capybara_get_item_description_scale()
	capybara_item_add_description_panel.rect_size = CAPYBARA_ITEM_DESCRIPTION_SIZE
	capybara_item_add_description_panel.rect_pivot_offset = Vector2.ZERO
	capybara_item_add_description_panel.rect_scale = Vector2(
		description_scale,
		description_scale
	)

	var viewport_size = get_viewport_rect().size
	var displayed_size = capybara_item_add_description_panel.rect_size * description_scale
	var upgrade_rect = get_global_rect()

	var panel_position: Vector2
	if RunData.is_coop_run:
		# In co-op, center the description above the focused upgrade icon.
		panel_position = Vector2(
			upgrade_rect.position.x + (upgrade_rect.size.x - displayed_size.x) / 2.0,
			upgrade_rect.position.y - displayed_size.y - CAPYBARA_ITEM_DESCRIPTION_OFFSET
		)
	else:
		# Place the full-size extra panel outside the upgrade frame at its top-right.
		panel_position = Vector2(
			upgrade_rect.position.x + upgrade_rect.size.x + CAPYBARA_ITEM_DESCRIPTION_OFFSET,
			upgrade_rect.position.y
		)

		# Near the right edge, keep the same top alignment and move it to the left.
		if panel_position.x + displayed_size.x > viewport_size.x - CAPYBARA_ITEM_DESCRIPTION_OFFSET:
			panel_position.x = upgrade_rect.position.x - displayed_size.x - CAPYBARA_ITEM_DESCRIPTION_OFFSET

		# Keep the old visual offset in single-player mode.
		panel_position -= Vector2(
			displayed_size.x * (1.0 - capybara_description_move),
			displayed_size.y * capybara_description_move
		)

	panel_position.x = clamp(
		panel_position.x,
		CAPYBARA_ITEM_DESCRIPTION_OFFSET,
		max(CAPYBARA_ITEM_DESCRIPTION_OFFSET, viewport_size.x - displayed_size.x - CAPYBARA_ITEM_DESCRIPTION_OFFSET)
	)
	panel_position.y = clamp(
		panel_position.y,
		CAPYBARA_ITEM_DESCRIPTION_OFFSET,
		max(CAPYBARA_ITEM_DESCRIPTION_OFFSET, viewport_size.y - displayed_size.y - CAPYBARA_ITEM_DESCRIPTION_OFFSET)
	)

	capybara_item_add_description_panel.rect_global_position = panel_position


func _capybara_get_item_description_scale() -> float:
	if not RunData.is_coop_run:
		return CAPYBARA_ITEM_DESCRIPTION_SCALE

	match int(max(2, RunData.get_player_count())):
		2:
			return 0.8
		3:
			return 0.65
		_:
			return 0.5


func _capybara_hide_item_add_description() -> void:
	if is_instance_valid(capybara_item_add_description_panel):
		capybara_item_add_description_panel.visible = false


func _capybara_set_effect_visible(value: bool) -> void:
	if not is_instance_valid(capybara_effect_description):
		return
	if capybara_effect_description.visible == value:
		return
	capybara_effect_description.visible = value
	minimum_size_changed()
