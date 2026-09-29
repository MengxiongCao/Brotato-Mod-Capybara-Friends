class_name LightSaberPurple
extends "res://weapons/melee/melee_weapon.gd"
var capybara_mutex = false
onready var capybara_cursed_particle = $Sprite/Hitbox/CursedUnitParticles as CPUParticles2D

func _ready() -> void:
	if self.is_cursed:
		capybara_cursed_particle.visible = true
	else:
		capybara_cursed_particle.visible = false


func on_weapon_hit_something(_thing_hit: Node, damage_dealt: int, hitbox: Hitbox) -> void :
	.on_weapon_hit_something(_thing_hit, damage_dealt, hitbox)
	
	
func shoot() -> void :
	.shoot()
	capybara_mutex = false
	

#func _capybara_projectile_on_hit(thing_hit: Node) -> void:
#	var capybara_args: = WeaponServiceInitStatsArgs.new()
#	var capybara_current_weapon_stats = WeaponService.init_ranged_stats(effects[0].weapon_stats, player_index, false, capybara_args)
#	var capybara_count:int = self.effects[0].value
#	for i in range(0,capybara_count):
#		var capybara_projectile_arg = WeaponServiceSpawnProjectileArgs.new()
#		var capybara_rand_direction = (2.0*PI/capybara_count)*(i+1)
#		WeaponService.spawn_projectile(
#		thing_hit.global_position, 
#		capybara_current_weapon_stats, 
#		capybara_rand_direction, 
#		self, 
#		capybara_projectile_arg
#		)
#
#func _on_Hitbox_hit_something(thing_hit: Node, damage_dealt: int) -> void :
#	._on_Hitbox_hit_something(thing_hit,damage_dealt)
#	if not capybara_mutex:
#		_capybara_projectile_on_hit(thing_hit)
#		capybara_mutex = true
