extends "res://weapons/shooting_behaviors/melee_weapon_shooting_behavior.gd"

var capybara_crystal_attack = true
var _capybara_ranged_spawn_projectile_args: = WeaponServiceSpawnProjectileArgs.new()
var _capybara_ranged_stats = null

func shoot(distance: float) -> void :
	var capybara_change_way_of_attack = RunData.get_player_effect(Keys.generate_hash("change_way_of_attack"), _parent.player_index)
	var capybara_ranged_melee_attack = RunData.get_player_effect(Keys.generate_hash("capybara_ranged_melee_attack"), _parent.player_index)
	if capybara_change_way_of_attack.size() <=0:
		if capybara_ranged_melee_attack.size() > 0 and capybara_crystal_attack:
			var args = WeaponServiceInitStatsArgs.new()
			var player_index = _parent.player_index
			for effect in capybara_ranged_melee_attack:
				_capybara_ranged_stats = WeaponService.init_ranged_stats(effect.weapon_stats, player_index, false, args)
			capybara_ranged_shoot(distance)
			capybara_crystal_attack = false
		else:
			.shoot(distance)
			capybara_crystal_attack = true
	else:
		var initial_position: Vector2 = _parent.sprite.position
		shooting_data = MeleeShootingData.new(_parent.current_stats, _parent.player_index)
		_parent.set_shooting(true)
		capybara_melee_attack(initial_position, distance)

func capybara_melee_attack(initial_position: Vector2, distance: float) -> void :
	_parent._hitbox.player_attack_id = _get_next_attack_id()

	var atk_distance = min(_parent.current_stats.max_range, max(MIN_SWEEP_DISTANCE, distance))
	shooting_data.update_atk_duration(atk_distance)

	var recoil = _parent.current_stats.recoil
	var recoil_duration = _parent.current_stats.recoil_duration
	var turn_angle = PI
	var sweep_half_duration = shooting_data.atk_duration / 4

	var angle_a = turn_angle
	var angle_b = - turn_angle

	if not _parent.sprite.flip_v:
		angle_a = - turn_angle
		angle_b = turn_angle
	_parent.enable_hitbox()
	interpolate("position", initial_position, Vector2(initial_position.x - recoil * 3, initial_position.y), recoil_duration)

	_parent.tween.start()
	yield(_parent.tween, "tween_all_completed")

	SoundManager.play(Utils.get_rand_element(_parent.current_stats.shooting_sounds), _parent.current_stats.sound_db_mod, 0.2)
	
	interpolate("position", _parent.sprite.position, Vector2(initial_position.x + _parent.get_sweep_range(atk_distance), initial_position.y), sweep_half_duration, Tween.TRANS_LINEAR)

	_parent.tween.start()
	yield(_parent.tween, "tween_all_completed")
	_parent.disable_hitbox()
	_parent.enable_hitbox()
	interpolate("rotation", _parent.sprite.rotation, angle_a, sweep_half_duration * 3, Tween.TRANS_LINEAR)
	
	_parent.tween.start()
	yield(_parent.tween, "tween_all_completed")

	interpolate("position", _parent.sprite.position, Vector2(initial_position.x - recoil * 3, initial_position.y), sweep_half_duration, Tween.TRANS_LINEAR)

	_parent.tween.start()
	yield(_parent.tween, "tween_all_completed")

	interpolate("position", _parent.sprite.position, initial_position, shooting_data.back_duration * 3)
	interpolate("rotation", _parent.sprite.rotation, 0, shooting_data.back_duration * 3)

	_parent.tween.start()
	yield(_parent.tween, "tween_all_completed")
	_parent.disable_hitbox()
	_parent.set_shooting(false)

func capybara_ranged_shoot(_distance: float) -> void :
	SoundManager.play(Utils.get_rand_element(_capybara_ranged_stats.shooting_sounds), _parent.current_stats.sound_db_mod, 0.2)

	var initial_position: Vector2 = _parent.sprite.position

	_parent.set_shooting(true)

	var attack_id: = _get_next_attack_id()
	for i in _capybara_ranged_stats.nb_projectiles:
		var proj_rotation = rand_range(_parent.rotation - _capybara_ranged_stats.projectile_spread, _parent.rotation + _capybara_ranged_stats.projectile_spread)
		var projectile = capybara_shoot_projectile(proj_rotation, Vector2(cos(proj_rotation), sin(proj_rotation)))
		projectile._hitbox.player_attack_id = attack_id

	_parent.tween.interpolate_property(
		_parent.sprite, 
		"position", 
		initial_position, 
		Vector2(initial_position.x - _capybara_ranged_stats.recoil, initial_position.y), 
		_capybara_ranged_stats.recoil_duration, 
		Tween.TRANS_EXPO, 
		Tween.EASE_OUT
	)

	_parent.tween.start()
	yield(_parent.tween, "tween_all_completed")

	_parent.tween.interpolate_property(
		_parent.sprite, 
		"position", 
		_parent.sprite.position, 
		initial_position, 
		_capybara_ranged_stats.recoil_duration, 
		Tween.TRANS_EXPO, 
		Tween.EASE_OUT
	)

	_parent.tween.start()
	yield(_parent.tween, "tween_all_completed")

	_parent.set_shooting(false)


func capybara_shoot_projectile(rotation: float = _parent.rotation, knockback: Vector2 = Vector2.ZERO) -> Node:
	_capybara_ranged_spawn_projectile_args.knockback_direction = knockback
	_capybara_ranged_spawn_projectile_args.effects = _parent.effects
	_capybara_ranged_spawn_projectile_args.from_player_index = _parent.player_index

	var projectile = WeaponService.spawn_projectile(
		_parent.muzzle.global_position, 
		_capybara_ranged_stats, 
		rotation, 
		_parent, 
		_capybara_ranged_spawn_projectile_args
	)
	
	return projectile
	
