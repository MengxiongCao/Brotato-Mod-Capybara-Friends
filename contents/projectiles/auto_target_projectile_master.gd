class_name AutoTargetPlayerProjectileMaster
extends "res://projectiles/player_projectile.gd"

var _capybara_current_target = []
var _capybara_speed:float = 1.0;
var _capybara_remain:Vector2
var _target_lost: bool = false  # 核心：标记是否丢失过目标
onready var _target_trigger = $TargetTriggerHitbox/Collision
export (ShaderMaterial) var capybara_shader = null
onready var capybara_sprite = $Sprite
onready var capybara_curse_particles = get_node_or_null("CapybaraCurseParticles")
onready var capybara_collision:CollisionShape2D = $Hitbox/Collision
signal capybara_stop()

func _ready():
	if capybara_curse_particles:
		capybara_curse_particles.visible = false

func stop() -> void :
	.stop()
	emit_signal("capybara_stop")

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

	# 同步方向
	rotation = velocity.angle()

func capybara_update_highlighting(tier, is_cursed:bool = false) -> void :
	if capybara_curse_particles:
		if is_cursed:
			capybara_curse_particles.visible = true
		else:
			capybara_curse_particles.visible = false
	var value = ProgressData.settings.weapon_highlighting
	if tier > 0 and value and capybara_sprite:
		capybara_shader.set_shader_param("outline_color_0", ItemService.get_color_from_tier(tier))
		capybara_shader.set_shader_param("outline_color_1", Color.transparent)
		capybara_shader.set_shader_param("outline_color_2", Color.transparent)
		capybara_shader.set_shader_param("outline_color_3", Color.transparent)
		capybara_shader.set_shader_param("texture_size", capybara_sprite.texture.get_size())
		capybara_shader.set_shader_param("alpha", 1.0)
		capybara_shader.set_shader_param("desaturation", 0.0)
		capybara_sprite.material = capybara_shader
		var outline_sprite = capybara_sprite
		if is_instance_valid(outline_sprite):
			if tier <= 0:
				outline_sprite.visible = false
			else:
				outline_sprite.visible = true
				outline_sprite.modulate = ItemService.get_color_from_tier(tier)
	else:
		if capybara_sprite:
			capybara_sprite.material = null

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
	rotation = p_rotation
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

#	_hitbox.ignored_objects.append(thing_hit)

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
	pass # Replace with function body.


func _on_Hitbox_added_gold_on_crit(gold_added):
	pass # Replace with function body.
