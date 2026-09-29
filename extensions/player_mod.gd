extends "res://entities/units/player/player.gd"

const CapybaraOnlineCompat = preload("res://mods-unpacked/Dbear-Capybara/extensions/brotato_online_compat.gd")

var capybara_angle_for_change_attack:float = 0.0
var capybara_change_attack = null
var capybara_special_dodge_times = 0
signal capybara_revive()
signal capybara_is_dodge()
var capybara_pets:Array = []
var capybara_turrets:Array = []
var capybara_killed_enemies = 0
var capybara_weapon_hold = 1
var cp_zone_min_pos:Vector2 = Vector2.ZERO
var cp_zone_max_pos:Vector2 = Vector2.ZERO
var capybara_round_weapons = null
var capybara_is_master = false
var capybara_player_scale = Vector2(1.0, 1.0)
var capybara_should_check_trees = false
var capybara_trees:int = 0
#var capybara_master_swords = []

func _ready() -> void:
	var capybara_pick_up_range = Utils.get_stat(Keys.pickup_range_hash, player_index)
	_item_attract_area.apply_pickup_range_effect(capybara_pick_up_range)

func _physics_process(delta:float) -> void :
	_capybara_move_weapons(delta)
	_capybara_manage_size()

func _capybara_manage_size() -> void:
	var size_modify = min(max(-0.5, Utils.get_stat(Keys.generate_hash("capybara_character_size"), player_index)/100.0), 10.0)
	var new_scale = Vector2(1.0 + size_modify, 1.0 + size_modify)
	if new_scale != capybara_player_scale:
		scale /= capybara_player_scale
		scale *= new_scale
	capybara_player_scale = new_scale

func _capybara_move_weapons(delta:float) -> void:
	if capybara_change_attack or capybara_round_weapons:
		capybara_angle_for_change_attack += 2 * delta
		if capybara_angle_for_change_attack > 2*PI:
			capybara_angle_for_change_attack = 0
		if not capybara_is_master:
			_weapons_container.capybara_update_weapons_positions(current_weapons, capybara_angle_for_change_attack)
		else:
			_weapons_container.capybara_update_weapons_positions_master(current_weapons, capybara_angle_for_change_attack)
func capybara_get_structure_pet(pets) -> Array:
	var structures = []
	if pets.size() > 0:
		for pet in pets:
			if pet is BotOMine:
				structures.append(pet)
	var capybara_future_effects = RunData.get_player_effect(Keys.generate_hash("capybara_boost_turret_when_nearby"), player_index)
	if capybara_future_effects.size() > 0:
		for structure in structures:
			var capybara_attack_speed_boost = 1.0
			var particles = null
			
			particles = load("res://mods-unpacked/Dbear-Capybara/contents/projectiles/future_particles.tscn").instance()
		
			for effect in capybara_future_effects:
				if (structure.global_position - global_position).length() <= 400:
					capybara_attack_speed_boost = effect[1] as float
					if not structure.has_outline(Color.aqua):
						structure.add_outline(Color.aqua)
						particles.visible = true
						particles.name = "capybara_future_particles"
						if not structure.has_node("capybara_future_particles"):
							structure.add_child(particles)
						var future_p = structure.get_node_or_null("capybara_future_particles")
						future_p.visible =true
						TempStats.add_stat(effect[0],effect[2], player_index)
						structure._base_weapon_stats.cooldown = 32/capybara_attack_speed_boost
				else:
					if structure.has_outline(Color.aqua):
						var particles_to_remove = structure.get_node_or_null("capybara_future_particles")
						if particles_to_remove:
							particles_to_remove.visible = false
						structure.remove_outline(Color.aqua)
						TempStats.remove_stat(effect[0], effect[2], player_index)
						structure._base_weapon_stats.cooldown = 32
	return structures

func swampman_add_weapon(weapons: Array , attach_to: Vector2, damage_shrink:float) -> Array:
	var weapons_data = []
	var i = 0
	for weapon in weapons:
		var instance = weapon.scene.instance().duplicate()
		instance.weapon_pos = i
		i += 1
		instance.stats = weapon.stats.duplicate()
		instance.stats.damage = weapon.stats.damage * damage_shrink

		var copied_scaling_stats := []
		for stat in weapon.stats.scaling_stats:
			copied_scaling_stats.append([
				stat[0],
				stat[1] * damage_shrink
			])
		instance.stats.scaling_stats = copied_scaling_stats
		instance.weapon_id = weapon.weapon_id 
		instance.weapon_id_hash = weapon.get_weapon_id_hash()
		instance.tier = weapon.tier
		instance.weapon_sets = weapon.sets
		instance.is_cursed = weapon.is_cursed
		instance.connect("tracked_value_updated", weapon, "on_tracked_value_updated")
		instance.connect("tracked_value_set", weapon, "on_tracked_value_set")

		for effect in weapon.effects:
			instance.effects.push_back(effect.duplicate())

		instance.global_position = attach_to
		weapons_data.push_back(instance)
	
	return weapons_data

func capybara_pet_add_weapon(weapons: Array , attach_to: Vector2, damage, scaling_stats) -> Array:
	var weapons_data = []
	var i = 0
	for weapon in weapons:
		var instance = weapon.scene.instance().duplicate()
		instance.weapon_pos = i
		i += 1
		instance.stats = weapon.stats.duplicate()
		instance.stats.damage = damage
		instance.stats.scaling_stats = scaling_stats
		instance.weapon_id = weapon.weapon_id 
		instance.weapon_id_hash = weapon.get_weapon_id_hash()
		instance.tier = weapon.tier
		instance.weapon_sets = weapon.sets
		instance.is_cursed = weapon.is_cursed
		instance.connect("tracked_value_updated", weapon, "on_tracked_value_updated")
		instance.connect("tracked_value_set", weapon, "on_tracked_value_set")

		for effect in weapon.effects:
			instance.effects.push_back(effect.duplicate())

		instance.global_position = attach_to
		weapons_data.push_back(instance)
	
	return weapons_data

func check_not_moving_stats(movement: Vector2) -> void :
	.check_not_moving_stats(movement)
	var capybara_gain_stats_per_interval = RunData.get_player_effect(Keys.generate_hash("gain_stats_per_interval"), player_index)

	if not not_moving_bonuses_applied and capybara_gain_stats_per_interval.size() > 0 and movement.x == 0 and movement.y == 0:
		not_moving_bonuses_applied = true
		_not_moving_timer.start()

	elif not_moving_bonuses_applied and (movement.x != 0 or movement.y != 0):
		not_moving_bonuses_applied = false
		_not_moving_timer.stop()

func apply_items_effects() -> void : #隐藏原型土豆的功能
	var capybara_potato_texture = load("res://entities/units/player/potato.png")
	var capybara_transparent_texture = load("res://mods-unpacked/Dbear-Capybara/extensions/cp_null.png")
	var capybara_legs = $Animation/Legs
	var capybara_potato = $Animation / Sprite
	capybara_potato.texture = capybara_potato_texture
	capybara_legs.visible = true
	.apply_items_effects()
	for effect in RunData.get_player_character(player_index).effects:
		if effect.custom_key == "capybara_hide_potato":
			var potato = $Animation / Sprite
			potato.texture = capybara_transparent_texture
			var legs = $Animation/Legs
			legs.visible = false

func capybara_disabled_timer_timeout() -> void:
	var capybara_disabled_effects = RunData.get_player_effect(Keys.generate_hash("capybara_disabled"),player_index)
	if capybara_disabled_effects.size() > 0:
		capybara_weapon_hold = min(current_weapons.size(), capybara_weapon_hold + 1)
		capybara_handle_disabled()

func _capybara_on_one_second_timeout() -> void :
	capybara_get_structure_pet(capybara_pets)
	var lose_percent_hp = RunData.get_player_effect(Keys.generate_hash("capybara_lose_percent_hp_per_second"), player_index)
	if lose_percent_hp > 0:
		var hp = Utils.get_stat(Keys.stat_max_hp_hash, player_index)
		var damage = hp * lose_percent_hp/100.0
		on_damage_effect(damage, false, false, self)
	var capybara_effect_1: Array = RunData.get_player_effect(Keys.generate_hash("gain_stats_per_interval"), player_index)
	for gain_effect in capybara_effect_1:
		assert (gain_effect[0] is int)
		var stat_key: int = gain_effect[0]
		var value: int = gain_effect[1]
		var interval: int = gain_effect[2]
		var reset_on_moving: bool = gain_effect[3]
		if _one_second_timeouts % interval == 0 and not _one_second_timeouts == 0:
			if reset_on_moving == true:
				if  not not_moving_bonuses_applied:
					TempStats.add_stat(stat_key, 0, player_index)
				else:
					RunData.add_stat(stat_key, value, player_index)
					RunData.add_tracked_value(player_index, Keys.generate_hash("character_capybara"), value)
			else:
				RunData.add_stat(stat_key, value, player_index)
	var capybara_projectile_per_interval = RunData.get_player_effect(Keys.generate_hash("capybara_projectile_per_interval"), player_index)
	if capybara_projectile_per_interval.size() > 0:
		for effect in capybara_projectile_per_interval:
			if _one_second_timeouts % effect[3][0] == 0:
				var capybara_args: = WeaponServiceInitStatsArgs.new()
				var weapon_stats = load(effect[2])
#				if not weapon_stats is RangedWeaponStats:
#					weapon_stats = load("res://mods-unpacked/Dbear-Capybara/contents/items/curse_scolar_book/curse_scholar_projectile_weapon_stats.tres")
				var capybara_current_weapon_stats = WeaponService.init_ranged_stats(weapon_stats, player_index, false, capybara_args)
				var capybara_count:int = effect[4] + Utils.get_stat(effect[0], player_index) * (effect[3][1]/100.0)
				if capybara_count > effect[1]:
					capybara_count = effect[1]
				var angle = 2*PI/(capybara_count+ RunData.get_player_effect(Keys.projectiles_hash,player_index))
				for i in range(0,capybara_count + RunData.get_player_effect(Keys.projectiles_hash,player_index)):
					var capybara_projectile_arg = WeaponServiceSpawnProjectileArgs.new()
					capybara_projectile_arg.damage_tracking_key_hash = effect[5]
					capybara_projectile_arg.from_player_index = player_index
					var capybara_direction = angle * i
					if effect[6]:
						capybara_direction = rand_range(0, 2*PI)
					var projectile = WeaponService.manage_capybara_spawn_projectile(
					self,
					capybara_current_weapon_stats, 
					capybara_direction, 
					effect[6],
					_entity_spawner_ref,
					self, 
					capybara_projectile_arg
					)
	var max_working_pets = 0
	var pet_is_working = 0
	for pet in capybara_pets:
		pet_is_working += 1
		var main = get_tree().current_scene
		if pet._end_of_wave:
			continue
		pet.reload_data()
		var capybara_pet_structure = RunData.get_player_effect(Keys.generate_hash("capybara_pet_structure_gold"), player_index)
		if capybara_pet_structure.size() > 0:
			for effect in capybara_pet_structure:
				if effect[6] > max_working_pets:
					max_working_pets = effect[6]
				var gold_gain = min(effect[4], 1 + RunData.get_nb_structures(player_index) * effect[2]/100.0)
				# 👇 用新计时器
				if _one_second_timeouts % effect[3] == 0:
					RunData.add_gold(gold_gain, player_index)
					RunData.add_tracked_value(player_index, Keys.generate_hash("character_golden"), gold_gain)
					main._floating_text_manager.capybara_pet_work_gain(gold_gain, pet.global_position + Vector2(0,-30), player_index)
		if pet_is_working >= max_working_pets:
			break

func cp_main():
	var main = get_tree().current_scene
	return main

func capybara_should_run_authoritative_logic() -> bool:
	return CapybaraOnlineCompat.should_run_authoritative_logic(self)

func add_weapon(weapon: WeaponData, pos: int) -> void :
	.add_weapon(weapon, pos)
	call_deferred("capybara_handle_disabled")

func capybara_handle_disabled() -> void:
	var capybara_disabled_effects = RunData.get_player_effect(Keys.generate_hash("capybara_disabled"),player_index)
	if capybara_disabled_effects.size() > 0:
		var enabled_weapons = []
		for weapon in current_weapons:
			var pos = weapon.weapon_pos
			if pos >= capybara_weapon_hold:
				current_weapons[pos].visible = false
				current_weapons[pos]._range.set_deferred("monitoring", false)
			else:
				current_weapons[pos].visible = true
				current_weapons[pos]._range.set_deferred("monitoring", true)
				enabled_weapons.append(weapon)
		_weapons_container.update_weapons_positions(enabled_weapons)

var capybara_disabled_timer = null

func _capybara_manage_wave_timer() -> void:
	var capybara_time_change = Utils.get_stat(Keys.generate_hash("stat_capybara_wave_time"), player_index)
#	var capybara_time_for_x_items = RunData.get_player_effect(Keys.generate_hash("capybara_wave_time_for_x_items"), player_index)
#	for effect in capybara_time_for_x_items:
#		var item_count = RunData.capybara_get_nb_of_item(effect[2], player_index)
#		var stat_scaled_value = effect[3]
#		var add_value = effect[1]
#		capybara_time_change += ((add_value * item_count)/stat_scaled_value) as int
	var new_time = cp_main()._wave_timer.wait_time + capybara_time_change
	if new_time < cp_main()._wave_timer.wait_time/3:
		new_time = cp_main()._wave_timer.wait_time/3
	elif new_time > 120:
		new_time = 120
	cp_main()._wave_timer.start(new_time)
	var lose_percent_hp = RunData.get_player_effect(Keys.generate_hash("capybara_lose_percent_hp_per_second"), player_index)
	if lose_percent_hp > 0:
		_one_second_timer.start()
var capybara_crystal_upgrade_icon = load("res://mods-unpacked/Dbear-Capybara/icons/cp_crystal_heart_core.png")
var capybara_crystallized_particles = load("res://mods-unpacked/Dbear-Capybara/contents/projectiles/capybara_crystal_particles.tscn")

func _capybara_manage_crystallized() -> void:
	var main = cp_main()
	var crystal = Utils.get_stat(Keys.generate_hash("stat_capybara_crystal"), player_index)
	var crystal_state:int = min(crystal/Utils.CAPYBARA_CRYSTAL_MAX_RATE, Utils.CAPYBARA_DAMAGE_TAKEN_TO_BREAK)
	var current_crystal_state:int = RunData.get_stat(Keys.generate_hash("stat_capybara_crystal_state"), player_index)
	var lap:int = crystal_state - current_crystal_state
	if RunData.current_wave == 1 and ItemService.capybara_crystal_path(player_index) <= 0:
		var capybara_upgrade_to_process = UpgradesUI.UpgradeToProcess.new()
		capybara_upgrade_to_process.level = -1
		capybara_upgrade_to_process.player_index = player_index
		main._upgrades_to_process[player_index].push_back(capybara_upgrade_to_process)
		main._things_to_process_player_containers[player_index].upgrades.add_element(capybara_crystal_upgrade_icon, -1)
	for i in lap:
		RunData.add_stat(Keys.generate_hash("stat_capybara_crystal_state"),1, player_index)
		for effect in RunData.get_player_effect(Keys.generate_hash("capybara_stat_when_crystal_level"), player_index):
			RunData.add_stat(effect[0], effect[1], player_index)
		var capybara_upgrade_to_process = UpgradesUI.UpgradeToProcess.new()
		capybara_upgrade_to_process.level = - (i + 1 + current_crystal_state)
		capybara_upgrade_to_process.player_index = player_index
		main._upgrades_to_process[player_index].push_back(capybara_upgrade_to_process)
		main._things_to_process_player_containers[player_index].upgrades.add_element(capybara_crystal_upgrade_icon, - (i + 1 + current_crystal_state))
	if not has_outline(Color.white) and crystal_state > 1:
		var instance = capybara_crystallized_particles.instance()
		var child = instance.get_child(0)
		instance.visible = true
		instance.amount = crystal_state as int
		instance.position = Vector2(0,-20)
		child.amount = crystal_state
		child.scale_amount = 2.5 * (1 + 0.05 * crystal_state)
		instance.visible = true
		if RunData.current_wave == 1:
			yield(get_tree().create_timer(1), "timeout")
		add_child(instance)
		add_outline(Color.white)

func capybara_manage_merge_character() -> void:
	ItemService.capybara_merge_character[player_index] = null
	if RunData.capybara_last_character[player_index] and not RunData.get_player_effect(Keys.generate_hash("capybara_add_item"), player_index).size() > 0 and RunData.capybara_last_character[player_index].my_id == RunData.get_player_character(player_index).my_id:
		RunData.capybara_last_character[player_index] = null

func _capybara_manage_banned_items() -> void:
	var current_character = RunData.get_player_character(player_index)
	var banned_keys = []
	var die_on_one_hit = RunData.get_player_effect(Keys.die_in_one_hit_hash, player_index)
	if die_on_one_hit > 0:
		banned_keys.append_array(["stat_armor", "stat_hp_regeneration", "stat_max_hp", "stat_lifesteal"])
	for stat in ItemService.stats:
		if stat.is_primary_stat:
			var gain_stat = "gain_" + stat.stat_name
			var gain_stat_value = RunData.get_player_effect(Keys.generate_hash(gain_stat), player_index)
			if gain_stat_value != -100:
				continue
			var stat_name = gain_stat.trim_prefix("gain_")
			if not stat_name in banned_keys:
				banned_keys.append(stat_name)
	var cannot_level_up = RunData.get_player_effect(Keys.generate_hash("capybara_can_not_level_up"), player_index)
	if cannot_level_up.size() > 0:
		if not "xp_gain" in banned_keys:
			banned_keys.append("xp_gain")
	var player_run_data = RunData.players_data[player_index]
	for key in banned_keys:
		var upgrade_key = key.replace("stat_", "upgrade_")
		if not current_character.banned_upgrades.has(upgrade_key):
			current_character.banned_upgrades.push_back(upgrade_key)
	for item in ItemService.items:
		if item.tags.empty():
			continue
		var all_tags_are_banned = true
		for tag in item.tags:
			if not banned_keys.has(tag):
				all_tags_are_banned = false
				break
		if all_tags_are_banned and not player_run_data.banned_items.has(item.my_id_hash):
			player_run_data.banned_items.append(item.my_id_hash)
	if banned_keys.has("xp_gain") and not player_run_data.banned_items.has(Keys.item_celery_tea_hash):
		player_run_data.banned_items.append(Keys.item_celery_tea_hash)
#			if item.tags.has(key):
#				item_should_be_reloaded = false
#		if item_should_be_reloaded:
#			player_run_data.banned_items.erase(item.my_id_hash)
				
				
#		if ItemService.items.size() > (player_run_data.banned_items.size() + 20):
#			player_run_data.banned_items.push_back(item.my_id_hash)
#			print(item.my_id)
#	for item_key in RunData.players_data[player_index].banned_items:
#		print(Keys.hash_to_string[item_key])

func _capybara_manage_special_dodge() -> void:
	var capybara_special_dodge = RunData.get_player_effect(Keys.generate_hash("capybara_special_dodge"), player_index)
	if capybara_special_dodge.size() > 0:
		for effect in capybara_special_dodge:
			if effect[0] > 0 and Utils.get_stat(effect[1], player_index) > 0:
				capybara_special_dodge_times += int(effect[0] * Utils.get_stat(effect[1], player_index)/ 100.0)
				cp_main().capybara_update_special_dodge_label(player_index, capybara_special_dodge_times)

func init(zone_min_pos: Vector2, zone_max_pos: Vector2, p_players_ref: Array = [], entity_spawner_ref = null) -> void :
	cp_main().connect("cp_neutral_died", self,"_capybara_on_neutral_died")
	cp_main().connect("cp_levelled_up", self, "_capybara_on_levelled_up")
	cp_main().connect("end_of_the_wave", self, "_capybara_end_of_wave")
	cp_main().connect("capybara_healed", self,"_capybara_on_healed")
	cp_main().connect("cp_on_enemy_died",self,"_capybara_on_enemy_died")
	call_deferred("_capybara_manage_special_dodge")
	_capybara_manage_wave_timer()
	capybara_manage_merge_character()
	cp_zone_max_pos = zone_max_pos
	cp_zone_min_pos = zone_min_pos
	_capybara_spawn_trees((zone_min_pos + zone_max_pos)/2, RunData.get_player_effect(Keys.generate_hash("capybara_start_with_x_trees"), player_index))
	RunData.capybara_killed_enemies[player_index] = 0
	_one_second_timer.connect("timeout", self, "_capybara_on_one_second_timeout")
	var capybara_future_effects = RunData.get_player_effect(Keys.generate_hash("capybara_boost_turret_when_nearby"), player_index)
	if capybara_future_effects.size() > 0:
		_one_second_timer.start()
	var capybara_disabled_effects = RunData.get_player_effect(Keys.generate_hash("capybara_disabled"),player_index)
	if capybara_disabled_effects.size() > 0:
		for effect in capybara_disabled_effects:
			capybara_disabled_timer = Timer.new()
			capybara_disabled_timer.wait_time = effect[1]
			capybara_disabled_timer.connect("timeout", self, "capybara_disabled_timer_timeout")
			add_child(capybara_disabled_timer)
			capybara_disabled_timer.start()
	_capybara_spawn_for_every_stat(zone_min_pos,zone_max_pos)
	capybara_change_attack = RunData.get_player_effect(Keys.generate_hash("change_way_of_attack"), player_index)
	for effect in capybara_change_attack:
		if effect.custom_key == "master":
			capybara_is_master = true
	capybara_round_weapons = RunData.get_player_effect(Keys.generate_hash("capybara_round_weapons"), player_index)
	.init(zone_min_pos, zone_max_pos, p_players_ref, entity_spawner_ref)
	entity_spawner_ref.connect("pet_spawned",self,"_capybara_on_pet_spawned")
#	entity_spawner_ref.connect("neutral_spawned", self, "_capybara_on_neutral_spawned")
#	entity_spawner_ref.connect("neutral_respawned", self,"_capybara_on_neutral_respawned")
	var capybara_gain_stats_per_interval = RunData.get_player_effect(Keys.generate_hash("gain_stats_per_interval"), player_index)
	if capybara_gain_stats_per_interval.size() > 0:
		_one_second_timer.start()
	var capybara_projectile_per_interval = RunData.get_player_effect(Keys.generate_hash("capybara_projectile_per_interval"), player_index)
	if capybara_projectile_per_interval.size() > 0:
		_one_second_timer.start()
	var capybara_pet_structure = RunData.get_player_effect(Keys.generate_hash("capybara_pet_structure_gold"), player_index)
	if capybara_pet_structure.size() > 0:
		_one_second_timer.start()
	_capybara_manage_special_entities()
#	_capybara_spawn_bosses(global_position, 1)

var capybara_try_to_die: bool = false

func _capybara_manage_special_entities() -> void:
	var foxfire_scene:PackedScene = load("res://mods-unpacked/Dbear-Capybara/contents/pets/fox_fire/fox_fire.tscn")
	var capybara_effects = RunData.get_player_effect(Keys.generate_hash("foxfire_count"), player_index)
	var item_foxfire = RunData.get_player_item(Keys.generate_hash("item_foxfire"), player_index)
	if capybara_effects.size() > 0:
		var foxfire_items = []
		var foxfire_count = 0
		var items_foxfire = RunData.get_player_items(player_index)
		for item in items_foxfire:
			if item.my_id == "item_foxfire":
				foxfire_count += 1
				foxfire_items.append(item)
		for i in range(foxfire_count):
			var args = EntitySpawner.SpawnEntityArgs.new(global_position, - 1)
			args.player_index = player_index
			var foxfire = _entity_spawner_ref.spawn_entity(foxfire_scene, args)
			var item_data = foxfire_items[i]
			foxfire.capybara_init_trajectory(i, foxfire_count, self, capybara_effects[i], item_data)
	var cp_enemies_killed_counter_scene:PackedScene = load("res://mods-unpacked/Dbear-Capybara/contents/killed_enemies_counter/enemies_killed_counter.tscn")
	var capybara_args = EntitySpawner.SpawnEntityArgs.new(global_position, - 1)
	capybara_args.player_index = player_index
	var cp_enemies_killed_counter =  _entity_spawner_ref.spawn_entity(cp_enemies_killed_counter_scene, capybara_args)
	cp_enemies_killed_counter.capybara_init(self)
	var cp_holy_sword_scene:PackedScene = load("res://mods-unpacked/Dbear-Capybara/contents/pets/holy_sword_of_judgement/holy_sword.tscn")
	var capybara_holy_sword_effects = RunData.get_player_effect(Keys.generate_hash("capybara_holy_sword_of_judgement"), player_index)
	if capybara_holy_sword_effects.size() > 0:
		var new_items = []
		var count = 0
		var items = RunData.get_player_items(player_index)
		for item in items:
			if item.my_id == "item_golden_wings":
				count += 1
				new_items.append(item)
		for i in range(count):
			var args = EntitySpawner.SpawnEntityArgs.new(global_position, - 1)
			args.player_index = player_index
			var holy_sword = _entity_spawner_ref.spawn_entity(cp_holy_sword_scene, args)
			var item_data = new_items[i]
			holy_sword.capybara_init_trajectory(i, count, self, capybara_holy_sword_effects[i], item_data)
#	if RunData.current_wave < 7 and not RunData.capybara_null_crystal:
#		var living_crystal_scene:PackedScene = load("res://mods-unpacked/Dbear-Capybara/contents/entities/living_crystal.tscn")
#		var args = EntitySpawner.SpawnEntityArgs.new(global_position, - 1)
#		capybara_args.player_index = player_index
#		var living_crystal =  _entity_spawner_ref.spawn_entity(living_crystal_scene, args)
#		living_crystal.capybara_init(self)
func _capybara_on_neutral_spawned(neutral) -> void:
	pass

func _capybara_on_neutral_respawned(neutral) -> void:
	pass

signal capybara_player_killed_enemy(enemy, args)

var capybara_items_dropped = {}

func _capybara_on_enemy_died(enemy, args) -> void:
	emit_signal("capybara_player_killed_enemy",enemy,args)
	if RunData.get_player_effect(Keys.generate_hash("capybara_reload_when_cursed_killed"), player_index).size() > 0:
		if enemy is Enemy:
			if enemy.has_outline(Utils.CURSE_COLOR):
				for weapon in current_weapons:
					weapon._current_cooldown = 0
	var main = cp_main()
	if main._cleaning_up:
		return
	var special_drop_item_effects = RunData.get_player_effect(Keys.generate_hash("capybara_spawn_special_item"), player_index)
	for effect in special_drop_item_effects:
		if Utils.get_chance_success(effect[1]/100.0):
			if effect[2] < 0:
				main.capybara_spawn_consumable(enemy.global_position, effect)
			else:
				if effect[0] in capybara_items_dropped and capybara_items_dropped[effect[0]] < effect[2]:
					main.capybara_spawn_consumable(enemy.global_position, effect)
					capybara_items_dropped[effect[0]] += 1
				elif not effect[0] in capybara_items_dropped:
					capybara_items_dropped[effect[0]] = 1
	var capybara_gain_extra_material_for_killing_burning_enemy = RunData.get_player_effect(Keys.generate_hash("capybara_spawn_gold_burning"),player_index)
	for effect in capybara_gain_extra_material_for_killing_burning_enemy:
		if enemy is Enemy:
			if enemy._is_burning:
				if effect[0] == Keys.generate_hash("stat_capybara_gold"):
					main.spawn_gold(effect[1], enemy.global_position, 10)
				else:
					RunData.add_stat(effect[0], effect[1], player_index)
	capybara_killed_enemies += 1
	if enemy is Boss:
		var effects = RunData.get_player_effect(Keys.generate_hash("extra_boss_when_upgrade"), player_index)
		if effects.size() > 0:
			for effect in effects:
				if Utils.get_stat(effect[0], player_index) < effect[3]:
					RunData.add_stat(effect[0] , effect[4] , player_index)
	var tree_effects = RunData.get_player_effect(Keys.generate_hash("capybara_spawn_tree_every_enemies_killed"), player_index)
	if capybara_should_run_authoritative_logic() and tree_effects.size() > 0:
		for effect in tree_effects:
			var enemies_needed = effect[2] as int
			var number_to_spawn = effect[1] as int
			if capybara_killed_enemies > enemies_needed:
				capybara_killed_enemies -= enemies_needed
				for i in number_to_spawn:
					var zone_data:ZoneData = _capybara_get_current_zone_data()
					var queue = main._entity_spawner.queue_to_spawn_trees
					var groups_data = zone_data.groups_data_in_all_waves
					var neutral_scene = null
					for group_data in groups_data:
						if group_data.is_neutral:
							for unit_data in group_data.wave_units_data:
								neutral_scene = unit_data.unit_scene
								break
					if neutral_scene:
						var r = rand_range(100.0,150.0)
						var a = rand_range(0, 2*PI)
						var v = Vector2(r*cos(a),r*sin(a))
						queue.push_back([EntityType.NEUTRAL, neutral_scene, enemy.global_position + v])
						RunData.add_tracked_value(player_index, Keys.generate_hash("item_capybara_little_world"), 1)

func _capybara_spawn_trees(pos:Vector2, number_to_spawn:int) -> void:
	if not capybara_should_run_authoritative_logic():
		return
	var main = cp_main()
	var rand_a = rand_range(0,PI/3)
	for i in number_to_spawn:
		var zone_data:ZoneData = _capybara_get_current_zone_data()
		var queue = main._entity_spawner.queue_to_spawn_trees
		var groups_data = zone_data.groups_data_in_all_waves
		var neutral_scene = null
		for group_data in groups_data:
			if group_data.is_neutral:
				for unit_data in group_data.wave_units_data:
					neutral_scene = unit_data.unit_scene
					break
		if neutral_scene:
			var r = rand_range(200.0,250.0)
			var part_a = 2*PI/number_to_spawn
			var a = part_a * (i + 1) + rand_a
			var v = Vector2(r * cos(a), r * sin(a))
			var spawn_pos = pos + v
			spawn_pos.x = clamp(spawn_pos.x, cp_zone_min_pos.x, cp_zone_max_pos.x)
			spawn_pos.y = clamp(spawn_pos.y, cp_zone_min_pos.y, cp_zone_max_pos.y)

			queue.push_back([EntityType.NEUTRAL, neutral_scene, spawn_pos])

func _capybara_spawn_bosses(pos:Vector2, number_to_spawn:int) -> void:
	if not capybara_should_run_authoritative_logic():
		return
	var main = cp_main()
	for i in number_to_spawn:
		var queue = main._entity_spawner.queue_to_spawn_bosses
		var boss = Utils.get_rand_element(ItemService.elites)
		var boss_scene = boss.scene
		if boss_scene:
			var r = rand_range(200.0,250.0)
			var part_a = 2*PI/number_to_spawn
			var a = rand_range((i-1) * part_a, i * part_a)
			var x = clamp(r * cos(a), cp_zone_min_pos.x, cp_zone_max_pos.x)
			var y = clamp(r * sin(a), cp_zone_min_pos.y, cp_zone_max_pos.y)
			var v = Vector2(x,y)
			queue.push_back([EntityType.BOSS, boss_scene, pos + v])

func _capybara_spawn_pets(pos:Vector2, number_to_spawn:int, scene:PackedScene, effect) -> void:
	if not capybara_should_run_authoritative_logic():
		return
	var main = cp_main()
	for i in number_to_spawn:
		var queue = main._entity_spawner.queues_to_spawn_pets[player_index]
		var pet = effect
		var pet_scene = scene
		queue.push_back([EntityType.PET, pet_scene, pos, pet])
					
func _capybara_get_current_zone_data() -> ZoneData:
	var zone_data = ZoneService.zones[0]
	for zone in ZoneService.zones:
		if zone.my_id == RunData.current_zone:
			zone_data = zone
	return zone_data

func _capybara_on_pet_spawned(pet) -> void:
	if pet.player_index == player_index:
		capybara_pets.append(pet)

func _capybara_on_healed(_value:int, player_index:int) -> void:
	if not capybara_should_run_authoritative_logic():
		return
	var gain_gold_when_heal_effect = RunData.get_player_effect(Keys.generate_hash("gain_gold_when_heal"), player_index)
	var gain_stats_when_heal_effect = RunData.get_player_effect(Keys.generate_hash("gain_stats_when_heal"), player_index)
	if gain_gold_when_heal_effect.size() > 0:
		for effect in gain_gold_when_heal_effect:
			if Utils.get_chance_success(effect[2]/100.0):
				RunData.add_gold(effect[1] , player_index)
				cp_main()._floating_text_manager.capybara_on_gold_added(effect[1], player_index)
				RunData.add_tracked_value(player_index, Keys.generate_hash("item_philosopher_stone"), effect[1])
	if gain_stats_when_heal_effect.size() > 0:
		for effect in gain_stats_when_heal_effect:
			var stat = effect[0]
			if Utils.get_chance_success(effect[2]/100.0):
				RunData.add_stat(stat, effect[1] , player_index)

func capybara_manage_crystal_items() -> void:
	var number = min(RunData.current_wave/ 5 + 1, 4) as int
	var count = 0
	var rand_uncrystallized_items = RunData.capybara_get_uncrystallized_items(player_index)
	for rand_uncrystallized_item in rand_uncrystallized_items:
		if Utils.get_chance_success(min(Utils.CAPYBARA_ITEM_CRYSTALLIZATION_CAP_CHANCE, Utils.get_stat(Keys.generate_hash("stat_capybara_crystal"), player_index)/Utils.CAPYBARA_CRYSTAL_CHANCE_RATE)/100.0):
			var crystallized_item = RunData.capybara_crystallize_item(rand_uncrystallized_item, player_index)
			if not rand_uncrystallized_item is WeaponData and not rand_uncrystallized_item is CharacterData:
				RunData.add_item(crystallized_item, player_index)
				RunData.capybara_remove_item(rand_uncrystallized_item, player_index)
				count += 1
		if count >= number:
			break
	var rand_uncrystallized_weapons = RunData.capybara_get_uncrystallized_weapons(player_index)
	for rand_uncrystallized_weapon in rand_uncrystallized_weapons:
		if Utils.get_chance_success(min(Utils.CAPYBARA_ITEM_CRYSTALLIZATION_CAP_CHANCE, Utils.get_stat(Keys.generate_hash("stat_capybara_crystal"), player_index)/Utils.CAPYBARA_CRYSTAL_CHANCE_RATE)/100.0):
			var crystallized_weapon = RunData.capybara_crystallize_item(rand_uncrystallized_weapon, player_index)
			if rand_uncrystallized_weapon is WeaponData:
				RunData.add_weapon(crystallized_weapon, player_index)
				RunData.remove_weapon(rand_uncrystallized_weapon, player_index)
				break
	RunData.capybara_manage_crystallized_items_duplicate(player_index)


func _capybara_end_of_wave() -> void:
	_capybara_manage_banned_items()
	RunData.capybara_killed_enemies[player_index] = 0
	var main = cp_main()
	main.capybara_wave_end = true
	if not capybara_should_run_authoritative_logic():
		return
	for item in RunData.get_player_items(player_index):
		if item.my_id_hash == Keys.generate_hash("item_crystal_turret_charge") and not RunData.capybara_check_crystal(item):
			RunData.remove_item(item, player_index)
	capybara_manage_crystal_items()
	var capybara_pet_structure = RunData.get_player_effect(Keys.generate_hash("capybara_pet_structure_gold"), player_index)
	if capybara_pet_structure.size() > 0:
		# 👇 用新的计时器
		for effect in capybara_pet_structure:
			var gold_gain = RunData.get_nb_pets(player_index) * effect[0]
			RunData.add_gold(gold_gain, player_index)
			main._floating_text_manager.capybara_on_gold_added(gold_gain, player_index)
			if RunData.get_player_gold(player_index) >= 300:
				if RunData.get_stat(Keys.weapon_slot_hash, player_index) < effect[5]:
					RunData.add_gold(effect[1], player_index)
					RunData.add_stat(Keys.weapon_slot_hash, 1, player_index)
	var effects = RunData.get_player_effects(player_index)
	for effect in effects[Keys.generate_hash("capybara_curse_random_weapon")]:
		var possible_curse= []
		var weapons = RunData.get_player_weapons(player_index)
		for weapon in weapons:
			if not weapon.is_cursed:
				possible_curse.append(weapon)
		if possible_curse.size() > 0:
			var weapon_to_curse = Utils.get_rand_element(possible_curse)
			for dlc_id in RunData.enabled_dlcs:
				var dlc_data = ProgressData.get_dlc_data(dlc_id)
				if dlc_data and dlc_data.has_method("curse_item"):
					var weapon_to_cursed = dlc_data.curse_item(weapon_to_curse, player_index, false, 0.5)
					RunData.add_weapon(weapon_to_cursed, player_index)
					RunData.remove_weapon(weapon_to_curse, player_index)
					main._floating_text_manager.capybara_on_random_weapon_cursed(1,player_index)
		else:
			assert (effect[0] is int)
			RunData.add_stat(effect[0], effect[1], player_index)
			var value = -effect[1]
			RunData.add_tracked_value(player_index, Keys.generate_hash("item_curse_forger"), value)
	var capybara_stats = RunData.get_player_effect(Keys.generate_hash("convert_certain_stats"), player_index)
	for stat_to_convert in capybara_stats:
		var max_stat = stat_to_convert[3]
		var stat_to_remove = stat_to_convert[0]
		var stat_to_add = stat_to_convert[2]
		var to_remove_value = stat_to_convert[1]
		var to_add_value = stat_to_convert[4]
		var stat_to_remove_has_value = RunData.get_stat(stat_to_remove, player_index) as int
		var current_weapon_slot = RunData.get_stat(Keys.weapon_slot_hash, player_index)
		var n: int = stat_to_remove_has_value/to_remove_value
		if to_remove_value <= stat_to_remove_has_value:
			if stat_to_add != Keys.weapon_slot_hash:
				RunData.remove_stat(stat_to_remove, to_remove_value*n, player_index)
				RunData.add_stat(stat_to_add, to_add_value*n, player_index)
			elif current_weapon_slot < max_stat:
				if current_weapon_slot + to_add_value*n > max_stat:
					to_add_value = max_stat - current_weapon_slot
					RunData.remove_stat(stat_to_remove, to_remove_value, player_index)
					RunData.add_stat(stat_to_add, to_add_value, player_index)
				else:
					RunData.remove_stat(stat_to_remove, to_remove_value * n, player_index)
					RunData.add_stat(stat_to_add, to_add_value * n, player_index)

func _capybara_on_neutral_died(neutral:Neutral, args:Entity.DieArgs) -> void:
	if not capybara_should_run_authoritative_logic():
		return
	var main = cp_main()
	if not main._cleaning_up:
		var chance = 0
		var capybara_turret_effect:TurretEffect = null
		for effect in RunData.get_player_effect(Keys.generate_hash("capybara_spwan_fairy_when_tree"), player_index):
			chance = effect.value/100.0
			capybara_turret_effect = effect.effect
			if Utils.get_chance_success(chance) and capybara_turret_effect:
				var pos = main._entity_spawner.get_spawn_pos_in_area(global_position, 200)
				var queue = main._entity_spawner.queues_to_spawn_structures[player_index]
				queue.push_back([EntityType.STRUCTURE, capybara_turret_effect.scene, pos, capybara_turret_effect])

func _capybara_spawn_for_every_stat(zone_min_pos:Vector2,zone_max_pos:Vector2) -> void:
	if not capybara_should_run_authoritative_logic():
		return
	var main = cp_main()
	if not main._cleaning_up:
		var capybara_turret_effect:TurretEffect
		for effect in RunData.get_player_effect(Keys.generate_hash("capybara_spawn_turret_for_per_stat"), player_index):
			var count:int = (Utils.get_stat(effect.custom_key_hash, player_index)/effect.value)*effect.stat_scaled
			for i in count:
				capybara_turret_effect = effect.effect
				var pos = _capybara_get_pos_around_player(zone_min_pos,zone_max_pos)
				var queue = main._entity_spawner.queues_to_spawn_structures[player_index]
				queue.push_back([EntityType.STRUCTURE, capybara_turret_effect.scene, pos, capybara_turret_effect])

func _capybara_get_pos_around_player(zone_min_pos:Vector2,zone_max_pos:Vector2) -> Vector2:
	var rand_r = rand_range(100,500)
	var rand_a = rand_range(0, 2*PI)
	return Vector2(rand_r*cos(rand_a),rand_r*sin(rand_a)) + (zone_min_pos+zone_max_pos)/2

func _capybara_on_levelled_up(cp_player_index:int) -> void:
	if cp_player_index == player_index:
		if not capybara_should_run_authoritative_logic():
			return
		var main = cp_main()
		var capybara_curse_item_effects = RunData.get_player_effect(Keys.generate_hash("capybara_curse_rand_item"),player_index)
		if capybara_curse_item_effects:
			var capybara_items = RunData.get_player_items(player_index)
			var items_to_curse = []
			for effect in capybara_curse_item_effects:
				for item in capybara_items:
					if not item.is_cursed and not item is CharacterData:
						items_to_curse.append(item)

				if items_to_curse.size() > 0:
					var capybara_rand_item:ItemData = Utils.get_rand_element(items_to_curse)
					for dlc_id in RunData.enabled_dlcs:
						var dlc_data = ProgressData.get_dlc_data(dlc_id)
						if dlc_data and dlc_data.has_method("curse_item") and capybara_rand_item:
							var cursed_capybara_rand_item = dlc_data.curse_item(capybara_rand_item, player_index, false, 0.5)
							
							RunData.add_item(cursed_capybara_rand_item, player_index)
							RunData.capybara_remove_item(capybara_rand_item, player_index)
							RunData.add_tracked_value(player_index, Keys.generate_hash("character_curse_scholar"), 1)
							main._floating_text_manager.capybara_on_random_item_cursed(1,player_index)
				else:
					RunData.add_stat(effect[0], effect[1], player_index)


		var capybara_effects_mod_1 = RunData.get_player_effect(Keys.generate_hash("extra_boss_when_upgrade"), player_index)
		var capybara_effects = RunData.get_player_effects(player_index)
		if capybara_effects_mod_1.size() > 0:
			for effect in capybara_effects_mod_1:
				var level_check = RunData.get_player_level(player_index) % effect[1]
				var level = RunData.get_player_level(player_index)
				var level_base = RunData.get_player_level(player_index)/effect[1]
				var final_level_base = level_base
				if level_base > effect[2]:
					final_level_base = effect[2] as int
				for i in range(0, final_level_base):
					if level_check == 0 and level != 0 and RunData.current_wave < RunData.nb_of_waves-1:
						var rand_elite_id = ItemService.get_random_elite_id_hash_from_zone(ZoneService.current_zone.my_id)
						capybara_effects[Keys.extra_enemies_next_wave_hash].append(["res://zones/common/elite/group_elite.tres", 1, rand_elite_id])
				if level_check == 0 and level != 0:
					if RunData.current_wave < RunData.nb_of_waves -1:
						var sound = load("res://mods-unpacked/Dbear-Capybara/music/cp_a_tribulation.mp3")
						SoundManager.play(sound, -5, 0.2)
						main._floating_text_manager.capybara_on_tribulation(0, player_index)

func capybara_spawn_holy_sword() -> void:
	var cp_holy_sword_scene:PackedScene = load("res://mods-unpacked/Dbear-Capybara/contents/pets/holy_sword_of_judgement/holy_sword.tscn")
	var capybara_holy_sword_effects = RunData.get_player_effect(Keys.generate_hash("capybara_holy_sword_of_judgement"), player_index)
	if capybara_holy_sword_effects.size() > 0:
		var new_items = []
		var count = 0
		var items = RunData.get_player_items(player_index)
		for item in items:
			if item.my_id == "item_golden_wings":
				count += 1
				new_items.append(item)
		for i in range(count):
			var args = EntitySpawner.SpawnEntityArgs.new(global_position, - 1)
			args.player_index = player_index
			var holy_sword = _entity_spawner_ref.spawn_entity(cp_holy_sword_scene, args)
			var item_data = new_items[i]
			holy_sword.capybara_init_trajectory(i, count, self, capybara_holy_sword_effects[i], item_data)

func die(args: = Utils.default_die_args) -> void :
	# BrotatoOnline sets this marker while applying an authoritative remote death.
	# Do not let Capybara's local revive interception block that synchronized death.
	if bool(get_meta("brotato_online_allow_remote_die", false)):
		.die(args)
		return
	var capybara_relive_by_upgrades = RunData.get_player_effect(Keys.generate_hash("relive_by_upgrades"), player_index)
	var capybara_have_golden_heart = RunData.get_player_item(Keys.generate_hash("item_golden_heart"), player_index)
	if capybara_have_golden_heart != null:
		capybara_try_to_die = true
		cleaning_up = false
		return
	if capybara_relive_by_upgrades.size() > 0:
		for effect in capybara_relive_by_upgrades:
			if Utils.get_stat(effect[0], player_index) >= effect[1]:
				capybara_try_to_die = true
				cleaning_up = false
				return
	.die(args)

signal capybara_holy_sword_added()

var capybara_no_hurt = false

func capybara_handle_no_hurt() -> void:
	modulate.a = 0.5
	capybara_no_hurt = true
	TempStats.add_stat(Keys.stat_speed_hash, 30, player_index)
	yield(get_tree().create_timer(1), "timeout")
	TempStats.remove_stat(Keys.stat_speed_hash, 30, player_index)
	modulate.a = 1
	capybara_no_hurt = false

func get_damage_value(dmg_value: int,_from_player_index: int,armor_applied := true,dodgeable := true,_is_crit := false,_hitbox: Hitbox = null,_is_burning := false) -> Unit.GetDamageValueResult:
	var capybara_special_dodge: Array = RunData.get_player_effect(Keys.generate_hash("capybara_special_dodge"), player_index)
	if dodgeable and capybara_special_dodge_times > 0:
		# 必须先消耗，避免后面的闪避效果触发伤害重入时重复使用。
		capybara_special_dodge_times -= 1
		cp_main().capybara_update_special_dodge_label(player_index, capybara_special_dodge_times)
		var capybara_result := Unit.GetDamageValueResult.new()
		capybara_result.value = 0
		capybara_result.dodged = true
		capybara_result.protected = false
		return capybara_result

	# 拥有特殊闪避效果时禁止普通随机闪避，但仍让父类正常处理hit_protection和护甲。
	var capybara_allow_normal_dodge: bool = dodgeable and capybara_special_dodge.empty()
	return .get_damage_value(dmg_value,_from_player_index,armor_applied,capybara_allow_normal_dodge,_is_crit,_hitbox,_is_burning)
		

func take_damage(value:int, args: TakeDamageArgs) -> Array:
	if capybara_no_hurt:
		return [0,0,false]
	var capybara_damage_took = .take_damage(value, args)
	if capybara_damage_took[2]:
		emit_signal("capybara_is_dodge")
	if capybara_damage_took[1] > 0:
		var capybara_disabled_effects = RunData.get_player_effect(Keys.generate_hash("capybara_disabled"),player_index)
		if capybara_disabled_effects.size() > 0:
			capybara_weapon_hold = max(1, capybara_weapon_hold - 1)
			capybara_handle_disabled()
			capybara_disabled_timer.start()
			capybara_handle_no_hurt()
	var capybara_relive_by_upgrades = RunData.get_player_effect(Keys.generate_hash("relive_by_upgrades"), player_index)
	var capybara_have_golden_heart = RunData.get_player_item(Keys.generate_hash("item_golden_heart"), player_index)
	var capybara_return_damage
	var capybara_reload_when_dodge = RunData.get_player_effect(Keys.generate_hash("capybara_reload_when_dodge"),player_index)
	if capybara_reload_when_dodge.size() > 0:
		for effect in capybara_reload_when_dodge:
			if capybara_damage_took[2]:
				for weapon in current_weapons:
					var capybara_projectile_stats = effect.weapon_stats
					var capybara_args: = WeaponServiceInitStatsArgs.new()
					var capybara_current_weapon_stats = WeaponService.init_ranged_stats(capybara_projectile_stats, player_index, false, capybara_args)
					var capybara_projectile_arg = WeaponServiceSpawnProjectileArgs.new()
					capybara_projectile_arg.from_player_index = player_index
					var capybara_direction = rand_range(0, 2 * PI)
					if weapon._current_target.size() > 0 and is_instance_valid(weapon._current_target[0]):
						capybara_direction = (weapon._current_target[0].global_position - global_position).angle()
					WeaponService.spawn_projectile(
					weapon.global_position, 
					capybara_current_weapon_stats, 
					capybara_direction, 
					self, 
					capybara_projectile_arg
					)
					if weapon._current_cooldown > 0:
						weapon._current_cooldown = 0
				return [0, 0 , true]
	var capybara_temp_stat_when_dodge = RunData.get_player_effect(Keys.generate_hash("capybara_temp_stat_when_dodge"), player_index)
	if capybara_damage_took[2]:
		for effect in capybara_temp_stat_when_dodge:
			TempStats.add_stat(effect[0], effect[1], player_index)
	if capybara_have_golden_heart != null or capybara_relive_by_upgrades.size() > 0 and not capybara_damage_took[2] and not _hit_protection > 0:
		if capybara_try_to_die:
			if capybara_have_golden_heart == null:
				if capybara_relive_by_upgrades.size() > 0:
					for effect in capybara_relive_by_upgrades:
						if Utils.get_stat(effect[0], player_index) >= effect[1]:
							cp_main()._floating_text_manager.on_relive_by_upgrades(0, player_index)
							var val = Utils.get_stat(effect[0], player_index)
							RunData.remove_stat(effect[0], val, player_index)
							var max_hp = RunData.get_stat(Keys.stat_max_hp_hash, player_index)
							on_healing_effect(max_hp)
							RunData.add_tracked_value(player_index, Keys.generate_hash("character_angel"), 1)
							var xp_gain = val * effect[2]
							var gold_gain = val * effect[2]
							RunData.add_xp(xp_gain , player_index)
							RunData.add_gold(gold_gain , player_index)
							cp_main()._floating_text_manager.capybara_on_gold_added(gold_gain, player_index)
							cp_main()._floating_text_manager.capybara_on_xp_added(xp_gain, player_index)
							var gain_item_effects = RunData.get_player_effect(Keys.generate_hash("capybara_gain_item_when_revive"),player_index)
							if gain_item_effects.size() > 0:
								for gain_item_effect in gain_item_effects:
									var new_item:ItemData = null
									var new_count = 0
									for item in ItemService.items:
										if item.my_id == load(gain_item_effect[2]).my_id:
											new_item = item
									for item in RunData.get_player_items(player_index):
										if item.my_id == load(gain_item_effect[2]).my_id:
											new_count += 1
									for i in gain_item_effect[1]:
										if new_item != null and new_count < 6:
											emit_signal("capybara_holy_sword_added")
											RunData.add_item(new_item, player_index)
											capybara_spawn_holy_sword()
							capybara_try_to_die = false
							capybara_handle_no_hurt()
							return [0, 0 , false]
						else:
							die(Utils.default_die_args)
				else:
					die(Utils.default_die_args)
			else:
				cp_main()._floating_text_manager.on_relive(-1, player_index)
				var golden_heart = RunData.get_player_item(Keys.generate_hash("item_golden_heart"), player_index)
				var effects = RunData.get_player_effect(Keys.generate_hash("relive_chance"), player_index)
				var stat_to_add:int
				for effect in effects:
					stat_to_add = effect[0]
					var relive_stat_gain = effect[1]
					var Item_data = load("res://mods-unpacked/Dbear-Capybara/contents/items/golden_heart/golden_heart_data.tres")
					if golden_heart != null:
						var max_hp = RunData.get_stat(Keys.stat_max_hp_hash, player_index)
						on_healing_effect(max_hp)
						RunData.remove_item(Item_data,  player_index, true)
						RunData.add_stat(stat_to_add, relive_stat_gain, player_index)
						RunData.add_tracked_value(player_index, Keys.generate_hash("character_angel"), 1)
						var gain_item_effects = RunData.get_player_effect(Keys.generate_hash("capybara_gain_item_when_revive"),player_index)
						if gain_item_effects.size() > 0:
							for gain_item_effect in gain_item_effects:
								var new_item:ItemData = null
								var new_count = 0
								for item in ItemService.items:
									if item.my_id == load(gain_item_effect[2]).my_id:
										new_item = item
								for item in RunData.get_player_items(player_index):
									if item.my_id == load(gain_item_effect[2]).my_id:
										new_count += 1
								for i in gain_item_effect[1]:
									if new_item != null and new_count < 6:
										emit_signal("capybara_holy_sword_added")
										RunData.add_item(new_item, player_index)
										capybara_spawn_holy_sword()
						capybara_try_to_die = false
						capybara_handle_no_hurt()
						return [0,0,false]
					else:
						die(Utils.default_die_args)
	return capybara_damage_took

func on_consumable_picked_up(consumable_data: ConsumableData) -> void :
	.on_consumable_picked_up(consumable_data)
	if RunData.get_player_effect(Keys.generate_hash("capybara_reload_when_consumable"), player_index) > 0:
		for weapon in current_weapons:
			weapon._current_cooldown = 0
	for effect in RunData.get_player_effect(Keys.generate_hash("capybara_projectile_when_consumable"), player_index):
		_capybara_spawn_projectile(effect, consumable_data.icon)

func _capybara_spawn_projectile(effect:Effect, icon = null) -> void:
	var stats = effect.weapon_stats
	stats = WeaponService.init_ranged_stats(effect.weapon_stats, player_index, true)

	var auto_target_enemy: bool = effect.auto_target_enemy
	var from = self
	var cp_args = WeaponServiceSpawnProjectileArgs.new()
	if effect.key_hash == Keys.generate_hash("capybara_projectile_when_consumable"):
		cp_args.damage_tracking_key_hash = Keys.generate_hash("character_cp_long_tongue")
	cp_args.from_player_index = player_index
	var _projectile:PlayerProjectile = WeaponService.manage_capybara_spawn_projectile(
		self, 
		stats, 
		rand_range( - PI, PI), 
		auto_target_enemy, 
		_entity_spawner_ref, 
		from, 
		cp_args
	)
	if icon:
		var projectile_p:Sprite = _projectile.get_node_or_null("Sprite")
		if projectile_p:
			projectile_p.texture = icon

func _capybara_spawn_pos_projectile(effect:Effect, icon = null, pos:Vector2 = global_position, rand_scale:bool = false) -> void:
	var stats = effect.weapon_stats
	stats = WeaponService.init_ranged_stats(effect.weapon_stats, player_index, true)

	var auto_target_enemy: bool = effect.auto_target_enemy
	var from = self
	var cp_args = WeaponServiceSpawnProjectileArgs.new()
	if effect.key_hash == Keys.generate_hash("capybara_projectile_when_x_cursed_killed"):
		cp_args.damage_tracking_key_hash = Keys.generate_hash("character_cp_exorcist_miko")
	cp_args.from_player_index = player_index
	var _projectile:PlayerProjectile = WeaponService.spawn_projectile(
		pos,
		stats,
		rand_range( - PI, PI), 
		from, 
		cp_args
	)
	if icon:
		var projectile_p:Sprite = _projectile.get_node_or_null("Sprite")
		if projectile_p:
			projectile_p.texture = icon
	if rand_scale:
		var size_mod = rand_range(0.8,1.2)
		_projectile.scale = Vector2.ONE * size_mod

func life_bar_effects() -> Dictionary:
	var _capybara_golden_heart =  RunData.get_player_item(Keys.generate_hash("item_golden_heart"), player_index)
	var _capybara_have_golden_heart = 0
	if _capybara_golden_heart:
		_capybara_have_golden_heart = 1
	var capybara_life_bar_effects:Dictionary = {
		"capybara_special_dodge": capybara_special_dodge_times,
		"capybara_golden_heart": _capybara_have_golden_heart,
	}
	var capybara_raw_effects = .life_bar_effects()
	capybara_raw_effects.merge(capybara_life_bar_effects)
	return capybara_raw_effects

func capybara_explode(stats: WeaponStats, effect: ExplodingEffect, nb_explosions: int, pos:Vector2, args:WeaponServiceExplodeArgs, weapon_stats:WeaponStats) -> void :
	var chance = effect.chance
	if effect.custom_key == "thunder":
		chance = effect.chance * (weapon_stats.cooldown/(5.0 + weapon_stats.cooldown))
		if weapon_stats is MeleeWeaponStats:
			chance *= 2
	for i in nb_explosions:
		if Utils.get_chance_success(chance):
			var rand_r = rand_range(50 * (i+1), 50 * (i+1) + 100)
			if rand_r > 1500:
				rand_r = 1500
			var rand_a = rand_range(0 , 2*PI)
			args.pos = pos + Vector2(rand_r * cos(rand_a), rand_r * sin(rand_a))
			args.damage = stats.damage + effect.get_additional_scaling_damage(player_index)
			args.accuracy = stats.accuracy
			args.crit_chance = stats.crit_chance
			args.crit_damage = stats.crit_damage
			args.burning_data = stats.burning_data
			args.scaling_stats = stats.scaling_stats
			args.from_player_index = player_index
			args.damage_tracking_key_hash = effect.tracking_key_hash

			if stats.shooting_sounds.size() > 0:
				SoundManager2D.play(Utils.get_rand_element(stats.shooting_sounds), global_position, stats.sound_db_mod, 0.2, true)

			var _inst = WeaponService.explode(effect, args)

func won() -> void :
	.won()
	for pet in capybara_pets:
		if pet.has_method("vampire_queen_win"):
			pet.vampire_queen_win()
