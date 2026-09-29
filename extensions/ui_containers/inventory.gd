extends "res://ui/menus/shop/inventory.gd"


func set_elements(elements: Array, reverse_order: bool = false, replace: bool = true, prioritize_gameplay_elements: bool = false, animated_entrance: bool = false) -> void:
	var capybara_elements = elements.duplicate()
	for i in capybara_elements.size():
		if capybara_elements[i] is CharacterData and RunData.capybara_check_crystal(capybara_elements[i]):
			capybara_elements[i] = _capybara_make_character_display_item(capybara_elements[i])

	.set_elements(capybara_elements,reverse_order,replace,prioritize_gameplay_elements,animated_entrance)

func _capybara_make_character_display_item(character: CharacterData) -> ItemData:
	var item_template = ItemService.get_item_from_id(
		Keys.generate_hash("item_capybara_item_character")
	)

	if item_template == null:
		return character

	var display_item: ItemData = item_template.duplicate()
	display_item.my_id = character.my_id

	# 保留角色自己的ID。
	# 不同角色不会互相堆叠，同一个角色可以堆叠。
	display_item.my_id = character.my_id
	display_item.my_id_hash = character.my_id_hash

	display_item.unlocked_by_default = character.unlocked_by_default
	display_item.can_be_looted = character.can_be_looted
	display_item.icon = character.icon
	display_item.name = character.name
	display_item.tier = character.tier
	display_item.value = character.value
	display_item.tracking_text = character.tracking_text
	display_item.is_lockable = character.is_lockable
	display_item.unlock_codex_descr_after_get_it = character.unlock_codex_descr_after_get_it
	display_item.is_locked = character.is_locked
	display_item.is_cursed = character.is_cursed
	display_item.curse_factor = character.curse_factor

	display_item.max_nb = character.max_nb
	display_item.tags = character.tags.duplicate()
	display_item.replaced_by = character.replaced_by
	
	display_item.effects = []
	for effect in character.effects:
		if effect != null and is_instance_valid(effect):
			display_item.effects.append(effect)

	display_item.item_appearances = []
	for appearance in character.item_appearances:
		var copied_appearance = appearance.duplicate()
		copied_appearance.is_character_appearance = false
		display_item.item_appearances.append(copied_appearance)

	# 用来区分普通晶化物品与角色转换物品。
	display_item.set_meta("capybara_character_display_item", true)

	display_item.set_meta("capybara_character_display_item", true)
	return display_item

func get_elements_with_count(elements: Array) -> Array:
	var parent_element_list = .get_elements_with_count(elements)
	var isolated_crystals = {}

	# Preserve crystal entries that another extension has already separated.
	for element_with_count in parent_element_list:
		var grouped_element = element_with_count[0]
		var grouped_count = element_with_count[1]
		if grouped_count == 1 and _capybara_needs_independent_icon(grouped_element):
			if not isolated_crystals.has(grouped_element.my_id_hash):
				isolated_crystals[grouped_element.my_id_hash] = []
			isolated_crystals[grouped_element.my_id_hash].append(grouped_element)

	var crystals_to_extract = {}

	for element in elements:
		if not _capybara_needs_independent_icon(element):
			continue

		if isolated_crystals.has(element.my_id_hash):
			var isolated_index = isolated_crystals[element.my_id_hash].find(element)
			if isolated_index >= 0:
				isolated_crystals[element.my_id_hash].remove(isolated_index)
				continue

		if not crystals_to_extract.has(element.my_id_hash):
			crystals_to_extract[element.my_id_hash] = []
		crystals_to_extract[element.my_id_hash].append(element)

	var element_list = []
	for element_with_count in parent_element_list:
		var grouped_element = element_with_count[0]
		var grouped_count = element_with_count[1]
		var element_hash = grouped_element.my_id_hash

		if grouped_count <= 1 or not crystals_to_extract.has(element_hash) or crystals_to_extract[element_hash].empty():
			element_list.append(element_with_count)
			continue

		# Leave at least one element in the group; it may itself represent the
		# final crystal when every element in the group is crystallized.
		var extract_count = min(grouped_count - 1, crystals_to_extract[element_hash].size())
		var adjusted_group = element_with_count.duplicate()
		adjusted_group[1] = grouped_count - extract_count

		if RunData.capybara_check_crystal(grouped_element):
			var replacement = _capybara_find_stackable_element(elements, element_hash)
			if replacement != null:
				adjusted_group[0] = replacement

		element_list.append(adjusted_group)
		for _i in extract_count:
			element_list.append([crystals_to_extract[element_hash].pop_front(), 1])

	return element_list


func add_element(element, check_for_duplicates = false, sort_inventory = true, _display_banned: float = 0, animated_entrance = false):
	var parent_check_for_duplicates = _capybara_should_check_for_duplicates(element, check_for_duplicates)
	.add_element(element, parent_check_for_duplicates, sort_inventory, _display_banned, animated_entrance)


func _capybara_should_check_for_duplicates(element: ItemParentData, check_for_duplicates: bool) -> bool:
	if not check_for_duplicates or _capybara_needs_independent_icon(element):
		return false

	var has_same_element = false
	for child in get_children():
		if child.item == null or child.item.my_id != element.my_id:
			continue

		has_same_element = true
		if _capybara_can_stack(child.item):
			return true

	# When every existing element with this ID is independent, the new one must
	# also be spawned independently instead of being stacked onto a crystal.
	return not has_same_element


func _capybara_needs_independent_icon(element: ItemParentData) -> bool:
	# Cursed elements are already separated by the original implementation.
	return not element.is_cursed and RunData.capybara_check_crystal(element)


func _capybara_can_stack(element: ItemParentData) -> bool:
	return not element.is_cursed and not RunData.capybara_check_crystal(element)


func _capybara_find_stackable_element(elements: Array, element_hash: int):
	for element in elements:
		if element.my_id_hash == element_hash and _capybara_can_stack(element):
			return element
	return null
