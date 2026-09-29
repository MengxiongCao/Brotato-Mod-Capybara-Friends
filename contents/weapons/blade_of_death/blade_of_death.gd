class_name CapybaraBladeOfDeath
extends "res://weapons/melee/melee_weapon.gd"

onready var _one_second_timer = $OneSecondTimer
var count_the_second = 0
var bonus_damage = 0
var capybara_should_shot_sword_wave = false
var capybara_mutex = false
var capybara_projectile_stats:Resource
onready var sword_wave_particles = $Sprite/CursedUnitParticles
var args: = WeaponServiceInitStatsArgs.new()
var base_damage = 0
var duplicated_stats:MeleeWeaponStats = null

func _ready() -> void:
	count_the_second = 0
	bonus_damage = 0
	var error = _parent.connect("took_damage", self, "capybara_player_hit")
	capybara_should_shot_sword_wave = false
	_one_second_timer.start()
	sword_wave_particles.visible = false

func capybara_player_hit(_unit: Unit, value: int, _knockback_direction: Vector2, _is_crit: bool, _is_dodge: bool, _is_protected: bool, _armor_did_something: bool, _args: TakeDamageArgs, _hit_type: int, _is_one_shot: bool) -> void:
	if _is_dodge or _is_protected:
		return
	count_the_second = 0
	bonus_damage = 0
	sword_wave_particles.visible = false
	capybara_should_shot_sword_wave = false
	init_stats(false)

func init_stats(at_wave_begin: bool = true) -> void :
	args.sets = weapon_sets
	args.effects = effects
	base_damage = stats.damage

	if at_wave_begin and duplicated_stats == null:
		duplicated_stats = stats.duplicate()
	duplicated_stats.damage = base_damage + bonus_damage

	current_stats = WeaponService.init_melee_stats(duplicated_stats, player_index, args)

	_hitbox.projectiles_on_hit = []

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
			if count_the_second >= effect.time_to_shoot_sword_wave:
				capybara_projectile_stats = effect.weapon_stats
				capybara_should_shot_sword_wave = true
				sword_wave_particles.visible = true
	for effect in effects:
		if effect.custom_key == "capybara_player_no_hit":
			var interval = effect.interval
			var boost_damage = effect.value
			if count_the_second % interval == 0 and count_the_second != 0:
				bonus_damage += boost_damage
				init_stats(false)
				break
func shoot() -> void :
	.shoot()
	capybara_mutex = false
	

func _capybara_projectile_on_hit(thing_hit: Node) -> void:
	var capybara_args: = WeaponServiceInitStatsArgs.new()
	var capybara_weapon_stats = capybara_projectile_stats.duplicate()
	capybara_weapon_stats.damage = capybara_projectile_stats.damage + bonus_damage
	var capybara_current_weapon_stats = WeaponService.init_ranged_stats(capybara_weapon_stats, player_index, false, capybara_args)
	
	var capybara_count:int = 1
	for i in range(0,capybara_count):
		var capybara_projectile_arg = WeaponServiceSpawnProjectileArgs.new()
		var capybara_direction = (thing_hit.global_position - global_position).angle()
		WeaponService.spawn_projectile(
		muzzle.global_position, 
		capybara_current_weapon_stats, 
		capybara_direction, 
		self, 
		capybara_projectile_arg
		)

func _on_Hitbox_hit_something(thing_hit: Node, damage_dealt: int) -> void :
	._on_Hitbox_hit_something(thing_hit,damage_dealt)
	if not capybara_mutex:
		if capybara_should_shot_sword_wave:
			_capybara_projectile_on_hit(thing_hit)
			capybara_mutex = true
