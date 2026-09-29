class_name CapyabaraWanderingTurretProjectile
extends PlayerProjectile

onready var end_container = $EndContainer
onready var start_container = $StartContainer
onready var contents = $Contents
signal rainbow_killed_something(thing_killed)


func shoot() -> void :
	.shoot()
	start_container.modulate.a = ProgressData.settings.projectile_opacity
	end_container.modulate.a = ProgressData.settings.projectile_opacity

	_animation_player.playback_speed = 2
	var sprite_w = _sprite.texture.get_width()
	var base_scale_x = max(1.0, float(_weapon_stats.max_range) / float(sprite_w))
	var hitbox_scale_x = max(1.0, (_weapon_stats.max_range + sprite_w * 2.0) / sprite_w)

	_sprite.scale.x = base_scale_x
	_hitbox.scale.x = hitbox_scale_x
	_hitbox.position.x = - sprite_w
	end_container.position.x = _weapon_stats.max_range + sprite_w
	contents.position.x = sprite_w
	start_container.position.x = 0



func _on_Hitbox_killed_something(thing_killed):
	# 先判断来源是否有效
	if is_instance_valid(_hitbox.from):
		# 直接修改来源（独角兽）的变量！
		if "thing_killed_count" in _hitbox.from:
			_hitbox.from.thing_killed_count += 1
