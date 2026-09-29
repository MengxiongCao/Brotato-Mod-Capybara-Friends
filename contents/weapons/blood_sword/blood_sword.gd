class_name CapybaraBloodSword
extends "res://weapons/melee/melee_weapon.gd"

var count_the_second = 0
var capybara_should_shot_sword_wave = false
var capybara_mutex = false
var capybara_projectile_stats:Resource
onready var sword_wave_particles = $Sprite/Hitbox/CursedUnitParticles
var args: = WeaponServiceInitStatsArgs.new()
var base_damage = 0
var duplicated_stats:MeleeWeaponStats = null
var capybara_main = null
var capybara_healed_health = 0
var stat_to_add = 0

func _ready() -> void:
	count_the_second = 0
	capybara_main = _parent.get_tree().current_scene
	var error = capybara_main.connect("capybara_healed", self, "_capybara_player_healed")
	capybara_should_shot_sword_wave = false
	sword_wave_particles.visible = false

func _capybara_player_healed(value, player_index) -> void:
	capybara_healed_health += value
	
func _physics_process(delta) -> void:
	if capybara_healed_health > effects[0].value2:
		capybara_healed_health -= effects[0].value2
		stat_to_add += 1
		init_stats(false)

func init_stats(at_wave_begin: bool = true) -> void :
	args.sets = weapon_sets
	args.effects = effects
	base_damage = stats.damage

	if at_wave_begin and duplicated_stats == null:
		duplicated_stats = stats.duplicate()
	duplicated_stats.damage = base_damage + effects[0].value * stat_to_add

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


