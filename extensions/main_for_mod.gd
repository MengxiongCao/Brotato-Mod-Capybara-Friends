extends "res://main.gd"

const CapybaraOnlineCompat = preload("res://mods-unpacked/Dbear-Capybara/extensions/brotato_online_compat.gd")
const CAPYBARA_SPECIAL_ITEM_META = "capybara_special_item_id"

signal capybara_special_consumables_collected

var capybara_wave_end = false
var capybara_crystal_progress_bar = load("res://mods-unpacked/Dbear-Capybara/extensions/ui_containers/ui_crystal_progress_bar.tscn")
var capybara_special_consumable_pool_id: int = -1
var capybara_special_collect_queue: Array = []
var capybara_special_collect_index: int = 0
var capybara_special_collect_timer: Timer = null

var capybara_colors = {
		"capybara_special_dodge":Color.lightsteelblue,
		"capybara_golden_heart": Color.gold,
	}

func capybara_spawn_enemy(enemy: Enemy, spawn_position: Vector2) -> Enemy:
	if not CapybaraOnlineCompat.should_run_authoritative_logic(self):
		return null
	if not is_instance_valid(enemy):
		return null
	var capybara_scene_path = enemy.filename
	if capybara_scene_path.empty():
		push_warning("Capybara cannot spawn an enemy whose source scene path is empty.")
		return null
	var capybara_enemy_scene = load(capybara_scene_path)
	if not capybara_enemy_scene is PackedScene:
		push_warning("Capybara could not load enemy scene: %s" % capybara_scene_path)
		return null
	if not is_instance_valid(_entity_spawner):
		return null
	var capybara_entity_type = EntityType.BOSS if enemy is Boss else EntityType.ENEMY
	var capybara_spawn_args = EntitySpawner.SpawnEntityArgs.new(spawn_position, capybara_entity_type)
	var capybara_spawned_enemy = _entity_spawner.spawn_entity(capybara_enemy_scene, capybara_spawn_args)
	return capybara_spawned_enemy if capybara_spawned_enemy is Enemy else null

func capybara_update_special_dodge_label(player_index, capybara_special_dodge_times:int) -> void:
	var player_ui: PlayerUIElements = _players_ui[player_index]
	var life_bar = player_ui.life_bar

	var icon = life_bar.get_node_or_null("CapybaraSpecialDodgeIcon")
	var label = life_bar.get_node_or_null("CapybaraSpecialDodgeLabel")

	if not icon or not is_instance_valid(icon):
		icon = TextureRect.new()
		icon.name = "CapybaraSpecialDodgeIcon"
		icon.texture = RunData.get_player_character(player_index).icon

		icon.anchor_left = 0.0
		icon.anchor_top = 0.5
		icon.anchor_right = 0.0
		icon.anchor_bottom = 0.5

		icon.margin_left = 5.0
		icon.margin_right = 39.0
		icon.margin_top = -17.0
		icon.margin_bottom = 17.0

		icon.expand = true
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

		life_bar.add_child(icon)

	if not label or not is_instance_valid(label):
		label = Label.new()
		label.name = "CapybaraSpecialDodgeLabel"

		var capybara_font = DynamicFont.new()
		capybara_font.font_data = load("res://mods-unpacked/Dbear-Capybara/extensions/ui_containers/capybara_dynamicfontdata.tres")
		capybara_font.size = 30
		capybara_font.outline_size = 3

		label.add_font_override("font", capybara_font)
		label.add_color_override("font_color", Color.white)
		label.add_color_override("font_outline_modulate", Color.black)

		label.anchor_left = 0.0
		label.anchor_top = 0.0
		label.anchor_right = 1.0
		label.anchor_bottom = 1.0

		label.margin_left = 46.0
		label.margin_top = 2.0
		label.margin_right = 5.0
		label.margin_bottom = 2.0

		label.align = Label.ALIGN_LEFT
		label.valign = Label.VALIGN_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE

		life_bar.add_child(label)
	label.text = str(capybara_special_dodge_times)
	if capybara_special_dodge_times <= 0:
		label.visible = false
		icon.visible = false
	else:
		label.visible = true
		icon.visible = true
	
func _physics_process(_delta: float) -> void :

	for player_index in RunData.get_player_count():
		var life_bar_effects = _players[player_index].life_bar_effects()
		var player_ui: PlayerUIElements = _players_ui[player_index]
		player_ui.life_bar.effect_colors.merge(capybara_colors,true)
		player_ui.life_bar.update_color_from_effects(life_bar_effects)
		player_ui.player_life_bar.effect_colors.merge(capybara_colors,true)
		player_ui.player_life_bar.update_color_from_effects(life_bar_effects)

func _capybara_on_pet_work(value, pos, player_index) -> void:
	_floating_text_manager.capybara_pet_work_gain(value, pos ,player_index)

func _on_HarvestingTimer_timeout() -> void:
	for player_index in RunData.get_player_count():
		capybara_remove_maxed_item_chance_descriptions(player_index)
	var capybara_no_harvesting_decrease = [false, false, false, false]
	var capybara_temp_harvesting = [0,0,0,0]
	for player_index in RunData.get_player_count():
		var harvesting_stat = Utils.get_stat(Keys.stat_harvesting_hash, player_index)
		var items_mod = RunData.get_player_items_ref(player_index)
		for item in items_mod:
			if item.my_id_hash == Keys.generate_hash("item_eternal_tiara"):
				capybara_no_harvesting_decrease[player_index] = true
		if capybara_no_harvesting_decrease[player_index] and RunData.current_wave > RunData.nb_of_waves:
			var stat_to_temp_remove = Utils.get_stat(Keys.stat_harvesting_hash, player_index)
			TempStats.remove_stat(Keys.stat_harvesting_hash,stat_to_temp_remove , player_index)
			capybara_temp_harvesting[player_index] = stat_to_temp_remove
	._on_HarvestingTimer_timeout()
	if capybara_no_harvesting_decrease and RunData.current_wave > RunData.nb_of_waves:
		for player_index in RunData.get_player_count():
			var stat_to_temp_add = capybara_temp_harvesting[player_index]
			TempStats.add_stat(Keys.stat_harvesting_hash,stat_to_temp_add , player_index)
			var harvesting_stat = Utils.get_stat(Keys.stat_harvesting_hash, player_index)
			var harvesting_growth = RunData.get_player_effect(Keys.harvesting_growth_hash, player_index)
			var val = ceil(harvesting_stat * (harvesting_growth / 100.0))

			var has_crown = false
			var crown_value = 0

			var items = RunData.get_player_items_ref(player_index)
			for item in items:


				if item.my_id_hash == Keys.item_crown_hash:
					has_crown = true
					crown_value = item.effects[0].value
					break

			if has_crown:
				RunData.add_tracked_value(player_index, Keys.item_crown_hash, ceil(harvesting_stat * (crown_value / 100.0)) as int)

			if val > 0:
				RunData.add_stat(Keys.stat_harvesting_hash, val, player_index)
	

var capybara_crystal_progress_height: float = 8.0
var capybara_experience_bar_separation: int = 2


func _on_EntitySpawner_players_spawned(players: Array) -> void:
	._on_EntitySpawner_players_spawned(players)
	capybara_wave_end = false

	var capybara_has_golden_piggy_bank: Array = [false, false, false, false]

	for player_index in RunData.get_player_count():
		var items_mod = RunData.get_player_items_ref(player_index)
		for item in items_mod:
			if item.my_id_hash == Keys.generate_hash("item_golden_piggy_bank"):
				capybara_has_golden_piggy_bank[player_index] = true

	for player_index in _players.size():
		if capybara_has_golden_piggy_bank[player_index] and RunData.current_wave > RunData.nb_of_waves:
			var pct_val = RunData.get_player_effect(Keys.gain_pct_gold_start_wave_hash, player_index)
			if pct_val < 0:
				pct_val = -100.0

			var val = RunData.get_player_gold(player_index) * (pct_val / 100.0)
			RunData.add_gold(val, player_index)

			if pct_val > 0:
				RunData.add_tracked_value(player_index, Keys.item_piggy_bank_hash, val)

	if RunData.capybara_null_crystal:
		return

	for player in _players:
		for player_ui in _players_ui:
			if player_ui.player_index == player.player_index:
				capybara_add_crystal_progress_bar(player_ui, player)
				break


func capybara_add_crystal_progress_bar(capybara_player_ui, capybara_player) -> void:
	if not is_instance_valid(capybara_player_ui):
		return
	if not is_instance_valid(capybara_player_ui.xp_bar):
		return

	var capybara_original_xp_bar = capybara_player_ui.xp_bar
	var capybara_bars_container = capybara_get_or_create_experience_bars_container(capybara_original_xp_bar)

	if not is_instance_valid(capybara_bars_container):
		return

	if capybara_bars_container.has_node("CapybaraCrystalProgressBar"):
		var capybara_existing_bar = capybara_bars_container.get_node("CapybaraCrystalProgressBar")

		if is_instance_valid(capybara_existing_bar) and capybara_existing_bar.has_method("capybara_set_player"):
			capybara_existing_bar.capybara_set_player(capybara_player)

		call_deferred("capybara_refresh_experience_bars_layout", capybara_bars_container, capybara_original_xp_bar, capybara_existing_bar)
		return

	var capybara_crystal_progress_instance = capybara_crystal_progress_bar.instance()

	if not is_instance_valid(capybara_crystal_progress_instance):
		return

	capybara_crystal_progress_instance.name = "CapybaraCrystalProgressBar"
	capybara_crystal_progress_instance.rect_min_size = Vector2(0.0, capybara_crystal_progress_height)
	capybara_crystal_progress_instance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	capybara_crystal_progress_instance.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	capybara_crystal_progress_instance.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if capybara_crystal_progress_instance.has_method("capybara_set_player"):
		capybara_crystal_progress_instance.capybara_set_player(capybara_player)

	capybara_bars_container.add_child(capybara_crystal_progress_instance)
	capybara_bars_container.move_child(capybara_crystal_progress_instance, capybara_original_xp_bar.get_index() + 1)

	call_deferred("capybara_refresh_experience_bars_layout", capybara_bars_container, capybara_original_xp_bar, capybara_crystal_progress_instance)


func capybara_get_or_create_experience_bars_container(capybara_original_xp_bar):
	if not is_instance_valid(capybara_original_xp_bar):
		return null

	var capybara_original_parent = capybara_original_xp_bar.get_parent()

	if not is_instance_valid(capybara_original_parent):
		return null

	if capybara_original_parent is VBoxContainer and capybara_original_parent.name == "CapybaraExperienceBarsContainer":
		capybara_original_parent.add_constant_override("separation", capybara_experience_bar_separation)
		return capybara_original_parent

	if not (capybara_original_parent is Container):
		push_warning("原版经验条的父节点不是Container，无法自动排开其他UI。")
		return null

	var capybara_original_index: int = capybara_original_xp_bar.get_index()
	var capybara_original_width: float = capybara_original_xp_bar.rect_min_size.x
	var capybara_original_height: float = capybara_get_progress_bar_required_height(capybara_original_xp_bar)
	var capybara_original_horizontal_flags: int = capybara_original_xp_bar.size_flags_horizontal
	var capybara_bars_container = VBoxContainer.new()

	capybara_bars_container.name = "CapybaraExperienceBarsContainer"
	capybara_bars_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capybara_bars_container.size_flags_horizontal = capybara_original_horizontal_flags
	capybara_bars_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	capybara_bars_container.rect_min_size = Vector2(capybara_original_width, capybara_original_height)
	capybara_bars_container.add_constant_override("separation", capybara_experience_bar_separation)

	capybara_original_parent.add_child(capybara_bars_container)
	capybara_original_parent.move_child(capybara_bars_container, capybara_original_index)
	capybara_original_parent.remove_child(capybara_original_xp_bar)
	capybara_bars_container.add_child(capybara_original_xp_bar)

	capybara_original_xp_bar.rect_min_size.y = capybara_original_height
	capybara_original_xp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	capybara_original_xp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	capybara_original_xp_bar.minimum_size_changed()
	capybara_bars_container.minimum_size_changed()
	capybara_bars_container.queue_sort()

	return capybara_bars_container


func capybara_get_progress_bar_required_height(capybara_bar) -> float:
	if not is_instance_valid(capybara_bar):
		return capybara_crystal_progress_height

	var capybara_height: float = max(capybara_crystal_progress_height, capybara_bar.rect_min_size.y)
	capybara_height = max(capybara_height, capybara_bar.get_combined_minimum_size().y)

	if capybara_bar.rect_size.y > 0.0:
		capybara_height = max(capybara_height, capybara_bar.rect_size.y)

	if capybara_bar is TextureProgress:
		if capybara_bar.texture_under != null:
			capybara_height = max(capybara_height, float(capybara_bar.texture_under.get_height()))
		if capybara_bar.texture_progress != null:
			capybara_height = max(capybara_height, float(capybara_bar.texture_progress.get_height()))
		if capybara_bar.texture_over != null:
			capybara_height = max(capybara_height, float(capybara_bar.texture_over.get_height()))

	return max(1.0, capybara_height)


func capybara_refresh_experience_bars_layout(capybara_bars_container, capybara_original_xp_bar, capybara_crystal_progress_bar) -> void:
	if not is_instance_valid(capybara_bars_container):
		return
	if not is_instance_valid(capybara_original_xp_bar):
		return
	if not is_instance_valid(capybara_crystal_progress_bar):
		return

	var capybara_original_height: float = capybara_get_progress_bar_required_height(capybara_original_xp_bar)
	var capybara_crystal_height: float = capybara_get_progress_bar_required_height(capybara_crystal_progress_bar)
	var capybara_required_height: float = capybara_original_height + capybara_crystal_height + float(capybara_experience_bar_separation)

	capybara_original_xp_bar.rect_min_size.y = capybara_original_height
	capybara_crystal_progress_bar.rect_min_size.y = capybara_crystal_height

	capybara_original_xp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	capybara_original_xp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	capybara_crystal_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	capybara_crystal_progress_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var capybara_container_min_size: Vector2 = capybara_bars_container.rect_min_size
	capybara_container_min_size.y = capybara_required_height
	capybara_bars_container.rect_min_size = capybara_container_min_size
	capybara_bars_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	capybara_original_xp_bar.minimum_size_changed()
	capybara_crystal_progress_bar.minimum_size_changed()
	capybara_bars_container.minimum_size_changed()
	capybara_bars_container.queue_sort()

	capybara_queue_experience_parent_layout(capybara_bars_container)


func capybara_queue_experience_parent_layout(capybara_control) -> void:
	var capybara_current_node = capybara_control

	while is_instance_valid(capybara_current_node):
		if capybara_current_node is Control:
			capybara_current_node.minimum_size_changed()

		if capybara_current_node is Container:
			capybara_current_node.queue_sort()

		capybara_current_node = capybara_current_node.get_parent()
			

#func _on_WaveTimer_timeout() -> void :
#	._on_WaveTimer_timeout()
#	capybara_wave_end = true
#
#	for player_index in RunData.get_player_count():
#		var capybara_pet_structure = RunData.get_player_effect(Keys.generate_hash("capybara_pet_structure_gold"), player_index)
#		if capybara_pet_structure.size() > 0:
#			# 👇 用新的计时器
#			for effect in capybara_pet_structure:
#				var gold_gain = RunData.get_nb_pets(player_index) * effect[0]
#				RunData.add_gold(gold_gain, player_index)
#				_floating_text_manager.capybara_on_gold_added(gold_gain, player_index)
#				if RunData.get_player_gold(player_index) >= 300:
#					RunData.add_gold(effect[1], player_index)
#					RunData.add_stat(Keys.weapon_slot_hash, 1, player_index)
#		var effects = RunData.get_player_effects(player_index)
#		for effect in effects[Keys.generate_hash("capybara_curse_random_weapon")]:
#			var possible_curse= []
#			var weapons = RunData.get_player_weapons(player_index)
#			for weapon in weapons:
#				if not weapon.is_cursed:
#					possible_curse.append(weapon)
#			if possible_curse.size() > 0:
#				var weapon_to_curse = Utils.get_rand_element(possible_curse)
#				for dlc_id in RunData.enabled_dlcs:
#					var dlc_data = ProgressData.get_dlc_data(dlc_id)
#					if dlc_data and dlc_data.has_method("curse_item"):
#						var weapon_to_cursed = dlc_data.curse_item(weapon_to_curse, player_index, false, 0.5)
#						RunData.remove_weapon(weapon_to_curse, player_index)
#						RunData.add_weapon(weapon_to_cursed, player_index)
#						_floating_text_manager.capybara_on_random_weapon_cursed(1,player_index)
#			else:
#				assert (effect[0] is int)
#				RunData.add_stat(effect[0], effect[1], player_index)
#				var value = -effect[1]
#				RunData.add_tracked_value(player_index, Keys.generate_hash("item_curse_forger"), value)
#		var capybara_stats = RunData.get_player_effect(Keys.generate_hash("convert_certain_stats"), player_index)
#		if capybara_stats.empty():
#			break
#		for stat_to_convert in capybara_stats:
#			var max_stat = stat_to_convert[3]
#			var stat_to_remove = stat_to_convert[0]
#			var stat_to_add = stat_to_convert[2]
#			var to_remove_value = stat_to_convert[1]
#			var to_add_value = stat_to_convert[4]
#			var stat_to_remove_has_value = Utils.get_stat(stat_to_remove, player_index) as int
#			var current_weapon_slot = RunData.get_stat(Keys.weapon_slot_hash, player_index)
#			var n: int = stat_to_remove_has_value/to_remove_value
#			if to_remove_value <= stat_to_remove_has_value:
#				if stat_to_add != Keys.weapon_slot_hash:
#					RunData.remove_stat(stat_to_remove, to_remove_value*n, player_index)
#					RunData.add_stat(stat_to_add, to_add_value*n, player_index)
#				elif current_weapon_slot < max_stat:
#					if current_weapon_slot + to_add_value*n > max_stat:
#						to_add_value = max_stat - current_weapon_slot
#						RunData.remove_stat(stat_to_remove, to_remove_value, player_index)
#						RunData.add_stat(stat_to_add, to_add_value, player_index)
#					else:
#						RunData.remove_stat(stat_to_remove, to_remove_value * n, player_index)
#						RunData.add_stat(stat_to_add, to_add_value * n, player_index)

signal capybara_healed(_value, player_index)

func on_player_healed(_value: int, player_index: int) -> void :
	.on_player_healed(_value, player_index)
	emit_signal("capybara_healed", _value, player_index)
#	var gain_gold_when_heal_effect = RunData.get_player_effect(Keys.generate_hash("gain_gold_when_heal"), player_index)
#	var gain_stats_when_heal_effect = RunData.get_player_effect(Keys.generate_hash("gain_stats_when_heal"), player_index)
#	if gain_gold_when_heal_effect.size() > 0:
#		for effect in gain_gold_when_heal_effect:
#			if Utils.get_chance_success(effect[2]/100.0):
#				RunData.add_gold(effect[1] , player_index)
#				_floating_text_manager.capybara_on_gold_added(effect[1], player_index)
#				RunData.add_tracked_value(player_index, Keys.generate_hash("item_philosopher_stone"), effect[1])
#	if gain_stats_when_heal_effect.size() > 0:
#		for effect in gain_stats_when_heal_effect:
#			var stat = effect[0]
#			if Utils.get_chance_success(effect[2]/100.0):
#				RunData.add_stat(stat, effect[1] , player_index)

#func _on_player_health_updated(player, current_val, max_val) -> void :
#	._on_player_health_updated(player, current_val, max_val)
#	var capybara_player_index = player.player_index
#	var golden_heart_have = RunData.get_player_item(Keys.generate_hash("item_golden_heart"), capybara_player_index)
#	RunData.players_data[capybara_player_index].current_health = current_val
#	if current_val <= 0 and golden_heart_have != null:
#		_floating_text_manager.on_relive(-1, capybara_player_index)
#	if player.current_stats.health <= 0:
#		if golden_heart_have == null:
#			var relive_by_upgrades = RunData.get_player_effect(Keys.generate_hash("relive_by_upgrades"), capybara_player_index)
#			if relive_by_upgrades.size() > 0:
#				for effect in relive_by_upgrades:
#					if RunData.get_stat(effect[0], capybara_player_index) >= effect[1]:
#						_floating_text_manager.on_relive_by_upgrades(0, capybara_player_index)
#						var val = RunData.get_stat(effect[0], capybara_player_index)
#						var xp_gain = val * effect[2]
#						var gold_gain = val * effect[2]
#						_floating_text_manager.capybara_on_gold_added(gold_gain, capybara_player_index)
#						_floating_text_manager.capybara_on_xp_added(xp_gain, capybara_player_index)

#func _on_enemy_died(enemy:Enemy, args:Entity.DieArgs) -> void:
#	._on_enemy_died(enemy, args)
#	var capybara_live_players: = _get_shuffled_live_players()
#	for player in capybara_live_players:
#		var player_id = player.player_index
#		var capybara_weapons = RunData.get_player_weapons(player_id)
#		var capybara_has_set = false
#		var capybara_effects = RunData.get_player_effect(Keys.generate_hash("gain_stats_every_killed_enemy_with_weapon_class"), player_id)
#		for weapon in capybara_weapons:
#			if capybara_effects.size() > 0:
#				for set in weapon.sets:
#					for effect in capybara_effects:
#						if set.my_id == Keys.hash_to_string[effect[0]].replace("weapon_class_", "set_"):
#							capybara_has_set = true
#		if capybara_has_set:
#			for effect in capybara_effects:
#				if enemy is Looter and not _cleaning_up:
#					RunData.add_stat(effect[2], effect[3], player_id)
signal cp_levelled_up(player_index)

func on_levelled_up(player_index: int) -> void :
	.on_levelled_up(player_index)
	emit_signal("cp_levelled_up",player_index)
#	var capybara_level = RunData.get_player_level(player_index)
#	var capybara_upgrade_to_process = UpgradesUI.UpgradeToProcess.new()
#	capybara_upgrade_to_process.level = -1
#	capybara_upgrade_to_process.player_index = player_index
#	_upgrades_to_process[player_index].push_back(capybara_upgrade_to_process)
#	_things_to_process_player_containers[player_index].upgrades.add_element(capybara_crystal_upgrade_icon, -1)

signal cp_neutral_died(neutral,args)

func _on_neutral_died(neutral, args):
	._on_neutral_died(neutral,args)
	emit_signal("cp_neutral_died", neutral, args)

func _on_enemy_took_damage(enemy,value,knockback_direction,is_crit,is_dodge,is_protected,armor_did_something,args,hit_type,is_one_shot):
	._on_enemy_took_damage(enemy, value, knockback_direction, is_crit, is_dodge,is_protected, armor_did_something, args, hit_type, is_one_shot)
	

signal cp_on_enemy_died(enemy,args)
func _on_enemy_died(enemy, args):
	._on_enemy_died(enemy, args)
	for player in _get_shuffled_live_players():
		var player_index = player.player_index
		var projectiles_on_death = RunData.get_player_effect(Keys.generate_hash("capybara_projectiles_on_death"), player_index)
		if projectiles_on_death.empty():
			continue
		
		for effect in projectiles_on_death:
			for i in effect.value:
				var stats = effect.weapon_stats
				stats = WeaponService.init_ranged_stats(effect.weapon_stats, player_index, true)

				var auto_target_enemy: bool = effect.auto_target_enemy
				var from = player
				if player.current_weapons.size() > 0:
					from = player.current_weapons[0]
				var cp_args = WeaponServiceSpawnProjectileArgs.new()
				cp_args.from_player_index = player_index
				var _projectile = WeaponService.manage_special_spawn_projectile(
					enemy, 
					stats, 
					rand_range( - PI, PI), 
					auto_target_enemy, 
					_entity_spawner, 
					from, 
					cp_args
				)
	emit_signal("cp_on_enemy_died",enemy,args)

func _capybara_break_particles(break_particles:PackedScene, pos:Vector2, size) -> void:
	var instance = break_particles.instance()
	instance.visible = true
	instance.global_position = pos
	instance.scale = Vector2(size, size)
	add_child(instance)
	instance.restart()

func on_upgrade_selected(upgrade_data: UpgradeData, upgrade: UpgradesUI.UpgradeToProcess) -> void :
	
	if capybara_check_is_item_add(upgrade_data, upgrade.player_index, true):
		var player_index = upgrade.player_index
		RunData.capybara_last_character[player_index] = RunData.get_player_character(player_index)
		if capybara_check_is_apply_effects(upgrade_data, upgrade.player_index, true):
			capybara_remove_maxed_item_chance_descriptions(player_index)
			return
	for cp_effect in upgrade_data.effects:
		var n_effect = null
		var player_index = upgrade.player_index
		if cp_effect.custom_key == "CAPYBARA_INCREASE_THE_CHANCE_OF_ITEM".to_lower():
			var value = 0
			for effect in RunData.get_player_effect(cp_effect.custom_key_hash, player_index):
				if effect[0] == cp_effect.key_hash:
					value = effect[1]
			n_effect = NullEffect.new()
			n_effect.key = cp_effect.key
			n_effect.key_hash = cp_effect.key_hash
			n_effect.value = value + cp_effect.value
			n_effect.text_key = "EFFECT_CAPYBARA_INCREASE_THE_CHANCE_OF_ITEM_SUM".to_lower()
			n_effect.storage_method = StorageMethod.SUM
			n_effect.effect_sign = Sign.POSITIVE
		if n_effect:
			var capybara_character_data = RunData.get_player_character(player_index)
			if capybara_character_data == null or not is_instance_valid(capybara_character_data):
				continue
			var capybara_new_character_data = capybara_character_data.duplicate()
			var capybara_new_effects = []
			var capybara_effect_replaced = false
			for capybara_character_effect in capybara_character_data.effects:
				if capybara_character_effect != null and is_instance_valid(capybara_character_effect) and capybara_character_effect.key_hash == n_effect.key_hash and capybara_character_effect.text_key == n_effect.text_key:
					capybara_new_effects.append(n_effect)
					capybara_effect_replaced = true
				else:
					capybara_new_effects.append(capybara_character_effect)
			if not capybara_effect_replaced:
				capybara_new_effects.append(n_effect)
			capybara_new_character_data.effects = capybara_new_effects
			capybara_new_character_data.item_appearances = capybara_character_data.item_appearances.duplicate()
			var capybara_player_items = RunData.players_data[player_index].items
			var capybara_character_index = capybara_player_items.find(capybara_character_data)
			if capybara_character_index >= 0:
				capybara_player_items[capybara_character_index] = capybara_new_character_data
			RunData.players_data[player_index].current_character = capybara_new_character_data
	.on_upgrade_selected(upgrade_data, upgrade)
	capybara_remove_maxed_item_chance_descriptions(upgrade.player_index)
		

func capybara_remove_maxed_item_chance_descriptions(player_index: int) -> void:
	var capybara_character_data = RunData.get_player_character(player_index)
	if capybara_character_data == null or not is_instance_valid(capybara_character_data):
		return
	var capybara_new_effects = []
	var capybara_removed_description = false
	for capybara_character_effect in capybara_character_data.effects:
		if capybara_character_effect != null and is_instance_valid(capybara_character_effect) and capybara_character_effect.text_key.to_upper() == "EFFECT_CAPYBARA_INCREASE_THE_CHANCE_OF_ITEM_SUM" and ItemService.is_item_id(capybara_character_effect.key_hash):
			var capybara_item_data = ItemService.get_item_from_id(capybara_character_effect.key_hash)
			if capybara_item_data.max_nb != -1 and RunData.get_nb_item(capybara_item_data.my_id_hash, player_index, false) >= capybara_item_data.max_nb:
				capybara_removed_description = true
				continue
			elif capybara_item_data.max_nb == 1 and capybara_item_data.replaced_by and RunData.get_nb_item(capybara_item_data.replaced_by.my_id_hash, player_index, false) >= capybara_item_data.max_nb:
				capybara_removed_description = true
				continue
		capybara_new_effects.append(capybara_character_effect)
	var capybara_new_character_data = capybara_character_data.duplicate()
	capybara_new_character_data.effects = capybara_new_effects
	capybara_new_character_data.item_appearances = capybara_character_data.item_appearances.duplicate()
	var capybara_player_items = RunData.players_data[player_index].items
	var capybara_character_index = capybara_player_items.find(capybara_character_data)
	if capybara_character_index >= 0:
		capybara_player_items[capybara_character_index] = capybara_new_character_data
	RunData.players_data[player_index].current_character = capybara_new_character_data


func capybara_check_is_apply_effects(upgrade_data:UpgradeData, player_index:int, add_item: = false) -> bool:
	var should_apply_new_effect = false
	var should_apply_new_effect_to_weapon = false
	for effect in upgrade_data.effects:
		if effect == null or not is_instance_valid(effect):
			continue
		if effect.custom_key_hash == Keys.generate_hash("capybara_add_item"):
			if add_item:
				if effect.key_hash == Keys.effect_increase_stat_gains_hash:
					RunData.capybara_modify_crystal_alloy(player_index, effect)
					return true
				elif effect.key == "capybara_alloy_new_effect":
					should_apply_new_effect = true
				elif effect.key == "capybara_crystal_weapon_new_effect":
					should_apply_new_effect_to_weapon = true
	if should_apply_new_effect:
		for effect in upgrade_data.effects:
			if effect == null or not is_instance_valid(effect):
				continue
			if not effect.key == "capybara_alloy_new_effect":
				RunData.capybara_modify_crystal_alloy(player_index, effect)
		return true
	if should_apply_new_effect_to_weapon:
		for effect in upgrade_data.effects:
			if effect == null or not is_instance_valid(effect):
				continue
			if not effect.key == "capybara_crystal_weapon_new_effect":
				RunData.capybara_modify_crystallized_weapon(player_index, effect)
	return false

func capybara_check_is_item_add(upgrade_data:UpgradeData, player_index:int, add_item: = false) -> bool:
	for effect in upgrade_data.effects:
		if effect == null or not is_instance_valid(effect):
			continue
		if effect.custom_key_hash == Keys.generate_hash("capybara_add_item"):
			if add_item:
				if ItemService.is_item_id(effect.key_hash):
					var item_to_add = ItemService.get_item_from_id(effect.key_hash).duplicate()
					if effect.key_hash == Keys.generate_hash("item_capybara_crystal_pet"):
						for pet_item in ItemService.capybara_get_pet_items():
							for pet_effect in pet_item.effects:
								if "weapon_stats" in pet_effect:
									var gain_stat_effect = GainStatForEveryStatEffect.new()
									for stat in pet_effect.weapon_stats.scaling_stats:
										gain_stat_effect.key_hash = stat[0]
										gain_stat_effect.key = Keys.hash_to_string[stat[0]]
										if stat[0] == Keys.generate_hash("stat_capybara_enemies_killed"):
											if pet_item.tier < 3:
												gain_stat_effect.key_hash = Keys.stat_harvesting_hash
												gain_stat_effect.key = "stat_harvesting"
											else:
												gain_stat_effect.key_hash = Keys.number_of_enemies_hash
												gain_stat_effect.key = "number_of_enemies"
										elif stat[0] == Keys.stat_levels_hash:
											gain_stat_effect.key_hash = Keys.xp_gain_hash
											gain_stat_effect.key = "xp_gain"
#										if stat[0] in Utils.get_primary_stat_keys():
#											gain_stat_effect.value = ItemService._capybara_get_balance_stats_rand_value(gain_stat_effect.key_hash, 1) * max(1, pet_item.tier)
#										else:
#											gain_stat_effect.value = ItemService._capybara_get_balance_stats_rand_value(gain_stat_effect.key_hash, 1)
										gain_stat_effect.value = ItemService._capybara_get_balance_stats_rand_value(gain_stat_effect.key_hash, 1) * max(1, pet_item.tier)
										break
									gain_stat_effect.storage_method = StorageMethod.SUM
									gain_stat_effect.text_key = "EFFECT_GAIN_STAT_FOR_EVERY_STAT"
									gain_stat_effect.nb_stat_scaled = 1
									gain_stat_effect.stat_scaled = pet_item.my_id
									gain_stat_effect.stat_scaled_hash = pet_item.my_id_hash
									gain_stat_effect.perm_stats_only = true
									item_to_add.effects.push_back(gain_stat_effect)
								else:
									var gain_stat_effect = GainStatForEveryStatEffect.new()
									if pet_item.my_id_hash == Keys.generate_hash("item_lootworm"):
										gain_stat_effect.key_hash = Keys.pickup_range_hash
										gain_stat_effect.key = "pickup_range"
										gain_stat_effect.value = 100
									elif pet_item.my_id_hash == Keys.generate_hash("item_scapegoat"):
										gain_stat_effect.key_hash = Keys.stat_armor_hash
										gain_stat_effect.key = "stat_armor"
										gain_stat_effect.value = 10
									elif pet_item.my_id_hash == Keys.generate_hash("item_jellyshield"):
										gain_stat_effect.key_hash = Keys.stat_dodge_hash
										gain_stat_effect.key = "stat_dodge"
										gain_stat_effect.value = 5
									if not gain_stat_effect.key_hash == Keys.empty_hash:
										gain_stat_effect.storage_method = StorageMethod.SUM
										gain_stat_effect.text_key = "EFFECT_GAIN_STAT_FOR_EVERY_STAT"
										gain_stat_effect.nb_stat_scaled = 1
										gain_stat_effect.stat_scaled = pet_item.my_id
										gain_stat_effect.stat_scaled_hash = pet_item.my_id_hash
										gain_stat_effect.perm_stats_only = true
										item_to_add.effects.push_back(gain_stat_effect)
									
					RunData.add_item(item_to_add, player_index)
					
				elif ItemService.capybara_is_character_id(effect.key):
					var character_to_add = null
					if effect.key == "GMO_dummy" and RunData.capybara_last_character[player_index] is CharacterData:
						character_to_add = RunData.capybara_last_character[player_index]
					else:
						character_to_add = ItemService.capybara_get_character_from_id(effect.key)
					if character_to_add == null:
						return true
					var item_to_add = ItemService.get_item_from_id(Keys.generate_hash("item_capybara_item_character"))
					var final_item = RunData.capybara_turn_character_into_item(item_to_add, character_to_add, player_index)
					RunData.add_item(final_item, player_index)
				if effect.key_hash == Keys.generate_hash("capybara_crystal_turret_level"):
					var player_items = RunData.get_player_items(player_index)
					var current_level = 0
					var item_to_remove = null
					for item in player_items:
						if item.my_id.begins_with("item_cp_crystal_turret"):
							current_level = item.tier
							item_to_remove = item
							break
					if current_level < Tier.LEGENDARY:
						var item_to_add = ItemService.get_item_from_id(Keys.generate_hash("item_cp_crystal_turret_" + str(current_level + 1)))
						RunData.add_item(item_to_add, player_index)
						if item_to_remove:
							RunData.remove_item(item_to_remove, player_index)
			return true
	return false

func on_item_box_ban_button_pressed(item_data, consumable):
	.on_item_box_ban_button_pressed(item_data, consumable)

func on_item_box_take_button_pressed(item_data,consumable):
	.on_item_box_take_button_pressed(item_data, consumable)

	for effect in item_data.effects:
		if effect == null or not is_instance_valid(effect):
			continue
		var player_index = consumable.player_index
		if effect.custom_key_hash == Keys.generate_hash("capybara_crystallize_tier_weapon"):
			var current_weapons = RunData.get_player_weapons(player_index)
			var weapon_to_remove = null
			for weapon in current_weapons:
				if not weapon_to_remove and not RunData.capybara_check_crystal(weapon):
					weapon_to_remove = weapon
				if weapon_to_remove and not RunData.capybara_check_crystal(weapon) and ((weapon.tier > weapon_to_remove.tier or (weapon.tier == weapon_to_remove.tier and weapon.is_cursed))):
					weapon_to_remove = weapon
			if weapon_to_remove:
				var weapon_to_add = RunData.capybara_crystallize_item(weapon_to_remove, player_index)
				RunData.add_weapon(weapon_to_add, player_index)
				RunData.remove_weapon(weapon_to_remove, player_index)
			else:
				RunData.add_stat(effect.key_hash , effect.value, player_index)

var cp_shadow = load("res://mods-unpacked/Dbear-Capybara/contents/pets/dark_fish/cp_shadow.png")

func capybara_spawn_consumable(pos: Vector2, effect: Array) -> void:
	if _cleaning_up or effect.empty() or consumable_scene == null:
		return
	var item_to_add = ItemService.get_item_from_id(effect[0])
	if item_to_add == null:
		return
	var consumable_data: ConsumableData = ItemService.get_consumable_for_tier(Tier.UNCOMMON)
	if consumable_data == null:
		return
	if capybara_special_consumable_pool_id == -1:
		capybara_special_consumable_pool_id = Keys.generate_hash("capybara_special_consumable_pool")
	var consumable: Consumable = get_node_from_pool(capybara_special_consumable_pool_id, _consumables_container)
	if consumable == null:
		consumable = consumable_scene.instance()
		_consumables_container.call_deferred("add_child", consumable)
		var _error = consumable.connect("picked_up", self, "_capybara_on_special_item_picked_up")
		yield(consumable, "ready")
	if not is_instance_valid(consumable) or _cleaning_up:
		if is_instance_valid(consumable):
			consumable.queue_free()
		return
	consumable.already_picked_up = false
	consumable.set_meta(CAPYBARA_SPECIAL_ITEM_META, effect[0])
	consumable.consumable_data = consumable_data
	consumable.set_texture(item_to_add.icon)
	consumable.drop(pos, 0, ZoneService.capybara_get_rand_pos_in_area(pos, 500.0, 300))
	var shadow = consumable.get_node_or_null("CapybaraSpecialConsumableShadow")
	if shadow == null:
		shadow = Sprite.new()
		shadow.name = "CapybaraSpecialConsumableShadow"
		shadow.texture = cp_shadow
		shadow.show_behind_parent = true
		consumable.add_child(shadow)
	if effect[0] == Keys.generate_hash("item_crystal_turret_charge"):
		var flow_light = consumable.get_node_or_null("CapybaraSpecialConsumableFlowLight")
		if flow_light == null:
			flow_light = RunData.capybara_get_colorful_flow_light()
			var light_instance = flow_light.instance()
			light_instance.name = "CapybaraSpecialConsumableFlowLight"
			consumable.sprite.add_child(light_instance)
	_capybara_update_special_consumable_fog_light(consumable, effect[0])
	_consumables.push_back(consumable)


func _capybara_update_special_consumable_fog_light(consumable: Consumable, item_id: int) -> void:
	if not _is_fog_wave or not is_instance_valid(_fog_viewport):
		return
	_capybara_stop_special_consumable_fog_light(consumable)
	if item_id != Keys.generate_hash("item_crystal_turret_charge"):
		return
	var light: Node2D = null
	if _fog_viewport.structure_and_pet_lights_pool.empty():
		light = _fog_viewport.structure_and_pet_light_in_shadow_scene.instance()
		_fog_viewport.add_child(light)
	else:
		light = _fog_viewport.structure_and_pet_lights_pool.pop_back()
	light.modulate = _fog_viewport.fire_light_color
	light.show()
	_fog_viewport.structure_and_pet_lights[consumable] = light


func _capybara_stop_special_consumable_fog_light(consumable: Node) -> void:
	if not is_instance_valid(_fog_viewport) or not _fog_viewport.structure_and_pet_lights.has(consumable):
		return
	var light: Node2D = _fog_viewport.structure_and_pet_lights[consumable]
	_fog_viewport.structure_and_pet_lights.erase(consumable)
	light.hide()
	_fog_viewport.structure_and_pet_lights_pool.push_back(light)


func _capybara_on_special_item_picked_up(consumable: Node, player_index: int) -> void:
	if not is_instance_valid(consumable) or consumable.already_picked_up:
		return
	consumable.already_picked_up = true
	_capybara_stop_special_consumable_fog_light(consumable)
	_consumables.erase(consumable)
	consumable.hide()
	consumable.set_physics_process(false)
	if consumable.get_parent() != null:
		call_deferred("add_node_to_pool", consumable, capybara_special_consumable_pool_id)
	if not consumable.has_meta(CAPYBARA_SPECIAL_ITEM_META):
		return
	var item_to_add = ItemService.get_item_from_id(consumable.get_meta(CAPYBARA_SPECIAL_ITEM_META))
	if item_to_add != null:
		RunData.add_item(item_to_add, player_index)


func clean_up_room() -> void:
	if not _is_run_lost and not _is_wave_failed and not _is_run_won:
		_capybara_queue_special_consumables_for_collection()
	.clean_up_room()


func _capybara_queue_special_consumables_for_collection() -> void:
	if _consumables.empty():
		return
	var capybara_live_players: Array = _get_shuffled_live_players()
	if capybara_live_players.empty():
		return
	var capybara_normal_consumables: Array = []
	for i in _consumables.size():
		var consumable: Consumable = _consumables[i]
		if not is_instance_valid(consumable):
			continue
		if not consumable.has_meta(CAPYBARA_SPECIAL_ITEM_META):
			capybara_normal_consumables.append(consumable)
			continue
		_capybara_stop_special_consumable_fog_light(consumable)
		if consumable.already_picked_up:
			if consumable.get_parent() != null:
				add_node_to_pool(consumable, capybara_special_consumable_pool_id)
			continue
		var capybara_player_index: int = capybara_live_players[i % capybara_live_players.size()].player_index
		capybara_special_collect_queue.append([consumable, consumable.get_meta(CAPYBARA_SPECIAL_ITEM_META), capybara_player_index])
		consumable.already_picked_up = true
		consumable.reset()
	_consumables = capybara_normal_consumables
	if capybara_special_collect_queue.empty():
		return
	if not is_instance_valid(capybara_special_collect_timer):
		capybara_special_collect_timer = Timer.new()
		capybara_special_collect_timer.name = "CapybaraSpecialConsumableCollector"
		capybara_special_collect_timer.wait_time = 0.016
		add_child(capybara_special_collect_timer)
		capybara_special_collect_timer.connect("timeout", self, "_capybara_collect_special_consumables_batch")
	capybara_special_collect_timer.start()


func _capybara_collect_special_consumables_batch() -> void:
	var capybara_started_at: int = OS.get_ticks_msec()
	var capybara_processed: int = 0
	while capybara_special_collect_index < capybara_special_collect_queue.size() and capybara_processed < 8:
		var capybara_entry: Array = capybara_special_collect_queue[capybara_special_collect_index]
		capybara_special_collect_index += 1
		capybara_processed += 1
		var consumable: Consumable = capybara_entry[0]
		if is_instance_valid(consumable) and consumable.get_parent() != null:
			add_node_to_pool(consumable, capybara_special_consumable_pool_id)
		var item_to_add = ItemService.get_item_from_id(capybara_entry[1])
		if item_to_add != null:
			RunData.add_item(item_to_add, capybara_entry[2])
		if OS.get_ticks_msec() - capybara_started_at >= 3:
			break
	if capybara_special_collect_index >= capybara_special_collect_queue.size():
		capybara_special_collect_timer.stop()
		capybara_special_collect_queue.clear()
		capybara_special_collect_index = 0
		emit_signal("capybara_special_consumables_collected")


func _on_EndWaveTimer_timeout() -> void:
	if not capybara_special_collect_queue.empty():
		yield(self, "capybara_special_consumables_collected")
	._on_EndWaveTimer_timeout()
	
func get_gold_value(entity_type: int, args: Entity.DieArgs, base_value: float, unit: Unit = null) -> float:
	var capybara_value = .get_gold_value(entity_type, args, base_value, unit)
	if unit and is_instance_valid(unit) and "capybara_is_duplicated_enemy" in unit and unit.capybara_is_duplicated_enemy:
		return 0.0
	return capybara_value
