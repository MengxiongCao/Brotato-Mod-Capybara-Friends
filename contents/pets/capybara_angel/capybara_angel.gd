class_name CapybaraAngel
extends Pet

export (String) var damage_tracking_id

onready var _bow = $Animation/Viewport/offset/offset_body/sp_body/bow_pivot_r
onready var _bow_sprite = $Animation/Viewport/offset/offset_body/sp_body/bow_pivot_r/bow_offset/sp_bow
export (PackedScene) var _charm_arrow_scene
var _targets_in_range: = []
var _current_target: = []

var _base_weapon_stats: = WeaponStats.new()
var _current_weapon_stats: = WeaponStats.new()
var _damage_tracking_id_hash: int = Keys.empty_hash
var _landmine_effect
var _cooldown: float = 0.0
var _is_shooting: bool = false
var _next_proj_rotation = 0
var _bow_shooting_sprite = load("res://mods-unpacked/Dbear-Capybara/contents/pets/capybara_angel/cp_angel_bow_shooting.png")
var _bow_idle = load("res://mods-unpacked/Dbear-Capybara/contents/pets/capybara_angel/cp_angel_bow.png")
var capybara_bow_recoil = 0
onready var _range_shape = $TargetTriggerZone / CollisionShape2D
var _capybara_player
export (Resource) var capybara_charm_effect
var bow_rotation_remain = 0
var capybara_angel_effect = null

func init(zone_min_pos: Vector2, zone_max_pos: Vector2, p_players_ref: Array = [], entity_spawner_ref = null) -> void :
	.init(zone_min_pos, zone_max_pos, p_players_ref, entity_spawner_ref)

	_movement_behavior._target_player = true
	_damage_tracking_id_hash = Keys.generate_hash(damage_tracking_id)
	_capybara_player = p_players_ref[player_index]

func update_data(effect: PetEffect) -> void :
	.update_data(effect)
	_base_weapon_stats = effect.weapon_stats
	capybara_angel_effect = effect

	reload_data()

	_cooldown = _current_weapon_stats.cooldown

func should_data_be_reload() -> bool:
	return true

func reload_data():
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

func _physics_process(delta) -> void :
	_cooldown = max(_cooldown - Utils.physics_one(delta), 0)
	_current_target = Utils.get_nearest(_targets_in_range, global_position, _current_weapon_stats.min_range)
	if not capybara_bow_recoil > 0:
		bow_rotate_target()
	if should_shoot():
		shoot()
		capybara_bow_recoil = _base_weapon_stats.cooldown/2
	if capybara_bow_recoil > 0:
		capybara_bow_recoil = max(capybara_bow_recoil - Utils.physics_one(delta), 0)
		_bow_sprite.texture = _bow_shooting_sprite
	else:
		_bow_sprite.texture = _bow_idle

func bow_rotate_target() -> void:
	if _current_target and is_instance_valid(_current_target[0]):
		var target = _current_target[0]
		var target_dir = (target.global_position - global_position).angle()
		var accuracy_factor = rand_range( - 1 + _current_weapon_stats.accuracy, 1 - _current_weapon_stats.accuracy)
		_next_proj_rotation = target_dir + accuracy_factor
		if sprite.scale.x > 0:
			_bow.rotation_degrees = rad2deg(target_dir)
			if target.global_position.x > global_position.x:
				_bow.scale.y = 1
			else:
				_bow.scale.y = - 1
		else:
			_bow.rotation_degrees = int(180 - rad2deg(target_dir)) % 360
			if target.global_position.x > global_position.x:
				_bow.scale.y = - 1
			else:
				_bow.scale.y = 1
	else:
		_bow.rotation_degrees = 0
func should_shoot() -> bool:
	return (_cooldown == 0 and 
		not _is_shooting and 
		(
			_current_target.size() > 0
			and is_instance_valid(_current_target[0])
			and Utils.is_between(_current_target[1], _current_weapon_stats.min_range, _current_weapon_stats.max_range)
		)
	)

func shoot() -> void :
	if _current_target.size() == 0 or not is_instance_valid(_current_target[0]):
		_is_shooting = false
		_cooldown = _current_weapon_stats.cooldown
	else:
		var target_dir = (_current_target[0].global_position - global_position).angle()
		var accuracy_factor = rand_range( - 1 + _current_weapon_stats.accuracy, 1 - _current_weapon_stats.accuracy)
		_next_proj_rotation = target_dir + accuracy_factor
	var muzzle_pos = Vector2(45, 0)
	if sprite.scale.x < 0:
		muzzle_pos = Vector2(-45, 0)
	var _projectile = _spawn_projectile(_animation.global_position + muzzle_pos + Vector2(0, -10))
	_is_shooting = false
	_cooldown = _current_weapon_stats.cooldown
	for projectile in _projectile:
		projectile.connect("hit_something", self, "capybara_angel_hit_something")

func capybara_angel_hit_something(thing_hit, damage_dealt) -> void:
	if thing_hit is Enemy:
		if thing_hit.can_be_charmed:
			RunData.add_tracked_value(player_index, _damage_tracking_id_hash, 1, 1)

func _spawn_projectile(pos: Vector2) -> Array:
	var list_projectile: Array
	for i in _current_weapon_stats.nb_projectiles:
		var charm_arrow = false
		var proj_weapon_stats = _current_weapon_stats.duplicate()
		var proj_rotation = rand_range(_next_proj_rotation - _current_weapon_stats.projectile_spread, _next_proj_rotation + _current_weapon_stats.projectile_spread)
		var args: = WeaponServiceSpawnProjectileArgs.new()
		args.knockback_direction = Vector2(cos(proj_rotation), sin(proj_rotation))
		args.from_player_index = player_index
		args.damage_tracking_key_hash = _damage_tracking_id_hash
		if Utils.get_chance_success(capybara_angel_effect.boost_attack_speed/100.0):
			proj_weapon_stats.projectile_scene = _charm_arrow_scene
			args.effects = [capybara_charm_effect]
			charm_arrow = true
		var projectile = WeaponService.spawn_projectile(pos, proj_weapon_stats, proj_rotation, self, args)
		if charm_arrow:
			list_projectile.append(projectile)
	return list_projectile

func _on_TargetTriggerZone_body_entered(body):
	if not body is Boss:
		_targets_in_range.push_back(body)
		var _error = body.connect("died", self, "on_target_died")

func _on_TargetTriggerZone_body_exited(body):
	_targets_in_range.erase(body)
	body.disconnect("died", self, "on_target_died")

func on_target_died(target: Node2D, _args: Entity.DieArgs) -> void :
	_targets_in_range.erase(target)


func update_animation(movement: Vector2) -> void :
	.update_animation(movement)
	if not (_animation_player.current_animation == "idle" or _animation_player.current_animation == "pet"):
		_animation_player.play("idle")


func _can_pet():
	yield(get_tree().create_timer(0.1), "timeout")
	_animation_player.play("pet")
	yield(get_tree().create_timer(1.4), "timeout")
	_animation_player.play("idle_pet")
