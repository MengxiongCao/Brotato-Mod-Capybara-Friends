extends "res://dlcs/dlc_1/effect_behaviors/player/for_every_step_effect_behavior.gd"

var capybara_step_count:Array = []
var capybara_step_count_time = []

func on_moved(delta_position: Vector2) -> void:
	var capybara_index = 0
	var capybara_projectile_on_move_effects = RunData.get_player_effect(Keys.generate_hash("capybara_wind"),_player_index)
	for effect in capybara_projectile_on_move_effects:
		if capybara_step_count.size() < capybara_projectile_on_move_effects.size():
			capybara_step_count.append(0)
		var capybara_steps_taken_before = _steps_taken - capybara_step_count[capybara_index] * effect.scale
		if capybara_steps_taken_before > effect.scale:
			capybara_handle_stat_for_steps(effect,effect.scale, capybara_steps_taken_before)
			capybara_step_count[capybara_index] += 1
		capybara_index += 1
	capybara_on_moved(delta_position)
	.on_moved(delta_position)

func capybara_on_moved(delta_position:Vector2) -> void:
	var main = _parent.get_tree().current_scene
	var capybara_index = 0
	var capybara_materials_on_move_effects = RunData.get_player_effect(Keys.generate_hash("capybara_gain_stat_for_every_step_after_equip"), _player_index)
	for effect in capybara_materials_on_move_effects:
		if capybara_step_count.size() < capybara_materials_on_move_effects.size():
			capybara_step_count.append(0)
		var capybara_steps_taken_before = _steps_taken - capybara_step_count[capybara_index] * effect[2]
		if capybara_steps_taken_before > effect[2]:
			if effect[0] == Keys.generate_hash("stat_capybara_gold"):
				capybara_spawn_gold(effect[1], _parent.global_position, main)
			else:
				RunData.add_stat(effect[0], effect[1], _player_index)
			RunData.add_tracked_value(_player_index, Keys.generate_hash("character_turretato"), effect[1])
			capybara_step_count[capybara_index] += 1
		capybara_index += 1

func capybara_spawn_gold(value, pos, main) -> void:
	main.spawn_gold(value, pos, 50)

func capybara_handle_stat_for_steps(effect:Effect, for_every_step_count: int, steps_taken_before: float) -> void:
	var weapon_stats:RangedWeaponStats = effect.weapon_stats
	var capybara_args: = WeaponServiceInitStatsArgs.new()
	var capybara_current_weapon_stats = WeaponService.init_ranged_stats(weapon_stats, _player_index, false, capybara_args)
	for i in effect.value:
		var capybara_projectile_arg = WeaponServiceSpawnProjectileArgs.new()
		capybara_projectile_arg.from_player_index = _player_index
		var capybara_direction = rand_range(0, 2*PI)
		var projectile = WeaponService.manage_capybara_spawn_projectile(
		_parent,
		capybara_current_weapon_stats, 
		capybara_direction, 
		effect.target_enemy,
		_parent._entity_spawner_ref,
		_parent, 
		capybara_projectile_arg
		)
