extends "res://weapons/shooting_behaviors/ranged_weapon_shooting_behavior.gd"


func shoot_projectile(rotation: float = _parent.rotation, knockback: Vector2 = Vector2.ZERO) -> Node:
	var capybara_proj = .shoot_projectile(rotation, knockback)
	capybara_proj.scale = _parent.get_parent().get_parent().scale
	return capybara_proj
