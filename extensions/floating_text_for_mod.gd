class_name CapybaraFloatingText
extends "res://visual_effects/floating_text/floating_text_manager.gd"


func capybara_display_icon(value: int, icon: Resource, pos_sounds: Array, neg_sounds: Array, pos: Vector2, p_direction: Vector2 = direction, db_mod: float = 0.0, player_index: int = - 1) -> void :
	display(str(""), pos, Color(ProgressData.settings.color_negative), icon, duration * 3, false, p_direction, false, Vector2(0.7, 0.7), player_index)
	if neg_sounds.size() > 0:
		SoundManager.play(Utils.get_rand_element(neg_sounds), - 8 + db_mod, 0.2, true)

func capybara_display_text(value: String, icon: Resource, pos_sounds: Array, neg_sounds: Array, pos: Vector2, p_direction: Vector2 = direction, db_mod: float = 0.0, player_index: int = - 1) -> void :
	display(tr(value.to_upper()), pos, Color.yellow, icon, duration * 3, false, p_direction, false, Vector2(0.5, 0.5), player_index)
	if neg_sounds.size() > 0:
		SoundManager.play(Utils.get_rand_element(pos_sounds), - 8 + db_mod, 0.2, true)

func capybara_display_icon_minor(value: int, icon: Resource, pos_sounds: Array, neg_sounds: Array, pos: Vector2, p_direction: Vector2 = direction, db_mod: float = 0.0, player_index: int = - 1) -> void :
	display(str("+",value), pos, Color(ProgressData.settings.color_positive), icon, duration * 2, false, p_direction, false, Vector2(0.5, 0.5), player_index)
	if neg_sounds.size() > 0:
		SoundManager.play(Utils.get_rand_element(pos_sounds), - 12 + db_mod, 0.2, true)

func on_relive(value: int, player_index: int) -> void :
	var icon_data = load("res://mods-unpacked/Dbear-Capybara/icons/relive/cp_relive_icon.png")
	var player: Player = players[player_index]
	if not player.dead:
		players_add_stats_count[player_index] += 1
		var pos = player.global_position - players_add_stats_count[player_index] * offset
		capybara_display_icon(value,icon_data , stat_pos_sounds, stat_neg_sounds, pos, Vector2(0, -30), player_index)

func capybara_text(value: String, player_index: int) -> void:
	var player: Player = players[player_index]
	var icon = load("res://mods-unpacked/Dbear-Capybara/extensions/cp_null.png")

	if not player.dead:
		var pos = player.global_position - 1 * offset
		capybara_display_text(value, icon, stat_pos_sounds, stat_neg_sounds, pos, Vector2(0, -100), player_index)

func capybara_on_random_weapon_cursed(value: int, player_index: int) -> void :
	var icon_data = load("res://mods-unpacked/Dbear-Capybara/contents/items/curse_forger/cp_curse_forger.png")
	var player: Player = players[player_index]
	if not player.dead:
		players_add_stats_count[player_index] += 1
		var pos = player.global_position - players_add_stats_count[player_index] * offset
		display_icon(value,icon_data , stat_pos_sounds, stat_neg_sounds, pos, Vector2(0, -30), player_index)

func capybara_on_random_item_cursed(value: int, player_index: int) -> void :
	var icon_data = load("res://mods-unpacked/Dbear-Capybara/icons/cp_item_cursed_icon.png")
	var player: Player = players[player_index]
	if not player.dead:
		players_add_stats_count[player_index] += 1
		var pos = player.global_position - players_add_stats_count[player_index] * offset
		display_icon(value,icon_data , stat_pos_sounds, stat_neg_sounds, pos, Vector2(0, -30), player_index)

func capybara_on_tribulation(value: int, player_index: int) -> void :
	var player: Player = players[player_index]
	var icon = load("res://mods-unpacked/Dbear-Capybara/icons/cp_tribulation_icon.png")

	if not player.dead:
		players_add_stats_count[player_index] += 1
		var pos = player.global_position - players_add_stats_count[player_index] * offset
		capybara_display_icon(value, icon, stat_neg_sounds, stat_pos_sounds, pos, Vector2(0, -100), player_index)

func capybara_on_gold_added(value: int, player_index: int) -> void :
	var player: Player = players[player_index]

	if not player.dead:
		var pos = player.global_position - players_add_stats_count[player_index] * offset
		players_add_stats_count[player_index] += 1
		display_icon(value, ItemService.get_icon(Keys.icon_harvesting_hash), stat_pos_sounds, stat_neg_sounds, pos, Vector2(0, -30), player_index)

func capybara_pet_work_gain(value: int, pos: Vector2, player_index) -> void :
	capybara_display_icon_minor(value, ItemService.get_icon(Keys.icon_harvesting_hash), stat_pos_sounds, stat_neg_sounds, pos, Vector2(0, -30), player_index)

func capybara_on_xp_added(value: int, player_index: int) -> void :
	var player: Player = players[player_index]
	var xp_icon = load("res://items/all/bean_teacher/bean_teacher_icon.png")
	if not player.dead:
		var pos = player.global_position - players_add_stats_count[player_index] * offset
		players_add_stats_count[player_index] += 1
		display_icon(value, xp_icon, stat_pos_sounds, stat_neg_sounds, pos, Vector2(0, -30), player_index)

func on_relive_by_upgrades(value: int, player_index: int) -> void :
	var icon_data_1 = load("res://mods-unpacked/Dbear-Capybara/icons/relive/cp_relive_by_up_grades_icon.png")
	var player: Player = players[player_index]
	if not player.dead:
		players_add_stats_count[player_index] += 1
		var pos = player.global_position - players_add_stats_count[player_index] * offset
		capybara_display_icon(value,icon_data_1 , stat_pos_sounds, stat_neg_sounds, pos, Vector2(0, -30), player_index)

func on_stat_added(stat: int, value: int, db_mod: float, player_index: int, pos_sounds: Array = stat_pos_sounds, neg_sounds: Array = stat_neg_sounds) -> void :
	var capybara_enemy_damage = load("res://mods-unpacked/Dbear-Capybara/icons/cp_enemy_damage_icon.png")
	var capybara_enemy_speed = load("res://mods-unpacked/Dbear-Capybara/icons/cp_enemy_speed_icon.png")
	var capybara_enemy_health = load("res://mods-unpacked/Dbear-Capybara/icons/cp_enemy_health_icon.png")
	var capybara_weapon_slot = load("res://items/upgrades/weapon_slot/weapon_slot.png")
	var capybara_player: Player = players[player_index]
	if not capybara_player.dead:
		if stat == Keys.enemy_damage_hash:
			var capybara_pos = capybara_player.global_position - Vector2(0, 50) - players_add_stats_count[player_index] * offset
			players_add_stats_count[player_index] += 1
			capybara_display_icon_minor(value, capybara_enemy_damage, neg_sounds, pos_sounds, capybara_pos, direction, db_mod, player_index)
		elif stat == Keys.enemy_health_hash:
			var capybara_pos = capybara_player.global_position - Vector2(0, 50) - players_add_stats_count[player_index] * offset
			players_add_stats_count[player_index] += 1
			capybara_display_icon_minor(value, capybara_enemy_health, neg_sounds, pos_sounds, capybara_pos, direction, db_mod, player_index)
		elif stat == Keys.enemy_speed_hash:
			var capybara_pos = capybara_player.global_position - Vector2(0, 50) - players_add_stats_count[player_index] * offset
			players_add_stats_count[player_index] += 1
			capybara_display_icon_minor(value, capybara_enemy_speed, neg_sounds, pos_sounds, capybara_pos, direction, db_mod, player_index)
		elif stat == Keys.weapon_slot_hash:
			var capybara_pos = capybara_player.global_position - Vector2(0, 50) - players_add_stats_count[player_index] * offset
			players_add_stats_count[player_index] += 1
			capybara_display_icon_minor(value, capybara_weapon_slot, pos_sounds, neg_sounds, capybara_pos, direction, db_mod, player_index)
		elif stat == Keys.bounce_hash:
			var capybara_pos = capybara_player.global_position - Vector2(0, 50) - players_add_stats_count[player_index] * offset
			players_add_stats_count[player_index] += 1
			var weapon_icon = ItemService.get_weapon_from_weapon_id(Keys.generate_hash("weapon_slingshot")).icon
			capybara_display_icon_minor(value, weapon_icon, pos_sounds, neg_sounds, capybara_pos, direction, db_mod, player_index)
		elif stat == Keys.burning_cooldown_reduction_hash:
			var capybara_pos = capybara_player.global_position - Vector2(0, 50) - players_add_stats_count[player_index] * offset
			players_add_stats_count[player_index] += 1
			var item_icon = ItemService.get_item_from_id(Keys.generate_hash("item_eyes_surgery")).icon
			capybara_display_icon_minor(value, item_icon, pos_sounds, neg_sounds, capybara_pos, direction, db_mod, player_index)
		elif stat == Keys.explosion_damage_hash:
			var capybara_pos = capybara_player.global_position - Vector2(0, 50) - players_add_stats_count[player_index] * offset
			players_add_stats_count[player_index] += 1
			var item_icon = ItemService.get_item_from_id(Keys.generate_hash("item_dynamite")).icon
			capybara_display_icon_minor(value, item_icon, pos_sounds, neg_sounds, capybara_pos, direction, db_mod, player_index)
		elif stat == Keys.explosion_size_hash:
			var capybara_pos = capybara_player.global_position - Vector2(0, 50) - players_add_stats_count[player_index] * offset
			players_add_stats_count[player_index] += 1
			var item_icon = ItemService.get_item_from_id(Keys.generate_hash("item_plastic_explosive")).icon
			capybara_display_icon_minor(value, item_icon, pos_sounds, neg_sounds, capybara_pos, direction, db_mod, player_index)
		elif stat == Keys.generate_hash("capybara_crystal_jelly"):
			var capybara_pos = capybara_player.global_position - Vector2(0, 50) - players_add_stats_count[player_index] * offset
			players_add_stats_count[player_index] += 1
			var item_icon = ItemService.get_item_from_id(Keys.generate_hash("item_crystal_jelly")).icon
			capybara_display_icon_minor(value, item_icon, pos_sounds, neg_sounds, capybara_pos, direction, db_mod, player_index)
		else:
			.on_stat_added(stat, value, db_mod, player_index, pos_sounds, neg_sounds)

func _on_unit_took_damage(unit: Unit, value: int, _knockback_direction: Vector2, is_crit: bool, is_dodge: bool, is_protected: bool, armor_did_something: bool, _args: TakeDamageArgs, hit_type: int, is_one_shot: bool) -> void :
	if not ProgressData.settings.damage_display:
		return
	if _args.has_meta("capybara_hunted"):
		var color: Color = Color.white
		if is_crit:
			color = Color.yellow
		var text = str(value)
		var always_display = false
		var need_translate = false
		var icon = ItemService.get_item_from_id(Keys.generate_hash("item_capybara_crystal_hawk")).icon
		display(text, unit.global_position, color, icon, duration, always_display, direction, need_translate)
		return
	if _args.has_meta("capybara_crystal_hawk"):
		var color: Color = Color.aqua
		var text = str(value)
		var always_display = false
		var need_translate = false
		var icon = null if hit_type == HitType.NORMAL else get_special_hit_icon(hit_type)
		display(text, unit.global_position, color, icon, duration, always_display, direction, need_translate)
		return
	if _args.has_meta("capybara_bonus_burning"):
		var color: Color = Color.white
		color = Color.orange
		var text = str(value)
		var always_display = false
		var need_translate = false
		var icon = null if hit_type == HitType.NORMAL else get_special_hit_icon(hit_type)
		display(text, unit.global_position, color, icon, duration, always_display, direction, need_translate)
		return
	if _args.has_meta("capybara_burn_can_crit"):
		var color: Color = Color.white
		color = Color.orangered
		var text = str(value)
		var always_display = false
		var need_translate = false
		var icon = null if hit_type == HitType.NORMAL else get_special_hit_icon(hit_type)
		display(text, unit.global_position, color, icon, duration, always_display, direction, need_translate)
		return
	if _args.has_meta("capybara_crystal_break"):
		var color: Color = Color("#BFD2FF")
		var text = str(value)
		var always_display = false
		var need_translate = false
		var icon = null if hit_type == HitType.NORMAL else get_special_hit_icon(hit_type)
		display(text, unit.global_position, color, icon, duration, always_display, direction, need_translate)
		return
	._on_unit_took_damage(unit, value, _knockback_direction, is_crit, is_dodge, is_protected, armor_did_something, _args, hit_type, is_one_shot)
