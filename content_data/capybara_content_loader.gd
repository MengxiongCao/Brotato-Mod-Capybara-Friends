class_name CapybaraContentLoader
extends Node

const LOG_NAME := "Dbear-Capybara:ContentLoader"
const MOD_RESOURCE_PREFIX := "res://mods-unpacked/Dbear-Capybara/"
const DLC_ONLY_SET_IDS := ["set_musical", "set_naval"]
const DLC_ONLY_STAT_KEYS := ["reroll_price", "stat_curse", "structure_percent_damage", "stat_structure_percent_damage", "structure_range", "stat_structure_range"]
const DLC_ONLY_EFFECT_MARKERS := [
	"bonus_current_health_damage",
	"bonus_damage_against_targets_above_hp",
	"bonus_damage_against_targets_below_hp",
	"bonus_non_elemental_damage_against_burning_targets",
	"bonus_weapon_class_damage_against_cursed_enemies",
	"break_on_hit",
	"charm_on_hit",
	"consumable_heal_over_time",
	"convert_bonus_gold",
	"crit_on_hitting_burning_target",
	"curse_locked_items",
	"cursed_starting_item",
	"decaying_stats_on_consumable",
	"decaying_stats_on_hit",
	"disable_item_locking",
	"duplicate_item",
	"explode_on_consumable_burning",
	"explode_on_overkill",
	"explode_when_below_hp",
	"extra_item_in_crate",
	"extra_loot_aliens",
	"gain_stat_for_every_step_after_equip",
	"gain_stat_when_attack_killed_enemies",
	"gain_stats_on_reroll",
	"gold_on_cursed_enemy_kill",
	"heal_on_kill",
	"increase_material_value",
	"increase_tier_on_reroll",
	"item_builder_turret_0",
	"item_fish_hook",
	"item_goldfish",
	"item_mirror",
	"item_pearl",
	"item_spyglass",
	"item_steals",
	"item_steals_spawns_random_elite",
	"knockback_aura",
	"level_upgrades_modifications",
	"lock_current_weapons",
	"loot_alien_chance",
	"loot_alien_speed",
	"max_turret_count",
	"modify_every_x_projectile",
	"poisoned_fruit",
	"reload_turrets_on_shoot",
	"reload_when_pickup_gold",
	"remove_shop_items",
	"reroll_price",
	"stats_on_fruit",
	"stronger_elites_on_kill",
	"stronger_loot_aliens_on_kill",
	"structure",
	"structure_percent_damage",
	"structure_range",
	"temp_consumable_stats_while_max",
	"weapon_class_naval",
	"weapon_harpoon_gun",
	"weapon_harpoon_gun_2",
]
const DLC_ONLY_EFFECT_SCRIPT_PATHS := [
	"res://effects/consumables/consumable_damage_effect.gd",
	"res://effects/items/builder_turret_effect.gd",
	"res://effects/items/builder_turret_upgrade_effect.gd",
	"res://effects/items/charm_effect.gd",
	"res://effects/items/effect_with_sub_effects.gd",
	"res://effects/items/item_exploding_and_burn_effect.gd",
	"res://effects/items/item_exploding_when_below_hp_effect.gd",
	"res://effects/items/swap_max_min_stat_effect.gd",
	"res://effects/items/weapon_type_bonus_effect.gd",
	"res://effects/weapons/null_charm_effect.gd",
	"res://effects/weapons/null_double_value_effect.gd",
	"res://effects/weapons/weapon_effect_with_sub_effect.gd",
	"res://effects/weapons/weapon_gain_stat_for_every_stat_effect.gd",
	"res://effects/weapons/weapon_percent_damage_effect.gd",
]

var _registered_paths: Array = []
var _registered_dlc_paths: Dictionary = {}
var _loaded_content: Dictionary = {}
var _dlc_dependency_cache: Dictionary = {}
var _dlc_effect_dependency_cache: Dictionary = {}
var _curse_dependency_cache: Dictionary = {}
var _logged_dlc_skips: Dictionary = {}
var _logged_content_skips: Dictionary = {}
var _added_resources: Dictionary = {}
var _added_starting_weapon_refs: Dictionary = {}
var _installed := false
var _installing := false


func register_data_path(path: String, requires_dlc: bool = false) -> void:
	if path == "":
		return
	if not _registered_paths.has(path):
		_registered_paths.append(path)
	if requires_dlc:
		_registered_dlc_paths[path] = true


func is_installed() -> bool:
	return _installed


func install_registered_data() -> bool:
	if _installing:
		return false

	_installing = true
	var was_installed := _installed
	var installed_any := false

	for path in _registered_paths:
		if not _should_load_data_path(path):
			continue
		var content_data = _load_content_data(path)
		if content_data == null:
			continue
		_install_content_data(content_data, path)
		installed_any = true

	_finalize_install()
	_installing = false
	_installed = _installed or installed_any

	if _installed and not was_installed and get_parent() != null and get_parent().has_method("_capybara_on_content_installed"):
		get_parent()._capybara_on_content_installed()

	return _installed


func refresh_runtime_state() -> void:
	_rebuild_lookup_caches()
	Utils.reset_stat_keys()

	if is_instance_valid(ChallengeService):
		ChallengeService.set_stat_challenges()

	if is_instance_valid(EffectBehaviorService):
		EffectBehaviorService.reset()

	if is_instance_valid(ProgressData) and ProgressData.items_unlocked is Array:
		ProgressData.add_unlocked_by_default()

	if is_instance_valid(ItemService) and ItemService._tiers_data is Array:
		ItemService.init_unlocked_pool()


func refresh_zones_after_dlc_reset() -> void:
	for path in _registered_paths:
		if not _should_load_data_path(path):
			continue
		var content_data = _load_content_data(path)
		if content_data == null:
			continue
		_install_zones(_get_array(content_data, "zones"), path)
		_install_groups_in_all_zones(_get_array(content_data, "groups_in_all_zones"))


func _load_content_data(path: String):
	if _loaded_content.has(path):
		return _loaded_content[path]

	if not ResourceLoader.exists(path):
		ModLoaderLog.error("Missing content data: " + path, LOG_NAME)
		return null

	var content_data = load(path)
	if content_data == null:
		ModLoaderLog.error("Failed to load content data: " + path, LOG_NAME)
		return null

	_loaded_content[path] = content_data
	return content_data


func _should_load_data_path(path: String) -> bool:
	var dlc_available := _is_dlc_available()
	if _registered_dlc_paths.has(path) and not dlc_available:
		_log_dlc_skip(path, false)
		return false
	return true


func _is_dlc_available() -> bool:
	var mod_main = get_parent()
	return is_instance_valid(mod_main) and mod_main.has_method("capybara_is_dlc_available") and mod_main.capybara_is_dlc_available()


func _resource_depends_on_dlc(path: String) -> bool:
	if _dlc_dependency_cache.has(path):
		return _dlc_dependency_cache[path]
	var result := _resource_depends_on_dlc_recursive(path, {})
	_dlc_dependency_cache[path] = result
	return result


func _resource_depends_on_dlc_recursive(path: String, visited: Dictionary) -> bool:
	if path.begins_with("res://dlcs/"):
		return true
	if _dlc_dependency_cache.has(path):
		return _dlc_dependency_cache[path]
	if path == "" or visited.has(path) or not ResourceLoader.exists(path):
		return false
	visited[path] = true
	for raw_dependency in ResourceLoader.get_dependencies(path):
		var dependency := str(raw_dependency)
		var type_separator := dependency.find("::")
		if type_separator >= 0:
			dependency = dependency.substr(0, type_separator)
		if not dependency.begins_with("res://dlcs/") and not dependency.begins_with(MOD_RESOURCE_PREFIX):
			continue
		if _resource_depends_on_dlc_recursive(dependency, visited):
			_dlc_dependency_cache[path] = true
			return true
	_dlc_dependency_cache[path] = false
	return false


func _log_dlc_skip(path: String, unexpected_dependency: bool) -> void:
	if _logged_dlc_skips.has(path):
		return
	_logged_dlc_skips[path] = true
	if unexpected_dependency:
		ModLoaderLog.error("Skipped base content with a disabled DLC dependency: " + path, LOG_NAME)
	else:
		ModLoaderLog.info("Skipped DLC content: " + path, LOG_NAME)


func _install_content_data(content_data, source_path: String) -> void:
	var characters = _get_array(content_data, "characters")
	var items = _filter_content_values(_get_array(content_data, "items"), "items", source_path)
	var weapon_data = _filter_weapons_and_characters(_get_array(content_data, "weapons"), _get_array(content_data, "weapons_characters"), source_path)
	var weapons = weapon_data[0]
	var weapons_characters = weapon_data[1]
	var sets = _filter_content_values(_get_array(content_data, "sets"), "sets", source_path)
	var stats = _filter_content_values(_get_array(content_data, "stats"), "stats", source_path)
	var upgrades = filter_dlc_only_upgrades(_filter_content_values(_get_array(content_data, "upgrades"), "upgrades", source_path), source_path)

	_sanitize_effect_owners(characters, "characters", source_path)
	_sanitize_effect_owners(items, "items", source_path)
	_sanitize_effect_owners(weapons, "weapons", source_path)
	_sanitize_effect_owners(upgrades, "upgrades", source_path)

	_append_unique_array("items", ItemService.items, items)
	_sanitize_weapon_dlc_content(weapons, source_path)
	_append_unique_array("weapons", ItemService.weapons, weapons)
	_sanitize_character_dlc_content(characters, source_path)
	_append_unique_array("characters", ItemService.characters, characters)
	_append_unique_array("sets", ItemService.sets, sets)
	_append_unique_array("upgrades", ItemService.upgrades, upgrades)
	_append_unique_array("consumables", ItemService.consumables, _get_array(content_data, "consumables"))
	_append_unique_array("elites", ItemService.elites, _get_array(content_data, "elites"))
	_append_unique_array("bosses", ItemService.bosses, _get_array(content_data, "bosses"))
	_append_unique_array("difficulties", ItemService.difficulties, _get_array(content_data, "difficulties"))
	_append_unique_array("effects", ItemService.effects, _get_array(content_data, "effects"))
	_append_unique_array("stats", ItemService.stats, stats)
	_append_unique_array("entities", ItemService.entities, _get_array(content_data, "entities"))
	_append_unique_array("icons", ItemService.icons, _get_array(content_data, "icons"))
	_append_unique_array("title_screen_backgrounds", ItemService.title_screen_backgrounds, _get_array(content_data, "title_screen_backgrounds"))
	_append_unique_array("background_colors", ItemService.background_colors, _get_array(content_data, "background_colors"))
	_append_unique_array("frames_element_level", ItemService.frames_element_level, _get_array(content_data, "frames_element_level"))

	var backgrounds_added = _append_unique_array("backgrounds", ItemService.backgrounds, _get_array(content_data, "backgrounds"))
	if backgrounds_added > 0:
		ItemService.emit_signal("backgrounds_updated")

	_install_zones(_get_array(content_data, "zones"), source_path)
	_append_unique_array("endless_groups", ZoneService.endless_groups, _get_array(content_data, "endless_groups"))
	_append_unique_array("endless_unit_groups", ZoneService.endless_unit_groups, _get_array(content_data, "endless_unit_groups"))
	_append_unique_array("extra_enemy_scenes", ZoneService.extra_enemy_scenes, _get_array(content_data, "extra_enemy_scenes"))
	_append_unique_array("bullets_hell", ZoneService.bullets_hell, _get_array(content_data, "bullets_hell"))
	_install_groups_in_all_zones(_get_array(content_data, "groups_in_all_zones"))

	_append_unique_array("challenges", ChallengeService.challenges, _get_array(content_data, "challenges"))
	_append_unique_array("scene_effect_behaviors", EffectBehaviorService.scene_effect_behaviors, _get_array(content_data, "scene_effect_behaviors"))
	_append_unique_array("enemy_effect_behaviors", EffectBehaviorService.enemy_effect_behaviors, _get_array(content_data, "enemy_effect_behaviors"))
	_append_unique_array("player_effect_behaviors", EffectBehaviorService.player_effect_behaviors, _get_array(content_data, "player_effect_behaviors"))

	DebugService.debug_items = DebugService.debug_items.duplicate()
	DebugService.debug_weapons = DebugService.debug_weapons.duplicate()
	DebugService.debug_enemies = DebugService.debug_enemies.duplicate()
	_append_unique_array("debug_items", DebugService.debug_items, _get_array(content_data, "debug_items"))
	_append_unique_array("debug_weapons", DebugService.debug_weapons, _get_array(content_data, "debug_weapons"))
	_append_unique_array("debug_enemies", DebugService.debug_enemies, _get_array(content_data, "debug_enemies"))

	if is_instance_valid(MusicManager):
		_append_unique_array("music_tracks", MusicManager.new_tracks, _get_array(content_data, "music_tracks"))

	_install_translations(_get_array(content_data, "translations"))
	_merge_dictionary(Text.keys_needing_operator, _get_dictionary(content_data, "translation_keys_needing_operator"))
	_merge_dictionary(Text.keys_needing_percent, _get_dictionary(content_data, "translation_keys_needing_percent"))
	_install_tracking_data(content_data)
	_install_serialization_keys(content_data)
	_apply_weapons_characters(weapons, weapons_characters)
	_apply_weapon_starting_character_ids(weapons)


func _filter_content_values(values: Array, category: String, source_path: String) -> Array:
	if _is_dlc_available():
		return values
	var filtered: Array = []
	for value in values:
		if _is_content_value_allowed(value, category, source_path):
			filtered.append(value)
	return filtered


func filter_dlc_only_upgrades(upgrades: Array, source_path: String = "runtime upgrades") -> Array:
	if _is_dlc_available():
		return upgrades
	var filtered_upgrades: Array = []
	for upgrade in upgrades:
		if not _is_valid_object(upgrade) or not _has_property(upgrade, "effects"):
			filtered_upgrades.append(upgrade)
			continue
		var upgrade_effects = upgrade.get("effects")
		if not upgrade_effects is Array:
			filtered_upgrades.append(upgrade)
			continue
		var valid_effects: Array = []
		for effect in upgrade_effects:
			if _is_valid_object(effect) and not _is_dlc_only_effect(effect, {}):
				valid_effects.append(effect)
			else:
				_log_content_skip(effect, "upgrade_effects", source_path, "DLC-only effect or stat")
		if not upgrade_effects.empty() and valid_effects.empty():
			_log_content_skip(upgrade, "upgrades", source_path, "all effects require DLC stats")
			continue
		if valid_effects.size() != upgrade_effects.size():
			upgrade.set("effects", valid_effects)
		filtered_upgrades.append(upgrade)
	return filtered_upgrades


func _sanitize_character_dlc_content(characters: Array, source_path: String) -> void:
	if _is_dlc_available():
		return
	for character in characters:
		if not _is_valid_object(character):
			continue
		_filter_character_array_property(character, "effects", "character_effects", source_path)
		_filter_character_array_property(character, "starting_items", "character_starting_items", source_path)
		_filter_character_array_property(character, "starting_weapons", "character_starting_weapons", source_path)
		_filter_character_array_property(character, "tags", "character_tags", source_path)
		_filter_character_array_property(character, "wanted_tags", "character_wanted_tags", source_path)
		_filter_character_array_property(character, "banned_item_groups", "character_banned_item_groups", source_path)
		_filter_character_array_property(character, "banned_items", "character_banned_items", source_path)
		_filter_character_array_property(character, "banned_upgrades", "character_banned_upgrades", source_path)


func _sanitize_weapon_dlc_content(weapons: Array, source_path: String) -> void:
	if _is_dlc_available():
		return
	for weapon in weapons:
		if not _is_valid_object(weapon) or not _has_property(weapon, "sets"):
			continue
		var weapon_sets = weapon.get("sets")
		if not weapon_sets is Array:
			continue
		var filtered_sets: Array = []
		for weapon_set in weapon_sets:
			if _is_content_value_allowed(weapon_set, "weapon_sets", source_path):
				filtered_sets.append(weapon_set)
		if filtered_sets.size() != weapon_sets.size():
			weapon.set("sets", filtered_sets)


func _filter_character_array_property(character, property_name: String, category: String, source_path: String) -> void:
	if not _has_property(character, property_name):
		return
	var values = character.get(property_name)
	if not values is Array:
		return
	var filtered_values: Array = []
	for value in values:
		var value_allowed := _is_content_value_allowed(value, category, source_path)
		if value_allowed and property_name == "effects" and _is_dlc_only_effect(value, {}):
			_log_content_skip(value, category, source_path, "DLC-only effect")
			value_allowed = false
		if value_allowed:
			filtered_values.append(value)
	if filtered_values.size() != values.size():
		character.set(property_name, filtered_values)


func _is_dlc_only_effect(value, visited: Dictionary) -> bool:
	if value == null:
		return false
	if value is String:
		return DLC_ONLY_STAT_KEYS.has(value)
	if value is int:
		return is_instance_valid(Keys) and Keys.hash_to_string.has(value) and DLC_ONLY_STAT_KEYS.has(str(Keys.hash_to_string[value]))
	if value is Array:
		for child in value:
			if _is_dlc_only_effect(child, visited):
				return true
		return false
	if value is Dictionary:
		for child in value.values():
			if _is_dlc_only_effect(child, visited):
				return true
		return false
	if not value is Resource or not is_instance_valid(value):
		return false

	var cache_key = value.resource_path if value.resource_path != "" else "instance:" + str(value.get_instance_id())
	if _dlc_effect_dependency_cache.has(cache_key):
		return _dlc_effect_dependency_cache[cache_key]
	if visited.has(value.get_instance_id()):
		return false
	visited[value.get_instance_id()] = true

	var value_script = value.get_script()
	if value_script is Script and DLC_ONLY_EFFECT_SCRIPT_PATHS.has(value_script.resource_path):
		_dlc_effect_dependency_cache[cache_key] = true
		return true

	for marker_property in ["key", "key2", "custom_key"]:
		if _has_property(value, marker_property) and DLC_ONLY_EFFECT_MARKERS.has(str(value.get(marker_property))):
			_dlc_effect_dependency_cache[cache_key] = true
			return true
	if _has_property(value, "set_id") and DLC_ONLY_SET_IDS.has(str(value.get("set_id"))):
		_dlc_effect_dependency_cache[cache_key] = true
		return true

	for property in value.get_property_list():
		if (int(property.get("usage", 0)) & PROPERTY_USAGE_STORAGE) == 0:
			continue
		var property_name := str(property.get("name", ""))
		if property_name == "script" or property_name == "key" or property_name == "key2" or property_name == "custom_key":
			continue
		var property_value = value.get(property_name)
		if _is_dlc_only_effect(property_value, visited):
			_dlc_effect_dependency_cache[cache_key] = true
			return true

	_dlc_effect_dependency_cache[cache_key] = false
	return false


func _filter_weapons_and_characters(weapons: Array, weapons_characters: Array, source_path: String) -> Array:
	if _is_dlc_available():
		return [weapons, weapons_characters]
	var filtered_weapons: Array = []
	var filtered_characters: Array = []
	for index in weapons.size():
		var weapon = weapons[index]
		if not _is_content_value_allowed(weapon, "weapons", source_path):
			continue
		filtered_weapons.append(weapon)
		var starting_characters = weapons_characters[index] if index < weapons_characters.size() else []
		filtered_characters.append(_filter_content_values(starting_characters, "weapon_starting_characters", source_path) if starting_characters is Array else [])
	return [filtered_weapons, filtered_characters]


func _is_content_value_allowed(value, category: String, source_path: String) -> bool:
	if _is_dlc_available() or not _is_valid_value(value):
		return true
	if category == "stats" and _is_dlc_only_stat(value):
		_log_content_skip(value, category, source_path, "DLC-only stat")
		return false
	if (category == "sets" or category == "weapon_sets") and _is_dlc_only_set(value):
		_log_content_skip(value, category, source_path, "DLC-only weapon set")
		return false
	if value is Resource and value.resource_path != "" and _resource_depends_on_dlc(value.resource_path):
		_log_content_skip(value, category, source_path, "DLC resource dependency")
		return false
	if _is_curse_related_value(value, {}, true):
		_log_content_skip(value, category, source_path, "curse-related content")
		return false
	return true


func _is_dlc_only_set(value) -> bool:
	return _is_valid_object(value) and _has_property(value, "my_id") and DLC_ONLY_SET_IDS.has(str(value.get("my_id")))


func _is_dlc_only_stat(value) -> bool:
	return _is_valid_object(value) and _has_property(value, "stat_name") and DLC_ONLY_STAT_KEYS.has(str(value.get("stat_name")))


func _is_curse_related_value(value, visited: Dictionary, is_root: bool = false) -> bool:
	if value == null:
		return false
	if value is String:
		return _contains_curse_marker(value)
	if value is int:
		return is_instance_valid(Keys) and Keys.hash_to_string.has(value) and _contains_curse_marker(str(Keys.hash_to_string[value]))
	if value is Array:
		for child in value:
			if _is_curse_related_value(child, visited):
				return true
		return false
	if value is Dictionary:
		for key in value:
			if _is_curse_related_value(key, visited) or _is_curse_related_value(value[key], visited):
				return true
		return false
	if not value is Resource or not is_instance_valid(value):
		return false
	if value is Script:
		return false
	if _is_presentation_resource(value):
		return is_root and value.resource_path != "" and _contains_curse_marker(value.resource_path)

	var cache_key = value.resource_path if value.resource_path != "" else "instance:" + str(value.get_instance_id())
	if _curse_dependency_cache.has(cache_key):
		return _curse_dependency_cache[cache_key]
	if visited.has(value.get_instance_id()):
		return false
	visited[value.get_instance_id()] = true

	if value.resource_path != "" and _contains_curse_marker(value.resource_path):
		_curse_dependency_cache[cache_key] = true
		return true

	for property in value.get_property_list():
		if (int(property.get("usage", 0)) & PROPERTY_USAGE_STORAGE) == 0:
			continue
		var property_name := str(property.get("name", ""))
		if property_name == "script":
			continue
		var property_value = value.get(property_name)
		if property_name == "is_cursed":
			if property_value == true:
				_curse_dependency_cache[cache_key] = true
				return true
			continue
		if property_name == "curse_factor":
			if (property_value is int or property_value is float) and float(property_value) > 0.0:
				_curse_dependency_cache[cache_key] = true
				return true
			continue
		if _is_curse_related_value(property_value, visited):
			_curse_dependency_cache[cache_key] = true
			return true

	return false


func _contains_curse_marker(value: String) -> bool:
	var normalized := value.to_lower()
	return normalized.find("curse") >= 0 or normalized.find("诅咒") >= 0


func _is_presentation_resource(value: Resource) -> bool:
	return value is PackedScene or value is Texture or value is AudioStream or value is Material or value is Shader or value is Gradient or value is Curve or value is Animation or value is Font or value is Mesh


func _log_content_skip(value, category: String, source_path: String, reason: String) -> void:
	var identity := _resource_identity(value)
	var log_key := reason + "::" + category + "::" + identity
	if _logged_content_skips.has(log_key):
		return
	_logged_content_skips[log_key] = true
	ModLoaderLog.info("Skipped %s/%s from %s because it contains %s" % [category, identity, source_path, reason], LOG_NAME)


func _finalize_install() -> void:
	for stat in ItemService.stats:
		if _is_valid_object(stat) and stat.has_method("generate_hashes"):
			stat.generate_hashes()

	Utils.reset_stat_keys()
	_rebuild_lookup_caches()


func _sanitize_effect_owners(resources: Array, category: String, source_path: String) -> void:
	for resource in resources:
		if not _is_valid_object(resource) or not _has_property(resource, "effects"):
			continue
		var effects = resource.get("effects")
		if not effects is Array:
			continue
		var valid_effects: Array = []
		for effect in effects:
			if not _is_valid_object(effect):
				ModLoaderLog.error("Removed null Effect from %s/%s in %s" % [category, _resource_identity(resource), source_path], LOG_NAME)
				continue
			if not _is_dlc_available() and _is_dlc_only_effect(effect, {}):
				_log_content_skip(effect, category + "_effects", source_path, "DLC-only effect or stat")
				continue
			valid_effects.append(effect)
		if valid_effects.size() != effects.size():
			resource.set("effects", valid_effects)


func _install_zones(zones: Array, source_path: String) -> void:
	for zone in zones:
		if not _is_valid_object(zone):
			ModLoaderLog.error("Skipped null zone in " + source_path, LOG_NAME)
			continue
		if not _is_content_value_allowed(zone, "zones", source_path):
			continue
		if not _has_property(zone, "my_id"):
			ModLoaderLog.error("Skipped zone without my_id in " + source_path, LOG_NAME)
			continue

		var zone_id = int(zone.get("my_id"))
		var current_index := -1
		for index in ZoneService.zones.size():
			if _same_resource(ZoneService.zones[index], zone):
				current_index = index
				break
		if current_index == zone_id:
			continue
		if current_index >= 0:
			ZoneService.zones.remove(current_index)
		if zone_id < ZoneService.zones.size():
			var existing_zone = ZoneService.zones[zone_id]
			if _same_resource(existing_zone, zone):
				continue
			ModLoaderLog.error("Zone id %d is already occupied; skipped %s" % [zone_id, _resource_identity(zone)], LOG_NAME)
			continue
		if zone_id > ZoneService.zones.size():
			ModLoaderLog.error("Zone id %d must equal the next array index %d; skipped %s" % [zone_id, ZoneService.zones.size(), _resource_identity(zone)], LOG_NAME)
			continue

		ZoneService.zones.append(zone)
		_record_added("zones", zone)


func _install_groups_in_all_zones(groups: Array) -> void:
	if groups.empty():
		return
	for zone in ZoneService.zones:
		if not _is_valid_object(zone) or not _has_property(zone, "groups_data_in_all_waves"):
			continue
		var zone_groups = zone.get("groups_data_in_all_waves")
		if zone_groups is Array:
			_append_unique_array("groups_in_all_zones", zone_groups, groups)


func _apply_weapons_characters(weapons: Array, weapons_characters: Array) -> void:
	for index in weapons_characters.size():
		if index >= weapons.size():
			break
		var weapon = weapons[index]
		var characters = weapons_characters[index]
		if not _is_valid_object(weapon) or not characters is Array:
			continue
		for character in characters:
			_add_starting_weapon(character, weapon)


func _apply_weapon_starting_character_ids(weapons: Array) -> void:
	for weapon in weapons:
		if not _is_valid_object(weapon) or not _has_property(weapon, "add_to_chars_as_starting"):
			continue
		var character_ids = weapon.get("add_to_chars_as_starting")
		if not character_ids is Array:
			continue
		for character_id in character_ids:
			var character = ItemService.get_element_safe(ItemService.characters, str(character_id))
			_add_starting_weapon(character, weapon)


func _add_starting_weapon(character, weapon) -> void:
	if not _is_valid_object(character) or not _is_valid_object(weapon):
		return
	if not character.starting_weapons.has(weapon):
		character.starting_weapons.append(weapon)
		_added_starting_weapon_refs[_resource_identity(character) + "::" + _resource_identity(weapon)] = [character, weapon]


func _install_translations(translations: Array) -> void:
	for translation in translations:
		if not _is_valid_object(translation):
			continue
		var translation_was_added := false
		for existing_translation in _added_resources.get("translations", []):
			if _same_resource(existing_translation, translation):
				translation_was_added = true
				break
		if translation_was_added:
			continue
		TranslationServer.add_translation(translation)
		_record_added("translations", translation)


func _install_tracking_data(content_data) -> void:
	var tracked_items = _convert_dictionary_keys_to_hash(_get_dictionary(content_data, "tracked_items"))
	var tracked_effects = _convert_dictionary_keys_to_hash(_get_dictionary(content_data, "tracked_effects"))
	_merge_dictionary(RunData.init_tracked_items, tracked_items)

	var tracked_effects_target = RunData.get("ncl_init_tracked_effects") if _has_property(RunData, "ncl_init_tracked_effects") else null
	if tracked_effects_target is Dictionary:
		_merge_dictionary(tracked_effects_target, tracked_effects)
	else:
		_merge_dictionary(RunData.init_tracked_items, tracked_effects)


func _install_serialization_keys(content_data) -> void:
	_append_unique_array("primary_stats_list", RunData.primary_stats_list, _convert_strings_to_hashes(_get_array(content_data, "primary_stats_list")))
	_append_unique_array("effect_keys_full_serialization", RunData.effect_keys_full_serialization, _convert_strings_to_hashes(_get_array(content_data, "effect_keys_full_serialization")))
	_append_unique_array("effect_keys_with_weapon_stats", RunData.effect_keys_with_weapon_stats, _convert_strings_to_hashes(_get_array(content_data, "effect_keys_with_weapon_stats")))

	var quiet_stat_hashes = _convert_strings_to_hashes(_get_array(content_data, "quiet_stat_keys"))
	if not quiet_stat_hashes.empty() and Utils.has_method("ncl_register_quiet_stat_keys"):
		Utils.ncl_register_quiet_stat_keys(quiet_stat_hashes)


func _append_unique_array(category: String, target: Array, values: Array) -> int:
	var added := 0
	for value in values:
		if not _is_valid_value(value):
			ModLoaderLog.error("Skipped null resource in category: " + category, LOG_NAME)
			continue
		if category != "characters" and not _is_content_value_allowed(value, category, "runtime content"):
			continue
		var already_exists := false
		for existing in target:
			if _same_resource(existing, value):
				already_exists = true
				break
		if already_exists:
			continue
		target.append(value)
		_record_added(category, value)
		added += 1
	return added


func _record_added(category: String, value) -> void:
	if not _added_resources.has(category):
		_added_resources[category] = []
	_added_resources[category].append(value)


func _same_resource(left, right) -> bool:
	if left == right:
		return true
	var left_identity = _resource_identity(left)
	var right_identity = _resource_identity(right)
	return left_identity != "" and left_identity == right_identity


func _resource_identity(value) -> String:
	if not _is_valid_value(value):
		return ""
	if _has_property(value, "my_id"):
		var my_id = value.get("my_id")
		if not my_id is String or not my_id.empty():
			return "my_id:" + str(my_id)
	if _has_property(value, "stat_name"):
		var stat_name = value.get("stat_name")
		if not stat_name is String or not stat_name.empty():
			return "stat_name:" + str(stat_name)
	if value is Resource and value.resource_path != "":
		return "path:" + value.resource_path
	if value is Object:
		return "instance:" + str(value.get_instance_id())
	return "value:" + str(value)


func _prepare_resource(value) -> void:
	if not _is_valid_object(value):
		return
	if value.has_method("_generate_hashes"):
		value._generate_hashes()
	elif value.has_method("generate_hashes"):
		value.generate_hashes()


func _rebuild_lookup_caches() -> void:
	if not is_instance_valid(ItemService):
		return
	ItemService._item_id_lookup = {}
	ItemService._weapon_id_lookup = {}
	for category in [ItemService.items, ItemService.weapons, ItemService.characters, ItemService.upgrades, ItemService.consumables, ItemService.sets, ItemService.difficulties, ItemService.entities]:
		for resource in category:
			_prepare_resource(resource)


func _merge_dictionary(target: Dictionary, values: Dictionary) -> void:
	for key in values:
		if not target.has(key):
			target[key] = values[key]


func _convert_dictionary_keys_to_hash(values: Dictionary) -> Dictionary:
	var converted: Dictionary = {}
	for key in values:
		var converted_key = Keys.generate_hash(key) if key is String else key
		converted[converted_key] = values[key]
	return converted


func _convert_strings_to_hashes(values: Array) -> Array:
	var converted: Array = []
	for value in values:
		var converted_value = Keys.generate_hash(value) if value is String else value
		if not converted.has(converted_value):
			converted.append(converted_value)
	return converted


func _get_array(content_data, property_name: String) -> Array:
	if not _has_property(content_data, property_name):
		return []
	var value = content_data.get(property_name)
	return value if value is Array else []


func _get_dictionary(content_data, property_name: String) -> Dictionary:
	if not _has_property(content_data, property_name):
		return {}
	var value = content_data.get(property_name)
	return value if value is Dictionary else {}


func _has_property(value, property_name: String) -> bool:
	if not _is_valid_object(value):
		return false
	for property in value.get_property_list():
		if property.get("name", "") == property_name:
			return true
	return false


func _is_valid_object(value) -> bool:
	return value != null and value is Object and is_instance_valid(value)


func _is_valid_value(value) -> bool:
	if value == null:
		return false
	if value is Object:
		return is_instance_valid(value)
	return true
