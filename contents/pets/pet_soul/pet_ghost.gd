class_name CapybaraPetSoul
extends Pet

export (String) var damage_tracking_id
var _targets_in_range: = []
var _current_target: = []

var _base_weapon_stats: = WeaponStats.new()
var _current_weapon_stats: = WeaponStats.new()
var _damage_tracking_id_hash: int = Keys.empty_hash
var _landmine_effect
var _cooldown: float = 0.0
var _is_shooting: bool = false
var capybara_bow_recoil = 0
onready var _range_shape = $TargetTriggerZone / CollisionShape2D
var _capybara_player
var capybara_effect = null
export (float) var rush_time = 30
export (float) var rush_speed = 20
var current_rush_time = 0
onready var _hitbox = $Hitbox
var rush_dir = Vector2.ZERO
onready var body_sp = $Animation/Sprite
export (Resource) var weapon_data
var current_mov = Vector2.ZERO

func init(zone_min_pos: Vector2, zone_max_pos: Vector2, p_players_ref: Array = [], entity_spawner_ref = null) -> void :
	.init(zone_min_pos, zone_max_pos, p_players_ref, entity_spawner_ref)

	_movement_behavior._target_player = true
	_damage_tracking_id_hash = Keys.generate_hash(damage_tracking_id)
	_capybara_player = p_players_ref[player_index]
	_hitbox.disable()
	_hitbox.damage_tracking_key_hash = _damage_tracking_id_hash

func update_data(effect: PetEffect) -> void :
	.update_data(effect)
	_base_weapon_stats = effect.weapon_stats
	capybara_effect = effect

	reload_data()

	_cooldown = _current_weapon_stats.cooldown

func should_data_be_reload() -> bool:
	return true

func reload_data():
	var args: = WeaponServiceInitStatsArgs.new()
	_current_weapon_stats = WeaponService.init_melee_pet_stats(_base_weapon_stats, player_index, args)
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
	if _end_of_wave:
		return
	if not current_rush_time > 0:
		if current_mov.x > 0:
			body_sp.flip_h = false
		else:
			body_sp.flip_h = true
	_cooldown = max(_cooldown - Utils.physics_one(delta), 0)
	if _current_target.size() > 0 and is_instance_valid(_current_target[0]) and not current_rush_time > 0:
		rush_dir = (_current_target[0].global_position - global_position).normalized()
	_current_target = Utils.get_nearest(_targets_in_range, global_position, _current_weapon_stats.min_range)
	if should_shoot() and not current_rush_time > 0:
		_is_shooting = true
		current_rush_time = rush_time
		_cooldown = _current_weapon_stats.cooldown
		_hitbox.projectiles_on_hit = []
		_current_weapon_stats.burning_data.from = self
		_can_move = false
		var hitbox_args: = Hitbox.HitboxArgs.new().set_from_weapon_stats(_current_weapon_stats)
		_hitbox.effect_scale = _current_weapon_stats.effect_scale
		_hitbox.set_damage(_current_weapon_stats.damage, hitbox_args)
		_hitbox.speed_percent_modifier = _current_weapon_stats.speed_percent_modifier
		_hitbox.from = self
		_hitbox.enable()
	current_rush_time = max(0, current_rush_time - Utils.physics_one(delta))
	if current_rush_time > 0:
		global_position += rush_dir * rush_speed
	if not _can_move and not current_rush_time > 0:
		_can_move = true
		_hitbox.disable()
	if not should_shoot() and not current_rush_time > 0:
		_is_shooting = false
	if current_rush_time > 0:
		if rush_dir.x > 0:
			body_sp.flip_h = false
		else:
			body_sp.flip_h = true
func should_shoot() -> bool:
	return (_cooldown == 0 and 
		not _is_shooting and 
		(
			_current_target.size() > 0
			and is_instance_valid(_current_target[0])
			and Utils.is_between(_current_target[1], _current_weapon_stats.min_range, _current_weapon_stats.max_range)
		)
	)

func _on_TargetTriggerZone_body_entered(body):
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
	current_mov = movement

func _on_Hitbox_hit_something(thing_hit, damage_dealt):
	var args: = WeaponServiceInitStatsArgs.new()
	_current_weapon_stats = WeaponService.init_melee_pet_stats(_base_weapon_stats, player_index, args)


func _on_Hitbox_killed_something(thing_killed):
	pass # Replace with function body.
