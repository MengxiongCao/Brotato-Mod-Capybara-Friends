extends Pet

export (String) var damage_tracking_id
onready var _muzzle = $"%Muzzle"
onready var _gun_pivot = $"%Gun_pivot"
var capybara_trigger_zone_entered = false
var capybara_body = null
var _angle = 0
var _phase = 0
var radius = 100
var rotation_speed = 1
onready var darkfish_collision = $Collision

var _base_weapon_stats: = load("res://mods-unpacked/Dbear-Capybara/contents/pets/dark_fish/dark_fish_weapon_stats.tres")
var _current_weapon_stats: = WeaponStats.new()

var close_player_array: = []
var _targets_in_range: = []
var _current_target: = []

var _cooldown: float = 0.0
var _is_shooting: bool = false
var _next_proj_rotation = 0
var attach_angle = rand_range(0,2*PI)
var attach_radius = rand_range(50,150) as float

var _damage_tracking_id_hash: int = Keys.empty_hash
var capybara_effect

func init(zone_min_pos: Vector2, zone_max_pos: Vector2, p_players_ref: Array = [], entity_spawner_ref = null) -> void :
	_damage_tracking_id_hash = Keys.generate_hash(damage_tracking_id)
	rotation_speed = rand_range(0.5,2.5)
	capybara_trigger_zone_entered = false
	radius = rand_range(100,200)
	capybara_body = null
	_cooldown = _current_weapon_stats.cooldown
	.init(zone_min_pos, zone_max_pos, p_players_ref, entity_spawner_ref)
	_hurtbox.disable()

func update_data(effect: PetEffect) -> void :
	.update_data(effect)

	_base_weapon_stats = effect.weapon_stats

	var args: = WeaponServiceInitStatsArgs.new()
	_current_weapon_stats = WeaponService.init_ranged_pet_stats(effect.weapon_stats, player_index, false, args)
	_current_weapon_stats.burning_data.from = self
	capybara_effect = effect

func should_data_be_reload() -> bool:
	return true

func reload_data():
	var args: = WeaponServiceInitStatsArgs.new()
	_current_weapon_stats = WeaponService.init_ranged_pet_stats(_base_weapon_stats, player_index, false, args)
	_current_weapon_stats.burning_data.from = self

func set_current_stats(stats: Array) -> void :
	_current_weapon_stats = stats[0]
	_current_weapon_stats.burning_data.from = self

func get_stats() -> Array:
	return [_current_weapon_stats]

func _physics_process(delta) -> void :
	if dead: return
	_cooldown = max(_cooldown - Utils.physics_one(delta), 0)
	_current_target = Utils.get_nearest(_targets_in_range, _animation.global_position + _muzzle.global_position - Vector2(100, 100), _current_weapon_stats.min_range)
	if should_shoot(_cooldown, _current_target):
		shoot(_current_target)
		if capybara_body == null:
			_cooldown = _current_weapon_stats.cooldown
		else:
			_cooldown = _current_weapon_stats.cooldown/capybara_effect.boost_attack_speed

	if capybara_body!=null:
		var body_position = capybara_body.global_position
		global_position = Vector2(body_position.x + cos(attach_angle) * attach_radius, body_position.y + sin(attach_angle) * attach_radius)
		
	


func should_shoot(cooldown: float, current_target: Array) -> bool:
	return (cooldown == 0 and 
		not _is_shooting and 
		(
			current_target.size() > 0
			and is_instance_valid(current_target[0])
			and Utils.is_between(current_target[1], _current_weapon_stats.min_range, _current_weapon_stats.max_range)
		)
	)

func shoot(current_target: Array) -> void :
	var muzzle: Node2D = _muzzle
	var gun_pivot: Node2D = _gun_pivot

	if current_target.size() == 0 or not is_instance_valid(current_target[0]):
		_is_shooting = false
	else:
		_animation_player.play("attack")
		var target_dir = (current_target[0].global_position - global_position).angle()
		var accuracy_factor = rand_range( - 1 + _current_weapon_stats.accuracy, 1 - _current_weapon_stats.accuracy)
		_next_proj_rotation = target_dir + accuracy_factor

	var _projectile = _spawn_projectile(_animation.global_position + muzzle.global_position - Vector2(100, 100))
	_is_shooting = false

func _on_TargetTriggerZone_body_entered(body):
	_targets_in_range.push_back(body)
	var _error = body.connect("died", self, "on_target_died")

func _on_TargetTriggerZone_body_exited(body):
	_targets_in_range.erase(body)
	body.disconnect("died", self, "on_target_died")

func _on_PlayerTriggerZone_body_entered(body):
	if body is Pet and body.stats!=stats and capybara_body == null:
		if not capybara_trigger_zone_entered and not body is Player:
			capybara_trigger_zone_entered = true
			capybara_body = body
			_can_move = false
			collision_mask = 0
			collision_layer = 0

func _on_PlayerTriggerZone_body_exited(body):
	if body is Pet and body.stats!=stats:
		if capybara_trigger_zone_entered and not body is Player:
			_animation_player.play("happy")
			capybara_trigger_zone_entered = false
			_can_move = true
			

func _spawn_projectile(position: Vector2) -> Array:
	var list_projectile: Array
	for i in _current_weapon_stats.nb_projectiles:
		var proj_rotation = rand_range(_next_proj_rotation - _current_weapon_stats.projectile_spread, _next_proj_rotation + _current_weapon_stats.projectile_spread)
		var args: = WeaponServiceSpawnProjectileArgs.new()
		args.knockback_direction = Vector2(cos(proj_rotation), sin(proj_rotation))
		args.from_player_index = player_index
		args.damage_tracking_key_hash = _damage_tracking_id_hash
		list_projectile.push_back(WeaponService.spawn_projectile(position, _current_weapon_stats, proj_rotation, self, args))
	return list_projectile

func on_target_died(target: Node2D, _args: Entity.DieArgs) -> void :
	_targets_in_range.erase(target)

func update_animation(movement: Vector2) -> void :
	.update_animation(movement)
	if movement.length() > 0.1:
		if not (_animation_player.current_animation == "move" or _animation_player.current_animation == "pet_the_darkfish" or _animation_player.current_animation == "attack" or _animation_player.current_animation == "happy"):
			_animation_player.play("move")
	elif movement.length() <= 0.1:
		if not (_animation_player.current_animation == "idle_pet" or _animation_player.current_animation == "pet_the_darkfish" or _animation_player.current_animation == "attack" or _animation_player.current_animation == "happy"):
			_animation_player.play("idle_pet")


func _can_pet():
	_can_move = false
	self.mode = RigidBody2D.MODE_STATIC
	_animation_player.play("idle_pet")
	yield(get_tree().create_timer(0.1), "timeout")
	_animation_player.play("pet_the_darkfish")
	yield(get_tree().create_timer(2), "timeout")
	_animation_player.play("idle_pet")
