extends "res://dlcs/dlc_1/dlc_1_data.gd"

func curse_item(item_data, player_index: int, turn_randomization_off: bool = false, min_modifier: float = 0.0):
	if item_data == null or not is_instance_valid(item_data):
		return item_data
	item_data = _capybara_get_curse_safe_item(item_data)
	var raw_curse_item = .curse_item(item_data,player_index,turn_randomization_off,min_modifier)
	if raw_curse_item == null or not is_instance_valid(raw_curse_item):
		return item_data
	if item_data.is_cursed == true:
		return raw_curse_item
	var capybara_original_curse_effect = null
	for raw_effect in raw_curse_item.effects:
		if raw_effect != null and is_instance_valid(raw_effect) and raw_effect.key_hash == Keys.stat_curse_hash:
			capybara_original_curse_effect = raw_effect
			break
	var capybara_new_effects: = []
	var capybara_max_effect_modifier = 0.0
	var capybara_curse_effect_modified: = false
	var capybara_new_item_data = item_data.duplicate()
	for effect in item_data.effects:
		if effect == null or not is_instance_valid(effect):
			continue
		var effect_modifier:float = rand_range(0, 1.1)
		if effect.key != "":
			assert (effect.key_hash != null and effect.key_hash != Keys.empty_hash)
		
		if effect.custom_key_hash == Keys.generate_hash("foxfire_count"):
			effect_modifier = _get_cursed_item_effect_modifier(turn_randomization_off, min_modifier)
			capybara_max_effect_modifier = max(capybara_max_effect_modifier, effect_modifier)
			var cp_new_effect = effect.duplicate()
			var new_weapon_stats = effect.weapon_stats.duplicate()
			var new_burning_stats = effect.burning_data.duplicate()
			new_burning_stats.scaling_stats =  _boost_scaling_sats(effect.burning_data.scaling_stats, effect_modifier)
			cp_new_effect.weapon_stats = _boost_weapon_stats_damage(effect.weapon_stats, effect_modifier)
			cp_new_effect.burning_data = new_burning_stats
			raw_curse_item.effects = [cp_new_effect]
			var extra_effect = Effect.new()
			extra_effect.key = "stat_curse"
			extra_effect.key_hash = Keys.stat_curse_hash
			extra_effect.value = int(ceil(10 * (1.0 + effect_modifier)))
			extra_effect.effect_sign = Sign.OVERRIDE
			capybara_new_effects.append(extra_effect)
		
		if effect.custom_key_hash == Keys.generate_hash("capybara_darkfish") and effect is PetEffect:
			effect_modifier = _get_cursed_item_effect_modifier(turn_randomization_off, min_modifier)
			capybara_max_effect_modifier = max(capybara_max_effect_modifier, effect_modifier)
			var cp_new_effect = effect.duplicate()
			cp_new_effect.is_cursed = true
			cp_new_effect.weapon_stats = _boost_weapon_stats_damage(effect.weapon_stats, effect_modifier)
			cp_new_effect.boost_attack_speed = (effect.boost_attack_speed * (1 + effect_modifier)) as int
			raw_curse_item.effects = [cp_new_effect]
			var extra_effect = Effect.new()
			extra_effect.key = "stat_curse"
			extra_effect.key_hash = Keys.stat_curse_hash
			extra_effect.value = int(ceil(4 * (1.0 + effect_modifier)))
			extra_effect.effect_sign = Sign.OVERRIDE
			capybara_new_effects.append(extra_effect)
		
		if effect.custom_key_hash == Keys.generate_hash("capybara_unicorn_effect") and effect is PetEffect:
			effect_modifier = _get_cursed_item_effect_modifier(turn_randomization_off, min_modifier)
			capybara_max_effect_modifier = max(capybara_max_effect_modifier, effect_modifier)
			var cp_new_effect = effect.duplicate()
			cp_new_effect.is_cursed = true
			cp_new_effect.melee_weapon_stats = _boost_weapon_stats_damage(effect.melee_weapon_stats, effect_modifier)
			cp_new_effect.ranged_weapon_stats = _boost_weapon_stats_damage(effect.ranged_weapon_stats, effect_modifier)
			cp_new_effect.ice_cream_stats = _boost_weapon_stats_damage(effect.ice_cream_stats, effect_modifier)
			cp_new_effect.light_count = (effect.light_count * (1 + effect_modifier)) as int
			raw_curse_item.effects = [cp_new_effect]
			var extra_effect = Effect.new()
			extra_effect.key = "stat_curse"
			extra_effect.key_hash = Keys.stat_curse_hash
			extra_effect.value = int(ceil(10 * (1.0 + effect_modifier)))
			extra_effect.effect_sign = Sign.OVERRIDE
			capybara_new_effects.append(extra_effect)
		if effect.custom_key == "capybara_swampman" and effect is PetEffect:
			effect_modifier = _get_cursed_item_effect_modifier(turn_randomization_off, min_modifier)
			capybara_max_effect_modifier = max(capybara_max_effect_modifier, effect_modifier)
			var cp_new_effect = effect.duplicate()
			cp_new_effect.is_cursed = true
			cp_new_effect.value = (effect.value * 2) as int
			cp_new_effect.damage_shrink = (effect.damage_shrink * (1 + effect_modifier)) as int
			raw_curse_item.effects[0] = cp_new_effect
			
#			var extra_effect = Effect.new()
#			extra_effect.key = "stat_curse"
#			extra_effect.key_hash = Keys.stat_curse_hash
#			extra_effect.value = int(ceil(16 * (1.0 + effect_modifier)))
#			extra_effect.effect_sign = Sign.OVERRIDE
#			capybara_new_effects.append(extra_effect)
		if effect.custom_key_hash == Keys.generate_hash("capybara_holy_sword_of_judgement"):
			effect_modifier = _get_cursed_item_effect_modifier(turn_randomization_off, min_modifier)
			capybara_max_effect_modifier = max(capybara_max_effect_modifier, effect_modifier)
			var cp_new_effect = effect.duplicate()
			var new_weapon_stats = effect.weapon_stats.duplicate()
			cp_new_effect.weapon_stats = _boost_weapon_stats_damage(effect.weapon_stats, effect_modifier)
			raw_curse_item.effects = [cp_new_effect]
			var extra_effect = Effect.new()
			extra_effect.key = "stat_curse"
			extra_effect.key_hash = Keys.stat_curse_hash
			extra_effect.value = int(ceil(10 * (1.0 + effect_modifier)))
			extra_effect.effect_sign = Sign.OVERRIDE
			var extra_effect_1 = Effect.new()
			capybara_new_effects.append(extra_effect)
			extra_effect_1.key = "xp_gain"
			extra_effect_1.key_hash = Keys.xp_gain_hash
			extra_effect_1.value = int(ceil(15 * (1.0 + effect_modifier)))
			extra_effect_1.effect_sign = Sign.POSITIVE
			capybara_new_effects.append(extra_effect_1)
		if effect.key_hash == Keys.generate_hash("capybara_three_weapon_stats"):
			effect_modifier = _get_cursed_item_effect_modifier(turn_randomization_off, min_modifier)
			capybara_max_effect_modifier = max(capybara_max_effect_modifier, effect_modifier)
			var cp_new_effect = effect.duplicate()
			var new_weapon_stats = effect.weapon_stats.duplicate()
			cp_new_effect.weapon_stats = _boost_weapon_stats_damage(effect.weapon_stats, effect_modifier)
			new_weapon_stats = effect.weapon_stats_1.duplicate()
			cp_new_effect.weapon_stats_1 = _boost_weapon_stats_damage(effect.weapon_stats_1, effect_modifier)
			new_weapon_stats = effect.weapon_stats_2.duplicate()
			cp_new_effect.weapon_stats_2 = _boost_weapon_stats_damage(effect.weapon_stats_2, effect_modifier)
			raw_curse_item.effects[0] = cp_new_effect
		if effect.custom_key == "capybara_angel" and effect is PetEffect:
			effect_modifier = _get_cursed_item_effect_modifier(turn_randomization_off, min_modifier)
			capybara_max_effect_modifier = max(capybara_max_effect_modifier, effect_modifier)
			var cp_new_effect = effect.duplicate()
			cp_new_effect.is_cursed = true
			cp_new_effect.weapon_stats = _boost_weapon_stats_damage(effect.weapon_stats, effect_modifier)
			cp_new_effect.boost_attack_speed = effect.boost_attack_speed * (1 + effect_modifier)
			raw_curse_item.effects = [cp_new_effect]
			var extra_effect = Effect.new()
			extra_effect.key = "stat_curse"
			extra_effect.key_hash = Keys.stat_curse_hash
			extra_effect.value = int(ceil(4 * (1.0 + effect_modifier)))
			extra_effect.effect_sign = Sign.OVERRIDE
			var extra_effect_1 = Effect.new()
			extra_effect_1.key = "capybara_charm_time"
			extra_effect_1.key_hash = Keys.generate_hash("capybara_charm_time")
			extra_effect_1.value = int(ceil(3 * (1.0 + effect_modifier)))
			capybara_new_effects.append_array([extra_effect_1,extra_effect])
		if effect.key_hash == Keys.generate_hash("capybara_charmed_enemies_attack"):
			effect_modifier = _get_cursed_item_effect_modifier(turn_randomization_off, min_modifier)
			capybara_max_effect_modifier = max(capybara_max_effect_modifier, effect_modifier)
			var cp_new_effect = effect.duplicate()
			cp_new_effect.weapon_stats = _boost_weapon_stats_damage(effect.weapon_stats, effect_modifier)
			raw_curse_item.effects = [cp_new_effect]
			var extra_effect = Effect.new()
			extra_effect.key = "stat_curse"
			extra_effect.key_hash = Keys.stat_curse_hash
			extra_effect.value = int(ceil(10 * (1.0 + effect_modifier)))
			extra_effect.effect_sign = Sign.OVERRIDE
			var extra_effect_1 = Effect.new()
			extra_effect_1.key = "capybara_charm_time"
			extra_effect_1.key_hash = Keys.generate_hash("capybara_charm_time")
			extra_effect_1.value = int(ceil(6 * (1.0 + effect_modifier)))
			capybara_new_effects.append_array([extra_effect_1,extra_effect])
		if effect.key_hash == Keys.generate_hash("capybara_spawn_pets_for_x_enemies"):
			effect_modifier = _get_cursed_item_effect_modifier(turn_randomization_off, min_modifier)
			capybara_max_effect_modifier = max(capybara_max_effect_modifier, effect_modifier)
			var cp_new_effect = effect.duplicate()
			cp_new_effect.stat_scaled = (max(1, effect.stat_scaled / (1 + effect_modifier))) as int
			cp_new_effect.max_num = (effect.max_num * (1 + effect_modifier)) as int
			for i in range(0,raw_curse_item.effects.size()):
				var ef = raw_curse_item.effects[i]
				if ef.custom_key == effect.custom_key and ef.key_hash == effect.key_hash:
					raw_curse_item.effects[i] = cp_new_effect
		if effect is PetEffect:
			if effect.custom_key == "capybara_pet_soul":
				effect_modifier = _get_cursed_item_effect_modifier(turn_randomization_off, min_modifier)
				capybara_max_effect_modifier = max(capybara_max_effect_modifier, effect_modifier)
				var cp_new_effect = effect.duplicate()
				cp_new_effect.is_cursed = true
				cp_new_effect.weapon_stats = _boost_weapon_stats_damage(effect.weapon_stats, effect_modifier)
				raw_curse_item.effects = [cp_new_effect]
				var extra_effect = Effect.new()
				extra_effect.key = "stat_curse"
				extra_effect.key_hash = Keys.stat_curse_hash
				extra_effect.value = int(ceil(4 * (1.0 + effect_modifier)))
				extra_effect.effect_sign = Sign.OVERRIDE
				capybara_new_effects.append(extra_effect)
			elif effect.custom_key == "capybara_god_of_death":
				effect_modifier = _get_cursed_item_effect_modifier(turn_randomization_off, min_modifier)
				capybara_max_effect_modifier = max(capybara_max_effect_modifier, effect_modifier)
				var cp_new_effect = effect.duplicate()
				cp_new_effect.is_cursed = true
				cp_new_effect.weapon_stats = _boost_weapon_stats_damage(effect.weapon_stats, effect_modifier)
				cp_new_effect.value2 = (effect.value2 * (1+effect_modifier)) as int
				raw_curse_item.effects = [cp_new_effect]
				var extra_effect = Effect.new()
				extra_effect.key = "stat_curse"
				extra_effect.key_hash = Keys.stat_curse_hash
				extra_effect.value = int(ceil(10 * (1.0 + effect_modifier)))
				extra_effect.effect_sign = Sign.OVERRIDE
				capybara_new_effects.append(extra_effect)
		if effect.key == "capybara_lotus_text" or effect.key == "capybara_light_saber_text":
			effect_modifier = _get_cursed_item_effect_modifier(turn_randomization_off, min_modifier)
			capybara_max_effect_modifier = max(capybara_max_effect_modifier, effect_modifier)
			var cp_new_effect = effect.duplicate()
			cp_new_effect.weapon_stats = _boost_weapon_stats_damage(effect.weapon_stats, effect_modifier)
			if effect.key == "capybara_lotus_text":
				cp_new_effect.value = effect.value * (2 + effect_modifier)
			else:
				cp_new_effect.value = effect.value * (1 + effect_modifier)
			for i in range(0,raw_curse_item.effects.size()):
				var ef = raw_curse_item.effects[i]
				if ef.custom_key == effect.custom_key and ef.key_hash == effect.key_hash:
					raw_curse_item.effects[i] = cp_new_effect
		if effect.custom_key == "capybara_player_no_hit":
			effect_modifier = _get_cursed_item_effect_modifier(turn_randomization_off, min_modifier)
			capybara_max_effect_modifier = max(capybara_max_effect_modifier, effect_modifier)
			var cp_new_effect = effect.duplicate()
			cp_new_effect.weapon_stats = _boost_weapon_stats_damage(effect.weapon_stats, effect_modifier)
			cp_new_effect.value = effect.value * (1 + effect_modifier)
			cp_new_effect.interval = effect.interval / (1 + effect_modifier)
			cp_new_effect.time_to_shoot_sword_wave = effect.time_to_shoot_sword_wave / (1 + effect_modifier)
			for i in range(0,raw_curse_item.effects.size()):
				var ef = raw_curse_item.effects[i]
				if ef.custom_key == effect.custom_key and ef.key_hash == effect.key_hash:
					raw_curse_item.effects[i] = cp_new_effect
			
	var capybara_has_curse_effect = false
	for final_effect in raw_curse_item.effects + capybara_new_effects:
		if final_effect != null and is_instance_valid(final_effect) and final_effect.key_hash == Keys.stat_curse_hash:
			capybara_has_curse_effect = true
			break
	if not capybara_has_curse_effect and capybara_original_curse_effect != null:
		capybara_new_effects.append(capybara_original_curse_effect)
	if capybara_new_effects.size() > 0:
		capybara_new_item_data.effects = raw_curse_item.effects + capybara_new_effects
	else:
		capybara_new_item_data.effects = raw_curse_item.effects
	capybara_new_item_data.is_cursed = true
	capybara_new_item_data.curse_factor = raw_curse_item.curse_factor
	
	if item_data is WeaponData:
		var effect_modifier: = _get_cursed_item_effect_modifier(turn_randomization_off, min_modifier)
		capybara_max_effect_modifier = max(capybara_max_effect_modifier, effect_modifier)
		capybara_new_item_data.stats = _boost_weapon_stats_damage(item_data.stats, effect_modifier)

	return capybara_new_item_data

func _capybara_get_curse_safe_item(item_data):
	var capybara_safe_effects = _capybara_get_valid_curse_effects(item_data.effects)
	if capybara_safe_effects.size() == item_data.effects.size():
		return item_data
	var capybara_safe_item = item_data.duplicate()
	capybara_safe_item.effects = capybara_safe_effects
	return capybara_safe_item

func _capybara_get_valid_curse_effects(effects: Array) -> Array:
	var capybara_valid_effects = []
	for effect in effects:
		if effect == null or not is_instance_valid(effect) or not effect is Effect:
			continue
		capybara_valid_effects.append(effect)
	return capybara_valid_effects
