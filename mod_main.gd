extends Node

const MOD_DIR := "Dbear-Capybara/"
const LOG_NAME := "Dbear-Capybara"

var mod_base_dir := ""
var is_mod_initialized := false

# 测试开关：改为 true 后，即使本机已经安装 DLC，也会让 Dbear 按未安装 DLC 处理。
const CAPYBARA_TEST_FORCE_NO_DLC := false
const CAPYBARA_DLC_ID := "abyssal_terrors"
const CAPYBARA_DLC_DATA_PATH := "res://dlcs/dlc_1/dlc_data.tres"

# 内容数据
const CONTENT_DATA_PATHS = [
	"res://mods-unpacked/Dbear-Capybara/content_data/content_data_weapon_characters.tres",
	"res://mods-unpacked/Dbear-Capybara/content_data/content_data.tres",
	"res://mods-unpacked/Dbear-Capybara/content_data/content_data_entities_and_effects.tres",
]

const DLC_CONTENT_DATA_PATHS = [
	"res://mods-unpacked/Dbear-Capybara/content_data/content_data_dlc_1.tres",
]

const CONTENT_LOADER_SCRIPT = "res://mods-unpacked/Dbear-Capybara/content_data/capybara_content_loader.gd"

const DLC_EXTENSIONS = [
	"res://mods-unpacked/Dbear-Capybara/extensions/dlc_1_data.gd",
	"res://mods-unpacked/Dbear-Capybara/extensions/for_every_step_effect_behavior.gd",
	"res://mods-unpacked/Dbear-Capybara/extensions/enemy_effect_behaviour/charm_enemy_effect_behaviour_mod.gd",
	"res://mods-unpacked/Dbear-Capybara/extensions/enemy_effect_behaviour/curse_enemy_effect_behavior.gd",
]

const CAPYBARA_DUPLICATE_PARENT_SCRIPT_PATHS = [
	"res://singletons/player_run_data.gd",
	"res://dlcs/dlc_1/dlc_1_data.gd",
	"res://items/global/effect.gd",
	"res://items/global/item_parent_data.gd",
	"res://items/global/weapon_data.gd",
]

const CAPYBARA_GMO_EFFECT_EXTENSION_REL_PATH = "GAFF-GMO3/extensions/items/global/effect.gd"

# 翻译
const TRANSLATION_PATHS := [
	"translations/trans.en.translation",
	"translations/trans.zh_Hans_CN.translation"
]

# 扩展脚本
const EXTENSION_SCRIPTS := [
	"extensions/main_for_mod.gd",
	"extensions/player_mod.gd",
	"extensions/weapon_container_mod.gd",
	"extensions/character_panel_ui_mod.gd",
	"extensions/player_run_data_mod.gd",
	"extensions/service/item_service_mod.gd",
	"extensions/floating_text_for_mod.gd",
	"extensions/utils_mod.gd",
	"extensions/progress_data_mod.gd",
	"extensions/run_data_mod.gd",
	"extensions/melee_weapon_shoot_mod.gd",
	"extensions/weapon_mod.gd",
	"extensions/service/zone_service_mod.gd",
	"extensions/service/entity_service_mod.gd",
	"extensions/turret_mod.gd",
	"extensions/service/weapon_service_mod.gd",
	"extensions/linked_stats_mod.gd",
	"extensions/upgrades_ui_player_container_mod.gd",
	"extensions/shop_item_mod.gd",
	"extensions/neutral_mod.gd",
	"extensions/burning_particles_mod.gd",
	"extensions/enemy_mod.gd",
	"extensions/item_description_mod.gd",
	"extensions/effect_line_mod.gd",
	"extensions/shop/item_popup.gd",
	"extensions/base_tools/text.gd",
	"extensions/ui_containers/stats_container_mod.gd",
	"extensions/service/effect_behaviours_service.gd",
	"extensions/ui_containers/inventory_element.gd",
	"extensions/ui_containers/icon_panel.gd",
	"extensions/ui_containers/inventory.gd",
	"extensions/shop/base_shop.gd",
	"extensions/ui_containers/ui_upgrade_to_process_list.gd",
	"extensions/ui_containers/upgrade_ui.gd",
	"extensions/ui_containers/shop_items_container.gd",
	"extensions/ui_containers/run_options/run_options_panel.gd",
	"extensions/ranged_weapon_shooting_behaviour.gd",
	"extensions/floating_text_manager_shop.gd",
#	"extensions/pet.gd",
]

# ==============================================
# 初始化
# ==============================================
func _init():
	ModLoaderLog.info("Init start", LOG_NAME)
	if CAPYBARA_TEST_FORCE_NO_DLC:
		ModLoaderLog.info("CAPYBARA_TEST_FORCE_NO_DLC is enabled", LOG_NAME)

	mod_base_dir = ModLoaderMod.get_unpacked_dir() + MOD_DIR

#	_capybara_remove_conflicting_gmo_effect_extension()
	_capybara_cache_duplicate_parent_scripts()

	_install_all_extension_scripts()
	_capybara_setup_content_loader()
	_add_capybara_translation_resources()

	ModLoaderLog.info("Init finished", LOG_NAME)


func _capybara_remove_conflicting_gmo_effect_extension() -> void:
	if not is_instance_valid(ModLoaderStore):
		return
	var extension_path = ModLoaderMod.get_unpacked_dir() + CAPYBARA_GMO_EFFECT_EXTENSION_REL_PATH
	var extension_removed = false
	while ModLoaderStore.script_extensions.has(extension_path):
		ModLoaderStore.script_extensions.erase(extension_path)
		extension_removed = true
	if ModLoaderStore.saved_extension_paths.has("GAFF-GMO3"):
		while ModLoaderStore.saved_extension_paths["GAFF-GMO3"].has(extension_path):
			ModLoaderStore.saved_extension_paths["GAFF-GMO3"].erase(extension_path)
	if extension_removed:
		ModLoaderLog.info("Disabled conflicting GMO Effect extension: %s" % extension_path, LOG_NAME)


func _capybara_cache_duplicate_parent_scripts() -> void:
	if not is_instance_valid(ModLoaderStore):
		return
	for parent_script_path in CAPYBARA_DUPLICATE_PARENT_SCRIPT_PATHS:
		if ModLoaderStore.saved_scripts.has(parent_script_path):
			continue
		if not ResourceLoader.exists(parent_script_path):
			continue
		var parent_script = load(parent_script_path)
		if parent_script == null:
			continue
		ModLoaderStore.saved_scripts[parent_script_path] = [parent_script]
		ModLoaderLog.info("Cached duplicate-safe parent script: %s" % parent_script_path, LOG_NAME)


func _install_all_extension_scripts():
	for script_rel in EXTENSION_SCRIPTS:
		var full_path = mod_base_dir + script_rel
		if ResourceLoader.exists(full_path):
			ModLoaderMod.install_script_extension(full_path)
			ModLoaderLog.info("Installed: " + script_rel, LOG_NAME)
		else:
			ModLoaderLog.error("Missing script: " + full_path, LOG_NAME)


func _capybara_setup_content_loader() -> void:
	var existing_loader = get_node_or_null("CapybaraContentLoader")
	if is_instance_valid(existing_loader):
		return
	var loader_script = load(CONTENT_LOADER_SCRIPT)
	if loader_script == null:
		ModLoaderLog.error("Failed to load CapybaraContentLoader", LOG_NAME)
		return
	var loader = loader_script.new()
	loader.name = "CapybaraContentLoader"
	add_child(loader)
	for path in CONTENT_DATA_PATHS:
		loader.register_data_path(path, false)
	for path in DLC_CONTENT_DATA_PATHS:
		loader.register_data_path(path, true)


func capybara_is_forcing_no_dlc() -> bool:
	return CAPYBARA_TEST_FORCE_NO_DLC


func capybara_should_load_dlc_files() -> bool:
	if CAPYBARA_TEST_FORCE_NO_DLC or not ResourceLoader.exists(CAPYBARA_DLC_DATA_PATH):
		return false
	if is_instance_valid(Platform) and Platform.has_method("is_dlc_owned"):
		return Platform.is_dlc_owned(CAPYBARA_DLC_ID)
	return true


func capybara_is_dlc_available() -> bool:
	if not capybara_should_load_dlc_files():
		return false
	if not is_instance_valid(ProgressData) or not ProgressData.has_method("is_dlc_available"):
		return false
	return ProgressData.is_dlc_available(CAPYBARA_DLC_ID)


func capybara_install_dlc_extensions() -> bool:
	if not capybara_should_load_dlc_files():
		return false
	_capybara_cache_duplicate_parent_scripts()
	for extension_path in DLC_EXTENSIONS:
		if not ResourceLoader.exists(extension_path):
			ModLoaderLog.error("Missing DLC extension: " + extension_path, LOG_NAME)
			return false
		ModLoaderMod.install_script_extension(extension_path)
		ModLoaderLog.info("Installed DLC extension: " + extension_path, LOG_NAME)
	return true


# ==============================================
# Ready
# ==============================================
func _ready():
	ModLoaderLog.info("Starting setup...", LOG_NAME)
	var content_loader = get_node_or_null("CapybaraContentLoader")
	if not is_instance_valid(content_loader):
		ModLoaderLog.error("CapybaraContentLoader node is missing", LOG_NAME)
		return
	call_deferred("_capybara_finalize_runtime_content")


func _capybara_on_content_installed() -> void:
	_capybara_character_starting_items()
	_capybara_character_starting_with_all_set_weapon()
	is_mod_initialized = true
	ModLoaderLog.info("All Capybara content registered", LOG_NAME)


func _capybara_finalize_runtime_content() -> void:
	var content_loader = get_node_or_null("CapybaraContentLoader")
	if is_instance_valid(content_loader):
		if not content_loader.is_installed():
			content_loader.install_registered_data()
		content_loader.refresh_runtime_state()

# ==============================================
# 翻译
# ==============================================
func _add_capybara_translation_resources() -> void:
	for rel_path in TRANSLATION_PATHS:
		var full_path = mod_base_dir + rel_path
		var file = File.new()
		if file.file_exists(full_path):
			ModLoaderMod.add_translation(full_path)
			ModLoaderLog.info("Loaded translation: " + rel_path, LOG_NAME)

const CAPYBARA_STARTING_ITEMS = [
	"res://mods-unpacked/Dbear-Capybara/contents/items/unicorn/unicorn_data.tres",
	"res://mods-unpacked/Dbear-Capybara/contents/items/dark_fish/dark_fish_data.tres",
	"res://mods-unpacked/Dbear-Capybara/contents/items/strange_bottle/swampman_data.tres",
	"res://mods-unpacked/Dbear-Capybara/contents/items/soul_wheat/soul_wheat_data.tres",
#	"res://mods-unpacked/Dbear-Capybara/contents/items/crystal_hawk/crystal_hawk_data.tres",

]
# ==============================================
# 开局物品
# ==============================================
func _capybara_character_starting_items() -> void:
	for character in ItemService.characters:
		if character == null or not is_instance_valid(character):
			continue
		if character.my_id == "character_beast_master":
			for item_path in CAPYBARA_STARTING_ITEMS:
				var data = null
				for registered_item in ItemService.items:
					if registered_item != null and is_instance_valid(registered_item) and registered_item.resource_path == item_path:
						data = registered_item
						break
				if data != null and not character.starting_items.has(data):
					character.starting_items.push_back(data)

func _capybara_character_starting_with_all_set_weapon() -> void:
	var weapon_sets= []
	var characters_to_process = []
	var characters_to_process_all_weapons = []
	for character in ItemService.characters:
		if character == null or not is_instance_valid(character):
			continue
		for effect in character.effects:
			if effect == null or not is_instance_valid(effect):
				continue
			if effect.custom_key == "capybara_starting_with_all_legendary":
				if effect.key == "all_weapons":
					characters_to_process_all_weapons.append(character)
					break
				weapon_sets.append(effect.key.replace("weapon_class_","set_"))
				characters_to_process.append(character)
				break
	for weapon in ItemService.weapons:
		if weapon == null or not is_instance_valid(weapon):
			continue
		for set in weapon.sets:
			if set == null or not is_instance_valid(set):
				continue
			for i in weapon_sets.size():
				if set.my_id == weapon_sets[i]:
					if i < characters_to_process.size() and not characters_to_process[i].starting_weapons.has(weapon):
						characters_to_process[i].starting_weapons.append(weapon)
	var weapons_seen = {}
	for weapon in ItemService.weapons:
		if weapon == null or not is_instance_valid(weapon):
			continue
		if not weapon.weapon_id in weapons_seen:
			weapons_seen[weapon.weapon_id] = weapon.tier
		elif weapons_seen[weapon.weapon_id] > weapon.tier:
			weapons_seen[weapon.weapon_id] = weapon.tier
	for weapon in ItemService.weapons:
		if weapon == null or not is_instance_valid(weapon):
			continue
		if weapon.tier == weapons_seen[weapon.weapon_id]:
			for character in characters_to_process_all_weapons:
				if not character.starting_weapons.has(weapon):
					character.starting_weapons.append(weapon)


# ==============================================
# 退出清理
# ==============================================
func _exit_tree():
	_clean_all()

func _clean_all():
	ModLoaderLog.info("Cleaning mod...", LOG_NAME)

	is_mod_initialized = false
