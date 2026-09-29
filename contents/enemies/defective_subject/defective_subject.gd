class_name DefectiveSubject
extends "res://entities/units/enemies/enemy.gd"

onready var _shooting_attack = $ShootingAttackBehaviour
var attack_time = 3
var main = null
var rotate_speed = 5.0
#onready var shooting_timer = $FlashTimer

func _ready() -> void:
	_shooting_attack.init(self)
	_all_attack_behaviors.push_back(_shooting_attack)
	_attack_behavior.connect("started_shooting", self, "capybara_shoot")
	main = get_tree().current_scene

func capybara_shoot():
	rotate_speed = 10.0
	if self and get_tree():
		yield(get_tree().create_timer(0.6),"timeout")
	rotate_speed = 20.0
	for i in attack_time:
		if self and get_tree():
			yield(get_tree().create_timer(0.3), "timeout")
			if main._cleaning_up:
				return
			_shooting_attack.shoot()
	rotate_speed = 5.0

func _physics_process(delta) -> void:
	if sprite.rotation_degrees > 360.0:
		sprite.rotation_degrees = 0
	else:
		sprite.rotation_degrees += rotate_speed
