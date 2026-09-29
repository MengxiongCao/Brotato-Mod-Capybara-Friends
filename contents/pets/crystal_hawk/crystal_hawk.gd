class_name CapybaraCrystalHawk
extends Pet


enum MovementState {
	ORBITING,
	DASHING,
	RETURNING
}


export (String) var damage_tracking_id
export (PackedScene) var marked_texture

export (float) var orbit_radius: = 120.0
export (float) var orbit_angular_speed: = 1.6
export (float) var orbit_follow_speed: = 520.0
export (float) var dash_speed: = 1500.0
export (float) var dash_duration: = 0.8
export (float) var dash_stop_distance: = 24.0
export (float) var dash_pass_through_distance: = 500.0
export (float) var return_speed: = 760.0
export (float) var return_stop_distance: = 8.0
export (int) var projectile_spawns_before_dash: = 4
export (Resource) var sound_of_hawk

var _targets_in_range: = []
var _current_target: = []
var _base_weapon_stats: = WeaponStats.new()
var _current_weapon_stats: = WeaponStats.new()
var _damage_tracking_id_hash: int = Keys.empty_hash
var _cooldown: float = 0.0
var _is_shooting: bool = false
var _next_proj_rotation: = 0.0
var _capybara_player = null
var capybara_crystal_hawk_effect = null
var certain_target = null

var _movement_state: int = MovementState.ORBITING
var _orbit_angle: float = 0.0
var _projectile_spawn_count: int = 0
var _dash_target: Node2D = null
var _dash_destination: Vector2 = Vector2.ZERO
var _dash_time_left: float = 0.0

onready var _muzzle = $Animation / sp_body / muzzle
onready var _hitbox = $"%Hitbox"
onready var _range_shape = $TargetTriggerZone / CollisionShape2D
onready var _sprite = $Animation / sp_body


func init(zone_min_pos: Vector2, zone_max_pos: Vector2, p_players_ref: Array = [], entity_spawner_ref = null) -> void :
	.init(zone_min_pos, zone_max_pos, p_players_ref, entity_spawner_ref)
	projectile_spawns_before_dash = rand_range(projectile_spawns_before_dash * 0.5, projectile_spawns_before_dash * 1.5) as int
	_can_move = false
	_movement_behavior._target_player = true
	_damage_tracking_id_hash = Keys.generate_hash(damage_tracking_id)
	_capybara_player = p_players_ref[player_index]
	_targets_in_range.clear()
	_current_target.clear()
	_movement_state = MovementState.ORBITING
	_orbit_angle = rand_range(0, 2 * PI)
	orbit_radius = rand_range(orbit_radius * 0.5, orbit_radius * 1.5)
	orbit_angular_speed = rand_range(orbit_angular_speed * 0.5, orbit_angular_speed * 1.5)
	_projectile_spawn_count = 0
	_dash_target = null
	_dash_destination = Vector2.ZERO
	_dash_time_left = 0.0
	_hitbox.disable()
	_set_horizontal_facing(Vector2.RIGHT)

	var player_offset: Vector2 = global_position - _capybara_player.global_position
	if player_offset.length_squared() > 0.001:
		_orbit_angle = player_offset.angle()

	for weapon in _capybara_player.current_weapons:
		var cp_weapon: Weapon = weapon
		if not cp_weapon.is_connected("capybara_weapon_hit_something", self, "on_weapon_hit_certain_enemy"):
			cp_weapon.connect("capybara_weapon_hit_something", self, "on_weapon_hit_certain_enemy")


func update_data(effect: PetEffect) -> void :
	.update_data(effect)
	_base_weapon_stats = effect.weapon_stats
	capybara_crystal_hawk_effect = effect

	reload_data()
	_cooldown = _current_weapon_stats.cooldown


func should_data_be_reload() -> bool:
	return true


func reload_data():
	_hitbox.damage = 1
	_hitbox.damage_tracking_key_hash = _damage_tracking_id_hash
	_hitbox.from = self
	var args: = WeaponServiceInitStatsArgs.new()
	_current_weapon_stats = WeaponService.init_structure_pet_stats(_base_weapon_stats, player_index, args)
	if _range_shape:
		_range_shape.shape.radius = _current_weapon_stats.max_range
	_current_weapon_stats.burning_data.from = self


func set_current_stats(stats: Array) -> void :
	_current_weapon_stats = stats[0]
	if _range_shape:
		_range_shape.shape.radius = _current_weapon_stats.max_range
	_current_weapon_stats.burning_data.from = self


func get_stats() -> Array:
	return [_current_weapon_stats]


func _physics_process(delta: float) -> void :
	if dead or _end_of_wave:
		_hitbox.disable()
		return

	_cooldown = max(_cooldown - Utils.physics_one(delta), 0)
	_current_target = Utils.get_nearest(
		_targets_in_range,
		global_position,
		_current_weapon_stats.min_range
	)

	var movement: = Vector2.ZERO
	match _movement_state:
		MovementState.ORBITING:
			movement = _process_orbiting(delta)
			if should_shoot():
				shoot()
		MovementState.DASHING:
			movement = _process_dashing(delta)
		MovementState.RETURNING:
			movement = _process_returning(delta)

	update_animation(movement)


func _process_orbiting(delta: float) -> Vector2:
	if not is_instance_valid(_capybara_player):
		return Vector2.ZERO

	_orbit_angle = fmod(_orbit_angle + orbit_angular_speed * delta, PI * 2.0)
	var orbit_destination: Vector2 = _get_orbit_destination()
	return _move_towards(orbit_destination, orbit_follow_speed, delta)


func _process_dashing(delta: float) -> Vector2:
	_dash_time_left -= delta
	if _dash_time_left <= 0.0:
		_begin_returning()
		return Vector2.ZERO

	if global_position.distance_squared_to(_dash_destination) <= dash_stop_distance * dash_stop_distance:
		_begin_returning()
		return Vector2.ZERO

	var movement: Vector2 = _move_towards(_dash_destination, dash_speed, delta)
	if global_position.distance_squared_to(_dash_destination) <= dash_stop_distance * dash_stop_distance:
		_begin_returning()
	return movement


func _process_returning(delta: float) -> Vector2:
	if not is_instance_valid(_capybara_player):
		return Vector2.ZERO

	var orbit_destination: Vector2 = _get_orbit_destination()
	if global_position.distance_squared_to(orbit_destination) <= return_stop_distance * return_stop_distance:
		global_position = orbit_destination
		_movement_state = MovementState.ORBITING
		return Vector2.ZERO

	var movement: Vector2 = _move_towards(orbit_destination, return_speed, delta)
	if global_position.distance_squared_to(orbit_destination) <= return_stop_distance * return_stop_distance:
		global_position = orbit_destination
		_movement_state = MovementState.ORBITING
	return movement


func _get_orbit_destination() -> Vector2:
	return _capybara_player.global_position + Vector2.RIGHT.rotated(_orbit_angle) * orbit_radius


func _move_towards(destination: Vector2, speed: float, delta: float) -> Vector2:
	var previous_position: Vector2 = global_position
	global_position = global_position.move_toward(destination, max(speed, 0.0) * delta)
	return global_position - previous_position


func should_shoot() -> bool:
	return (
		_movement_state == MovementState.ORBITING
		and _cooldown == 0
		and not _is_shooting
		and _current_target.size() > 0
		and is_instance_valid(_current_target[0])
		and Utils.is_between(
			_current_target[1],
			_current_weapon_stats.min_range,
			_current_weapon_stats.max_range
		)
	)


func shoot() -> void :
	if _current_target.size() == 0 or not is_instance_valid(_current_target[0]):
		_is_shooting = false
		_cooldown = _current_weapon_stats.cooldown
		return

	_is_shooting = true
	var target: Node2D = _current_target[0]
	var target_dir: float = (target.global_position - global_position).angle()
	var accuracy_factor: float = rand_range(
		- 1 + _current_weapon_stats.accuracy,
		1 - _current_weapon_stats.accuracy
	)
	_next_proj_rotation = target_dir + accuracy_factor

	var projectiles: Array = _spawn_projectile(_muzzle.global_position)
	for projectile in projectiles:
		projectile.connect("hit_something", self, "on_pet_hit_something")

	if not projectiles.empty():
		_projectile_spawn_count += 1
	_is_shooting = false
	_cooldown = _current_weapon_stats.cooldown

	if _projectile_spawn_count >= max(projectile_spawns_before_dash, 1):
		if Utils.get_chance_success(0.17):
			SoundManager2D.play(sound_of_hawk, global_position, 10.0, 0.5)
		_begin_dash(target)


func _begin_dash(target: Node2D) -> void:
	if not is_instance_valid(target):
		return

	_projectile_spawn_count = 0
	_dash_target = target
	var dash_direction: Vector2 = target.global_position - global_position
	if dash_direction.length_squared() <= 0.001:
		dash_direction = Vector2.RIGHT if _sprite.scale.x >= 0.0 else Vector2.LEFT
	else:
		dash_direction = dash_direction.normalized()
	var pass_through_distance: float = max(dash_pass_through_distance, 0.0)
	_dash_destination = target.global_position + dash_direction * pass_through_distance
	var required_duration: float = global_position.distance_to(_dash_destination) / max(dash_speed, 1.0)
	_dash_time_left = max(max(dash_duration, 0.01), required_duration + 0.1)
	_movement_state = MovementState.DASHING
	_hitbox.enable()


func _begin_returning() -> void:
	_dash_target = null
	_dash_destination = Vector2.ZERO
	_dash_time_left = 0.0
	_movement_state = MovementState.RETURNING
	_hitbox.disable()


func on_pet_hit_something(thing_hit, damage_dealt) -> void:
	pass


func _spawn_projectile(pos: Vector2) -> Array:
	var list_projectile: Array = []
	for i in _current_weapon_stats.nb_projectiles:
		var proj_weapon_stats = _current_weapon_stats.duplicate()
		var proj_rotation = rand_range(
			_next_proj_rotation - _current_weapon_stats.projectile_spread,
			_next_proj_rotation + _current_weapon_stats.projectile_spread
		)
		var args: = WeaponServiceSpawnProjectileArgs.new()
		args.knockback_direction = Vector2(cos(proj_rotation), sin(proj_rotation))
		args.from_player_index = player_index
		args.damage_tracking_key_hash = _damage_tracking_id_hash
		var projectile = WeaponService.spawn_projectile(pos, proj_weapon_stats, proj_rotation, self, args)
		list_projectile.append(projectile)
	return list_projectile


func _on_TargetTriggerZone_body_entered(body):
	if not _targets_in_range.has(body):
		_targets_in_range.push_back(body)
	if not body.is_connected("died", self, "on_target_died"):
		body.connect("died", self, "on_target_died")


func _on_TargetTriggerZone_body_exited(body):
	_targets_in_range.erase(body)
	if body.is_connected("died", self, "on_target_died"):
		body.disconnect("died", self, "on_target_died")


func on_target_died(target: Node2D, _args: Entity.DieArgs) -> void :
	_targets_in_range.erase(target)
	if target == _dash_target:
		_dash_target = null
		if target is Enemy:
			var node = target.get_node_or_null("capybara_mark")
			if node and node.visible:
				node.visible = false


func update_animation(movement: Vector2) -> void :
	_set_horizontal_facing(movement)
	if not (_animation_player.current_animation == "idle" or _animation_player.current_animation == "pet"):
		_animation_player.play("idle")


func _set_horizontal_facing(movement: Vector2) -> void:
	if movement.x > 0.001:
		sprite.scale.x = abs(sprite.scale.x)
		_sprite.scale.x = abs(_sprite.scale.x)
	elif movement.x < - 0.001:
		sprite.scale.x = - abs(sprite.scale.x)
		_sprite.scale.x = - abs(_sprite.scale.x)


func _can_pet():
	_hitbox.disable()
	yield(get_tree().create_timer(0.1), "timeout")
	_animation_player.play("pet")
	yield(get_tree().create_timer(1.4), "timeout")
	_animation_player.play("idle_pet")


func _on_Hitbox_hit_something(thing_hit, damage_dealt) -> void:
	if thing_hit is Enemy:
		var reload_effects = RunData.get_player_effect(Keys.generate_hash("capybara_reload_when_crystal_hawk_attack"),player_index)
		if reload_effects.size() > 0:
			if _capybara_player and is_instance_valid(_capybara_player):
				for weapon in _capybara_player.current_weapons:
					weapon._current_cooldown = 0
					weapon._current_target = [thing_hit, weapon.stats.max_range]
		var instance = marked_texture.instance()
		instance.name = "capybara_marked"
		var sprite_modify = (thing_hit.sprite.texture.get_size().x / 100.0) - 1.0
		var particle_size = 1.0 + sprite_modify / 3.0
		instance.scale = Vector2(
			particle_size,
			particle_size
		)
		instance.position.y = -thing_hit.sprite.texture.get_size().y / 4.0
		if not thing_hit.get_node_or_null("capybara_marked"):
			thing_hit.add_child(instance)
			if not thing_hit.is_connected("died", self, "on_hunted_enemy_died"):
				thing_hit.connect("died", self, "on_hunted_enemy_died")
		elif not thing_hit.get_node_or_null("capybara_marked").visible:
			thing_hit.get_node_or_null("capybara_marked").visible = true
			if not thing_hit.is_connected("died", self, "on_hunted_enemy_died"):
				thing_hit.connect("died", self, "on_hunted_enemy_died")

func on_hunted_enemy_died(enemy:Enemy, args: Entity.DieArgs) -> void:
	enemy.disconnect("died", self, "on_hunted_enemy_died")
	var effects = RunData.get_player_effect(Keys.generate_hash("capybara_gain_stat_when_killed_hunt"), player_index)
	for effect in effects:
		if effect[0] == Keys.generate_hash("stat_capybara_gold"):
			RunData.add_gold(effect[1], player_index)
			RunData.add_tracked_value(player_index, Keys.generate_hash("character_cp_relic_hunter"), effect[1])

func on_weapon_hit_certain_enemy(thing_hit, damage_dealt) -> void:
	if thing_hit is Enemy:
		if thing_hit.get_node_or_null("capybara_marked"):
			var marked = thing_hit.get_node_or_null("capybara_marked")
			if is_instance_valid(thing_hit) and capybara_crystal_hawk_effect and marked.visible:
				var per = capybara_crystal_hawk_effect.boost_attack_speed / 100.0
				var args = TakeDamageArgs.new(player_index, null)
				if not args.has_meta("capybara_crystal_hawk"):
					args.set_meta("capybara_crystal_hawk", marked_texture)
				thing_hit.take_damage(damage_dealt * per, args)
