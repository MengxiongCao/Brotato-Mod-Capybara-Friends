class_name EnemyParticleAcceleratorProjectile
extends EnemyProjectile

onready var end_container = $EndContainer
onready var start_container = $StartContainer
onready var end_sprite = $EndContainer/EndProjecitle
onready var start_sprite = $StartContainer/StartProjectile
onready var frame = $"%frame"
onready var contents = $Contents
export (int) var shooting_range = 10000.0
onready var sprite2 = $"%Sprite2"


func shoot() -> void :
	if end_container == null:
		end_container = get_node_or_null("EndContainer")

	if start_container == null:
		start_container = get_node_or_null("StartContainer")

	if contents == null:
		contents = get_node_or_null("Contents")

	if end_container == null:
		print("找不到 EndContainer")
		return
	if start_sprite == null:
		start_sprite = $StartContainer/StartProjectile
	if end_sprite == null:
		end_sprite = $EndContainer/EndProjecitle
	if frame == null:
		frame = $"%frame"
	if sprite2 == null:
		sprite2 = $"%Sprite2"
	.shoot()
	if not start_sprite.material:
		start_sprite.material = Utils.projectile_outline_shadermat
		end_sprite.material = Utils.projectile_outline_shadermat
		frame.material = Utils.projectile_outline_shadermat
		sprite2.material =  Utils.projectile_outline_shadermat
	if ProgressData.settings.projectile_highlighting:
		start_sprite.material.set_shader_param("texture_size", _sprite.texture.get_size())
		end_sprite.material.set_shader_param("texture_size", _sprite.texture.get_size())
		frame.material.set_shader_param("texture_size", _sprite.texture.get_size())
		sprite2.material.set_shader_param("texture_size", _sprite.texture.get_size())
	else:
		start_sprite.material.set_shader_param("texture_size", Vector2(0, 0))
		end_sprite.material.set_shader_param("texture_size", Vector2(0, 0))
		frame.material.set_shader_param("texture_size", Vector2(0, 0))
		sprite2.material.set_shader_param("texture_size", Vector2(0, 0))
	_animation_player.playback_speed = 2
	var sprite_w = _sprite.texture.get_width()
	var base_scale_x = max(1.0, float(shooting_range) / float(sprite_w))
	var frame_scale_x = max(1.0, float(shooting_range) / float(frame.texture.get_width()))
	var hitbox_scale_x = max(1.0, (shooting_range + sprite_w * 2.0) / sprite_w)

	_sprite.scale.x = base_scale_x
	frame.scale.x = frame_scale_x
	_hitbox.scale.x = hitbox_scale_x
	_hitbox.position.x = - sprite_w
	end_container.position.x = shooting_range + sprite_w
	contents.position.x = sprite_w
	start_container.position.x = 0

func _on_Hitbox_hit_something(_thing_hit: Node, _damage_dealt: int) -> void :
	pass
