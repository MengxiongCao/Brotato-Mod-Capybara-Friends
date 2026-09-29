extends PlayerProjectile

export (Material) var capybara_outline

func _ready() -> void:
	if not _sprite.material:
		_sprite.material = capybara_outline
	if ProgressData.settings.projectile_highlighting:
		_sprite.material.set_shader_param("texture_size", _sprite.texture.get_size())

func shoot() -> void :
	.shoot()
	velocity = Vector2.ZERO
	if not _sprite.material:
		_sprite.material = capybara_outline
	if ProgressData.settings.projectile_highlighting:
		_sprite.material.set_shader_param("texture_size", _sprite.texture.get_size())

func _on_Hitbox_hit_something(thing_hit: Node, damage_dealt: int) -> void :
	._on_Hitbox_hit_something(thing_hit, damage_dealt)
	_hitbox.ignored_objects.erase(thing_hit)
