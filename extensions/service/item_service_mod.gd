extends "res://singletons/item_service.gd"

const CAPYBARA_MOD_MAIN_PATH = "/root/ModLoader/Dbear-Capybara"

var capybara_merge_character = [null, null, null, null]

func get_upgrades(level: int, number: int, old_upgrades: Array, player_index: int) -> Array:
	if level < 0:
		return capybara_get_crystal_upgrades(player_index)
	var capybara_change_upgrades_into_chance_of_limited_items = RunData.get_player_effect(Keys.generate_hash("capybara_replace_upgrades_with_limited_items"), player_index)
	if capybara_change_upgrades_into_chance_of_limited_items > 0:
		var new_upgrades = _capybara_create_item_chance_upgrades(player_index)
		if new_upgrades.size() > 0:
			return new_upgrades
	
	var cp_projectiles_upgrade_data = load("res://mods-unpacked/Dbear-Capybara/contents/upgrades/nb_of_projectiles_data.tres")
	var cp_enemies_number_data = load("res://mods-unpacked/Dbear-Capybara/contents/upgrades/number_of_enemies/upgrade_number_of_enemies_data.tres")
	var cp_thunder_data = load("res://mods-unpacked/Dbear-Capybara/contents/upgrades/thunder/thunder_data.tres")
	var cp_fire_data = load("res://mods-unpacked/Dbear-Capybara/contents/upgrades/fire/fire_data.tres")
	var cp_wind_data = load("res://mods-unpacked/Dbear-Capybara/contents/upgrades/wind/wind_data.tres")
	var capybara_upgrades_to_show = .get_upgrades(level, number, old_upgrades, player_index)
	var cp_projectiles_upgrades = RunData.get_player_effect(Keys.generate_hash("cp_projectiles_upgrade"), player_index)
	var cp_number_of_enemies_upgrades = RunData.get_player_effect(Keys.generate_hash("cp_number_of_enemies_upgrade"), player_index)
	if cp_number_of_enemies_upgrades.size() > 0:
		for effect in cp_number_of_enemies_upgrades:
			if level <= effect[1]:
				return [cp_enemies_number_data]
	var cp_weapon_slot_upgrades = RunData.get_player_effect(Keys.weapon_slot_upgrades_hash, player_index)
	if cp_projectiles_upgrades.size() > 0:
		for effect in cp_projectiles_upgrades:
			if level <= effect[1]:
				if cp_weapon_slot_upgrades > 0:
					return capybara_upgrades_to_show.append_array([cp_projectiles_upgrade_data])
				else:
					return [cp_projectiles_upgrade_data]
	var cp_saint_upgrades = RunData.get_player_effect(Keys.generate_hash("capybara_junior_sister"), player_index)
	var cp_fire_effect = RunData.get_player_effect(Keys.generate_hash("capybara_fire"), player_index)
	var cp_thunder_effect = RunData.get_player_effect(Keys.generate_hash("capybara_thunder"), player_index)
	var cp_wind_effect = RunData.get_player_effect(Keys.generate_hash("capybara_wind"), player_index)
	var cp_fire = capybara_effect_count(cp_fire_effect, "fire")
	var cp_wind = capybara_effect_count(cp_wind_effect, "wind")
	var cp_thunder = capybara_effect_count(cp_thunder_effect,"thunder")
	if cp_saint_upgrades.size() > 0:
		for effect in cp_saint_upgrades:
			if level % effect[1] == 0:
				var cp_level = []
				if cp_fire < effect[2]:
					cp_level.append(cp_fire_data)
				if cp_thunder < effect[2]:
					cp_level.append(cp_thunder_data)
				if cp_wind < effect[2]:
					cp_level.append(cp_wind_data)
				if not cp_level.size() <= 0:
					return cp_level
	return capybara_upgrades_to_show

var capybara_upgrades_for_crystal = load("res://mods-unpacked/Dbear-Capybara/contents/upgrades/upgrades_for_crystal.tres")
var capybara_upgrades_for_crystal_1 = load("res://mods-unpacked/Dbear-Capybara/contents/upgrades/upgrades_for_crystal_1.tres")
var capybara_upgrades_for_crystal_1a = load("res://mods-unpacked/Dbear-Capybara/contents/upgrades/upgrades_for_crystal_1a.tres")
var capybara_upgrades_for_crystal_2 = load("res://mods-unpacked/Dbear-Capybara/contents/upgrades/upgrades_for_crystal_2.tres")

func capybara_get_crystal_upgrades(player_index:int) -> Array:
	var raw_upgrade_data = []
	
	for upgrade_data in capybara_upgrades_for_crystal.upgrades_for_crystal:
		if RunData.get_player_effect(Keys.max_turret_count_hash, player_index) == 1 and upgrade_data.upgrade_id == "upgrade_cp_crystal_turret":
			continue
		if upgrade_data.upgrade_id == "upgrade_cp_crystal_character":
			raw_upgrade_data.append(capybara_get_merge_character(upgrade_data, player_index))
		else:
			raw_upgrade_data.append(upgrade_data)
	match capybara_crystal_path(player_index):
		1:
			return capybara_upgrades_for_crystal_1a.upgrades_for_crystal
		2:
			return capybara_upgrades_for_crystal_2.upgrades_for_crystal
		3:
			return _capybara_create_crystal_alloy_upgrades(player_index)
		4:
			return capybara_create_character_upgrades(player_index)
		_:
			raw_upgrade_data
	return raw_upgrade_data

func capybara_create_character_upgrades(player_index:int) -> Array:
	var upgrade_data = []
	var characters_to_remove = []
	for item in RunData.get_player_items(player_index):
		if capybara_is_character_id(item.my_id):
			characters_to_remove.append(item.my_id_hash)
	var cp_characters = []
	for character in characters:
		if character == null or not is_instance_valid(character) or character.my_id == "GMO_dummy":
			continue
		if character.my_id_hash in characters_to_remove:
			continue
		cp_characters.append(character)
	var up_characters = capybara_get_random_elements(cp_characters, 4)
	for character in up_characters:
		var new_upgrade = UpgradeData.new()
		new_upgrade.my_id = "upgrade_cp_character_up"
		new_upgrade.my_id_hash = Keys.generate_hash(new_upgrade.my_id)
		new_upgrade.name = "CP_CRYSTAL_CHARACTER"
		new_upgrade.tier = Tier.LEGENDARY
		new_upgrade.value = 1
		new_upgrade.upgrade_id = new_upgrade.my_id
		new_upgrade.upgrade_id_hash = new_upgrade.my_id_hash
		new_upgrade.icon = character.icon
		var new_effect = Effect.new()
		new_effect.key = character.my_id
		new_effect.key_hash = character.my_id_hash
		new_effect.value = 1
		new_effect.custom_key = "capybara_add_item"
		new_effect.custom_key_hash = Keys.generate_hash("capybara_add_item")
		new_effect.text_key = "EFFECT_CAPYBARA_ADD_ITEM"
		new_effect.storage_method = StorageMethod.KEY_VALUE
		new_effect.effect_sign = Sign.FROM_VALUE
		new_upgrade.effects = [new_effect]
		upgrade_data.append(new_upgrade)
	return upgrade_data

func capybara_get_merge_character(
	character_up: UpgradeData,
	player_index: int
) -> UpgradeData:
	var final_character_up = character_up.duplicate() as UpgradeData
	var characters_data = []
	for character in ItemService.characters:
		if character == null or not is_instance_valid(character) or character.my_id == "GMO_dummy":
			continue
		characters_data.append(character)
	var character_to_process = null

	if not capybara_merge_character[player_index]:
		if not RunData.capybara_last_character[player_index]:
			if characters_data.empty():
				return character_up
			character_to_process = Utils.get_rand_element(characters_data)
		else:
			character_to_process = RunData.capybara_last_character[player_index]

		capybara_merge_character[player_index] = character_to_process
	else:
		character_to_process = capybara_merge_character[player_index]

	# 关键：复制整个升级数据，避免多人共用同一个资源
	var new_effects = []

	if character_to_process is CharacterData:
		for effect in character_up.effects:
			if effect == null or not is_instance_valid(effect):
				continue
			var new_effect = effect.duplicate()
			if new_effect == null or not is_instance_valid(new_effect):
				continue

			if new_effect.custom_key_hash == Keys.generate_hash("capybara_add_item"):
				new_effect.key_hash = character_to_process.my_id_hash
				new_effect.key = character_to_process.my_id

			elif new_effect.custom_key_hash == Keys.generate_hash("capybara_next_character"):
				var current_character = RunData.get_player_character(player_index)

				if current_character:
					new_effect.key_hash = current_character.my_id_hash
					new_effect.key = current_character.my_id

			new_effects.append(new_effect)

		final_character_up.effects = new_effects
		final_character_up.icon = character_to_process.icon

	return final_character_up

func capybara_crystal_path(player_index:int) -> int:
	for item in RunData.get_player_items(player_index):
		if item.my_id.begins_with("item_cp_crystal_turret"):
			return 1
		elif item.my_id_hash == Keys.generate_hash("item_capybara_crystal_pet"):
			return 2
		elif item.my_id_hash == Keys.generate_hash("item_capybara_crystal_alloy"):
			return 3
		elif capybara_is_character_id(item.my_id) and RunData.capybara_check_crystal(item):
			return 4
	return 0

func capybara_effect_count(cp_effect, custom_key) -> int:
	var count = 0
	for effect in cp_effect:
		if effect.custom_key == custom_key:
			count += 1
	return count

func get_icon_for_duplicate_shop_item(character: CharacterData, player_items: Array, player_weapons: Array, shop_item: ItemParentData, player_index: int):
	var capybara_icon = .get_icon_for_duplicate_shop_item(character, player_items, player_weapons, shop_item, player_index)
	return capybara_icon

func _capybara_get_nb_locked_items(items:Array, item_id:int) -> int:
	var result = 0
	for item in items:
		if item[0].my_id_hash == item_id:
			result += 1
	return result

func _capybara_get_broken_items(item_id:int, player_index:int) -> int:
	var item_data = get_element(items, item_id)
	var result = 0
	if item_data.replaced_by:
		var item_replaced = item_data.replaced_by.my_id_hash
		for item in RunData.get_player_items(player_index):
			if item.my_id_hash == item_replaced:
				result += 1
	return result

func get_player_shop_items(wave: int, player_index: int, args: ItemServiceGetShopItemsArgs) -> Array:
	var capybara_items = .get_player_shop_items(wave, player_index, args)
	var cp_ct = capybara_items.size()
	if cp_ct > 0:
		var nb_weapons_guaranteed = 0
		if RunData.current_wave <= MAX_WAVE_TWO_WEAPONS_GUARANTEED:
			nb_weapons_guaranteed = 2
		elif RunData.current_wave <= MAX_WAVE_ONE_WEAPON_GUARANTEED:
			nb_weapons_guaranteed = 1
		var minimum_weapons_in_shop = RunData.get_player_effect(Keys.minimum_weapons_in_shop_hash, player_index)
		nb_weapons_guaranteed = max(nb_weapons_guaranteed, minimum_weapons_in_shop)
		var nb_locked_weapons = 0
		for locked_item in args.locked_items:
			if locked_item[0] is WeaponData:
				nb_locked_weapons += 1
		var actual_nb_weapons_forced = max(0, nb_weapons_guaranteed - nb_locked_weapons)
		var guaranteed_items = RunData.get_player_effect(Keys.guaranteed_shop_items_hash, player_index).duplicate()
		var actual_guaranteed_items = actual_nb_weapons_forced + guaranteed_items.size()
		if not actual_guaranteed_items > cp_ct:
			var capybara_force_limit_item = RunData.get_player_effect(Keys.generate_hash("capybara_force_limit_item"), player_index)
			var index = actual_guaranteed_items
			for effect in capybara_force_limit_item:
				if index < cp_ct and RunData.capybara_get_nb_of_item(effect[0], player_index) + _capybara_get_nb_locked_items(args.locked_items, effect[0]) < get_element(items, effect[0]).max_nb and _capybara_get_broken_items(effect[0], player_index) < effect[1]:
					capybara_items[index] = [get_element(items, effect[0]), wave]
				index += 1
	return capybara_items

func get_stat_description_text(stat_hash: int, value: int, player_index: int) -> String:
	var capybara_text = .get_stat_description_text(stat_hash, value, player_index)
	if stat_hash == Keys.generate_hash("stat_capybara_crystal"):
		var stat_name = Keys.hash_to_string[stat_hash].to_upper()
		var stat_sign = "POS_" if value >= 0 else "NEG_"
		var key = "INFO_" + stat_sign + stat_name
		var t_value = abs(value)
		var damage_should_taken_to_break = Utils.CAPYBARA_DAMAGE_TAKEN_TO_BREAK as int
		var per_damage_against_enemy = t_value/Utils.CAPYBARA_CRYSTAL_RATE as int
		if per_damage_against_enemy > Utils.CAPYBARA_MAX_PER_DAMAGE_AGAINSR_ENEMY:
			per_damage_against_enemy = stepify(Utils.CAPYBARA_MAX_PER_DAMAGE_AGAINSR_ENEMY, 0.01)
		var boss_decrease = Utils.CAPYBARA_MAX_PER_DAMAGE_AGAINSR_ENEMY/Utils.CAPYBARA_MAX_PER_DAMAGE_AGAINSR_BOSS as float
		var per_damage_against_boss = stepify(per_damage_against_enemy/boss_decrease,0.01)
		if per_damage_against_boss > Utils.CAPYBARA_MAX_PER_DAMAGE_AGAINSR_BOSS:
			per_damage_against_boss = Utils.CAPYBARA_MAX_PER_DAMAGE_AGAINSR_BOSS
		var per_value_text = str(per_damage_against_enemy) + "%"
		var per_value_text_boss = str(per_damage_against_boss) + "%"
		var per_player_more_damage_taken = str(min(t_value, Utils.CAPYBARA_WEAKEN_MAX_RATE)) + "%"
		var crystallization_chance = str(min(Utils.CAPYBARA_CRYSTALLIZATION_CAP_CHANCE, t_value)) + "%"
		var min_item_crystallization_chance = stepify(min(Utils.CAPYBARA_ITEM_CRYSTALLIZATION_CAP_CHANCE, t_value/Utils.CAPYBARA_CRYSTAL_CHANCE_RATE), 0.01)
		var item_crystallization_chance = str(min_item_crystallization_chance) + "%"
		var capybara_mutation_cap_chance = str(stepify(min(Utils.CAPYBARA_MUTATION_CAP_CHANCE, Utils.capybara_get_factor(t_value)), 0.01))+ "%"
		return Text.text(key, [str(t_value), str(damage_should_taken_to_break), per_value_text, per_value_text_boss, per_player_more_damage_taken, crystallization_chance,item_crystallization_chance, capybara_mutation_cap_chance])
	return capybara_text

func capybara_is_character_id(id:String) -> bool:
	for character in characters:
		if character.my_id == id:
			return true
	return false

func capybara_get_character_from_id(id:String) -> CharacterData:
	for character in characters:
		if character.my_id == id:
			return character
	return null

func get_upgrade_data(level: int, player_index: int) -> UpgradeData:
	var capybara_add_upgrades = []
	var capy_tier = get_tier_from_wave(level, player_index)
	if _capybara_check_item_start_with("item_cp_crystal_turret", player_index):
		capybara_add_upgrades = _capybara_create_upgrades_data(capy_tier, capybara_upgrades_for_crystal_1.upgrades_for_crystal)
		_tiers_data[capy_tier][TierData.UPGRADES].append_array(capybara_add_upgrades)
	elif _capybara_check_item_start_with("item_capybara_crystal_pet", player_index):
		capybara_add_upgrades = _capybara_create_pet_upgrades(capy_tier)
		_tiers_data[capy_tier][TierData.UPGRADES].append_array(capybara_add_upgrades)
	elif _capybara_check_item_start_with("item_capybara_crystal_alloy", player_index):
		capybara_add_upgrades = _capybara_create_alloy_upgrades(capy_tier)
		_tiers_data[capy_tier][TierData.UPGRADES].append_array(capybara_add_upgrades)
	var capybara_upgrade = .get_upgrade_data(level, player_index)
	if capybara_add_upgrades.size() > 0:
		for upgrade_data in capybara_add_upgrades:
			_tiers_data[capy_tier][TierData.UPGRADES].erase(upgrade_data)
	return capybara_upgrade

func _capybara_check_item_start_with(s_name:String, player_index:int) -> bool:
	for item in RunData.get_player_items(player_index):
		if item.my_id.begins_with(s_name):
			return true
	return false

func _capybara_create_upgrades_data(tier:int, capybara_upgrades:Array) -> Array:
	var upgrades = []
	for upgrade_data in capybara_upgrades:
		var new_effects = []
		var new_upgrade:UpgradeData = upgrade_data.duplicate()
		new_upgrade.tier = tier
		for effect in new_upgrade.effects:
			var new_effect = effect.duplicate()
			new_effect.value = effect.value * (tier + 1 - upgrade_data.tier)
			new_effects.append(new_effect)
		new_upgrade.effects = new_effects
		if upgrade_data.tier <= tier:
			upgrades.append(new_upgrade)
	return upgrades

func capybara_get_pet_items() -> Array:
	var pet_items = []
	for item in items:
		for effect in item.effects:
			if effect is PetEffect:
				pet_items.append(item)
				break
	return pet_items

var capybara_pet_atk_upgrade = load("res://mods-unpacked/Dbear-Capybara/contents/upgrades/pet_attack_speed/upgrade_pet_attack_speed_data.tres")

func _capybara_create_pet_upgrades(tier:int) -> Array:
	var upgrades = []
	var special_upgrade = capybara_pet_atk_upgrade.duplicate()
	var effects = []
	special_upgrade.tier = tier
	for effect in special_upgrade.effects:
		var new_effect = effect.duplicate()
		new_effect.value = effect.value * (tier + 1)
		effects.append(new_effect)
	special_upgrade.effects = effects
	upgrades.append(special_upgrade)
	for item in capybara_get_pet_items():
		if item.tier == tier and item.max_nb == -1:
			var new_effect = Effect.new()
			new_effect.key = item.my_id
			new_effect.key_hash = item.my_id_hash
			new_effect.custom_key = "capybara_add_item"
			new_effect.custom_key_hash = Keys.generate_hash("capybara_add_item")
			new_effect.value = 1
			new_effect.text_key = "EFFECT_CAPYBARA_ADD_ITEM"
			new_effect.storage_method = StorageMethod.KEY_VALUE
			var new_effects = [new_effect]
			var new_upgrade = UpgradeData.new()
			new_upgrade.my_id = "upgrade_cp_" + item.my_id
			new_upgrade.my_id_hash = Keys.generate_hash("upgrade_cp_" + item.my_id)
			new_upgrade.tier = tier
			new_upgrade.effects = new_effects
			new_upgrade.icon = item.icon
			new_upgrade.name = item.name
			new_upgrade.upgrade_id = "upgrade_cp_" + item.my_id
			new_upgrade.upgrade_id_hash = Keys.generate_hash("upgrade_cp_" + item.my_id)
			
			upgrades.append(new_upgrade)
	return upgrades

func _capybara_get_upgrade_stat_keys() -> Array:
	var keys = []
	for upgrade in _tiers_data[0][TierData.UPGRADES]:
		for effect in upgrade.effects:
			if effect.key_hash in Utils._primary_stat_keys:
				keys.append(effect.key_hash)
	return keys

func _capybara_create_crystal_alloy_upgrades(player_index:int) -> Array:
	var upgrades = []
	var need_weapon_effects = false
	for weapon in RunData.get_player_weapons(player_index):
		if RunData.capybara_check_crystal(weapon):
			need_weapon_effects = true
	var nb_to_process:int = 4
	var index_a = [1, 3, 4, 5, 7, 9, 10, 12, 13]
	if _capybara_is_dlc_available():
		index_a.append_array([0, 2, 6, 11])
	if need_weapon_effects:
		index_a.append_array([-1, -2, -3, -5])
		if _capybara_is_dlc_available():
			index_a.append(-4)
	var rand_index = capybara_get_random_elements(index_a, 4)
	for i in rand_index:
		var upgrade = UpgradeData.new()
		var rand_stat_key = Utils.get_rand_element(_capybara_get_upgrade_stat_keys())
		var resourse = capybara_create_effect(i, rand_stat_key)
		upgrade.my_id = "upgrade_cp_alloy_" + resourse[3]
		upgrade.my_id_hash = Keys.generate_hash(upgrade.my_id)
		upgrade.icon = resourse[1]
		upgrade.effects = [resourse[0]]
		upgrade.tier = Tier.LEGENDARY
		upgrade.name = resourse[2]
		upgrade.upgrade_id = upgrade.my_id
		upgrade.my_id_hash = upgrade.my_id_hash
		var null_effect = NullEffect.new()
		null_effect.custom_key = "capybara_add_item"
		null_effect.custom_key_hash = Keys.generate_hash("capybara_add_item")
		null_effect.key = "capybara_alloy_new_effect"
		null_effect.text_key = "[EMPTY]"
		if need_weapon_effects and i < 0:
			null_effect.key = "capybara_crystal_weapon_new_effect"
			null_effect.text_key = "EFFECT_CAPYBARA_APPLY_EFFECT_TO_WEAPON"
		upgrade.effects.append(null_effect)
		upgrades.append(upgrade)
	return upgrades


func _capybara_is_dlc_available() -> bool:
	var mod_main = get_node_or_null(CAPYBARA_MOD_MAIN_PATH)
	return is_instance_valid(mod_main) and mod_main.has_method("capybara_is_dlc_available") and mod_main.capybara_is_dlc_available()

var capybara_projectiles_on_death = load("res://mods-unpacked/Dbear-Capybara/extensions/service/projectiles_on_death_effect.tres")

func capybara_create_effect(type:int, stat_key:int) -> Array:
	var new_effect = Effect.new()
	var icon = null
	var upgrade_name = ""
	var upgrade_id = ""
	if type == 0:
		var character = capybara_get_character_from_id("character_sailor")
		var rand_set = Utils.get_rand_element(ItemService.sets)
		var rand_set_key = rand_set.my_id.replace("set_","weapon_class_")
		icon = character.icon
		upgrade_name = character.name
		upgrade_id = character.my_id
		for effect in character.effects:
			if effect.custom_key_hash == Keys.bonus_weapon_class_damage_against_cursed_enemies_hash:
				new_effect = effect.duplicate()
				new_effect.key_hash = Keys.generate_hash(rand_set_key)
				new_effect.key = rand_set_key
				new_effect.value = rand_range(100, 200) as int
				break
	elif type == 1:
		var item = get_item_from_id(Keys.generate_hash("item_spicy_sauce"))
		icon = item.icon
		upgrade_name = item.name
		upgrade_id = item.my_id
		for effect in item.effects:
			if effect is ItemExplodingEffect:
				new_effect = effect.duplicate()
				new_effect.chance = (rand_range(50, 100) as int)/100.0
				var rand_scaling = rand_range(100, 300) as int
				
				var scaling = _capybara_get_balance_stats_rand_scaling(stat_key, rand_scaling)/100.0
				var new_scaling = [[stat_key, scaling]]
				new_effect.stats = effect.stats.duplicate()
				new_effect.stats.damage = 1
				new_effect.stats.scaling_stats = new_scaling
				
				break
	elif type == 2:
		var character = capybara_get_character_from_id("character_hiker")
		icon = character.icon
		upgrade_name = character.name
		upgrade_id = character.my_id
		for effect in character.effects:
			if effect.custom_key_hash == Keys.gain_stat_for_every_step_after_equip_hash and effect.key_hash != Keys.gold_hash:
				new_effect = effect.duplicate()
				new_effect.key_hash = stat_key
				new_effect.key = Keys.hash_to_string[stat_key]
				new_effect.value2 = rand_range(40, 160) as int
				break
	elif type == 3:
		var character = capybara_get_character_from_id("character_capybara")
		icon = character.icon
		upgrade_name = character.name
		upgrade_id = character.my_id
		for effect in character.effects:
			if effect.custom_key_hash == Keys.generate_hash("gain_stats_per_interval"):
				new_effect = effect.duplicate()
				new_effect.key_hash = stat_key
				new_effect.key = Keys.hash_to_string[stat_key]
				var rand_time = rand_range(5, 20) as int
				new_effect.interval = max(3, _capybara_get_balance_stats_rand_scaling(stat_key, rand_time)) as int
				break
	elif type == 4:
		var item = get_item_from_id(Keys.generate_hash("item_extra_stomach"))
		icon = item.icon
		upgrade_name = item.name
		upgrade_id = item.my_id
		for effect in item.effects:
			if effect.custom_key == "consumable_stats_while_max":
				new_effect = effect.duplicate()
				new_effect.key_hash = stat_key
				new_effect.key = Keys.hash_to_string[stat_key]
				new_effect.value2 = rand_range(2, 8) as int
				break
	elif type == 5:
		var item = get_item_from_id(Keys.generate_hash("item_snowball"))
		icon = item.icon
		upgrade_name = item.name
		upgrade_id = item.my_id
		for effect in item.effects:
			if effect.custom_key_hash == Keys.gain_stat_for_equipped_item_with_stat_hash:
				new_effect = effect.duplicate()
				new_effect.key_hash = stat_key
				new_effect.key = Keys.hash_to_string[stat_key]
				var rand_value = 1
				new_effect.value = _capybara_get_balance_stats_rand_value(stat_key, rand_value)
				new_effect.key2 = Keys.hash_to_string[Utils.get_rand_element(_capybara_get_upgrade_stat_keys())]
				break
	elif type == 6:
		var character = capybara_get_character_from_id("character_ogre")
		icon = character.icon
		upgrade_name = character.name
		upgrade_id = character.my_id
		for effect in character.effects:
			if effect.key_hash == Keys.explode_on_overkill_hash:
				new_effect = effect.duplicate()
				new_effect.value = rand_range(100, 200) as int
				var scaling = rand_range(10, 100) as int
				scaling = _capybara_get_balance_stats_rand_scaling(stat_key, scaling)/100.0
				var scaling_stats = [[stat_key, scaling]]
				new_effect.stats = effect.stats.duplicate()
				new_effect.stats.damage = 1
				new_effect.stats.scaling_stats = scaling_stats
				new_effect.scale = rand_range(1.0, 2.0)
				break
					
	elif type == 7:
		var item = get_item_from_id(Keys.generate_hash("item_baby_with_a_beard"))
		icon = item.icon
		upgrade_name = item.name
		upgrade_id = item.my_id
		for effect in item.effects:
			if effect.key_hash == Keys.projectiles_on_death_hash:
				new_effect = capybara_projectiles_on_death.duplicate()
				new_effect.value = rand_range(1,4) as int
				if Utils.get_chance_success(0.5):
					new_effect.auto_target_enemy = true
				new_effect.weapon_stats = Utils.get_rand_element(_capybara_get_ranged_weapons()).stats.duplicate()
				new_effect.weapon_stats.damage = 1
				var scaling = rand_range(10, 100) as int
				scaling = _capybara_get_balance_stats_rand_scaling(stat_key, scaling)/100.0
				var scaling_stats = [[stat_key, scaling]]
				new_effect.weapon_stats.scaling_stats = scaling_stats
				break
	elif type == 8:
		var item = get_item_from_id(Keys.generate_hash("item_baby_elephant"))
		icon = item.icon
		upgrade_name = item.name
		upgrade_id = item.my_id
		for effect in item.effects:
			if effect.custom_key_hash == Keys.dmg_when_pickup_gold_hash:
				new_effect = effect.duplicate()
				var rand_value =  rand_range(100, 200) as int
				new_effect.value = _capybara_get_balance_stats_rand_scaling(stat_key, rand_value)
				new_effect.chance = rand_range(25, 100) as int
				new_effect.key_hash = stat_key
				new_effect.key = Keys.hash_to_string[stat_key]
				break
	elif type == 9:
		var character = capybara_get_character_from_id("character_lich")
		icon = character.icon
		upgrade_name = character.name
		upgrade_id = character.my_id
		for effect in character.effects:
			if effect.custom_key_hash == Keys.dmg_when_heal_hash:
				new_effect = effect.duplicate()
				var rand_value =  rand_range(100, 200) as int
				new_effect.value = _capybara_get_balance_stats_rand_scaling(stat_key, rand_value)
				new_effect.chance = rand_range(50, 100) as int
				new_effect.key_hash = stat_key
				new_effect.key = Keys.hash_to_string[stat_key]
				break
	elif type == 10:
		var item = get_item_from_id(Keys.generate_hash("item_cyberball"))
		icon = item.icon
		upgrade_name = item.name
		upgrade_id = item.my_id
		for effect in item.effects:
			if effect.custom_key_hash == Keys.dmg_when_death_hash:
				new_effect = effect.duplicate()
				var rand_value =  rand_range(100, 200) as int
				new_effect.value = _capybara_get_balance_stats_rand_scaling(stat_key, rand_value)
				new_effect.chance = rand_range(25, 100) as int
				new_effect.key_hash = stat_key
				new_effect.key = Keys.hash_to_string[stat_key]
				break
	elif type == 11:
		var item = get_item_from_id(Keys.generate_hash("item_tardigrade"))
		icon = item.icon
		upgrade_name = item.name
		upgrade_id = item.my_id
		for effect in item.effects:
			if effect.key_hash == Keys.hit_protection_hash:
				new_effect = effect.duplicate()
				break
	elif type == 12:
		var item = capybara_get_character_from_id("character_cp_exorcist_miko")
		icon = item.icon
		upgrade_name = item.name
		upgrade_id = item.my_id
		new_effect = Effect.new()
		new_effect.key = "capybara_bonus_curse_factor"
		new_effect.key_hash = Keys.generate_hash(new_effect.key)
		new_effect.value = rand_range(3,6) as int
		new_effect.text_key = "effect_capybara_bonus_curse_factor"
		new_effect.effect_sign = Sign.OVERRIDE
	elif type == 13:
		var character = capybara_get_character_from_id("character_cp_comet_cowboy")
		icon = character.icon
		upgrade_name = character.name
		upgrade_id = character.my_id
		for effect in character.effects:
			if effect.custom_key_hash == Keys.generate_hash("capybara_gain_stat_when_attack_killed_enemies"):
				new_effect = effect.duplicate()
				new_effect.value2 = rand_range(4, 8) as int
				break
	elif type == -1:
		var new_rand_stats = [Keys.xp_gain_hash, Keys.explosion_size_hash, Keys.explosion_size_hash]
		new_rand_stats.append_array(_capybara_get_upgrade_stat_keys())
		stat_key = Utils.get_rand_element(new_rand_stats)
		var rand_w = []
		var weapon = get_weapon_from_weapon_id(Keys.generate_hash("weapon_ghost_scepter"))
		for cp_weapon in weapons:
			if cp_weapon.weapon_id.begins_with("weapon_ghost"):
				rand_w.append(cp_weapon)
		var r_w = Utils.get_rand_element(rand_w)
		icon = r_w.icon
		upgrade_name = r_w.name
		upgrade_id = r_w.weapon_id
		for effect in weapon.effects:
			if effect is GainStatEveryKilledEnemiesEffect:
				new_effect = effect.duplicate()
				new_effect.stat = Keys.hash_to_string[stat_key]
				new_effect.stat_nb = 1
				var rand_value =  rand_range(100, 200) as int
				new_effect.value = _capybara_get_balance_stats_rand_scaling(stat_key, rand_value)
				break
	elif type == -2:
		var weapon = get_weapon_from_weapon_id(Keys.generate_hash("weapon_plank"))
		icon = weapon.icon
		upgrade_name = weapon.name
		upgrade_id = weapon.weapon_id
		for effect in weapon.effects:
			if effect is ExplodingEffect:
				new_effect = effect.duplicate()
				new_effect.scale = rand_range(0.5, 2.0)
				new_effect.chance = rand_range(0.25, 1.0)
				break
	elif type == -3:
		var weapon = get_weapon_from_weapon_id(Keys.generate_hash("weapon_lightning_shiv"))
		icon = weapon.icon
		upgrade_name = weapon.name
		upgrade_id = weapon.weapon_id
		for effect in weapon.effects:
			if effect is ProjectilesOnHitEffect:
				new_effect = capybara_projectiles_on_death.duplicate()
				new_effect.value = rand_range(1,4) as int
				new_effect.key = "capybara_projectiles_on_hit"
				new_effect.key_hash = Keys.generate_hash(new_effect.key)
				new_effect.text_key = "effect_capybara_projectiles_on_hit"
				if Utils.get_chance_success(0.5):
					new_effect.auto_target_enemy = true
				new_effect.weapon_stats = Utils.get_rand_element(_capybara_get_ranged_weapons()).stats.duplicate()
				var scaling = rand_range(50, 200) as int
				scaling = _capybara_get_balance_stats_rand_scaling(stat_key, scaling)/100.0
				var scaling_stats = [[stat_key, scaling]]
				new_effect.weapon_stats.scaling_stats = scaling_stats
				new_effect.weapon_stats.damage = 1
				break
	elif type == -4:
		var weapon = get_weapon_from_weapon_id(Keys.generate_hash("weapon_hiking_stick"))
		icon = weapon.icon
		upgrade_name = weapon.name
		upgrade_id = weapon.weapon_id
		for effect in weapon.effects:
			if effect.custom_key_hash == Keys.gain_stat_for_every_step_after_equip_hash and effect.key_hash != Keys.gold_hash:
				new_effect = effect.duplicate()
				new_effect.key_hash = stat_key
				new_effect.key = Keys.hash_to_string[stat_key]
				var rand_value = rand_range(50, 100) as int
				new_effect.value2 = _capybara_get_balance_stats_rand_scaling(stat_key, rand_value)
				break
	elif type == -5:
		var weapon = get_weapon_from_weapon_id(Keys.generate_hash("weapon_torch"))
		icon = weapon.icon
		upgrade_name = weapon.name
		upgrade_id = weapon.weapon_id
		for effect in weapon.effects:
			if effect is BurningEffect:
				new_effect = effect.duplicate()
				var new_burning_data = BurningData.new()
				new_burning_data = effect.burning_data.duplicate()
				new_burning_data.damage = rand_range(3.0, 10.0) as int
				new_burning_data.duration = rand_range(3.0, 15.0) as int
				new_burning_data.spread = rand_range(0.0, 5.0) as int
				var scaling = rand_range(200, 500) as int
				scaling = _capybara_get_balance_stats_rand_scaling(stat_key, scaling)/100.0
				var scaling_stats = [[stat_key, scaling]]
				new_burning_data.scaling_stats = scaling_stats
				new_effect.burning_data = new_burning_data
		
				
	return [new_effect, icon, upgrade_name, upgrade_id]

func _capybara_get_ranged_weapons() -> Array:
	var ranged_weapons = []
	for weapon in weapons:
		if weapon.stats is RangedWeaponStats:
			ranged_weapons.append(weapon)
	return ranged_weapons

func capybara_get_random_elements(capybara_source: Array, capybara_amount: int) -> Array:
	if capybara_source.empty() or capybara_amount <= 0:
		return []

	var capybara_pool: Array = capybara_source.duplicate()
	var capybara_result: Array = []
	capybara_pool.shuffle()

	var capybara_count: int = min(capybara_amount, capybara_pool.size())
	for capybara_index in range(capybara_count):
		capybara_result.append(capybara_pool[capybara_index])

	return capybara_result


func _capybara_create_item_chance_upgrades(player_index) -> Array:
	var capybara_player_items: Array = RunData.get_player_items(player_index)
	var capybara_owned_item_ids: Dictionary = {}
	var capybara_unique_item_pool: Array = []
	var capybara_upgrades: Array = []
	var capybara_chance_value: int = RunData.get_player_effect(Keys.generate_hash("capybara_replace_upgrades_with_limited_items"), player_index)
	var capybara_custom_key = "capybara_increase_the_chance_of_item"
	var capybara_custom_key_hash = Keys.generate_hash(capybara_custom_key)

	for capybara_owned_item in capybara_player_items:
		if capybara_owned_item != null and is_instance_valid(capybara_owned_item):
			capybara_owned_item_ids[capybara_owned_item.my_id_hash] = true

	for capybara_item in items:
		if capybara_item == null or not is_instance_valid(capybara_item) or not capybara_item is ItemData:
			continue
		if capybara_item.max_nb != 1 or capybara_owned_item_ids.has(capybara_item.my_id_hash) or not capybara_item.can_be_looted:
			continue
		if capybara_item.replaced_by is ItemData and capybara_owned_item_ids.has(capybara_item.replaced_by.my_id_hash):
			continue
		capybara_unique_item_pool.append(capybara_item)

	var capybara_selected_items: Array = capybara_get_random_elements(capybara_unique_item_pool, 4)
	for capybara_item in capybara_selected_items:
		var capybara_effect = Effect.new()
		capybara_effect.key = capybara_item.my_id
		capybara_effect.key_hash = capybara_item.my_id_hash
		capybara_effect.custom_key = capybara_custom_key
		capybara_effect.custom_key_hash = capybara_custom_key_hash
		capybara_effect.value = capybara_chance_value
		capybara_effect.text_key = "EFFECT_CAPYBARA_INCREASE_THE_CHANCE_OF_ITEM".to_lower()
		capybara_effect.storage_method = StorageMethod.KEY_VALUE
		capybara_effect.effect_sign = Sign.POSITIVE
		var n_effect = null
		var value_effects = RunData.get_player_effect(capybara_custom_key_hash, player_index)
		for effect in value_effects:
			if effect[0] == capybara_item.my_id_hash:
				n_effect = NullEffect.new()
				n_effect.key = capybara_item.my_id
				n_effect.key_hash = capybara_item.my_id_hash
				n_effect.value = effect[1]
				n_effect.text_key = "EFFECT_CAPYBARA_INCREASE_THE_CHANCE_OF_ITEM_SUM".to_lower()
				n_effect.storage_method = StorageMethod.SUM
				n_effect.effect_sign = Sign.POSITIVE
		
		var capybara_upgrade = UpgradeData.new()
		capybara_upgrade.my_id = "upgrade_cp_increase_item_chance_" + capybara_item.my_id
		capybara_upgrade.my_id_hash = Keys.generate_hash(capybara_upgrade.my_id)
		capybara_upgrade.upgrade_id = capybara_upgrade.my_id
		capybara_upgrade.upgrade_id_hash = capybara_upgrade.my_id_hash
		capybara_upgrade.name = capybara_item.name
		capybara_upgrade.icon = capybara_item.icon
		capybara_upgrade.tier = capybara_item.tier
		capybara_upgrade.value = 1
		if n_effect:
			capybara_upgrade.effects = [capybara_effect, n_effect]
		else:
			capybara_upgrade.effects = [capybara_effect]
		capybara_upgrades.append(capybara_upgrade)

	return capybara_upgrades

func _capybara_create_alloy_upgrades(tier:int) -> Array:
	var upgrades = []
	var item = get_item_from_id(Keys.generate_hash("item_capybara_crystal_alloy"))
	var icon = item.icon
	for key in _capybara_get_upgrade_stat_keys():
		var new_upgrade = UpgradeData.new()
		new_upgrade.my_id = "upgrade_cp_gain_" + Keys.hash_to_string[key]
		new_upgrade.my_id_hash = Keys.generate_hash("upgrade_cp_gain_" + Keys.hash_to_string[key])
		new_upgrade.icon = icon
		new_upgrade.name = "CP_CRYSTAL_ALLOY_PART"
		new_upgrade.tier = tier
		new_upgrade.upgrade_id = new_upgrade.my_id
		new_upgrade.upgrade_id_hash = new_upgrade.my_id_hash
		var new_effect = StatGainsModificationEffect.new()
		new_effect.key = "effect_increase_stat_gains"
		new_effect.key_hash = Keys.effect_increase_stat_gains_hash
		new_effect.value = (tier + 1) * 3
		new_effect.storage_method = StorageMethod.SUM
		new_effect.effect_sign = Sign.FROM_VALUE
		new_effect.stat_displayed = Keys.hash_to_string[key]
		new_effect.stats_modified = [Keys.hash_to_string[key]]
		new_effect.custom_key = "capybara_add_item"
		new_effect.custom_key_hash = Keys.generate_hash("capybara_add_item")
		new_upgrade.effects = [new_effect]
		upgrades.append(new_upgrade)
	return upgrades

func _capybara_get_balance_stats_rand_value(stat_key:int, rand_value:int) -> int:
	if stat_key == Keys.stat_harvesting_hash or stat_key == Keys.stat_luck_hash or stat_key == Keys.stat_percent_damage_hash or stat_key == Keys.stat_attack_speed_hash:
		return rand_value * 5
	elif stat_key == Keys.stat_range_hash or stat_key == Keys.xp_gain_hash:
		return rand_value * 15
	elif stat_key == Keys.number_of_enemies_hash:
		return rand_value * 10/3
	elif stat_key == Keys.stat_melee_damage_hash:
		return rand_value * 2
	elif stat_key == Keys.stat_max_hp_hash or stat_key == Keys.stat_speed_hash or stat_key == Keys.stat_crit_chance_hash or stat_key == Keys.stat_dodge_hash:
		return rand_value * 3
	return rand_value

func _capybara_get_balance_stats_rand_scaling(stat_key:int, rand_value:int) -> int:
	if stat_key == Keys.stat_harvesting_hash or stat_key == Keys.stat_luck_hash or stat_key == Keys.stat_percent_damage_hash or stat_key == Keys.stat_attack_speed_hash:
		return max(1, rand_value / 5) as int
	elif stat_key == Keys.stat_range_hash:
		return max(1, rand_value / 15) as int
	elif stat_key == Keys.number_of_enemies_hash:
		return max(1, rand_value * 3 / 10) as int
	elif stat_key == Keys.stat_melee_damage_hash:
		return max(rand_value / 2, 1) as int
	elif stat_key == Keys.stat_max_hp_hash or stat_key == Keys.stat_speed_hash or stat_key == Keys.stat_crit_chance_hash or stat_key == Keys.stat_dodge_hash:
		return max(rand_value/ 3, 1) as int
	return rand_value

func _get_rand_item_for_wave(wave: int, player_index: int, type: int, args: GetRandItemForWaveArgs) -> ItemParentData:
	var capybara_rolled_item: ItemParentData = ._get_rand_item_for_wave(wave, player_index, type, args)
	if capybara_rolled_item == null or type != TierData.ITEMS:
		return capybara_rolled_item

	var capybara_effect_hash = Keys.generate_hash("capybara_increase_the_chance_of_item")
	var capybara_chance_effects = RunData.get_player_effect(capybara_effect_hash, player_index)

	var capybara_owned_and_shop_items: Array = args.owned_and_shop_items if args.owned_and_shop_items is Array else []
	var capybara_limited_items: Dictionary = get_limited_items(capybara_owned_and_shop_items)

	for capybara_effect_data in capybara_chance_effects:

		var capybara_target_item: ItemData = get_element(items, int(capybara_effect_data[0]))
		if capybara_target_item == null:
			continue

		var capybara_is_excluded = false
		for capybara_excluded_data in args.excluded_items:
			if not (capybara_excluded_data is Array) or capybara_excluded_data.empty():
				continue
			var capybara_excluded_item = capybara_excluded_data[0]
			if capybara_excluded_item != null and capybara_excluded_item.my_id_hash == capybara_target_item.my_id_hash:
				capybara_is_excluded = true
				break
		if capybara_is_excluded:
			continue

		if capybara_target_item.max_nb != -1 and capybara_limited_items.has(capybara_target_item.my_id_hash):
			var capybara_owned_count: int = capybara_limited_items[capybara_target_item.my_id_hash][1]
			if capybara_owned_count >= capybara_target_item.max_nb:
				continue

		var capybara_chance = clamp(float(capybara_effect_data[1]) / 100.0, 0.0, 1.0)
		if Utils.get_chance_success(capybara_chance):
			return apply_item_effect_modifications(capybara_target_item, player_index)

	return capybara_rolled_item
