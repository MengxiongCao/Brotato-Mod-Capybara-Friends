extends "res://singletons/progress_data.gd"

var capybara_check_dlc_data:bool = false
const CAPYBARA_MOD_MAIN_PATH = "/root/ModLoader/Dbear-Capybara"
const CAPYBARA_CONTENT_LOADER_PATH = "/root/ModLoader/Dbear-Capybara/CapybaraContentLoader"

# Ensure our DLC1 data override is applied (forces 110% cursed modifier).
func load_dlc_pcks() -> void:
	var mod_main = get_node_or_null(CAPYBARA_MOD_MAIN_PATH)
	if is_instance_valid(mod_main) and mod_main.has_method("capybara_is_forcing_no_dlc") and mod_main.capybara_is_forcing_no_dlc():
		ModLoaderLog.info("DLC package loading skipped by CAPYBARA_TEST_FORCE_NO_DLC", "Dbear-Capybara")
		capybara_check_dlc_data = true
		return
	.load_dlc_pcks()
	if capybara_check_dlc_data:
		return
	if is_instance_valid(mod_main) and mod_main.has_method("capybara_install_dlc_extensions") and mod_main.capybara_install_dlc_extensions():
		ModLoaderLog.info("Dbear DLC extensions enabled", "Dbear-Capybara")
	else:
		ModLoaderLog.info("Dbear DLC extensions skipped", "Dbear-Capybara")
	capybara_check_dlc_data = true


func check_for_available_dlcs() -> void:
	var mod_main = get_node_or_null(CAPYBARA_MOD_MAIN_PATH)
	if not is_instance_valid(mod_main) or not mod_main.has_method("capybara_is_forcing_no_dlc") or not mod_main.capybara_is_forcing_no_dlc():
		.check_for_available_dlcs()
		return
	available_dlcs.clear()
	ModLoaderLog.info("DLC disabled by CAPYBARA_TEST_FORCE_NO_DLC", "Dbear-Capybara")


func reset_dlc_resources_to_active_dlcs() -> void:
	.reset_dlc_resources_to_active_dlcs()
	_capybara_refresh_content_after_dlc_reset()


func load_game_file(try_fallback: = true) -> void:
	_capybara_install_content_before_restore()
	.load_game_file(try_fallback)


func _capybara_install_content_before_restore() -> void:
	var content_loader = get_node_or_null(CAPYBARA_CONTENT_LOADER_PATH)
	if is_instance_valid(content_loader):
		if not content_loader.is_installed():
			content_loader.install_registered_data()
	else:
		ModLoaderLog.error("CapybaraContentLoader was not available before save loading", "Dbear-Capybara")


func _capybara_refresh_content_after_dlc_reset() -> void:
	var content_loader = get_node_or_null(CAPYBARA_CONTENT_LOADER_PATH)
	if not is_instance_valid(content_loader):
		ModLoaderLog.error("CapybaraContentLoader was not available after DLC reset", "Dbear-Capybara")
		return
	if not content_loader.is_installed():
		content_loader.install_registered_data()
	else:
		content_loader.refresh_zones_after_dlc_reset()
	
func init_settings() -> void :
	.init_settings()
	settings.merge({"capybara_crystal_null": false})

func get_character_difficulty_info(character_id, zone_id, is_random_zone = false):
	return .get_character_difficulty_info(character_id, zone_id, is_random_zone)
