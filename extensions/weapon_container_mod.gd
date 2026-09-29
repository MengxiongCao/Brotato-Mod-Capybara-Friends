extends "res://entities/units/player/weapons_container.gd"


func update_weapons_positions(weapons: Array) -> void :
	.update_weapons_positions(weapons)

func capybara_update_weapons_positions(weapons:Array, phase: float) -> void:
	if not show_behind_parent:
		show_behind_parent = true
	var count = weapons.size()
	var angles = []
	if count > RunData.get_stat(Keys.weapon_slot_hash,get_parent().player_index):
		count = RunData.get_stat(Keys.weapon_slot_hash,get_parent().player_index)
	for i in count:
		var cp_radius = 60
		var capybara_round_weapons = RunData.get_player_effect(Keys.generate_hash("capybara_round_weapons"), get_parent().player_index)
		for effect in capybara_round_weapons:
			if cp_radius < effect[1]:
				cp_radius = effect[1]
		var r = (cp_radius + (count - 6) * 5) * 2
		var angle = i * ((2 * PI) / count)
		weapons[i].attach(Vector2(r * cos(angle + phase), r * sin(angle + phase)), 0)
		if angle + phase < PI:
			weapons[i].z_index = 1
		else:
			weapons[i].z_index = 0

func capybara_update_weapons_positions_master(weapons:Array, phase: float) -> void:
	if not show_behind_parent:
		show_behind_parent = true
	var count = weapons.size()
	var angles = []
	if count > RunData.get_stat(Keys.weapon_slot_hash,get_parent().player_index):
		count = RunData.get_stat(Keys.weapon_slot_hash,get_parent().player_index)
	for i in count:
		var cp_radius = 90
		var capybara_round_weapons = RunData.get_player_effect(Keys.generate_hash("capybara_round_weapons"), get_parent().player_index)
		for effect in capybara_round_weapons:
			if cp_radius < effect[1]:
				cp_radius = effect[1]
		var r = (cp_radius + (count - 6) * 5) * 2
		var angle = i * ((2 * PI) / count)
		weapons[i].attach(Vector2(r * cos(angle + phase), r * 0.4 * sin(angle + phase)), 0)
		if angle + phase < PI * 7.0/ 6.0 or angle + phase > PI * 11.0/ 6.0:
			weapons[i].z_index = 1
		else:
			weapons[i].z_index = 0

func capybara_update_weapons_positions_master_swamp(weapons:Array, phase: float, pos:Vector2) -> void:
	if not show_behind_parent:
		show_behind_parent = true
	var count = weapons.size()
	var angles = []
	if count > RunData.get_stat(Keys.weapon_slot_hash,get_parent().player_index):
		count = RunData.get_stat(Keys.weapon_slot_hash,get_parent().player_index)
	for i in count:
		var cp_radius = 60
		var capybara_round_weapons = RunData.get_player_effect(Keys.generate_hash("capybara_round_weapons"), get_parent().player_index)
		for effect in capybara_round_weapons:
			if cp_radius < effect[1]:
				cp_radius = effect[1]
		var r = (cp_radius + (count - 6) * 5) * 2
		var angle = i * ((2 * PI) / count)
		weapons[i].global_position = pos + Vector2(r * cos(angle + phase), r * 0.3 * sin(angle + phase))
		if angle + phase < PI * 7.0/ 6.0 or angle + phase > PI * 11.0/ 6.0:
			weapons[i].z_index = 1
		else:
			weapons[i].z_index = 0

func capybara_update_weapons_positions_swamp(weapons:Array, phase: float, pos:Vector2) -> void:
	if not show_behind_parent:
		show_behind_parent = true
	var count = weapons.size()
	var angles = []
	if count > RunData.get_stat(Keys.weapon_slot_hash,get_parent().player_index):
		count = RunData.get_stat(Keys.weapon_slot_hash,get_parent().player_index)
	for i in count:
		var cp_radius = 60
		var capybara_round_weapons = RunData.get_player_effect(Keys.generate_hash("capybara_round_weapons"), get_parent().player_index)
		for effect in capybara_round_weapons:
			if cp_radius < effect[1]:
				cp_radius = effect[1]
		var r = (cp_radius + (count - 6) * 5) * 2
		var angle = i * ((2 * PI) / count)
		weapons[i].global_position = pos + Vector2(r * cos(angle + phase), r * 0.65 * sin(angle + phase))
		if angle + phase < PI:
			weapons[i].z_index = 1
		else:
			weapons[i].z_index = 0
