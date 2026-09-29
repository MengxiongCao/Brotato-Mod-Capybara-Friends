extends "res://weapons/melee/melee_weapon.gd"
onready var capybara_cursed_particle = $Sprite/Hitbox/CurseUnitParticles as CPUParticles2D

func _ready() -> void:
	if self.is_cursed:
		capybara_cursed_particle.visible = true
	else:
		capybara_cursed_particle.visible = false
