extends Pet
var weapon_stats = load("res://mods-unpacked/Dbear-Capybara/contents/pets/unicorn/unicorn_weapon_stats.tres").duplicate()
var ranged_weapon_stats = load("res://mods-unpacked/Dbear-Capybara/contents/pets/unicorn/unicorn_ranged_stats.tres").duplicate()
var ice_cream_weapon_stats = load("res://mods-unpacked/Dbear-Capybara/contents/pets/unicorn/ice_cream_stats.tres").duplicate()
export (AudioStream) var pet_audio

onready var _hitbox: = $Hitbox as Hitbox
var _is_shooting = false
var _current_weapon_stats = null
var _current_ranged_weapon_stats = null
var _current_ice_cream_stats = null
var _current_cooldown: = 0
var _current_ranged_cooldown: = 0
var thing_killed_count = 0
var light_target = null
var target_in_range = []
var self_effect = null
var is_light_shooting = false
var rush_time = 30
var rush_target = Vector2(0,0)
var ice_cream_shoot = false
var rush_count = 0
var damge_tracking_key_hsh = Keys.generate_hash("item_unicorn_cake")
onready var rainbow = $"%capybara_line_effect"

func init(zone_min_pos: Vector2, zone_max_pos: Vector2, p_players_ref: Array = [], entity_spawner_ref = null) -> void :
	.init(zone_min_pos, zone_max_pos, p_players_ref, entity_spawner_ref)
	thing_killed_count = 0
	init_stats()
	light_target = null
	var is_light_shooting = false
	rainbow.visible = false
	_hitbox.damage_tracking_key_hash = Keys.generate_hash("item_unicorn_cake")
	rush_count = 0

func _unicorn_shoot_light() -> void:
	if not is_instance_valid(self):
		return

	_animation_player.play("fire", true)
	for i in range(0, self_effect.light_count):
		if not is_instance_valid(self):
			break

		var capybara_direction = rand_range(0, 2 * PI)
		var target = Utils.get_rand_element(target_in_range)

		if is_instance_valid(light_target):
			target = light_target

		if is_instance_valid(target):
			capybara_direction = (target.global_position - global_position).angle() + rand_range(-PI/6, PI/6)
		var capybara_projectile_arg = WeaponServiceSpawnProjectileArgs.new()
		capybara_projectile_arg.from_player_index = player_index
		capybara_projectile_arg.damage_tracking_key_hash = damge_tracking_key_hsh
		# 发射子弹（不变）
		var projectile:PlayerProjectile = WeaponService.spawn_projectile(
			global_position,
			_current_ranged_weapon_stats,
			capybara_direction,
			self,
			capybara_projectile_arg
		)

func ice_cream_bullet() -> void:
	var capybara_direction = rand_range(0, 2* PI)
	var target = Utils.get_rand_element(target_in_range)
	if light_target != null:
		target = light_target
	var capybara_projectile_arg = WeaponServiceSpawnProjectileArgs.new()
	capybara_projectile_arg.damage_tracking_key_hash = damge_tracking_key_hsh
	var explosion_effect = load("res://mods-unpacked/Dbear-Capybara/contents/pets/unicorn/ice_cream_explosion_effect.tres")
	capybara_projectile_arg.effects.append(explosion_effect)
	capybara_projectile_arg.from_player_index = player_index
	capybara_projectile_arg.damage_tracking_key_hash = damge_tracking_key_hsh
	if target != null:
		capybara_direction = (target.global_position - global_position).angle() + rand_range(-PI/6,PI/6)
	var projectile = WeaponService.spawn_projectile(
	global_position, 
	_current_ice_cream_stats, 
	capybara_direction, 
	self, 
	capybara_projectile_arg
	)
	projectile.connect("hit_something",self,"unicorn_hit_something")
	

func init_stats(at_wave_begin: bool = true) -> void :
	if self_effect:
		reload_data()
	else:
		var args: = WeaponServiceInitStatsArgs.new()
		_current_weapon_stats = WeaponService.init_melee_pet_stats(weapon_stats, player_index, args)
		_current_ranged_weapon_stats = WeaponService.init_ranged_pet_stats(ranged_weapon_stats, player_index, false, args)
		_current_ice_cream_stats = WeaponService.init_ranged_pet_stats(ice_cream_weapon_stats, player_index, false, args)
	
	_hitbox.projectiles_on_hit = []
	_hitbox.crit_chance = _current_weapon_stats.crit_chance
	_hitbox.crit_damage = _current_weapon_stats.crit_damage
	_hitbox.damage = _current_weapon_stats.damage
	_hitbox.scaling_stats = _current_weapon_stats.scaling_stats

	_current_weapon_stats.burning_data.from = self
	_current_ranged_weapon_stats.burning_data.from = self
	_hitbox.from = self

	_current_cooldown = _current_weapon_stats.cooldown
	_current_ranged_cooldown = _current_ranged_weapon_stats.cooldown

func update_data(effect: PetEffect) -> void :
	.update_data(effect)
	self_effect = effect
	reload_data()

func reload_data() -> void:
	if self_effect:
		var args: = WeaponServiceInitStatsArgs.new()
		_current_weapon_stats = WeaponService.init_melee_pet_stats(self_effect.melee_weapon_stats, player_index, args)
		_current_ranged_weapon_stats = WeaponService.init_ranged_pet_stats(self_effect.ranged_weapon_stats, player_index, false, args)
		_current_ice_cream_stats = WeaponService.init_ranged_pet_stats(self_effect.ice_cream_stats, player_index, false, args)
		_hitbox.damage = _current_weapon_stats.damage
		_hitbox.scaling_stats =  _current_weapon_stats.scaling_stats
		_hitbox.crit_chance =  _current_weapon_stats.crit_chance
		_hitbox.crit_damage =  _current_weapon_stats.crit_damage
		_current_weapon_stats.burning_data.from = self
		_current_ranged_weapon_stats.burning_data.from = self

func _physics_process(delta: float) -> void :
	if _end_of_wave:
		modulate = Color.white
		return
	if thing_killed_count >= self_effect.enemy_needed:
		thing_killed_count -= self_effect.enemy_needed
		RunData.add_stat(Keys.stat_luck_hash, self_effect.value_gain, player_index)
		RunData.add_tracked_value( player_index, damge_tracking_key_hsh, self_effect.value_gain, 1)
	if light_target:
		if light_target.dead:
			light_target = null
	if target_in_range.size() > 0:
		for target in target_in_range:
			if target.dead:
				target_in_range.erase(target)
	if not _is_shooting:
		_current_cooldown = max(_current_cooldown - Utils.physics_one(delta), 0)
	# 核心：冷却到了 **才发射**，并且立刻重置冷却
		
	if _current_cooldown <= 0 and not _is_shooting:
		rainbow.visible = true
		rush_count += 1
		_is_shooting = true
		_hitbox.enable()
		_can_move = false
		_hitbox.deals_damage = true
	
	if not _is_shooting and is_instance_valid(current_target):
		rush_target = (current_target.global_position - global_position).normalized()
	if _is_shooting and rush_time > 0:
		rush_time = max(rush_time - Utils.physics_one(delta), 0)
	if _is_shooting and rush_time <= 15 and not ice_cream_shoot:
		ice_cream_bullet()
		ice_cream_shoot = true
	if _is_shooting and rush_time > 0:
		global_position += rush_target * 30
	elif _is_shooting and rush_time <= 0:
		rainbow.visible = false
		ice_cream_shoot = false
		_can_move = true
		_hitbox.disable()
		_current_cooldown = _current_weapon_stats.cooldown
		_is_shooting = false
		rush_time = 30
		if rush_count >= self_effect.interval:
			_unicorn_shoot_light()
			rush_count = 0

func update_animation(movement: Vector2) -> void :
	.update_animation(movement)
	if movement.length() > 0.1:
		if not (_animation_player.current_animation == "rush" or _animation_player.current_animation == "fire" or _animation_player.current_animation == "move" or _animation_player.current_animation == "eat" or _animation_player.current_animation == "pet"):
			_animation_player.play("move")
	elif movement.length() <= 0.1:
		if not (_animation_player.current_animation == "rush" or _animation_player.current_animation == "fire" or _animation_player.current_animation == "idle" or _animation_player.current_animation == "eat" or _animation_player.current_animation == "pet"):
			_animation_player.play("idle")

func _on_Hitbox_hit_something(thing_hit, damage_dealt):
	RunData.manage_life_steal(_current_weapon_stats, player_index)
	reload_data()

func unicorn_hit_something(thing_hit, damage_dealt):
	if thing_hit is Enemy:
		if thing_hit.dead:
			thing_killed_count += 1
			return
		if not thing_hit.is_connected("died",self,"unicorn_check_target_died"):
			thing_hit.connect("died",self,"unicorn_check_target_died")
		

func unicorn_check_target_died(enemy, args):
	thing_killed_count += 1

func _can_pet():
	rainbow.visible = false
	yield(get_tree().create_timer(0.1), "timeout")
	_animation_player.play("pet")
	SoundManager.play(pet_audio, 1, 0)
	yield(get_tree().create_timer(2), "timeout")
	_animation_player.play("idle")

func _on_Hitbox_killed_something(thing_killed):
	thing_killed_count += 1
	_animation_player.play("eat")

func _on_LightTriggerZone_hit_something(thing_hit, damage_dealt):
	if thing_hit is Boss:
		light_target = thing_hit
	if not target_in_range.has(thing_hit):
		target_in_range.append(thing_hit)
