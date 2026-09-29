extends Pet

export (Array, Resource) var effects
export (Color) var color_enemy_modulation = Color.salmon
export (AudioStreamSample) var sound_enter_zone
export (AudioStreamSample) var sound_exit_zone
onready var _capybara_flash_timer = $FlashTimer
onready var _cp_ani_pl = $AnimationPlayer2
var _owner:Player
var stat_to_add = 0
onready var _boost_zone: Area2D = $"BoostZone"
var enemies_inside_body:Array = []
var vampire_queen_effect = null
onready var blood_aura = $BoostZone/aura
var _hp_gained_tracking_id_hash: int = Keys.empty_hash
var enemies_inside: int = 0
var healed_value = 0
var _current_weapon_stats:RangedWeaponStats = null
var base_a = 0.2
signal enemies_in_blood_aura(value)
var capybara_main:Main = null

func init(zone_min_pos: Vector2, zone_max_pos: Vector2, p_players_ref: Array = [], entity_spawner_ref = null) -> void :
	.init(zone_min_pos, zone_max_pos, p_players_ref, entity_spawner_ref)
	_capybara_flash_timer.start()
	_owner = p_players_ref[player_index]
	_owner.connect("healed", self, "_shoot_blood_magic")
	capybara_main = get_tree().current_scene

func vampire_queen_win() -> void:
	_animation_player.play("death")

func _shoot_blood_magic(value, player_index) -> void:
	healed_value += value

func update_data(effect: PetEffect) -> void :
	.update_data(effect)
	_can_move = false
	vampire_queen_effect = effect
	var capybara_r = min(vampire_queen_effect.aura_range/100.0 + Utils.get_stat(Keys.stat_range_hash, player_index)/100.0, 5.0)
	_boost_zone.scale = Vector2(capybara_r, capybara_r)

func _on_BoostZone_body_entered(body):
	if not RunData.wave_in_progress:
		return

	if body is Enemy and is_instance_valid(body):
		var enemy = body as Enemy
		enemy._set_color_modulation(color_enemy_modulation)
		enemies_inside_body.append(body)

func _physics_process(delta) -> void:
	_boost_zone.modulate.a = min(base_a + healed_value * 0.08, 1.0) 
	if is_instance_valid(_owner):
		global_position = _owner.global_position
	else:
		return
	if not vampire_queen_effect:
		return
	if healed_value >= vampire_queen_effect.blood_need:
		healed_value -= vampire_queen_effect.blood_need
		var args = WeaponServiceInitStatsArgs.new()
		var weapon_stats = WeaponService.init_ranged_pet_stats(vampire_queen_effect.weapon_stats, player_index, false, args)
		var proj_args = WeaponServiceSpawnProjectileArgs.new()
		_current_weapon_stats = weapon_stats
		proj_args.damage_tracking_key_hash = Keys.generate_hash("character_vampire_queen")
		proj_args.from_player_index = player_index
		var projectile:PlayerProjectile = WeaponService.manage_capybara_spawn_projectile(
			_owner,
			weapon_stats, 
			rand_range(0,2*PI), 
			true,
			_owner._entity_spawner_ref,
			_owner, 
			proj_args
			)
		projectile.connect("hit_something", self, "_capybara_hit_something")

func _capybara_hit_something(thing_hit,damage_dealt) -> void:
	if _current_weapon_stats:
		RunData.manage_life_steal(_current_weapon_stats, player_index)

func _on_FlashTimer_timeout() -> void:
	if _end_of_wave:
		return
	var count = 0
	for enemy in enemies_inside_body:
		if enemy.dead:
			count += 1
	TempStats.remove_stat(vampire_queen_effect.key_hash, vampire_queen_effect.value * stat_to_add, player_index)
	stat_to_add = enemies_inside_body.size() - count
	vampire_queen_effect.enemies_in_aura = stat_to_add
	RunData.capybara_vampire_queen_enemies_in_aura = stat_to_add
	TempStats.add_stat(vampire_queen_effect.key_hash, vampire_queen_effect.value * stat_to_add, player_index)

func _on_BoostZone_body_exited(body):
	if body is Enemy:
		var enemy = body as Enemy
		enemy.remove_color_modulation(color_enemy_modulation)
		enemies_inside_body.erase(body)
		


func update_animation(movement: Vector2) -> void :
	.update_animation(movement)
	if is_instance_valid(_owner) and not _owner.dead and not capybara_main._is_run_won:
		if not (_animation_player.current_animation == "idle_blood_wings"):
			_animation_player.play("idle_blood_wings")
	else:
		_animation_player.play("death")


func _update_transparency(value):
	._update_transparency(value)
	yield(get_tree(), "idle_frame")
	_boost_zone.modulate.a = value
