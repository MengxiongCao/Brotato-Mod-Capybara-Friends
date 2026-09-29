extends PlayerProjectile


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
	.shoot_ex(p_from, pos, p_velocity, p_rotation, p_weapon_stats, damage_tracking_key, effects, hitbox_args, knockback_direction)
	_capybara_keep_sprite_upright(p_rotation)


func bounce(thing_hit: Node) -> void:
	.bounce(thing_hit)
	_capybara_keep_sprite_upright(rotation)


func _capybara_keep_sprite_upright(projectile_rotation: float) -> void:
	if cos(projectile_rotation) < 0.0:
		_sprite.scale.y = -abs(_sprite.scale.y)
	else:
		_sprite.scale.y = abs(_sprite.scale.y)
