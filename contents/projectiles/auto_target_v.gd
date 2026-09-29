class_name AutoTargetPlayerProjectileV
extends "res://projectiles/player_projectile.gd"

var _capybara_current_target = []
var _capybara_speed:float = 1.0;
var _capybara_remain:Vector2
var _target_lost: bool = false  # 核心：标记是否丢失过目标
onready var _target_trigger = $TargetTriggerHitbox/Collision
onready var _cp_sprite = $Sprite

func _physics_process(delta: float) -> void :
	._physics_process(delta)

	# 清理无效目标
	_capybara_current_target.erase(_hitbox.ignored_objects)

	# 只有没丢失目标，才追踪
	if not _target_lost:
		if _capybara_current_target.size() > 0 and is_instance_valid(_capybara_current_target[0]):
			var capybara_distance = (_capybara_current_target[0].global_position - global_position).length()
			var capybara_direction = (_capybara_current_target[0].global_position - global_position).normalized()
			if capybara_distance <= _target_trigger.shape.radius:
				velocity = velocity.linear_interpolate(capybara_direction * _capybara_speed, 0.08)
				velocity = velocity.normalized() * _capybara_speed
		else:
			# 丢失目标 → 永久锁方向
			_target_lost = true
			_capybara_remain = velocity

	# 丢失目标后，永远保持最后方向
	if _target_lost:
		velocity = _capybara_remain
	if velocity.x > 0:
		_cp_sprite.flip_h = false
	else:
		_cp_sprite.flip_h = true



func shoot_ex(p_from: Node, 
		pos: Vector2, 
		p_velocity: Vector2, 
		p_rotation: float, 
		p_weapon_stats: WeaponStats, 
		damage_tracking_key: int, 
		effects: Array, 
		hitbox_args: Hitbox.HitboxArgs, 
		knockback_direction: Vector2
		) -> void :

	_hitbox.from = p_from
	spawn_position = pos
	velocity = p_velocity
	_capybara_speed = velocity.length()
	_capybara_remain = velocity
	_target_lost = false
	_weapon_stats = p_weapon_stats
	_piercing = _weapon_stats.piercing
	_bounce = _weapon_stats.bounce
	_max_range = _weapon_stats.max_range

	_hitbox.damage_tracking_key_hash = damage_tracking_key
	set_effects(effects)
	_hitbox.set_damage(p_weapon_stats.damage, hitbox_args)
	_hitbox.set_knockback(knockback_direction, p_weapon_stats.knockback, p_weapon_stats.knockback_piercing)
	_hitbox.effect_scale = p_weapon_stats.effect_scale
	_hitbox.speed_percent_modifier = p_weapon_stats.speed_percent_modifier
	shoot()


func _on_Hitbox_hit_something(thing_hit: Node, damage_dealt: int) -> void :
	_capybara_current_target.erase(thing_hit)
	emit_signal("hit_something", thing_hit, damage_dealt)
	RunData.manage_life_steal(_weapon_stats, _get_player_index())

	_hitbox.ignored_objects.append(thing_hit)

	if _bounce > 0:
		bounce(thing_hit)
	elif _piercing <= 0:
		stop()
	else:
		_piercing -= 1
		if _hitbox.damage > 0:
			_hitbox.damage = max(1, _hitbox.damage - (_hitbox.damage * _weapon_stats.piercing_dmg_reduction))


func bounce(thing_hit: Node) -> void :
	_bounce -= 1
	var target = thing_hit._entity_spawner_ref.get_rand_enemy(thing_hit)
	var direction: float

	if target != null and is_instance_valid(target):
		direction = (target.global_position - global_position).angle()
		_capybara_current_target.append(target)
		_target_lost = false
	else:
		direction = rand_range(-PI, PI)
		_target_lost = true

	velocity = Vector2.RIGHT.rotated(direction) * _capybara_speed
	rotation = velocity.angle()
	_capybara_remain = velocity
	_max_range = INFINITE_RANGE
	_set_time_until_max_range()
	set_knockback_vector(Vector2.ZERO, 0.0, 0.0)

	if _hitbox.damage > 0:
		_hitbox.damage = max(1, _hitbox.damage - (_hitbox.damage * _weapon_stats.bounce_dmg_reduction))

func _on_TargetTriggerHitbox_hit_something(thing_hit: Node, _damage_dealt: int) -> void :
	_target_lost = false
	_capybara_current_target = [thing_hit]


func _on_Hitbox_killed_something(thing_killed):
	pass
