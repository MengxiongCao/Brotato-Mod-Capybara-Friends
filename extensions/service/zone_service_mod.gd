extends "res://singletons/zone_service.gd"

const CAPYBARA_MOD_MAIN_PATH = "/root/ModLoader/Dbear-Capybara"

const CAPYBARA_BASE_ENEMY_SCENES = [
	"res://entities/units/enemies/tentacle/tentacle.tscn",
	"res://entities/units/enemies/spawner/spawner.tscn",
]

const CAPYBARA_DLC_ENEMY_SCENES = [
	"res://dlcs/dlc_1/enemies/pufferfish/pufferfish.tscn",
	"res://dlcs/dlc_1/enemies/blobfish/blobfish.tscn",
	"res://dlcs/dlc_1/enemies/clam/clam.tscn",
]

const CAPYBARA_CRYSTAL_ENEMIES = [
	"res://mods-unpacked/Dbear-Capybara/contents/enemies/defective_subject/defective_subject.tscn"
]

const CAPYBARA_CRYSTAL_TREES = [
	"res://mods-unpacked/Dbear-Capybara/contents/enemies/crystal_tree/crystal_tree.tscn"
]

func get_wave_data(my_id: int, index: int) -> Resource:
	var capybara_wave = .get_wave_data(my_id, index)
	var capybara_add_crystal_enemies = false
	for player_index in RunData.get_player_count():
		if not RunData.get_player_effect(Keys.generate_hash("capybara_crystal_null"), player_index).size() > 0 and not RunData.capybara_null_crystal:
			capybara_add_crystal_enemies = true
	if capybara_add_crystal_enemies:
		for path in CAPYBARA_CRYSTAL_TREES:
			var nb_enemies = 1
			var nb = 1
			if nb_enemies > 0:
				var capybara_scenes:Array = []
				capybara_scenes.append(load(path))
				var nb_additional_groups: = max(1, (nb_enemies / 10.0) as int) as int
				var wave_duration: = 60
				var bonus_enemies_per_group: = max(0, (nb_enemies/ 15.0) as int) as int
				var min_spawn_timing: = rand_range(20,30)
				var additional_groups = get_additional_groups(nb_additional_groups, wave_duration, bonus_enemies_per_group, capybara_scenes, min_spawn_timing)
				capybara_wave.groups_data.append_array(additional_groups)
		for path in CAPYBARA_CRYSTAL_ENEMIES:
			var nb_enemies = 1
			var nb = 1
			if nb_enemies > 0:
				var capybara_scenes:Array = []
				capybara_scenes.append(load(path))
				var nb_additional_groups: = max(1, (nb_enemies / 10.0) as int) as int
				var wave_duration: = 60
				var bonus_enemies_per_group: = max(0, (nb_enemies/ 15.0) as int) as int
				var min_spawn_timing = rand_range(50,60)
				for player_index in RunData.get_player_count():
					min_spawn_timing = max(1,rand_range(50,60) - Utils.get_stat(Keys.generate_hash("stat_capybara_crystal"), player_index))
				var additional_groups = get_additional_groups(nb_additional_groups, wave_duration, bonus_enemies_per_group, capybara_scenes, min_spawn_timing)
				capybara_wave.groups_data.append_array(additional_groups)
	for player_index in RunData.get_player_count():
		if RunData.get_player_effect(Keys.generate_hash("extra_bait_every_wave"), player_index):
			var capybara_enemy_paths := CAPYBARA_BASE_ENEMY_SCENES.duplicate()
			if _capybara_is_dlc_available():
				capybara_enemy_paths.append_array(CAPYBARA_DLC_ENEMY_SCENES)
			for path in capybara_enemy_paths:
				if not ResourceLoader.exists(path):
					continue
				var enemy_scene = load(path)
				if enemy_scene != null and not extra_enemy_scenes.has(enemy_scene):
					extra_enemy_scenes.append(enemy_scene)
			var nb_ranged_enemies = 1
			var nb = max(1, RunData.current_wave/3)
			if nb_ranged_enemies > 0:
				var capybara_scenes:Array = []
				if RunData.current_wave <= 5:
					var early_enemy_path = CAPYBARA_DLC_ENEMY_SCENES[0] if _capybara_is_dlc_available() else CAPYBARA_BASE_ENEMY_SCENES[0]
					if not ResourceLoader.exists(early_enemy_path):
						continue
					var early_enemy_scene = load(early_enemy_path)
					if early_enemy_scene == null:
						continue
					capybara_scenes.append(early_enemy_scene)
					var nb_additional_groups: = max(1, (nb_ranged_enemies / 10.0) as int) as int
					var wave_duration: = 60
					var bonus_enemies_per_group: = max(0, (nb_ranged_enemies/ 15.0) as int) as int
					var min_spawn_timing: = rand_range(3, 5)
					var additional_groups = get_additional_groups(nb_additional_groups, wave_duration, bonus_enemies_per_group, capybara_scenes, min_spawn_timing)
					capybara_wave.groups_data.append_array(additional_groups)
				else:
					for i in range(0,nb):
						capybara_scenes = [Utils.get_rand_element(extra_enemy_scenes)]
						var nb_additional_groups: = max(1, (nb_ranged_enemies / 10.0) as int) as int
						var wave_duration: = 60
						var bonus_enemies_per_group: = max(0, (nb_ranged_enemies/ 15.0) as int) as int
						var min_spawn_timing: = rand_range(25, 30)
						var additional_groups = get_additional_groups(nb_additional_groups, wave_duration, bonus_enemies_per_group, capybara_scenes, min_spawn_timing)
						capybara_wave.groups_data.append_array(additional_groups)
	return capybara_wave


func _capybara_is_dlc_available() -> bool:
	var mod_main = get_node_or_null(CAPYBARA_MOD_MAIN_PATH)
	return is_instance_valid(mod_main) and mod_main.has_method("capybara_is_dlc_available") and mod_main.capybara_is_dlc_available()

#func capybara_get_additional_groups(nb_additional_groups: int, wave_duration: int = 60, bonus_enemies_per_group: int = 1, enemy_scenes: Array = current_zone.endless_enemy_scenes, min_spawn_timing: int = 0, is_crystal = false) -> Array:
#	var groups = []
#
#	for i in nb_additional_groups:
#		var group_to_add = Utils.get_rand_element(endless_groups).duplicate()
#
#		group_to_add.spawn_timing = max(min_spawn_timing, ((i * ((wave_duration - 10.0) / nb_additional_groups)) + 1.0)) as int
#
#		var spawn_edge_of_map_rand = randf()
#		var area_rand = randf()
#
#		group_to_add.spawn_edge_of_map = spawn_edge_of_map_rand > 0.5
#		group_to_add.area = - 1 if area_rand > 0.5 else int(rand_range(200, 300))
#		group_to_add.repeating_interval = 60
#		group_to_add.min_repeating_interval = 1
#		group_to_add.repeating = 3
#		if is_crystal:
#			group_to_add.spawn_chance = 0
#			for player_index in RunData.get_player_count():
#				group_to_add.spawn_chance += Utils.get_stat(Keys.generate_hash("stat_capybara_crystal"), player_index) / 100.0
#		else:
#			group_to_add.spawn_chance = 1
#
#		var unit_group = Utils.get_rand_element(endless_unit_groups).duplicate()
#
#		unit_group.unit_scene = Utils.get_rand_element(enemy_scenes)
#		unit_group.min_number = int(1 + bonus_enemies_per_group)
#		unit_group.max_number = int(round(rand_range(unit_group.min_number, unit_group.min_number + 1)) + bonus_enemies_per_group)
#
#		group_to_add.wave_units_data.push_back(unit_group)
#		groups.push_back(group_to_add)
#	return groups

func capybara_get_rand_pos_in_area(base_pos: Vector2, area: float, edge: int = Utils.EDGE_MAP_DIST) -> Vector2:
	edge = _limit_dist_to_edge(edge)

	var min_x = current_zone_min_position.x + edge + area / 2
	var max_x = current_zone_max_position.x - edge - area / 2
	var min_y = current_zone_min_position.y + edge + area / 2
	var max_y = current_zone_max_position.y - edge - area / 2
	var pos = Vector2(clamp(base_pos.x, min_x, max_x), clamp(base_pos.y, min_y, max_y))
	var rand_a = rand_range(0, 2 * PI)
	if area > edge:
		var rand_r = rand_range(edge, area)
		var capy_pos = Vector2(pos.x + rand_r * cos(rand_a), pos.y + rand_r * sin(rand_a))
		return capy_pos
	return Vector2(rand_range(pos.x - area / 2, pos.x + area / 2), rand_range(pos.y - area / 2, pos.y + area / 2))
