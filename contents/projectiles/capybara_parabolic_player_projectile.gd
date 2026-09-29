class_name CapybaraParabolicPlayerProjectile
extends "res://projectiles/player_projectile.gd"


class CapybaraImpactRing:
	extends Node2D

	var ring_color: Color = Color.white
	var maximum_radius: float = 1.0
	var ring_width: float = 6.0
	var duration: float = 0.3
	var elapsed: float = 0.0
	var progress: float = 0.0
	var wave_strength: float = 8.0
	var wave_count: int = 6
	var wave_speed: float = 10.0
	var inner_delay: float = 0.15
	var random_phase: float = 0.0


	func setup(p_color: Color, p_maximum_radius: float, p_ring_width: float, p_duration: float, p_wave_strength: float, p_wave_count: int, p_wave_speed: float, p_inner_delay: float) -> void:
		ring_color = p_color
		maximum_radius = max(p_maximum_radius, 1.0)
		ring_width = max(p_ring_width, 1.0)
		duration = max(p_duration, 0.01)
		wave_strength = max(p_wave_strength, 0.0)
		wave_count = max(p_wave_count, 2)
		wave_speed = p_wave_speed
		inner_delay = clamp(p_inner_delay, 0.0, 0.8)
		random_phase = rand_range(0.0, PI * 2.0)
		update()


	func _process(delta: float) -> void:
		elapsed = min(elapsed + delta, duration)
		progress = elapsed / duration
		update()
		if progress >= 1.0:
			queue_free()


	func _draw() -> void:
		var eased_progress: float = 1.0 - pow(1.0 - progress, 3.0)
		var radius: float = maximum_radius * eased_progress
		if radius <= 0.0 or progress >= 1.0:
			return

		var fade: float = pow(1.0 - progress, 1.25)
		var current_width: float = max(ring_width * (1.0 - progress * 0.65), 1.0)
		var current_wave_strength: float = wave_strength * (0.35 + 0.65 * fade)
		var phase: float = random_phase + elapsed * wave_speed
		var main_points: PoolVector2Array = _build_wave_points(radius, current_wave_strength, wave_count, phase)
		var glow_color: Color = ring_color
		glow_color.a *= fade * 0.28
		var core_color: Color = ring_color
		core_color.a *= fade
		draw_polyline(main_points, glow_color, current_width * 2.6, true)
		draw_polyline(main_points, core_color, current_width, true)

		var inner_progress: float = clamp((progress - inner_delay) / max(1.0 - inner_delay, 0.01), 0.0, 1.0)
		if inner_progress > 0.0 and inner_progress < 1.0:
			var inner_eased_progress: float = 1.0 - pow(1.0 - inner_progress, 2.5)
			var inner_radius: float = maximum_radius * 0.78 * inner_eased_progress
			var inner_fade: float = (1.0 - inner_progress) * fade * 0.7
			var inner_points: PoolVector2Array = _build_wave_points(inner_radius, current_wave_strength * 0.55, wave_count + 2, -phase * 0.75)
			var inner_glow_color: Color = ring_color
			inner_glow_color.a *= inner_fade * 0.25
			var inner_core_color: Color = ring_color.linear_interpolate(Color.white, 0.25)
			inner_core_color.a = ring_color.a * inner_fade
			draw_polyline(inner_points, inner_glow_color, current_width * 1.8, true)
			draw_polyline(inner_points, inner_core_color, max(current_width * 0.55, 1.0), true)


	func _build_wave_points(base_radius: float, strength: float, frequency: int, phase: float) -> PoolVector2Array:
		var points: PoolVector2Array = PoolVector2Array()
		for i in range(65):
			var angle: float = (PI * 2.0 * i) / 64.0
			var wave: float = sin(angle * frequency + phase) * strength
			wave += sin(angle * (frequency + 3) - phase * 0.7) * strength * 0.45
			var point_radius: float = clamp(base_radius + wave, 1.0, maximum_radius)
			points.append(Vector2(cos(angle), sin(angle)) * point_radius)
		return points


# The arc height is calculated independently from projectile speed, so fast
# projectiles still have a clearly visible parabola.
export(float, 0.0, 1000.0, 5.0) var minimum_arc_height: float = 160.0
export(float, 0.0, 2.0, 0.01) var arc_height_per_distance: float = 0.45
export(float, 0.0, 2000.0, 5.0) var maximum_arc_height: float = 500.0

# 0.8 means that the hitbox is active only during the final 20% of each arc.
export(float, 0.0, 1.0, 0.01) var landing_hitbox_start: float = 0.8

# Keeps the projectile at the landing position briefly so deferred collision
# changes have time to be processed by the physics server.
export(float, 0.01, 1.0, 0.01) var landing_active_time: float = 0.08

export(Color) var impact_ring_color: Color = Color.aquamarine
export(float, 0.01, 2.0, 0.01) var impact_ring_duration: float = 0.3
export(float, 1.0, 64.0, 1.0) var impact_ring_width: float = 15.0
export(float, 0.0, 64.0, 0.5) var impact_ring_wave_strength: float = 8.0
export(int, 2, 16) var impact_ring_wave_count: int = 6
export(float, -30.0, 30.0, 0.5) var impact_ring_wave_speed: float = 10.0
export(float, 0.0, 0.8, 0.01) var impact_ring_inner_delay: float = 0.15


var _capybara_arc_start: Vector2 = Vector2.ZERO
var _capybara_arc_end: Vector2 = Vector2.ZERO
var _capybara_arc_duration: float = 0.0
var _capybara_arc_elapsed: float = 0.0
var _capybara_arc_height: float = 0.0
var _capybara_arc_gravity: float = 0.0
var _capybara_initial_y_speed: float = 0.0
var _capybara_projectile_speed: float = 1.0
var _capybara_landing_elapsed: float = 0.0
var _capybara_is_flying: bool = false
var _capybara_is_landed: bool = false
var _capybara_landing_hitbox_enabled: bool = false
var _capybara_hit_something_this_arc: bool = false
var _capybara_first_hit_this_arc: Node = null
var _capybara_impact_ring_spawned_this_arc: bool = false

func shoot() -> void:
	var launch_velocity: Vector2 = velocity
	.shoot()

	_capybara_projectile_speed = max(launch_velocity.length(), 1.0)
	velocity = Vector2.ZERO
	var target: Node2D = _capybara_get_initial_target(launch_velocity)
	if not is_instance_valid(target):
		stop()
		return
	_capybara_start_arc(global_position, target.global_position)


func _physics_process(delta: float) -> void:
	if _enable_stop_delay:
		_elapsed_delay += 60.0 * delta
		if _elapsed_delay >= stop_delay:
			_return_to_pool()
		return

	if _capybara_is_flying:
		_capybara_update_arc(delta)
	elif _capybara_is_landed:
		_capybara_landing_elapsed += delta
		if _capybara_landing_elapsed >= landing_active_time:
			_capybara_finish_landing()

	if destroy_on_leaving_screen and not ZoneService.current_zone_max_camera_rect.has_point(position):
		stop()


func _capybara_update_arc(delta: float) -> void:
	_capybara_arc_elapsed = min(_capybara_arc_elapsed + delta, _capybara_arc_duration)
	var progress: float = _capybara_arc_elapsed / _capybara_arc_duration
	var current_x: float = lerp(_capybara_arc_start.x, _capybara_arc_end.x, progress)
	var current_y: float = _capybara_arc_start.y + _capybara_initial_y_speed * _capybara_arc_elapsed + 0.5 * _capybara_arc_gravity * _capybara_arc_elapsed * _capybara_arc_elapsed
	global_position = Vector2(current_x, current_y)

	if not _capybara_landing_hitbox_enabled and progress >= clamp(landing_hitbox_start, 0.0, 1.0):
		_capybara_enable_landing_hitbox()

	if progress >= 1.0:
		global_position = _capybara_arc_end
		_capybara_is_flying = false
		_capybara_is_landed = true
		_capybara_landing_elapsed = 0.0
		if not _capybara_landing_hitbox_enabled:
			_capybara_enable_landing_hitbox()


func _capybara_start_arc(start_position: Vector2, end_position: Vector2) -> void:
	var distance: float = start_position.distance_to(end_position)
	if distance <= 0.001:
		stop()
		return

	_capybara_arc_start = start_position
	_capybara_arc_end = end_position
	_capybara_arc_height = clamp(distance * arc_height_per_distance, minimum_arc_height, maximum_arc_height)
	var arc_length: float = _capybara_estimate_arc_length()
	_capybara_arc_duration = max(arc_length / _capybara_projectile_speed, 0.01)
	_capybara_arc_gravity = 8.0 * _capybara_arc_height / (_capybara_arc_duration * _capybara_arc_duration)
	_capybara_initial_y_speed = (end_position.y - start_position.y - 0.5 * _capybara_arc_gravity * _capybara_arc_duration * _capybara_arc_duration) / _capybara_arc_duration
	_capybara_arc_elapsed = 0.0
	_capybara_landing_elapsed = 0.0
	_capybara_is_flying = true
	_capybara_is_landed = false
	_capybara_landing_hitbox_enabled = false
	_capybara_hit_something_this_arc = false
	_capybara_first_hit_this_arc = null
	_capybara_impact_ring_spawned_this_arc = false

	global_position = start_position
	global_rotation = 0.0 if end_position.x >= start_position.x else PI
	velocity = Vector2.ZERO
	_hitbox.active = false
	_hitbox.disable()


func _capybara_estimate_arc_length() -> float:
	var length: float = 0.0
	var previous_point: Vector2 = _capybara_get_arc_point(0.0)
	for i in range(1, 17):
		var progress: float = i / 16.0
		var current_point: Vector2 = _capybara_get_arc_point(progress)
		length += previous_point.distance_to(current_point)
		previous_point = current_point
	return max(length, 0.01)


func _capybara_get_arc_point(progress: float) -> Vector2:
	var linear_position: Vector2 = _capybara_arc_start.linear_interpolate(_capybara_arc_end, progress)
	linear_position.y -= 4.0 * _capybara_arc_height * progress * (1.0 - progress)
	return linear_position


func _capybara_get_initial_target(launch_velocity: Vector2) -> Node2D:
	var source = _hitbox.from
	if is_instance_valid(source) and (source is Weapon or source is Turret):
		var current_target = source._current_target
		if current_target is Array and current_target.size() > 0 and is_instance_valid(current_target[0]):
			return current_target[0]

	return _capybara_get_target_from_scene(launch_velocity)


func _capybara_get_target_from_scene(launch_velocity: Vector2) -> Node2D:
	var main = Utils.get_scene_node()
	if not is_instance_valid(main) or not ("_entity_spawner" in main):
		return null
	var entity_spawner = main._entity_spawner
	if not is_instance_valid(entity_spawner):
		return null

	var direction: Vector2 = launch_velocity.normalized()
	var best_target: Node2D = null
	var best_score: float = -INF
	for enemy in entity_spawner.get_all_enemies(false):
		if not is_instance_valid(enemy) or _hitbox.ignored_objects.has(enemy):
			continue
		var to_enemy: Vector2 = enemy.global_position - global_position
		if to_enemy.length_squared() <= 0.001:
			continue
		var directional_score: float = direction.dot(to_enemy.normalized())
		var score: float = directional_score * 100000.0 - to_enemy.length_squared()
		if score > best_score:
			best_score = score
			best_target = enemy
	return best_target


func _capybara_enable_landing_hitbox() -> void:
	_capybara_landing_hitbox_enabled = true
	_hitbox.active = true
	_hitbox.enable()


func _capybara_finish_landing() -> void:
	if not _capybara_hit_something_this_arc:
		stop()
		return
	if _bounce > 0:
		bounce(_capybara_first_hit_this_arc)
	elif _piercing > 0:
		_capybara_pierce_to_next_target(_capybara_first_hit_this_arc)
	else:
		stop()


func _on_Hitbox_hit_something(thing_hit: Node, damage_dealt: int) -> void:
	emit_signal("hit_something", thing_hit, damage_dealt)
	RunData.manage_life_steal(_weapon_stats, _get_player_index())

	if not _hitbox.ignored_objects.has(thing_hit):
		_hitbox.ignored_objects.append(thing_hit)

	if not _capybara_hit_something_this_arc:
		_capybara_hit_something_this_arc = true
		_capybara_first_hit_this_arc = thing_hit
	if not _capybara_impact_ring_spawned_this_arc:
		_capybara_spawn_impact_ring()


func bounce(thing_hit: Node) -> void:
	_bounce -= 1
	if _hitbox.damage > 0:
		_hitbox.damage = max(1, _hitbox.damage - (_hitbox.damage * _weapon_stats.bounce_dmg_reduction))
	set_knockback_vector(Vector2.ZERO, 0.0, 0.0)
	_capybara_start_next_target_arc(thing_hit)


func _capybara_pierce_to_next_target(thing_hit: Node) -> void:
	_piercing -= 1
	if _hitbox.damage > 0:
		_hitbox.damage = max(1, _hitbox.damage - (_hitbox.damage * _weapon_stats.piercing_dmg_reduction))
	_capybara_start_next_target_arc(thing_hit)


func _capybara_start_next_target_arc(thing_hit: Node) -> void:
	var next_target: Node2D = _capybara_get_next_target(thing_hit)
	if not is_instance_valid(next_target):
		stop()
		return
	_capybara_start_arc(global_position, next_target.global_position)


func _capybara_get_next_target(thing_hit: Node) -> Node2D:
	var entity_spawner = null
	if is_instance_valid(thing_hit) and "_entity_spawner_ref" in thing_hit:
		entity_spawner = thing_hit._entity_spawner_ref
	if not is_instance_valid(entity_spawner):
		var main = Utils.get_scene_node()
		if is_instance_valid(main) and "_entity_spawner" in main:
			entity_spawner = main._entity_spawner
	if not is_instance_valid(entity_spawner):
		return null

	for _attempt in 8:
		var ignored_target = thing_hit if is_instance_valid(thing_hit) else null
		var target = entity_spawner.get_rand_enemy(ignored_target)
		if is_instance_valid(target) and not _hitbox.ignored_objects.has(target):
			return target
	return null


func _capybara_spawn_impact_ring() -> void:
	var collision: CollisionShape2D = _hitbox.get_node_or_null("Collision") as CollisionShape2D
	if not is_instance_valid(collision) or collision.shape == null:
		return
	var effect_parent = get_parent()
	if not is_instance_valid(effect_parent):
		return

	var ring = CapybaraImpactRing.new()
	effect_parent.add_child(ring)
	ring.global_position = collision.global_position
	ring.z_index = z_index + 1
	var radius: float = _capybara_get_collision_radius(collision)
	ring.setup(impact_ring_color, radius, impact_ring_width, impact_ring_duration, impact_ring_wave_strength, impact_ring_wave_count, impact_ring_wave_speed, impact_ring_inner_delay)
	_capybara_impact_ring_spawned_this_arc = true


func _capybara_get_collision_radius(collision: CollisionShape2D) -> float:
	var scale_x: float = collision.global_transform.x.length()
	var scale_y: float = collision.global_transform.y.length()
	if collision.shape is CircleShape2D:
		var circle_shape: CircleShape2D = collision.shape as CircleShape2D
		return circle_shape.radius * max(scale_x, scale_y)
	if collision.shape is RectangleShape2D:
		var rectangle_shape: RectangleShape2D = collision.shape as RectangleShape2D
		return max(rectangle_shape.extents.x * scale_x, rectangle_shape.extents.y * scale_y)
	if collision.shape is CapsuleShape2D:
		var capsule_shape: CapsuleShape2D = collision.shape as CapsuleShape2D
		return max(capsule_shape.radius * scale_x, capsule_shape.height * 0.5 * scale_y)
	return 44.0 * max(scale_x, scale_y)


func stop() -> void:
	_capybara_is_flying = false
	_capybara_is_landed = false
	.stop()
