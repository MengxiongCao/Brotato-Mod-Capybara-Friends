class_name CrystalTurret
extends Turret

var capybara_has_shoot = false
var capybara_projectiles = []
var crystal_level = 0
export (Array, Resource) var crystal_icons = []
export (Array, String) var crystal_data_names = []
var crystal_data = null
onready var energy_bar = $UICrystalTurretProgressBar
var own_player = own_player

func _ready() -> void:
	crystal_level = RunData.get_player_effect(Keys.generate_hash("capybara_crystal_turret_level"), player_index)
	var sprite_level = min(crystal_level,3)
	sprite.texture = crystal_icons[sprite_level]
	_muzzle.position = Vector2(0, - crystal_level * 10.0 - 50.0)
	var main = get_tree().current_scene
	own_player = main._players[player_index]
	if own_player:
		energy_bar.capybara_set_player(own_player)
	energy_bar.rect_position.y = _muzzle.position.y - 50
	

func shoot() -> void :
	if not capybara_has_shoot:
		var capybara_temp_stats = stats.duplicate()
		if stats is RangedWeaponStats:
			stats.nb_projectiles += crystal_level
		.shoot()
		stats = capybara_temp_stats
		capybara_has_shoot = true
		for proj in capybara_projectiles:
			var sprite_level = min(crystal_level,3)
			proj.scale = Vector2(0.8 + sprite_level/10.0, 0.8 + sprite_level/10.0)
#		capybara_manage_next_shoot()
	else:
		for proj in capybara_projectiles:
			if proj.has_method("capybara_set_current_stats"):
				if stats is RangedWeaponStats:
					proj.capybara_set_current_stats(stats)
		return

func capybara_get_muzzle() -> Vector2:
	return _muzzle.global_position

func _spawn_projectile(position: Vector2) -> Node:
	var current_projectile = ._spawn_projectile(position)
	capybara_projectiles.append(current_projectile)
	return current_projectile

#func capybara_manage_next_shoot() -> void:
#	if not dead:
#		yield(get_tree().create_timer(5), "timeout")
#		capybara_has_shoot = false
#		if capybara_projectile and is_instance_valid(capybara_projectile) and capybara_projectile.has_method("capybara_stop"):
#			capybara_projectile.capybara_stop()

func die(args: = Utils.default_die_args) -> void :
	if capybara_projectiles.size() > 0:
		for projectile in capybara_projectiles:
			if is_instance_valid(projectile) and projectile.has_method("capybara_stop"):
				projectile.capybara_stop()
	var capybara_energy_left = energy_bar.capybara_current_energy
	if capybara_energy_left > 0:
		RunData.add_xp(capybara_energy_left, player_index)
		var xp_gained_key = "item_cp_crystal_turret_" + str(crystal_level)
		var xp_gained_key_hash = Keys.generate_hash(xp_gained_key)
		RunData.add_tracked_value(player_index, xp_gained_key_hash, capybara_energy_left, 1)
	.die(args)

func should_shoot() -> bool:
	if energy_bar.capybara_current_energy <= 0:
		capybara_disabled_crystal_turret()
		return false
	var capybara_should_shoot = .should_shoot()
	if capybara_should_shoot and capybara_has_shoot:
		shoot()
	return capybara_should_shoot and not capybara_has_shoot

func set_data(data: Resource) -> void :
	.set_data(data)
	crystal_data = data

func switch_crystal_turret_item(old_level: int, new_level: int, p_player_index: int) -> void :
	
	var new_item = ItemService.get_element(ItemService.items, Keys.generate_hash(crystal_data_names[min(3,crystal_level)]))

	RunData.add_item(new_item, p_player_index)

func capybara_disabled_crystal_turret() -> void:
	if capybara_projectiles.size() > 0:
		for projectile in capybara_projectiles:
			if is_instance_valid(projectile) and projectile.has_method("capybara_stop"):
				projectile.capybara_stop()
	capybara_projectiles.clear()
