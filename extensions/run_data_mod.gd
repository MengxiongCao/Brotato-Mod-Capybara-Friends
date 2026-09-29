extends "res://singletons/run_data.gd"

var capybara_last_character = [null, null, null, null]
var capybara_null_crystal:bool = false
var capybara_cursed_enemies = 0

var capybara_effects_full = [
	Keys.generate_hash("capybara_thunder"),
	Keys.generate_hash("capybara_fire"),
	Keys.generate_hash("capybara_reload_when_dodge"),
	Keys.generate_hash("capybara_wind"),
	Keys.generate_hash("change_way_of_attack"),
	Keys.generate_hash("capybara_spwan_fairy_when_tree"),
	Keys.generate_hash("capybara_lotus_text"),
	Keys.generate_hash("capybara_three_weapon_stats"),
	Keys.generate_hash("capybara_spawn_turret_for_per_stat"),
	Keys.generate_hash("capybara_trees_can_attack"),
	Keys.generate_hash("capybara_charmed_enemies_attack"),
	Keys.generate_hash("capybara_spawn_pets_for_x_enemies"),
	Keys.generate_hash("capybara_ranged_melee_attack"),
	Keys.generate_hash("capybara_projectiles_on_death"),
	Keys.generate_hash("capybara_projectiles_on_hit"),
	Keys.generate_hash("capybara_projectile_when_consumable"),
	Keys.generate_hash("capybara_projectile_when_x_cursed_killed"),
]

var capybara_vampire_queen_enemies_in_aura = 0
var capybara_tracking_effects: = {
	Keys.generate_hash("character_Daji"): 0,
	Keys.generate_hash("character_angel"): 0,
	Keys.generate_hash("character_capybara"): 0,
	Keys.generate_hash("item_darkfish"):0,
	Keys.generate_hash("item_foxfire"):0,
	Keys.generate_hash("item_philosopher_stone"):0,
	Keys.generate_hash("item_curse_forger"):0,
	Keys.generate_hash("character_curse_scholar"):0,
	Keys.generate_hash("item_turret_fairy"):0,
	Keys.generate_hash("character_golden"):0,
	Keys.generate_hash("item_unicorn_cake"):[0,0],
	Keys.generate_hash("item_strange_bottle"):0,
	Keys.generate_hash("item_curse_scholar_book"):0,
	Keys.generate_hash("item_golden_wings"):0,
	Keys.generate_hash("item_enjoy_the_music"):0,
	Keys.generate_hash("item_wandering_turret"):0,
	Keys.generate_hash("character_cp_monster"):0,
	Keys.generate_hash("character_vampire_queen"):0,
	Keys.generate_hash("item_capybara_little_world"):0,
	Keys.generate_hash("character_cp_master"):0,
	Keys.generate_hash("item_cp_call_for_love"):0,
	Keys.generate_hash("item_capybara_angel"):[0,0],
	Keys.generate_hash("item_cp_daji_gift"):0,
	Keys.generate_hash("character_cp_comet_cowboy"):0,
	Keys.generate_hash("item_capybara_pet_soul"):0,
	Keys.generate_hash("item_capybara_soul_wheat"):[0,0],
	Keys.generate_hash("character_turretato"):0,
	Keys.generate_hash("item_cp_crystal_turret_0"):[0,0],
	Keys.generate_hash("item_cp_crystal_turret_1"):[0,0],
	Keys.generate_hash("item_cp_crystal_turret_2"):[0,0],
	Keys.generate_hash("item_cp_crystal_turret_3"):[0,0],
	Keys.generate_hash("item_capybara_crystal_sword"):0,
	Keys.generate_hash("item_capybara_crystal_hawk"):0,
	Keys.generate_hash("character_cp_relic_hunter"):0,
	Keys.generate_hash("item_master_swords_box"):0,
	Keys.generate_hash("character_cp_long_tongue"):0,
	Keys.generate_hash("character_cp_exorcist_miko"):0,
}

func init_tracked_effects() -> Dictionary:
	capybara_vampire_queen_enemies_in_aura = 0
	for effect in capybara_effects_full:
		effect_keys_full_serialization.erase(effect)
	effect_keys_full_serialization.append_array(capybara_effects_full)
	var capybara_raw_trakcking_effects = .init_tracked_effects()
	capybara_raw_trakcking_effects.merge(capybara_tracking_effects)
	return capybara_raw_trakcking_effects

func capybara_get_player_nb_cursed_items(player_index: int) -> int:
	var items = get_player_items(player_index)
	var result = 0
	for item in items:
		if item.is_cursed:
			result += 1
	return result

func capybara_get_nb_of_item(item_id_hash:int, player_index: int) -> int:
	var items = get_player_items(player_index)
	var result = 0
	for item in items:
		if item.my_id_hash == item_id_hash:
			result += 1
	return result

func capybara_get_crystallized_items(player_index:int) -> Array:
	var crystallized_items = []
	for item in get_player_items(player_index):
		if capybara_check_crystal(item):
			crystallized_items.append(item)
	return crystallized_items

func capybara_get_items_to_duplicate(player_index: int) -> Array:
	var items_to_duplicate = []
	for item in capybara_get_crystallized_items(player_index):
		if capybara_check_should_duplicate(item):
			items_to_duplicate.append(item)
	return items_to_duplicate

func capybara_get_duplicate_count(item:ItemData) -> int:
	var count = 0
	for effect in item.effects:
		if effect == null or not is_instance_valid(effect):
			continue
		if effect.custom_key_hash == Keys.generate_hash("capybara_lose_effects"):
			count = effect.value
	return count

func _capybara_curse_item(item_data:ItemParentData, player_index) -> ItemParentData:
	var item:ItemParentData = null
	for dlc_id in enabled_dlcs:
		var dlc_data = ProgressData.get_dlc_data(dlc_id)
		if dlc_data and dlc_data.has_method("curse_item") and item_data:
			item = dlc_data.curse_item(item_data, player_index, false, item_data.curse_factor)
	return item

func capybara_manage_crystallized_items_duplicate(player_index:int) -> void:
	if not capybara_get_items_to_duplicate(player_index).size() > 0:
		return
	for item in capybara_get_items_to_duplicate(player_index):
		var count = capybara_get_duplicate_count(item)
		var item_to_add = ItemService.get_item_from_id(item.my_id_hash)
		if item.is_cursed:
			item_to_add = _capybara_curse_item(item_to_add, player_index)
		var duplicate_item = capybara_create_duplicate_item(item_to_add, player_index)
		for i in count:
			add_item(duplicate_item, player_index)
		capybara_remove_item(item, player_index)

func capybara_check_crystal(item_data:ItemParentData) -> bool:
	if item_data == null or not is_instance_valid(item_data):
		return false
	for effect in item_data.effects:
		if effect == null or not is_instance_valid(effect):
			continue
		if effect.custom_key_hash == Keys.generate_hash("capybara_is_crystallized"):
			return true
	return false

func capybara_check_should_duplicate(item_data:ItemParentData) -> bool:
	if item_data == null or not is_instance_valid(item_data):
		return false
	for effect in item_data.effects:
		if effect == null or not is_instance_valid(effect):
			continue
		if effect.custom_key_hash == Keys.generate_hash("capybara_lose_effects") and RunData.current_wave - effect.value2 == 0:
			return true
	return false

func capybara_get_scaling_bonus(value: int, stat_scaled: String, nb_stat_scaled: int, perm_stats_only: bool, player_index: int) -> int:
	var stat_scaled_hash: int = Keys.generate_hash(stat_scaled)
	var actual_nb_scaled: = 0.0
	if stat_scaled_hash == Keys.materials_hash:
		actual_nb_scaled = get_player_gold(player_index)
	elif stat_scaled_hash == Keys.structure_hash:
		actual_nb_scaled = get_nb_structures(player_index)
	elif stat_scaled_hash == Keys.pet_hash:
		actual_nb_scaled = get_nb_pets(player_index)
	elif stat_scaled == "living_enemy":
		actual_nb_scaled = current_living_enemies
	elif stat_scaled_hash == Keys.burning_enemy_hash:
		actual_nb_scaled = current_burning_enemies
	elif stat_scaled_hash == Keys.different_item_hash:
		actual_nb_scaled = get_nb_different_items_of_tier( - 1, player_index)
	elif stat_scaled_hash == Keys.common_item_hash:
		actual_nb_scaled = get_nb_different_items_of_tier(Tier.COMMON, player_index)
	elif stat_scaled_hash == Keys.legendary_item_hash:
		actual_nb_scaled = get_nb_different_items_of_tier(Tier.LEGENDARY, player_index)
	elif stat_scaled_hash == Keys.duplicate_item_hash:
		actual_nb_scaled = get_duplicate_items_count(player_index)
	elif stat_scaled.begins_with("item_"):
		actual_nb_scaled = get_nb_item(stat_scaled_hash, player_index)
	elif stat_scaled_hash == Keys.living_tree_hash:
		actual_nb_scaled = current_living_trees
	elif stat_scaled_hash == Keys.percent_player_missing_health_hash:
		var current_health = get_player_current_health(player_index)
		var max_health = get_player_max_health(player_index)
		actual_nb_scaled = WeaponService.apply_inverted_health_bonus(1, 1, current_health, max_health)
	elif stat_scaled_hash == Keys.free_weapon_slots_hash:
		actual_nb_scaled = get_free_weapon_slots(player_index)
	elif stat_scaled_hash == Keys.generate_hash("capybara_cursed_item"):
		actual_nb_scaled = capybara_get_player_nb_cursed_items(player_index)
	elif perm_stats_only:
		actual_nb_scaled = get_stat(stat_scaled_hash, player_index)
	else:
		actual_nb_scaled = get_stat(stat_scaled_hash, player_index) + TempStats.get_stat(stat_scaled_hash, player_index)

	return int(value * (actual_nb_scaled / nb_stat_scaled))

func get_nb_structures(player_index: int) -> int:
	var capybara_result = .get_nb_structures(player_index)
	var capybara_new_result = get_nb_item(Keys.item_pocket_factory_hash, player_index)
	for structure in get_player_effect(Keys.structures_hash, player_index):
		capybara_new_result += structure.value
	for pet in get_player_effect(Keys.stat_pets_hash, player_index):
		if pet.is_structure:
			capybara_new_result += pet.value

	return capybara_new_result

var capybara_killed_enemies = [0,0,0,0]

func get_stat(stat_hsh:int, player_index: int) -> float:
	if stat_hsh == Keys.generate_hash("stat_capybara_enemies_killed"):
		return capybara_killed_enemies[player_index]
	elif stat_hsh == Keys.generate_hash("capybara_number_of_merged_characters"):
		return capybara_get_nb_of_merged_characters(player_index) as float
	elif stat_hsh == Keys.generate_hash("capybara_cursed_enemies"):
		return capybara_cursed_enemies
#	if stat_hsh == Keys.generate_hash("stat_capybara_wave_time"):
#		var effects = get_player_effects(player_index)
#		return effects[Keys.generate_hash("capybara_wave_time")]
	return .get_stat(stat_hsh, player_index)

func add_xp(value: int, player_index: int) -> void :
	var capybara_value = value
	var capybara_can_not_level_up = get_player_effect(Keys.generate_hash("capybara_can_not_level_up"), player_index).size()
	if capybara_can_not_level_up > 0:
		capybara_value = 0
	.add_xp(capybara_value, player_index)

func add_stat(stat_hsh: int, value: int, player_index: int) -> void :
	if stat_hsh == Keys.generate_hash("stat_capybara_gold"):
		add_gold(value, player_index)
		emit_signal("stat_added", stat_hsh, value, 0.0, player_index)
		_are_player_stats_dirty[player_index] = true
		Utils.reset_stat_cache(player_index)
#	elif stat_hsh == Keys.generate_hash("stat_capybara_wave_time"):
#		var effects: = get_player_effects(player_index)
#		effects[Keys.generate_hash("capybara_wave_time")] += value
#		emit_signal("stat_added", stat_hsh, value, 0.0, player_index)
#		_are_player_stats_dirty[player_index] = true
#		Utils.reset_stat_cache(player_index)
	else:
		.add_stat(stat_hsh, value, player_index)

func capybara_crystallize_item(item_data: ItemParentData, player_index: int = -1) -> ItemParentData:
	if RunData.capybara_check_crystal(item_data):
		return item_data
	if not (item_data is ItemData or item_data is WeaponData) or item_data is CharacterData:
		return item_data
	if item_data.effects.size() <= 0 and item_data is ItemData:
		return item_data
	var new_effects: = []
	var new_item_data = item_data.duplicate()
	for effect in item_data.effects:
		if item_data is ItemData:
			continue
		if effect == null or not is_instance_valid(effect):
			continue
		var new_effect = effect.duplicate()
		new_effects.append(new_effect if new_effect != null else effect)
	if item_data is WeaponData:
		if new_item_data is WeaponData:
			new_item_data.upgrades_into = null
		new_item_data.stats = _capybara_manage_crystallized_weapon_stats(item_data.stats, false, item_data.tier)
		var extra_effect = NullEffect.new()
		extra_effect.key = "capybara_break_on_hit"
		extra_effect.key_hash = Keys.generate_hash("capybara_break_on_hit")
		extra_effect.text_key = "effect_capybara_break_on_hit"
		extra_effect.value = 5 - item_data.tier
		var extra_effect_1 = NullEffect.new()
		extra_effect_1.text_key = "effect_capybara_weapon_no_upgrade"
		new_effects.append(extra_effect_1)
		extra_effect.storage_method = StorageMethod.SUM
		extra_effect.effect_sign = Sign.NEGATIVE
		new_effects.append(extra_effect)
		if item_data.stats is MeleeWeaponStats:
			if Utils.get_chance_success(0.5):
				var melee_extra_effect = NullDoubleValueEffect.new()
				melee_extra_effect.key = "capybara_x_hit"
				melee_extra_effect.key_hash = Keys.generate_hash("capybara_x_hit")
				melee_extra_effect.text_key = "effect_capybara_x_hit"
				melee_extra_effect.value = item_data.tier + 3
				melee_extra_effect.storage_method = StorageMethod.SUM
				melee_extra_effect.effect_sign = Sign.FROM_VALUE
				melee_extra_effect.value2 = (item_data.tier + 1) * 15 + 20
				new_effects.append(melee_extra_effect)
			else:
				var melee_extra_effect = NullDoubleValueEffect.new()
				melee_extra_effect.key = "capybara_bounce_hit"
				melee_extra_effect.key_hash = Keys.generate_hash("capybara_bounce_hit")
				melee_extra_effect.text_key = "effect_capybara_bounce_hit"
				melee_extra_effect.value = item_data.tier + 3
				melee_extra_effect.storage_method = StorageMethod.SUM
				melee_extra_effect.effect_sign = Sign.FROM_VALUE
				melee_extra_effect.value2 = (item_data.tier + 1) * 15 + 20
				new_effects.append(melee_extra_effect)
	if item_data is ItemData:
		var null_effect = NullDoubleValueEffect.new()
		null_effect.key = item_data.my_id
		null_effect.key_hash = item_data.my_id_hash
		null_effect.custom_key = "capybara_lose_effects"
		null_effect.custom_key_hash = Keys.generate_hash("capybara_lose_effects")
		null_effect.text_key = "effect_capybara_lose_effects"
		null_effect.value = 2
		if RunData.current_wave < RunData.nb_of_waves:
			null_effect.value2 = min(RunData.current_wave + 3,19)
		else:
			null_effect.value2 = RunData.current_wave + 3
		if item_data.is_cursed:
			null_effect.value *= 1.5
		new_effects.append(null_effect)
	var null_effect = NullEffect.new()
	null_effect.custom_key = "capybara_is_crystallized"
	null_effect.custom_key_hash = Keys.generate_hash("capybara_is_crystallized")
	null_effect.text_key = "[EMPTY]"
	new_effects.append(null_effect)
	var global_extra_effect = Effect.new()
	global_extra_effect.key = "stat_capybara_crystal"
	global_extra_effect.text_key = "effect_stat_capybara_crystal"
	global_extra_effect.key_hash = Keys.generate_hash("stat_capybara_crystal")
	global_extra_effect.storage_method = StorageMethod.SUM
	global_extra_effect.value = item_data.tier + 1
	global_extra_effect.effect_sign = Sign.FROM_VALUE
	new_effects.append(global_extra_effect)
	new_item_data.effects = new_effects

	return new_item_data as ItemParentData

func capybara_create_duplicate_item(item_data: ItemParentData, player_index: int = -1) -> ItemParentData:
	if RunData.capybara_check_crystal(item_data):
		return item_data
	if not (item_data is ItemData or item_data is WeaponData) or item_data is CharacterData:
		return item_data
	var new_effects: = []
	var new_item_data = item_data.duplicate()
	for effect in item_data.effects:
		if effect == null or not is_instance_valid(effect):
			continue
		var new_effect = effect.duplicate()
		new_effects.append(new_effect if new_effect != null else effect)
	var n_effect = NullEffect.new()
	n_effect.custom_key = "capybara_is_crystallized"
	n_effect.custom_key_hash = Keys.generate_hash("capybara_is_crystallized")
	n_effect.text_key = "EFFECT_CAPYBARA_IS_DUPLICATED"
	new_effects.append(n_effect)
	new_item_data.effects = new_effects

	return new_item_data as ItemParentData

func capybara_modify_crystal_alloy(player_index: int = -1, effect = null) -> void:
	if effect == null:
		return

	var new_item = null
	var new_effects: Array = []
	var item_to_remove = null
	var should_add_new_effect: bool = true

	for item in get_player_items(player_index):
		if item.my_id_hash == Keys.generate_hash("item_capybara_crystal_alloy"):
			new_item = item.duplicate()
			item_to_remove = item
			break

	if new_item == null:
		return

	for old_effect in new_item.effects:
		if old_effect == null:
			continue

		var new_effect = old_effect.duplicate()

		if old_effect is StatGainsModificationEffect and effect is StatGainsModificationEffect:
			var old_stat_effect = old_effect as StatGainsModificationEffect
			var new_stat_effect = new_effect as StatGainsModificationEffect

			if old_stat_effect.stat_displayed == effect.stat_displayed:
				new_stat_effect.value += effect.value
				should_add_new_effect = false

		new_effects.append(new_effect)

	if should_add_new_effect:
		new_effects.append(effect.duplicate())

	new_item.effects = new_effects
	add_item(new_item, player_index)
	if item_to_remove:
		capybara_remove_item(item_to_remove, player_index)

func capybara_modify_crystallized_weapon(player_index: int = -1, effect = null) -> void:
	if effect == null:
		return
	var weapons_to_modify = capybara_get_crystallized_weapons(player_index)
	if weapons_to_modify.size() <= 0:
		return
	var new_weapon = null
	var weapon_to_remove = null
	for weapon in weapons_to_modify:
		if not new_weapon:
			new_weapon = weapon.duplicate()
			weapon_to_remove = weapon
		if new_weapon.tier < weapon.tier:
			new_weapon = weapon.duplicate()
			weapon_to_remove = weapon
	if new_weapon:
		new_weapon.effects.append(effect)
		add_weapon(new_weapon, player_index)
	if weapon_to_remove:
		remove_weapon(weapon_to_remove, player_index)
	

func capybara_get_crystallized_weapons(player_index:int) -> Array:
	var weapons = []
	for weapon in get_player_weapons(player_index):
		if capybara_check_crystal(weapon):
			weapons.append(weapon)
	return weapons

func capybara_check_duplicated(item_data:ItemParentData) -> bool:
	if item_data == null or not is_instance_valid(item_data):
		return false
	for effect in item_data.effects:
		if effect == null or not is_instance_valid(effect):
			continue
		if effect.custom_key_hash == Keys.generate_hash("capybara_is_crystallized") and effect.text_key == "EFFECT_CAPYBARA_IS_DUPLICATED":
			return true
	return false

func capybara_turn_character_into_item(item_data: ItemData, character_data:CharacterData, player_index: int = -1) -> CharacterData:
	if not character_data is CharacterData:
		return character_data
	var new_effects: = []
	var new_item_data:ItemData = item_data.duplicate()
	var new_character_data:CharacterData = character_data.duplicate()
	for effect in character_data.effects:
		if effect == null or not is_instance_valid(effect):
			continue
		new_effects.append(effect)
	new_character_data.item_appearances = character_data.item_appearances.duplicate()
	for item_appearance in new_character_data.item_appearances:
		item_appearance.is_character_appearance = false
	
	new_character_data.effects = new_effects
	if not capybara_check_crystal(item_data):
		var null_effect = NullEffect.new()
		null_effect.custom_key = "capybara_is_crystallized"
		null_effect.custom_key_hash = Keys.generate_hash("capybara_is_crystallized")
		null_effect.text_key = "[EMPTY]"
		new_character_data.effects.append(null_effect)
	var player_run_data = players_data[player_index]
	for item_name in character_data.banned_items:
		player_run_data.banned_items.push_back(Keys.generate_hash(item_name))
	for id in character_data.banned_item_groups:
		var item_to_ban = ItemService.item_groups.get(id)
		if item_to_ban:
			for item_name in item_to_ban:
				player_run_data.banned_items.push_back(Keys.generate_hash(item_name))
	if character_data.banned_upgrades.size() > 0:
		get_player_character(player_index).banned_upgrades.append_array(character_data.banned_upgrades)
	_capybara_manage_starting_item(new_character_data, player_index)

	return new_character_data as CharacterData

func _capybara_manage_crystallized_weapon_stats(stats:WeaponStats, double_merge:bool = false, tier:int = 0) -> WeaponStats:
	var new_stats = stats.duplicate()
	var max_v = 0
	for stat in stats.scaling_stats:
		if stat[1] > max_v:
			max_v = stat[1]
	var new_scale_stat = [Keys.generate_hash("stat_capybara_crystal"), max_v/5.0]
	new_stats.scaling_stats.append(new_scale_stat)
	if double_merge:
		for stat in new_stats.scaling_stats:
			stat[1] *= 1.5
	if new_stats is RangedWeaponStats:
		new_stats.nb_projectiles = stats.nb_projectiles + tier + 1
		if double_merge:
			new_stats.nb_projectiles = stats.nb_projectiles + 2 + tier
	return new_stats

var capybara_items_cannot_crystal = [
	"item_capybara_crystal_alloy",
	"item_capybara_crystal_pet",
	"item_cp_crystal_turret_0",
	"item_cp_crystal_turret_1",
	"item_cp_crystal_turret_2",
	"item_cp_crystal_turret_3",
	"item_goldfish_used",
]

func capybara_get_uncrystallized_items(player_index:int) -> Array:
	var items = get_player_items(player_index)
	var uncrystallized_items = []
	for item in items:
		if not capybara_check_crystal(item) and item.effects.size() > 0 and not item.my_id in capybara_items_cannot_crystal and item.max_nb == -1:
			uncrystallized_items.append(item)
	uncrystallized_items.append_array(capybara_get_crystallized_weapons(player_index))
	uncrystallized_items.shuffle()
	return uncrystallized_items

func capybara_get_uncrystallized_weapons(player_index:int) -> Array:
	var weapons = get_player_weapons(player_index)
	var uncrystallized_weapons = []
	for weapon in weapons:
		if not capybara_check_crystal(weapon):
			uncrystallized_weapons.append(weapon)
	return uncrystallized_weapons

func capybara_remove_item(item: ItemData, player_index: int, by_id: bool = false) -> void :
	item.replaced_by = null
	remove_item(item, player_index, by_id)


func _capybara_manage_starting_item(final_item:CharacterData, player_index) -> void:
	for effect in final_item.effects:
		if effect == null or not is_instance_valid(effect):
			continue
		if effect.custom_key == "starting_item":
			for i in effect.value:
				var item_to_add = ItemService.get_item_from_id(effect.key_hash)
				add_item(item_to_add, player_index)
		elif effect.custom_key == "starting_weapon":
			var weapon_to_add = ItemService.get_element(ItemService.weapons, effect.key_hash)
			add_weapon(weapon_to_add, player_index)
		elif effect.custom_key == "cursed_starting_item":
			for i in effect.value:
				var item_to_cursed = ItemService.get_item_from_id(effect.key_hash)
				for dlc_id in enabled_dlcs:
					var dlc_data = ProgressData.get_dlc_data(dlc_id)
					if dlc_data and dlc_data.has_method("curse_item") and item_to_cursed:
						var cursed_item = dlc_data.curse_item(item_to_cursed, player_index, false, 0.5)
						add_item(cursed_item, player_index)
		elif effect.custom_key == "cursed_starting_weapon":
			var item_to_cursed = ItemService.get_element(ItemService.weapons, effect.key_hash)
			for dlc_id in enabled_dlcs:
				var dlc_data = ProgressData.get_dlc_data(dlc_id)
				if dlc_data and dlc_data.has_method("curse_item") and item_to_cursed:
					var cursed_item = dlc_data.curse_item(item_to_cursed, player_index, false, 0.5)
					add_weapon(cursed_item, player_index)

func can_combine(weapon_data: WeaponData, player_index: int) -> bool:
	var capybara_can_combine = .can_combine(weapon_data, player_index)
	var cp_nb_duplicates = 0

	var capy_weapons: = get_player_weapons_ref(player_index)
	for weapon in capy_weapons:
		if weapon.my_id == weapon_data.my_id and not (capybara_check_crystal(weapon) or capybara_check_crystal(weapon_data)):
			cp_nb_duplicates += 1

	return capybara_can_combine and cp_nb_duplicates >= 2

func player_has_weapon_slots(player_index: int) -> bool:
	var capy_result = .player_has_weapon_slots(player_index)
	var capy_new_result = true
	var capy_has_knot_effect = RunData.get_player_effect(Keys.lock_current_weapons_hash, player_index)
	if capy_has_knot_effect > 0 and get_player_weapons(player_index).size() >= get_stat(Keys.weapon_slot_hash, player_index):
		capy_new_result = false
	return capy_result  and capy_new_result

func capybara_get_nb_of_merged_characters(player_index:int) -> int:
	var value = 0
	for item in get_player_items(player_index):
		if ItemService.capybara_is_character_id(item.my_id) and capybara_check_crystal(item):
			value += 1
	return value

func add_item(item: ItemData, player_index: int, is_selection: bool = false) -> void :
	if is_selection:
		for effect in item.effects:
			if effect == null or not is_instance_valid(effect):
				continue
			if effect.custom_key == "capybara_gain_weapons_when_selection":
				for i in effect.value:
					var weapon_to_add = ItemService.get_weapon_from_weapon_id(effect.key_hash)
					add_weapon(weapon_to_add, player_index)
	.add_item(item, player_index, is_selection)
	
func get_player_appearances(player_index:int) -> Array:
	var capybara_result_apps = []
	var capybara_apps = .get_player_appearances(player_index)
	var capybara_should_remove_app = false
	
	for effect in get_player_character(player_index).effects:
		if effect.key_hash == Keys.generate_hash("no_front_item_app") and effect.custom_key_hash == Keys.generate_hash("capybara_hide_potato"):
			for app in capybara_apps:
				if app is ItemAppearanceData:
					if app.depth <= 0 or app.is_character_appearance:
						capybara_result_apps.push_back(app)
			capybara_should_remove_app = true
			break
	if get_player_character(player_index).my_id == "character_cp_uncle_zhang":
		for app in capybara_apps:
			if app is ItemAppearanceData:
				if app.depth <= 0 or app.is_character_appearance:
					capybara_result_apps.push_back(app)
		capybara_should_remove_app = true
#	var capybara_app_effects = RunData.get_player_effect(Keys.generate_hash("capybara_hide_potato"),player_index)
#	if not capybara_should_remove_app and capybara_app_effects.size() > 0:
#		for app in capybara_apps:
#			if not app.is_character_appearance or app.depth <= 0 or (app.is_character_appearance and app.position == ItemAppearanceData.Position.OTHER):
#				capybara_result_apps.push_back(app)
#				capybara_should_remove_app = true
	if capybara_should_remove_app:
		return capybara_result_apps
	return capybara_apps

func get_player_currency(player_index: int) -> int:
	var capybara_stat_shop_remove_stat = null
	var capybara_borrow = 0
	for effect in get_player_effect(Keys.generate_hash("capybara_stat_shop"), player_index):
		capybara_stat_shop_remove_stat = effect[0]
		capybara_borrow = effect[1] as int
	if capybara_stat_shop_remove_stat:
		if capybara_borrow > 0:
			return get_stat(capybara_stat_shop_remove_stat, player_index) as int + capybara_borrow
		return get_stat(capybara_stat_shop_remove_stat, player_index) as int
	else:
		return .get_player_currency(player_index)

func get_player_effect(key: int, player_index: int):
	var result = .get_player_effect(key, player_index)
	if key == Keys.pickup_range_hash and (result is int or result is float):
		return result + TempStats.get_stat(key, player_index) + LinkedStats.get_stat(key, player_index)
	elif key == Keys.generate_hash("capybara_bonus_damage_against_cursed") and (result is int or result is float):
		return result + TempStats.get_stat(key, player_index) + LinkedStats.get_stat(key, player_index)
	return result

func remove_currency(value: int, player_index: int) -> void :
	var capybara_stat_shop_remove_stat = null
	for effect in get_player_effect(Keys.generate_hash("capybara_stat_shop"), player_index):
		capybara_stat_shop_remove_stat = effect[0]
	if capybara_stat_shop_remove_stat:
		remove_stat(capybara_stat_shop_remove_stat, value, player_index)
	else:
		.remove_currency(value, player_index)

var colorful_light = load("res://mods-unpacked/Dbear-Capybara/materials/capybara_flow_light_another.tscn")

func capybara_get_colorful_flow_light() -> PackedScene:
	return colorful_light
