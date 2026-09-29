extends "res://ui/menus/shop/stats_container.gd"


# 主要属性每页显示多少个。
var capybara_primary_stats_per_page: int = 18

# 非主要属性每页显示多少个。
var capybara_secondary_stats_per_page: int = 23

# 切换主要属性和非主要属性时，是否回到第一页。
export(bool) var capybara_reset_page_when_switching_tab = true

# 在最后一页按下一页时，是否回到第一页。
export(bool) var capybara_loop_pages = true

# 属性条目之间的纵向间距。
# 0表示没有额外间距，-1到-3会更加紧密。
export(int, -8, 16) var capybara_stats_separation = -6

# 清除属性条目额外的最小高度，并取消纵向扩展。
export(bool) var capybara_compact_stat_rows = true


var capybara_primary_page: int = 0
var capybara_secondary_page: int = 0

var capybara_page_bar: HBoxContainer = null
var capybara_previous_page_button: Button = null
var capybara_next_page_button: Button = null
var capybara_page_label: Label = null

# 记录本脚本实际新创建的属性，已经由父类创建的DLC属性不会进入这里。
var capybara_created_stats: Array = []

# 需要放入主要属性栏的自定义属性。
var capybara_primary_stat_names: Array = [
#	"stat_capybara_crystal",
	"stat_capybara_enemies_killed",
	"stat_capybara_wave_time",
]


func _ready() -> void:
	# 当前项目中父类_ready会先执行，这里不要再手动调用._ready()。
	capybara_add_or_move_custom_primary_stats()
	if capybara_is_yoko_more_stats_active():
		capybara_refresh_stats_arrays()
		call_deferred("capybara_finish_setup")
		return
	capybara_apply_compact_layout()
	capybara_refresh_stats_arrays()
	capybara_create_page_bar()
	call_deferred("capybara_finish_setup")


func capybara_finish_setup() -> void:
	for capybara_stat in capybara_created_stats:
		if not is_instance_valid(capybara_stat):
			continue
		capybara_stat.init_label_focus()

	# 父类或DLC可能在延迟阶段继续调整节点顺序，因此再次移动、整理并分页。
	capybara_add_or_move_custom_primary_stats()
	if capybara_is_yoko_more_stats_active():
		capybara_refresh_stats_arrays()
		capybara_refresh_yoko_more_stats()
		return
	capybara_apply_compact_layout()
	capybara_refresh_stats_arrays()
	capybara_apply_pages()


# ============================================================
# Yoko-MoreStatsContainer兼容
# ============================================================

func capybara_is_yoko_more_stats_active() -> bool:
	return has_method("_moresc_chunk_stats") or has_method("msc_apply_current_page_visibility")


func capybara_refresh_yoko_more_stats() -> void:
	if has_method("_moresc_chunk_stats"):
		call("_moresc_chunk_stats")

	var capybara_vbox = _primary_stats.get_parent() if is_instance_valid(_primary_stats) else null
	if not is_instance_valid(capybara_vbox) or not capybara_vbox.has_node("StatsCarousel"):
		return
	if has_method("_moresc_refresh_carousel_for_tab"):
		call("_moresc_refresh_carousel_for_tab")
	elif has_method("msc_apply_current_page_visibility"):
		call("msc_apply_current_page_visibility")


# ============================================================
# 自定义属性创建
# ============================================================

func capybara_add_or_move_custom_primary_stats() -> void:
	if not is_instance_valid(_primary_stats):
		return
	if _primary_stats.get_child_count() <= 0:
		return

	var capybara_template = _primary_stats.get_child(0)
	if not is_instance_valid(capybara_template):
		return

	# 按数组正序处理并依次移动到容器末尾，最终顺序与capybara_primary_stat_names一致。
	for capybara_stat_name in capybara_primary_stat_names:
		var capybara_stat_data = capybara_find_stat_data(capybara_stat_name)

		if capybara_stat_data == null:
			print("没有在ItemService.stats中找到属性：", capybara_stat_name)
			continue
		if not capybara_stat_data.is_primary_stat:
			print("属性不是主要属性：", capybara_stat_name)
			continue

		var capybara_key: String = capybara_stat_data.stat_name.to_upper()
		var capybara_stat_node = capybara_find_primary_stat_node(capybara_key)

		if not is_instance_valid(capybara_stat_node):
			capybara_stat_node = capybara_template.duplicate()
			if not is_instance_valid(capybara_stat_node):
				continue

			capybara_stat_node.key = capybara_key
			capybara_stat_node.color_override = capybara_stat_data.color_override
			capybara_stat_node.name = "Capybara_" + capybara_stat_name
			_primary_stats.add_child(capybara_stat_node)

			if not capybara_created_stats.has(capybara_stat_node):
				capybara_created_stats.append(capybara_stat_node)

		_primary_stats.move_child(capybara_stat_node, _primary_stats.get_child_count() - 1)


func capybara_find_stat_data(capybara_stat_name: String):
	for capybara_stat_data in ItemService.stats:
		if capybara_stat_data.stat_name == capybara_stat_name:
			return capybara_stat_data
	return null


func capybara_find_primary_stat_node(capybara_key: String):
	if not is_instance_valid(_primary_stats):
		return null

	for capybara_stat in _primary_stats.get_children():
		if not is_instance_valid(capybara_stat):
			continue
		if not "key" in capybara_stat:
			continue
		if str(capybara_stat.key).to_upper() == capybara_key.to_upper():
			return capybara_stat

	return null


# ============================================================
# 紧密排列属性
# ============================================================

func capybara_apply_compact_layout() -> void:
	capybara_compact_stats_container(_general_stats)
	capybara_compact_stats_container(_primary_stats)
	capybara_compact_stats_container(_secondary_stats)


func capybara_compact_stats_container(capybara_container) -> void:
	if not is_instance_valid(capybara_container):
		return

	capybara_container.add_constant_override("separation", capybara_stats_separation)
	capybara_container.add_constant_override("vseparation", capybara_stats_separation)

	if not capybara_compact_stat_rows:
		return

	for capybara_stat in capybara_container.get_children():
		if not is_instance_valid(capybara_stat):
			continue
		if not (capybara_stat is Control):
			continue

		var capybara_min_size: Vector2 = capybara_stat.rect_min_size
		capybara_min_size.y = 0
		capybara_stat.rect_min_size = capybara_min_size
		capybara_stat.size_flags_vertical = Control.SIZE_FILL


# ============================================================
# 重新收集属性数组
# ============================================================

func capybara_refresh_stats_arrays() -> void:
	if is_instance_valid(_general_stats):
		general_stats = _general_stats.get_children()
	if is_instance_valid(_primary_stats):
		primary_stats = _primary_stats.get_children()
	if is_instance_valid(_secondary_stats):
		secondary_stats = _secondary_stats.get_children()

	if not primary_stats.empty():
		first_primary_stat = primary_stats[0]
		last_primary_stat = primary_stats[primary_stats.size() - 1]

	for capybara_stat in primary_stats:
		if not is_instance_valid(capybara_stat):
			continue
		capybara_connect_stat_signals(capybara_stat)
		capybara_stat.enable_focus()


func capybara_connect_stat_signals(capybara_stat) -> void:
	if not capybara_stat.is_connected("focused", self, "on_stat_focused"):
		capybara_stat.connect("focused", self, "on_stat_focused")
	if not capybara_stat.is_connected("unfocused", self, "on_stat_unfocused"):
		capybara_stat.connect("unfocused", self, "on_stat_unfocused")
	if not capybara_stat.is_connected("hovered", self, "on_stat_hovered"):
		capybara_stat.connect("hovered", self, "on_stat_hovered")
	if not capybara_stat.is_connected("unhovered", self, "on_stat_unhovered"):
		capybara_stat.connect("unhovered", self, "on_stat_unhovered")


# ============================================================
# 创建翻页栏
# ============================================================

func capybara_create_page_bar() -> void:
	if not is_instance_valid(_general_stats):
		return
	if not is_instance_valid(_primary_stats):
		return
	if not is_instance_valid(_secondary_stats):
		return

	var capybara_parent = _general_stats.get_parent()
	if not is_instance_valid(capybara_parent):
		return

	if capybara_parent.has_node("CapybaraStatsPageBar"):
		capybara_page_bar = capybara_parent.get_node("CapybaraStatsPageBar")
		capybara_previous_page_button = capybara_page_bar.get_node("PreviousPage")
		capybara_page_label = capybara_page_bar.get_node("PageLabel")
		capybara_next_page_button = capybara_page_bar.get_node("NextPage")
		capybara_connect_page_buttons()
		return

	capybara_page_bar = HBoxContainer.new()
	capybara_page_bar.name = "CapybaraStatsPageBar"
	capybara_page_bar.alignment = BoxContainer.ALIGN_CENTER
	capybara_page_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	capybara_page_bar.size_flags_vertical = Control.SIZE_FILL
	capybara_page_bar.rect_min_size.y = 20
	capybara_page_bar.add_constant_override("separation", 3)

	capybara_previous_page_button = Button.new()
	capybara_previous_page_button.name = "PreviousPage"
	capybara_previous_page_button.text = "<"
	capybara_previous_page_button.rect_min_size = Vector2(30, 30)
	capybara_previous_page_button.focus_mode = Control.FOCUS_ALL

	capybara_page_label = Label.new()
	capybara_page_label.name = "PageLabel"
	capybara_page_label.align = Label.ALIGN_CENTER
	capybara_page_label.valign = Label.VALIGN_CENTER
	capybara_page_label.rect_min_size = Vector2(20, 20)

	capybara_next_page_button = Button.new()
	capybara_next_page_button.name = "NextPage"
	capybara_next_page_button.text = ">"
	capybara_next_page_button.rect_min_size = Vector2(30, 30)
	capybara_next_page_button.focus_mode = Control.FOCUS_ALL

	capybara_page_bar.add_child(capybara_previous_page_button)
	capybara_page_bar.add_child(capybara_page_label)
	capybara_page_bar.add_child(capybara_next_page_button)
	capybara_parent.add_child(capybara_page_bar)

	var capybara_insert_index: int = max(_general_stats.get_index(), max(_primary_stats.get_index(), _secondary_stats.get_index())) + 1
	capybara_parent.move_child(capybara_page_bar, capybara_insert_index)
	capybara_connect_page_buttons()


func capybara_connect_page_buttons() -> void:
	if is_instance_valid(capybara_previous_page_button):
		if not capybara_previous_page_button.is_connected("pressed", self, "_on_capybara_previous_page_pressed"):
			capybara_previous_page_button.connect("pressed", self, "_on_capybara_previous_page_pressed")

	if is_instance_valid(capybara_next_page_button):
		if not capybara_next_page_button.is_connected("pressed", self, "_on_capybara_next_page_pressed"):
			capybara_next_page_button.connect("pressed", self, "_on_capybara_next_page_pressed")


# ============================================================
# 每页属性数量
# ============================================================

func capybara_get_stats_per_page(capybara_tab: int) -> int:
	if capybara_tab == Tab.PRIMARY:
		return int(max(1, capybara_primary_stats_per_page))
	return int(max(1, capybara_secondary_stats_per_page))


# ============================================================
# 页数和当前页
# ============================================================

func capybara_get_page_count(capybara_stats: Array, capybara_tab: int) -> int:
	if capybara_stats.empty():
		return 1

	var capybara_per_page: int = capybara_get_stats_per_page(capybara_tab)
	return int(ceil(float(capybara_stats.size()) / float(capybara_per_page)))


func capybara_get_current_stats() -> Array:
	if focused_tab == Tab.PRIMARY:
		return primary_stats
	return secondary_stats


func capybara_get_current_page() -> int:
	if focused_tab == Tab.PRIMARY:
		return capybara_primary_page
	return capybara_secondary_page


func capybara_set_current_page(capybara_page: int) -> void:
	if focused_tab == Tab.PRIMARY:
		capybara_primary_page = capybara_page
	else:
		capybara_secondary_page = capybara_page


# ============================================================
# 分页显示
# ============================================================

func capybara_set_stats_page_visibility(capybara_stats: Array, capybara_page: int, capybara_tab: int) -> void:
	var capybara_per_page: int = capybara_get_stats_per_page(capybara_tab)
	var capybara_start_index: int = capybara_page * capybara_per_page
	var capybara_end_index: int = min(capybara_start_index + capybara_per_page, capybara_stats.size())

	for capybara_index in range(capybara_stats.size()):
		var capybara_stat = capybara_stats[capybara_index]
		if not is_instance_valid(capybara_stat):
			continue
		capybara_stat.visible = capybara_index >= capybara_start_index and capybara_index < capybara_end_index


func capybara_apply_pages() -> void:
	var capybara_primary_page_count: int = capybara_get_page_count(primary_stats, Tab.PRIMARY)
	var capybara_secondary_page_count: int = capybara_get_page_count(secondary_stats, Tab.SECONDARY)

	capybara_primary_page = int(clamp(capybara_primary_page, 0, capybara_primary_page_count - 1))
	capybara_secondary_page = int(clamp(capybara_secondary_page, 0, capybara_secondary_page_count - 1))

	capybara_set_stats_page_visibility(primary_stats, capybara_primary_page, Tab.PRIMARY)
	capybara_set_stats_page_visibility(secondary_stats, capybara_secondary_page, Tab.SECONDARY)
	capybara_update_primary_focus_range()
	capybara_update_page_bar()

	if not primary_stats.empty():
		set_focus_neighbours()

	capybara_update_page_focus_neighbours()
	capybara_refresh_stat_focus_neighbours()


func capybara_refresh_stat_focus_neighbours() -> void:
	var capybara_visible_stats: Array = capybara_get_visible_focusable_stats()
	if capybara_visible_stats.empty():
		return

	for i in range(capybara_visible_stats.size()):
		var capybara_current_stat = capybara_visible_stats[i]
		if i > 0:
			capybara_current_stat.focus_neighbour_left = capybara_current_stat.get_path_to(capybara_visible_stats[i - 1])
			capybara_current_stat.focus_neighbour_top = capybara_current_stat.get_path_to(capybara_visible_stats[i - 1])
		if i < capybara_visible_stats.size() - 1:
			capybara_current_stat.focus_neighbour_right = capybara_current_stat.get_path_to(capybara_visible_stats[i + 1])
			capybara_current_stat.focus_neighbour_bottom = capybara_current_stat.get_path_to(capybara_visible_stats[i + 1])


func capybara_update_primary_focus_range() -> void:
	if primary_stats.empty():
		return

	var capybara_per_page: int = capybara_get_stats_per_page(Tab.PRIMARY)
	var capybara_start_index: int = capybara_primary_page * capybara_per_page
	var capybara_end_index: int = min(capybara_start_index + capybara_per_page, primary_stats.size())

	if capybara_start_index >= capybara_end_index:
		return

	first_primary_stat = primary_stats[capybara_start_index]
	last_primary_stat = primary_stats[capybara_end_index - 1]


# ============================================================
# 页码显示
# ============================================================

func capybara_update_page_bar() -> void:
	if not is_instance_valid(capybara_page_bar):
		return

	var capybara_current_stats: Array = capybara_get_current_stats()
	var capybara_current_page: int = capybara_get_current_page()
	var capybara_page_count: int = capybara_get_page_count(capybara_current_stats, focused_tab)

	capybara_page_bar.visible = capybara_page_count > 1
	capybara_page_label.text = "%d / %d" % [capybara_current_page + 1, capybara_page_count]

	if capybara_loop_pages:
		capybara_previous_page_button.disabled = capybara_page_count <= 1
		capybara_next_page_button.disabled = capybara_page_count <= 1
	else:
		capybara_previous_page_button.disabled = capybara_current_page <= 0
		capybara_next_page_button.disabled = capybara_current_page >= capybara_page_count - 1


# ============================================================
# 翻页
# ============================================================

func capybara_change_page(capybara_direction: int) -> void:
	var capybara_current_stats: Array = capybara_get_current_stats()
	var capybara_page_count: int = capybara_get_page_count(capybara_current_stats, focused_tab)
	if capybara_page_count <= 1:
		return

	var capybara_new_page: int = capybara_get_current_page() + capybara_direction

	if capybara_loop_pages:
		if capybara_new_page < 0:
			capybara_new_page = capybara_page_count - 1
		elif capybara_new_page >= capybara_page_count:
			capybara_new_page = 0
	else:
		capybara_new_page = int(clamp(capybara_new_page, 0, capybara_page_count - 1))

	if capybara_new_page == capybara_get_current_page():
		return

	capybara_set_current_page(capybara_new_page)
	capybara_apply_pages()
	call_deferred("capybara_focus_first_visible_stat")


func _on_capybara_previous_page_pressed() -> void:
	capybara_change_page(-1)


func _on_capybara_next_page_pressed() -> void:
	capybara_change_page(1)


# ============================================================
# 焦点处理
# ============================================================

func capybara_get_visible_focusable_stats() -> Array:
	var capybara_result: Array = []

	for capybara_stat in capybara_get_current_stats():
		if not is_instance_valid(capybara_stat):
			continue
		if not capybara_stat.visible:
			continue
		if capybara_stat.focus_mode == Control.FOCUS_NONE:
			continue
		capybara_result.append(capybara_stat)

	return capybara_result


func capybara_focus_first_visible_stat() -> void:
	var capybara_visible_stats: Array = capybara_get_visible_focusable_stats()
	if capybara_visible_stats.empty():
		return
	capybara_visible_stats[0].grab_focus()


func capybara_update_page_focus_neighbours() -> void:
	if not is_instance_valid(capybara_page_bar):
		return
	if not capybara_page_bar.visible:
		return
	if not is_instance_valid(capybara_previous_page_button):
		return
	if not is_instance_valid(capybara_next_page_button):
		return

	capybara_previous_page_button.focus_neighbour_right = capybara_previous_page_button.get_path_to(capybara_next_page_button)
	capybara_next_page_button.focus_neighbour_left = capybara_next_page_button.get_path_to(capybara_previous_page_button)

	var capybara_visible_stats: Array = capybara_get_visible_focusable_stats()
	if capybara_visible_stats.empty():
		return

	var capybara_first_stat = capybara_visible_stats[0]
	var capybara_last_stat = capybara_visible_stats[capybara_visible_stats.size() - 1]

	# 当前页最后一个属性向下进入上一页按钮。
	capybara_last_stat.focus_neighbour_bottom = capybara_last_stat.get_path_to(capybara_previous_page_button)

	# 两个翻页按钮向上直接聚焦“次要属性”切换按钮。
	if is_instance_valid(_secondary_tab):
		capybara_previous_page_button.focus_neighbour_top = capybara_previous_page_button.get_path_to(_secondary_tab)
		capybara_next_page_button.focus_neighbour_top = capybara_next_page_button.get_path_to(_secondary_tab)

	if focus_neighbour_bottom != NodePath("") and has_node(focus_neighbour_bottom):
		var capybara_bottom_target = get_node(focus_neighbour_bottom)
		capybara_previous_page_button.focus_neighbour_bottom = capybara_previous_page_button.get_path_to(capybara_bottom_target)
		capybara_next_page_button.focus_neighbour_bottom = capybara_next_page_button.get_path_to(capybara_bottom_target)
	elif loop_focus_bottom:
		capybara_previous_page_button.focus_neighbour_bottom = capybara_previous_page_button.get_path_to(capybara_first_stat)
		capybara_next_page_button.focus_neighbour_bottom = capybara_next_page_button.get_path_to(capybara_first_stat)


# ============================================================
# 覆盖父类页签切换
# ============================================================

func update_tab(capybara_tab: int) -> void:
	var capybara_previous_tab: int = focused_tab
	.update_tab(capybara_tab)

	if capybara_reset_page_when_switching_tab and capybara_previous_tab != capybara_tab:
		if capybara_tab == Tab.PRIMARY:
			capybara_primary_page = 0
		else:
			capybara_secondary_page = 0

	if not is_instance_valid(capybara_page_bar):
		return

	capybara_apply_pages()
	call_deferred("capybara_focus_first_visible_stat")
