class_name CapybaraGoldenLotusSword
extends "res://weapons/melee/melee_weapon.gd"

onready var _one_second_timer = $OneSecondTimer
var count_the_second = 0
var bonus_crit_damage = 0
var capybara_should_shot_sword_wave = false
var capybara_mutex = false
var capybara_projectile_stats:Resource
var args: = WeaponServiceInitStatsArgs.new()
var base_crit_damage = 0
var duplicated_stats:MeleeWeaponStats = null

func _ready() -> void:
	count_the_second = 0
	bonus_crit_damage = 0
	var error = _parent.connect("took_damage", self, "capybara_player_hit")
	_one_second_timer.start()

func capybara_player_hit(_unit: Unit, value: int, _knockback_direction: Vector2, _is_crit: bool, _is_dodge: bool, _is_protected: bool, _armor_did_something: bool, _args: TakeDamageArgs, _hit_type: int, _is_one_shot: bool) -> void:
	if _is_dodge or _is_protected:
		return
	count_the_second = 0
	bonus_crit_damage = 0
	init_stats(false)

func init_stats(at_wave_begin: bool = true) -> void :
	args.sets = weapon_sets
	args.effects = effects
	base_crit_damage = stats.crit_damage

	if at_wave_begin and duplicated_stats == null:
		duplicated_stats = stats.duplicate()
	duplicated_stats.crit_damage = base_crit_damage + bonus_crit_damage

	current_stats = WeaponService.init_melee_stats(duplicated_stats, player_index, args)

	_hitbox.projectiles_on_hit = []
	_hitbox.crit_damage = current_stats.crit_damage

	var on_hit_args: = WeaponServiceInitStatsArgs.new()
	for effect in effects:
		if effect is ProjectilesOnHitEffect:
			var weapon_stats = WeaponService.init_ranged_stats(effect.weapon_stats, player_index, true, on_hit_args)
			_hitbox.projectiles_on_hit = [effect.value, weapon_stats, effect.auto_target_enemy]

	current_stats.burning_data.from = self

	var hitbox_args: = Hitbox.HitboxArgs.new().set_from_weapon_stats(current_stats)

	_hitbox.effect_scale = current_stats.effect_scale
	_hitbox.set_damage(current_stats.damage, hitbox_args)
	_hitbox.speed_percent_modifier = current_stats.speed_percent_modifier
	_hitbox.effects = effects
	_hitbox.from = self

	if at_wave_begin:
		_current_cooldown = get_next_cooldown(at_wave_begin)

	reset_cooldown()
	_range_shape.shape.radius = current_stats.max_range + DETECTION_RANGE

func _on_OneSecondTimer_timeout():
	count_the_second += 1
	for effect in effects:
		if effect.custom_key == "capybara_player_no_hit":
			var interval = effect.interval
			var boost_damage = effect.value
			if count_the_second % interval == 0 and count_the_second != 0:
				bonus_crit_damage += boost_damage/100.0
				init_stats(false)
				break
